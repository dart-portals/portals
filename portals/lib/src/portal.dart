import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:portals/src/connections/mailbox_server_connection.dart';
import 'package:portals/src/connections/server_connection.dart';

import 'errors.dart';
import 'phrase_generators/phrase_generator.dart';
import 'connections/dilated_connection.dart';
import 'connections/mailbox_connection.dart';
import 'constants.dart';
import 'events.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

/// Portals are strongly encrypted peer-to-peer connections.
/// Inspired by [Magic Wormhole](https://github.com/warner/magic-wormhole/).
///
/// To connect two devices, you need to create a portal on each of them.
///
/// On the first device:
/// ```
/// var portal = Portal(appId: 'my.app.example.com');
/// String phrase = await portal.open();
/// // TODO: Show the phrase to the user.
/// String key = await portal.waitForLink();
/// await portal.waitUntilReady();
/// ```
/// On the second device:
/// ```
/// var portal = Portal(appId: 'my.app.example.com');
/// // TODO: Let the user enter the phrase.
/// String key = await portal.openAndLinkTo(phrase);
/// await portal.waitUntilReady();
/// ```
class Portal {
  Portal({
    @required this.appId,
    this.info = '',
    this.mailboxServerUrl = defaultMailboxServerUrl,
    this.phraseGenerator = defaultCodeGenerator,
  })  : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(info != null),
        assert(mailboxServerUrl != null),
        assert(mailboxServerUrl.isNotEmpty) {
    _events = _eventController.stream.asBroadcastStream();
  }

  /// The id of your app.
  ///
  /// This doesn't really just have to be a domain you own, but it should be
  /// unique to your application. You can only connect to portals with the same
  /// [appId]. Theoretically, you can also use the same [appId] for multiple
  /// applications, but that makes the [phrase]s potentially longer, because
  /// there are probably more users connecting concurrently.
  final String appId;

  /// Information about your portal.
  ///
  /// Before trying to establish a peer-to-peer connection, portals exchange
  /// this [info]. The other side's info is available at [remoteInfo].
  /// This usually contains meta-information about the connection, like
  /// supported protocol versions or a human-readable display name of the user.
  final String info;

  /// The url of the mailbox server, which is used by portals to exchange
  /// information for direct peer-to-peer connections.
  ///
  /// If you are creating heavy loads, it's recommended that you run your own
  /// server. The server is just a plain old Magic Wormhole server, as can be
  /// seen at [the magic wormhole mailbox server repo](https://github.com/warner/magic-wormhole-mailbox-server).
  final String mailboxServerUrl;

  /// A converter between two Uint8Lists to a human-readable string.
  final PhraseGenerator phraseGenerator;

  /// The [info] of the other portal.
  String get remoteInfo => _remoteInfo;
  String _remoteInfo;

  /// A [String] that uniquely identifies this portal.
  String get phrase => _phrase;
  String _phrase;

  /// A [Uint8List] that represents the key used by both portals.
  ///
  /// Actually, this is a hash of the key, because the actual key is irrelevant
  /// for the rest of the app.
  Uint8List get key => _key;
  Uint8List _key;

  /// Events that this portal emits.
  Stream<PortalEvent> get events => _events;
  Stream<PortalEvent> _events;
  final _eventController = StreamController<PortalEvent>();
  void _registerEvent(PortalEvent event) => _eventController.add(event);

  // Different layers of connections.
  ServerConnection _server;
  MailboxServerConnection _mailboxServer;
  MailboxConnection _mailbox;
  DilatedConnection _client;

  Future<void> _setup([String phrase]) async {
    // Extract short key and nameplate from the phrase.
    _registerEvent(PortalOpening());
    final payload = phrase?.toPhrasePayload(phraseGenerator);
    final shortKey = payload?.key ?? PhraseGenerator.generateShortKey();
    var nameplate = payload?.nameplate?.utf8decoded;

    // Connect to the server.
    _server = ServerConnection(url: mailboxServerUrl);
    await _server.connect();
    _registerEvent(PortalServerReached());

    // Set up the mailbox server.
    _mailboxServer = MailboxServerConnection(server: _server, appId: appId);
    _mailboxServer.initialize(isFirstPortal: phrase == null);
    await _mailboxServer.bindAndWelcome();
    nameplate ??= await _mailboxServer.allocateNameplate();
    final mailbox = await _mailboxServer.claimNameplate(nameplate);
    await _mailboxServer.openMailbox(mailbox);

    // Create phrase.
    final phrasePayload = PhrasePayload(
      key: shortKey,
      nameplate: nameplate.utf8encoded,
    );
    _phrase = phraseGenerator.payloadToPhrase(phrasePayload);
    ifInDebugMode(() {
      PhraseGenerator.ensureGeneratorReversible(
        generator: phraseGenerator,
        payload: phrasePayload,
        generatedPhrase: _phrase,
      );
    });
    _registerEvent(PortalOpened(phrase: _phrase));

    // Create an encrypted connection over the mailbox and save its key hash.
    _mailbox = MailboxConnection(server: _mailboxServer, shortKey: shortKey);
    await _mailbox.initialize();
    _remoteInfo = await _mailbox.exchangeInfo(info);
    _key = sha256(_mailbox.key);
    _registerEvent(PortalLinked(key: _key));

    // Try several connections to the other client.
    _registerEvent(PortalConnecting());
    _client = DilatedConnection(mailbox: _mailbox);
    await _client.establishConnection();
    _registerEvent(PortalConnected());
  }

  /// Opens this portal.
  Future<String> open() async {
    unawaited(_setup());
    return waitForPhrase();
  }

  /// Opens this portal and links it to the given [phrase].
  Future<Uint8List> openAndLinkTo(String phrase) async {
    unawaited(_setup(phrase));
    return waitForLink();
  }

  Future<String> waitForPhrase() async {
    if (phrase != null) return phrase;
    return (await events.whereType<PortalOpened>().first).phrase;
  }

  /// Waits for a link.
  Future<Uint8List> waitForLink() async {
    if (key != null) return key;
    return (await events.whereType<PortalLinked>().first).key;
  }

  Future<void> waitUntilReady() => events.whereType<PortalConnected>().first;

  /// Sends the given message to the linked portal.
  void send(Uint8List message) => _client.send(message);

  /// Receives a message from the linked portal.
  Future<Uint8List> receive() => _client.receive();

  /// Closes this portal.
  Future<void> close() async {
    _remoteInfo = null;
    _phrase = null;
    _key = null;

    final hadConnection = _client != null;

    _client.close();
    _client = null;

    _mailbox = null;

    _mailboxServer.releaseNameplate();
    _mailboxServer.closeMailbox(hadConnection ? Mood.happy : Mood.lonely);
    _mailboxServer = null;

    await _server.close();
    _server = null;
  }
}

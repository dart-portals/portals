import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:portals/src/connections/mailbox_server_connection.dart';
import 'package:portals/src/connections/server_connection.dart';
import 'package:version/version.dart';

import 'code_generators/code_generator.dart';
import 'connections/dilated_connection.dart';
import 'connections/mailbox_connection.dart';
import 'constants.dart';
import 'events.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

class Portal {
  Portal({
    @required this.appId,
    @required this.version,
    this.relayUrl = defaultRelayUrl,
    this.codeGenerator = defaultCodeGenerator,
  })  : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(relayUrl != null),
        assert(relayUrl.isNotEmpty) {
    _events = _eventController.stream.asBroadcastStream();
  }

  final String appId;
  final Version version;
  final String relayUrl;
  final CodeGenerator codeGenerator;

  Version _remoteVersion;
  Version get remoteVersion => _remoteVersion;

  // Different layers of connections.
  ServerConnection _server;
  MailboxServerConnection _mailboxServer;
  MailboxConnection _mailbox;
  DilatedConnection _client;

  // Events that this portal emits.
  final _eventController = StreamController<PortalEvent>();
  Stream<PortalEvent> _events;
  Stream<PortalEvent> get events => _events;
  void _registerEvent(PortalEvent event) => _eventController.add(event);

  Future<void> _setup([String code]) async {
    // Extract short key and nameplate from the code.
    final payload = code == null ? null : codeGenerator.codeToPayload(code);
    Uint8List shortKey = payload?.key ?? CodeGenerator.generateShortKey();
    String nameplate =
        payload?.nameplate == null ? null : utf8.decode(payload?.nameplate);

    // Connect to the server.
    _server = ServerConnection(url: relayUrl);
    _server.connect();
    _registerEvent(PortalServerReached());

    // Set up the mailbox server.
    _mailboxServer = MailboxServerConnection(server: _server, appId: appId);
    _mailboxServer.initialize();
    await _mailboxServer.bindAndWelcome();
    nameplate ??= await _mailboxServer.allocateNameplate();
    final mailbox = await _mailboxServer.claimNameplate(nameplate);
    await _mailboxServer.openMailbox(mailbox);

    _registerEvent(PortalOpened(
      code: codeGenerator.payloadToCode(CodePayload(
        key: shortKey,
        nameplate: utf8.encode(nameplate),
      )),
    ));

    // Create an encrypted connection over the mailbox and save its key hash.
    _mailbox = MailboxConnection(server: _mailboxServer, shortKey: shortKey);
    await _mailbox.initialize();
    _remoteVersion = await _mailbox.exchangeVersions(version);
    _registerEvent(PortalLinked(sharedKeyHash: sha256(_mailbox.key)));

    // Try several connections to the other client.
    _client = DilatedConnection(mailbox: _mailbox);
    await _client.establishConnection();
    // print('Established connection.');
    _registerEvent(PortalReady());
  }

  /// Opens this portal.
  Future<String> open() async {
    unawaited(_setup());
    return (await events.whereType<PortalOpened>().first).code;
  }

  /// Waits for a link.
  Future<Uint8List> waitForLink() async {
    return (await events.whereType<PortalLinked>().first).sharedKeyHash;
  }

  /// Opens this portal and links it to the given [code].
  Future<Uint8List> openAndLinkTo(String code) async {
    unawaited(_setup(code));
    return (await events.whereType<PortalLinked>().first).sharedKeyHash;
  }

  Future<void> waitUntilReady() => events.whereType<PortalReady>().first;

  /// Sends the given message to the linked portal.
  void send(Uint8List message) => _client.send(message);

  /// Receives a message from the linked portal.
  Future<Uint8List> receive() => _client.receive();

  Future<void> close() async {
    //await _mailbox.close();
  }
}

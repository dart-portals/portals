/// Connections between the client and the server. For more information about
/// how the communication is structured, check out
/// https://github.com/warner/magic-wormhole/blob/master/docs/server-protocol.md

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'errors.dart';
import 'spake2/ed25519.dart';
import 'spake2/hkdf.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

/// A simple connection to the server.
///
/// Initially, the portal connects to a server. Portals use this server to
/// negotiate an end-to-end encrypted connection and exchange ip address
/// inforamtion in order to be able to create a direct peer-to-peer connection.
/// /// Portals use the Magic Wormhole protocol for communicating, so if you're
/// wondering how the server works or you want to run your own server, check
/// out the Magic Wormhole server repository:
/// https://github.com/warner/magic-wormhole-mailbox-server
class _ServerConnection {
  _ServerConnection({@required this.url})
      : assert(url != null),
        assert(url.isNotEmpty);

  final String url;

  IOWebSocketChannel _server;
  StreamQueue<String> _incomingData;

  Future<void> initialize() async {
    try {
      _server = IOWebSocketChannel.connect(
        url,
        pingInterval: Duration(minutes: 1),
      );
      _incomingData = StreamQueue<String>(_server.stream.cast<String>());
    } on WebSocketChannelException {
      throw PortalCannotConnectToServerException(url);
    }
  }

  void send(Map<String, dynamic> data) => _server.sink.add(json.encode(data));

  Future<Map<String, dynamic>> receive({String type}) async {
    try {
      while (true) {
        final response =
            json.decode(await _incomingData.next) as Map<String, dynamic>;
        if (type == null || response['type'] == type) {
          return response;
        }
      }
    } on FormatException {
      throw PortalServerCorruptException('Portal sent a non-json packet.');
    } on TypeError {
      throw PortalServerCorruptException(
          'The server sent a packet without a type.');
    }
  }
}

/// A mailbox connection over the server.
///
/// Connects to the server and opens a mailbox.
/// The server doesn't really do anything except offering "mailboxes", which
/// clients can connect to. Mailboxes are identified using large ids. Clients
/// can send messages to a mailbox, which will then get sent to everyone
/// connected to that mailbox.
/// In order to make the communication between the clients easier, there are
/// nameplates. Nameplates are short strings that point to a single mailbox and
/// can be claimed and released by clients.
/// Typically, one client allocates and claims a nameplate. Then, the nameplate
/// is transcribed to the second client, which also claims the nameplate to
/// retrieve the id of the connected mailbox. Now, both clients can connect to
/// the mailbox using the large id. Also, they can release the nameplate to
/// allow other clients to reuse the nameplate for another mailbox.
class MailboxConnection {
  MailboxConnection({
    @required String url,
    @required this.appId,
    String nameplate,
  })  : assert(appId != null),
        assert(appId.isNotEmpty),
        _connection = _ServerConnection(url: url),
        _nameplate = nameplate;

  final _ServerConnection _connection;
  final String appId;

  /// Each client has a [side]. By default, we receive everything sent to the
  /// mailbox. We can use the side to filter out the messages that come from
  /// clients other than us.
  String _side;
  String get side => _side;

  /// A mailbox can have a [nameplate]. If one is provided, we try to connect
  /// to that nameplate's mailbox. Otherwise, we'll allocate a new nameplate.
  String _nameplate;
  String get nameplate => _nameplate;

  String _mailbox;

  Future<void> initialize() async {
    await _connection.initialize();

    // If two clients have the same side, that's bad – they'll just ignore
    // everything. So, we choose a reasonably large random string as our side.
    final random = Random();
    _side = [
      for (var i = 0; i < 32; i++) random.nextInt(16).toRadixString(16),
    ].join();

    _bindToAppIdAndSide();
    await _receiveWelcome();

    if (nameplate == null) {
      await _allocateNameplate();
    }
    await _claimNameplate(nameplate);
    await _openMailbox();
  }

  void _bindToAppIdAndSide() =>
      _connection.send({'type': 'bind', 'appid': appId, 'side': _side});

  Future<void> _receiveWelcome() async {
    try {
      final welcomeMessage = await _connection.receive(type: 'welcome');
      final welcome = welcomeMessage['welcome'] as Map<String, dynamic>;

      // The welcome message can optionally contain an error message. If we
      // get one, we should terminate.
      if (welcome.containsKey('error')) {
        throw PortalInternalServerErrorException(welcome['error']);
      }

      // The welcome message can optionally contain a "motd" message with
      // information for developers, like notifications about performance
      // problems, scheduled downtime or the need for money donations to keep
      // the server running.
      assert(() {
        if (welcome.containsKey('motd')) {
          print(welcome['motd']);
        }
        return true;
      }());
    } on TypeError {
      throw PortalServerCorruptException(
          "Server's first packet didn't include a welcome message.");
    }
  }

  Future<void> _allocateNameplate() async {
    _connection.send({'type': 'allocate'});

    final allocation = await _connection.receive(type: 'allocated');
    try {
      _nameplate = allocation['nameplate'] as String;
    } on CastError {
      throw PortalServerCorruptException(
          'The nameplate that the server responded with was not a string.');
    }
    if (_nameplate == null) {
      throw PortalServerCorruptException(
          "The packet confirming the nameplate allocation didn't contain "
          'the allocated nameplate.');
    }
  }

  /// By allocating a nameplate, we automatically claim it. But it's good
  /// practice to claim it anyway.
  Future<void> _claimNameplate(String nameplate) async {
    _connection.send({'type': 'claim', 'nameplate': nameplate});

    final claim = await _connection.receive(type: 'claimed');
    try {
      _mailbox = claim['mailbox'] as String;
    } on CastError {
      throw PortalServerCorruptException(
          'The mailbox id that the server responded with was not a string.');
    }
    if (_nameplate == null) {
      throw PortalServerCorruptException(
          "The packet confirming the claim of the nameplate didn't contain "
          'the id of the mailbox that the nameplate points to.');
    }
  }

  void _openMailbox() =>
      _connection.send({'type': 'open', 'mailbox': _mailbox});

  void send({@required String phase, @required String message}) async {
    assert(phase != null);
    assert(message != null);

    _connection.send({'type': 'add', 'phase': phase, 'body': message});
  }

  Future<Map<String, dynamic>> receive({@required String phase}) async {
    while (true) {
      final response = await _connection.receive(type: 'message');

      if (response['side'] == _side) continue;
      if (phase == null || response['phase'] == phase) {
        return response;
      }
    }
  }
}

/// An encrypted connection over a mailbox.
///
/// Clients connected to the same mailbox can talk to each other. This layer
/// provides an abstraction on top to enable clients to negotiate a shared key
/// and from there on send each other end-to-end encrypted messages.
/// Spake2 allows this to happen: Both clients independently provide Spake2
/// with a short shared secret key. Spake2 then generates a random internal
/// Ed25519 point and returns a message that clients exchange and feed into
/// their instance of the Spake2 algorithm. The result will be that both
/// client's Spake2 algorithms deterministically generate the same long shared
/// super-secure key that can be used for further end-to-end encryption.
class EncryptedMailboxConnection {
  EncryptedMailboxConnection({
    @required this.mailbox,
    @required this.shortKey,
  })  : assert(mailbox != null),
        assert(shortKey != null),
        assert(shortKey.isNotEmpty);

  final MailboxConnection mailbox;
  final Uint8List shortKey;

  Uint8List _key;
  Uint8List get key => _key;
  Uint8List computeKeyHash() => sha256(_key);

  Future<void> initialize() async {
    final spake = Spake2(id: utf8.encode(mailbox.appId), password: shortKey);
    final outbound = spake.start();

    await mailbox.send(
      phase: 'pake',
      message: json.encode({'pake_v1': bytesToHex(outbound)}),
    );

    try {
      final inboundMessage = json.decode(
        (await mailbox.receive(phase: 'pake'))['body'],
      );
      final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
      _key = spake.finish(inboundBytes);
    } on TypeError {
      throw OtherPortalCorruptException(
          'The other portal sent a pake message without a body.');
    } on HkdfException {
      throw PortalEncryptionFailedException();
    } on Ed25519Exception {
      throw PortalEncryptionFailedException();
    }
  }

  Uint8List _deriveKey(Uint8List purpose) {
    try {
      return Hkdf(null, _key).expand(purpose, length: SecretBox.keyLength);
    } on HkdfException {
      throw PortalEncryptionFailedException();
    }
  }

  Uint8List _derivePhaseKey(String side, String phase) {
    final sideHash = bytesToHex(sha256(ascii.encode(side)));
    final phaseHash = bytesToHex(sha256(ascii.encode(phase)));
    final purpose = 'wormhole:phase:$sideHash$phaseHash';
    return _deriveKey(ascii.encode(purpose));
  }

  Uint8List _encryptData({@required Uint8List key, @required Uint8List data}) =>
      SecretBox(key).encrypt(data);

  Uint8List _decryptData({
    @required Uint8List key,
    @required Uint8List encryptedBytes,
  }) {
    try {
      return SecretBox(key).detectNonceAndDecrypt(encryptedBytes);
    } on String {
      throw PortalEncryptionFailedException();
    }
  }

  Future<void> send({@required String phase, @required String message}) async {
    final encrypted = bytesToHex(_encryptData(
      key: _derivePhaseKey(mailbox.side, phase),
      data: utf8.encode(message),
    ));
    mailbox.send(phase: phase, message: encrypted);
  }

  Future<String> receive({@required String phase}) async {
    final message = await mailbox.receive(phase: phase);
    try {
      return utf8.decode(_decryptData(
        key: _derivePhaseKey(message['side'], message['phase']),
        encryptedBytes: hexToBytes(message['body']),
      ));
    } on TypeError {
      throw OtherPortalCorruptException(
          'Other portal sent a message without a side, phase or body.');
    } on Exception {
      throw PortalEncryptionFailedException();
    }
  }
}

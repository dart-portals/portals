import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';
import 'package:portals/src/code_generators/code_generator.dart';
import 'package:portals/src/errors.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'spake2/hkdf.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

/// A simple connection to the server.
///
/// Offers send and receive calls for communicating with the server using json.
class _ServerConnection {
  _ServerConnection({@required this.url})
      : assert(url != null),
        assert(url.isNotEmpty);

  final String url;

  IOWebSocketChannel _relay;
  StreamQueue<String> _relayReceiver;

  Future<void> initialize() async {
    try {
      _relay = IOWebSocketChannel.connect(url);
      _relayReceiver = StreamQueue<String>(_relay.stream.cast<String>());
    } on WebSocketChannelException {
      throw PortalCannotConnectToServerException();
    }
  }

  void send(Map<String, dynamic> data) => _relay.sink.add(json.encode(data));

  Future<Map<String, dynamic>> receive({String type}) async {
    while (true) {
      final response =
          json.decode(await _relayReceiver.next) as Map<String, dynamic>;
      if (type == null || response['type'] == type) {
        return response;
      }
      if (response['type'] != 'ack') print(response);
    }
  }
}

/// A mailbox connection over the server.
///
/// Connects to the server and opens a mailbox.
/// Offers sending and receiving messages for communicating with other clients
/// connected to the same mailbox.
class MailboxConnection {
  /// Each mailbox has a [nameplate]. If one is provided, we try to connect to
  /// that mailbox. Otherwise, we'll allocate a new mailbox.
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

  String _nameplate;
  String get nameplate => _nameplate;

  String _side;
  String get side => _side;

  Future<void> initialize() async {
    await _connection.initialize();

    // Each client connected to the mailbox has a side. Messages have a "side"
    // attribute, so the side can be used to filter for messages that others
    // sent.
    // If two clients have the same side, that's bad – they'll just ignore
    // everything. So, we choose a reasonably large random string for a side.
    final random = Random();
    _side = [
      for (int i = 0; i < 10; i++) random.nextInt(16).toRadixString(16),
    ].join();
    print('Side is $_side');

    await _receiveWelcome();
    _bindToAppIdAndSide();

    _nameplate ??= await _allocateNameplate();
    final mailbox = await _claimNameplate(nameplate);
    await _openMailbox(mailbox);
  }

  Future<void> _receiveWelcome() async {
    final welcomeMessage = await _connection.receive(type: 'welcome');
    // TODO: throw server errors
    assert(!(welcomeMessage['welcome'] as Map<String, dynamic>)
        .containsKey('error'));
  }

  void _bindToAppIdAndSide() {
    _connection.send({'type': 'bind', 'appid': appId, 'side': _side});
  }

  // TODO: handle non-successful claims
  Future<String> _claimNameplate(String nameplate) async {
    _connection.send({'type': 'claim', 'nameplate': nameplate});
    final claim = await _connection.receive(type: 'claimed');

    final mailbox = claim['mailbox'] as String;
    assert(mailbox != null);
    return mailbox;
  }

  Future<String> _allocateNameplate() async {
    _connection.send({'type': 'allocate'});
    final allocation = await _connection.receive(type: 'allocated');

    final nameplate = allocation['nameplate'] as String;
    assert(nameplate != null);
    return nameplate;
  }

  void _openMailbox(String mailbox) {
    _connection.send({'type': 'open', 'mailbox': mailbox});
  }

  void send({@required String phase, @required String message}) async {
    assert(phase != null);
    _connection.send({'type': 'add', 'phase': phase, 'body': message});
  }

  Future<Map<String, dynamic>> receive({@required String phase}) async {
    Map<String, dynamic> response;
    while (true) {
      response = await _connection.receive(type: 'message');
      if (response['side'] == _side) continue;
      if (phase == null || response['phase'] == phase) break;
    }
    return response;
  }
}

/// An encrypted connection over a mailbox.
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

  Uint8List computeKeyHash() => sha256(_key);

  Future<void> initialize() async {
    // Agree on a shared key by exchange pake messages.
    final spake = Spake2(id: utf8.encode(mailbox.appId), password: shortKey);
    final outbound = spake.start();

    await mailbox.send(
      phase: 'pake',
      message: json.encode({'pake_v1': bytesToHex(outbound)}),
    );

    final inboundMessage = json.decode(
      (await mailbox.receive(phase: 'pake'))['body'],
    );
    final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
    _key = spake.finish(inboundBytes);
  }

  Uint8List _deriveKey(Uint8List purpose) =>
      Hkdf(null, _key).expand(purpose, length: SecretBox.keyLength);

  Uint8List _derivePhaseKey(String side, String phase) {
    final sideHash = bytesToHex(sha256(ascii.encode(side)));
    final phaseHash = bytesToHex(sha256(ascii.encode(phase)));
    final purpose = 'wormhole:phase:$sideHash$phaseHash';
    return _deriveKey(ascii.encode(purpose));
  }

  Uint8List _encryptData({@required Uint8List key, @required Uint8List data}) {
    final encrypted = SecretBox(key).encrypt(data);
    return encrypted;
  }

  Uint8List _decryptData({
    @required Uint8List key,
    @required Uint8List encryptedBytes,
  }) {
    final encrypted = EncryptedMessage(
      nonce: encryptedBytes.sublist(0, TweetNaCl.nonceLength),
      cipherText: encryptedBytes.sublist(TweetNaCl.nonceLength),
    );
    return SecretBox(key).decrypt(encrypted);
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
    return utf8.decode(_decryptData(
      key: _derivePhaseKey(message['side'], message['phase']),
      encryptedBytes: hexToBytes(message['body']),
    ));
  }
}

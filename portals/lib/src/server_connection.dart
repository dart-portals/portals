import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';
import 'package:web_socket_channel/io.dart';

import 'spake2/hkdf.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

class ServerConnection {
  ServerConnection(this.relayUrl)
      : assert(relayUrl != null),
        assert(relayUrl.isNotEmpty);

  final String relayUrl;

  IOWebSocketChannel _relay;
  StreamQueue<String> _relayReceiver;

  Future<void> initialize() async {
    _relay = IOWebSocketChannel.connect(relayUrl);
    _relayReceiver = StreamQueue<String>(_relay.stream.cast<String>());
  }

  void _send(Map<String, dynamic> data) => _relay.sink.add(json.encode(data));

  Future<Map<String, dynamic>> _receive({String type}) async {
    while (true) {
      final response =
          json.decode(await _relayReceiver.next) as Map<String, dynamic>;
      if (type == null || response['type'] == type) {
        return response;
      }
      if (response['type'] != 'ack') print(response);
    }
  }

  Future<void> welcomeAndBind(String appId, String side) async {
    final welcomeMessage = await _receive(type: 'welcome');
    assert(!(welcomeMessage['welcome'] as Map<String, dynamic>)
        .containsKey('error'));
    _send({'type': 'bind', 'appid': appId, 'side': side});
  }

  // TODO: handle non-successful claims
  Future<String> claimNameplate(String nameplate) async {
    _send({'type': 'claim', 'nameplate': nameplate});
    final claim = await _receive(type: 'claimed');

    final mailbox = claim['mailbox'] as String;
    assert(mailbox != null);
    return mailbox;
  }

  Future<String> allocate() async {
    _send({'type': 'allocate'});
    final allocation = await _receive(type: 'allocated');

    final nameplate = allocation['nameplate'] as String;
    assert(nameplate != null);
    return nameplate;
  }

  Future<void> openMailbox(String mailbox) async {
    _send({'type': 'open', 'mailbox': mailbox});
  }

  void sendMessage(String message, {@required String phase}) async {
    assert(phase != null);
    _send({'type': 'add', 'phase': phase, 'body': message});
  }

  Future<Map<String, dynamic>> receiveMessage(
    String mySide, {
    String phase,
  }) async {
    Map<String, dynamic> response;
    while (true) {
      response = await _receive(type: 'message');
      if (response['side'] == mySide) continue;
      if (phase == null || response['phase'] == phase) break;
    }
    return response;
  }
}

class EncryptedServerConnection {
  EncryptedServerConnection({
    @required this.connection,
    @required this.key,
    @required this.side,
  })  : assert(connection != null),
        assert(key != null),
        assert(side != null);

  final ServerConnection connection;
  final Uint8List key;
  final String side;

  Uint8List _deriveKey(Uint8List purpose) =>
      Hkdf(null, key).expand(purpose, length: SecretBox.keyLength);

  Uint8List _derivePhaseKey(String side, String phase) {
    final sideHash = bytesToHex(sha256(ascii.encode(side)));
    final phaseHash = bytesToHex(sha256(ascii.encode(phase)));
    final purpose = 'wormhole:phase:$sideHash$phaseHash';
    final theKey = _deriveKey(ascii.encode(purpose));
    // print('Purpose $purpose generates key $theKey');
    return theKey;
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

  Future<void> sendMessage(String message, {@required String phase}) async {
    final encrypted = bytesToHex(_encryptData(
      key: _derivePhaseKey(side, phase),
      data: utf8.encode(message),
    ));
    connection.sendMessage(encrypted, phase: phase);
  }

  Future<String> receiveMessage({String phase}) async {
    final message = await connection.receiveMessage(side, phase: phase);
    return utf8.decode(_decryptData(
      key: _derivePhaseKey(message['side'], message['phase']),
      encryptedBytes: hexToBytes(message['body']),
    ));
  }
}

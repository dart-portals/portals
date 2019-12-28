/// Connections between the client and the server. For more information about
/// how the communication is structured, check out
/// https://github.com/warner/magic-wormhole/blob/master/docs/server-protocol.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';

import 'connections/mailbox_connection.dart';
import 'errors.dart';
import 'spake2/ed25519.dart';
import 'spake2/hkdf.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

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
/*class EncryptedMailboxConnection {
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
    final outbound = await spake.start();

    await mailbox.send(
      phase: 'pake',
      message: json.encode({'pake_v1': bytesToHex(outbound)}),
    );

    try {
      final inboundMessage = json.decode(
        (await mailbox.receive(phase: 'pake'))['body'],
      );
      final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
      _key = await spake.finish(inboundBytes);
      print(
          '${mailbox.side.substring(0, 3)}: Finished with key ${bytesToHex(key)}.');
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
      final key = Hkdf(null, _key).expand(purpose, length: SecretBox.keyLength);
      return key;
    } on HkdfException {
      throw PortalEncryptionFailedException();
    }
  }

  Uint8List _derivePhaseKey(String side, String phase) {
    final sideHash = bytesToHex(sha256(ascii.encode(side)));
    final phaseHash = bytesToHex(sha256(ascii.encode(phase)));
    final purpose = 'wormhole:phase:$sideHash$phaseHash';
    final key = _deriveKey(ascii.encode(purpose));
    print('${mailbox.side.substring(0, 3)}: Derived phase key for side '
        '${side.substring(0, 3)}, phase $phase is '
        '${bytesToHex(key).substring(0, 5)}...');

    return key;
  }

  Uint8List _encryptData({@required Uint8List key, @required Uint8List data}) =>
      SecretBox(key).encrypt(data);

  Uint8List _decryptData({
    @required Uint8List key,
    @required Uint8List encryptedBytes,
  }) {
    try {
      return SecretBox(key).detectNonceAndDecrypt(encryptedBytes);
    } on String catch (e) {
      print(e);
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
    }
  }
}*/

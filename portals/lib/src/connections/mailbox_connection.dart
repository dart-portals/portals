import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';
import 'package:version/version.dart';

import '../errors.dart';
import '../spake2/ed25519.dart';
import '../spake2/hkdf.dart';
import '../spake2/spake2.dart';
import '../utils.dart';
import 'mailbox_server_connection.dart';

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
class MailboxConnection {
  MailboxConnection({
    @required this.server,
    @required this.shortKey,
  })  : assert(server != null),
        assert(shortKey != null);

  final MailboxServerConnection server;
  final Uint8List shortKey;

  String get side => server.side;

  Uint8List _key;
  Uint8List get key => _key;

  Future<void> initialize() async {
    // Start the spake2 encryption process.
    final spake = Spake2(id: utf8.encode(server.appId), password: shortKey);
    final outbound = await spake.start();

    // Exchange secrets with the other portal.
    await server.sendMessage(
      phase: 'pake',
      message: json.encode({'pake_v1': bytesToHex(outbound)}),
    );
    Map<String, dynamic> inboundMessage;
    try {
      inboundMessage = json.decode(
        (await server.receiveMessage(phase: 'pake'))['body'],
      );
    } on TypeError {
      throw OtherPortalCorruptException(
          'The other portal sent a pake message without a body.');
    }

    // Finish the spake2 encryption process.
    try {
      final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
      _key = await spake.finish(inboundBytes);
    } on HkdfException {
      throw PortalEncryptionFailedException();
    } on Ed25519Exception {
      throw PortalEncryptionFailedException();
    }
  }

  /// Exchanges the versions of this and the other portal's app protocol.
  Future<Version> exchangeVersions(Version myVersion) async {
    // print('${side.substring(0, 3)}: Sending my version $myVersion.');
    send(
      phase: 'versions',
      message: json.encode({
        'app_version': myVersion.toString(),
      }),
    );
    final response = await receive(phase: 'versions');
    // print('${side.substring(0, 3)}: Versions received: $response');

    // We now have a confirmed secured connection with the other portal.
    // Release the nameplate for the mailbox so other portals can use it.
    server.releaseNameplate();

    // Parse the response.
    Map<String, dynamic> body;
    try {
      body = json.decode(response);
    } on FormatException {
      throw OtherPortalCorruptException(
          'The other portal sent a non-json version message.');
    }
    try {
      return Version.parse(body['app_version'] as String);
    } on FormatException {
      throw OtherPortalCorruptException(
          'Other portal sent invalid semantic version: ${body['app_versions']}');
    }
  }

  /// Only messages from the same side and phase share a key.
  Uint8List _derivePhaseKey(String side, String phase) {
    final sideHash = bytesToHex(sha256(ascii.encode(side)));
    final phaseHash = bytesToHex(sha256(ascii.encode(phase)));
    final purpose = 'wormhole:phase:$sideHash$phaseHash';
    try {
      return Hkdf(null, _key)
          .expand(ascii.encode(purpose), length: SecretBox.keyLength);
    } on HkdfException {
      throw PortalEncryptionFailedException();
    }
  }

  void send({@required String phase, @required String message}) {
    // Encrypt and encode the message.
    final secretBox = SecretBox(_derivePhaseKey(server.side, phase));
    final encrypted = secretBox.encrypt(utf8.encode(message));
    final encoded = bytesToHex(encrypted);
    server.sendMessage(phase: phase, message: encoded);
  }

  Future<String> receive({String phase}) async {
    // Receive an encrypted message from the other side and extract side and
    // body.
    final message = await server.receiveMessage(phase: phase);
    String side, body;
    try {
      side = message['side'];
      body = message['body'];
    } on TypeError {
      // TODO: non-set values in map are null and don't throw an error.
      throw OtherPortalCorruptException(
          'Other portal sent a message without a side, phase or body.');
    }

    // Decode and decrypt the message.
    final decoded = hexToBytes(body);
    try {
      final decrypted = SecretBox(_derivePhaseKey(side, phase))
          .decrypt(EncryptedMessage.fromList(decoded));
      return utf8.decode(decrypted);
    } on String {
      throw PortalEncryptionFailedException();
    }
  }
}

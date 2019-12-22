import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pinenacl/secret.dart';

extension ToUint8ListConverter on Iterable<int> {
  /// Turns this [Iterable<int>] into a [Uint8List].
  Uint8List toUint8List() => Uint8List.fromList(this.toList());
}

extension LeadingZeros on String {
  /// Fill this string with leading zeros, so that the total length is at least
  /// [length].
  fillWithLeadingZeros(int length) =>
      '${[for (var i = length - this.length; i > 0; i--) '0'].join()}$this';
}

extension DetectNonce on SecretBox {
  Uint8List detectNonceAndDecrypt(Uint8List bytes) {
    final encrypted = EncryptedMessage(
      nonce: bytes.sublist(0, TweetNaCl.nonceLength),
      cipherText: bytes.sublist(TweetNaCl.nonceLength),
    );
    return decrypt(encrypted);
  }
}

extension Sum on Iterable<int> {
  int get min => this.reduce(math.min);
}

String bytesToHex(Uint8List bytes) {
  return bytes
      .map((byte) => byte.toRadixString(16).fillWithLeadingZeros(2))
      .join('');
}

Uint8List hexToBytes(String hexString) {
  final bytes = <int>[];
  for (var i = 0; i < hexString.length ~/ 2; i++) {
    final byteString = hexString.substring(2 * i, 2 * i + 2);
    bytes.add(int.parse(byteString, radix: 16));
  }
  return bytes.toUint8List();
}

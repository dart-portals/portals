import 'dart:math' as math;
import 'dart:math';
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

extension IntToBigInt on int {
  /// Turns this [int] into a [BigInt].
  BigInt get bi => BigInt.from(this);
}

extension StringToBigInt on String {
  /// Turns this [String] into a [BigInt].
  BigInt get bi => BigInt.parse(this);
}

BigInt bytesToNumber(Uint8List bytes) =>
    BigInt.parse(bytesToHex(bytes.reversed.toUint8List()), radix: 16);

Uint8List numberToBytes(BigInt number) =>
    hexToBytes(number.toRadixString(16).fillWithLeadingZeros(64))
        .reversed
        .toUint8List();

extension StreamWhereType<T> on Stream<T> {
  Stream<S> whereType<S extends T>() =>
      this.where((item) => item is S).cast<S>();
}

Uint8List generateRandomUint8List(int length) {
  final random = Random.secure();
  return [
    for (int i = 0; i < length; i++) random.nextInt(256),
  ].toUint8List();
}

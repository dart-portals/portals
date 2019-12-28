import 'dart:math' as math;
import 'dart:typed_data';

extension ToUint8ListConverter on Iterable<int> {
  /// Turns this [Iterable<int>] into a [Uint8List].
  Uint8List toUint8List() => Uint8List.fromList(this.toList());
}

extension Minimum on Iterable<int> {
  int get min => this.reduce(math.min);
}

extension LeadingZeros on String {
  /// Fill this string with leading zeros, so that the total length is at least
  /// [length].
  fillWithLeadingZeros(int length) =>
      '${[for (var i = length - this.length; i > 0; i--) '0'].join()}$this';
}

extension IntToBigInt on int {
  /// Turns this [int] into a [BigInt].
  BigInt get bi => BigInt.from(this);
}

extension StringToBigInt on String {
  /// Turns this [String] into a [BigInt].
  BigInt get bi => BigInt.parse(this);
}

extension StreamWhereType<T> on Stream<T> {
  Stream<S> whereType<S extends T>() =>
      this.where((item) => item is S).cast<S>();
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

BigInt bytesToNumber(Uint8List bytes) =>
    BigInt.parse(bytesToHex(bytes.reversed.toUint8List()), radix: 16);

Uint8List numberToBytes(BigInt number) =>
    hexToBytes(number.toRadixString(16).fillWithLeadingZeros(64))
        .reversed
        .toUint8List();

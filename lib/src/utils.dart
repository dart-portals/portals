import 'dart:typed_data';

extension _LeadingZeros on String {
  /// Fill this string with leading zeros, so that the total length is at least
  /// [length].
  fillWithLeadingZeros(int length) =>
      '${[for (var i = length - this.length; i > 0; i--) '0'].join()}$this';
}

extension ListComparator on List<int> {
  /// Compares this list with the other one. The smaller list is the one with
  /// the smaller element at the first position where the elements of the two
  /// lists are not the same.
  operator <(List<int> other) {
    assert(this.length == other.length);

    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return this[i] < other[i];
      }
    }
    return false; // All elements are equal.
  }
}

extension ToUint8ListConverter on Iterable<int> {
  /// Turns this [Iterable<int>] into a [Uint8List].
  Uint8List toUint8List() => Uint8List.fromList(this.toList());
}

extension IntToBigInt on int {
  /// Turns this [int] into a [BigInt].
  BigInt get bi => BigInt.from(this);
}

extension StringToBigInt on String {
  /// Turns this [String] into a [BigInt].
  BigInt get bi => BigInt.parse(this);
}

BigInt bytesToNumber(Uint8List bytes) {
  final hexString = bytes.reversed
      .map((byte) => byte.toRadixString(16).fillWithLeadingZeros(2))
      .join('');
  return BigInt.parse(hexString, radix: 16);
}

Uint8List numberToBytes(BigInt number) {
  var hexString = number.toRadixString(16).fillWithLeadingZeros(64);

  final bytes = <int>[];
  for (var i = 0; i < hexString.length ~/ 2; i++) {
    final byteString = hexString.substring(2 * i, 2 * i + 2);
    bytes.add(int.parse(byteString, radix: 16));
  }
  return Uint8List.fromList(bytes);
}

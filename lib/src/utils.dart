import 'dart:math';
import 'dart:typed_data';

extension _MakeStringEven on String {
  makeEvenlyLong() => this.length.isEven ? this : '0$this';
}

BigInt bytesToNumber(Uint8List bytes) {
  final hexString = bytes.reversed
      .map((byte) => byte.toRadixString(16).makeEvenlyLong())
      .join('');
  return BigInt.parse(hexString, radix: 16);
}

Uint8List numberToBytes(BigInt number) {
  var hexString = number.toRadixString(16).makeEvenlyLong();

  final bytes = <int>[];
  for (var i = 0; i < hexString.length ~/ 2; i++) {
    final byteString = hexString.substring(2 * i, 2 * i + 2);
    bytes.add(int.parse(byteString, radix: 16));
  }
  return Uint8List.fromList(bytes);
}

extension ListComparator on List<int> {
  operator <(List<int> other) {
    for (int i = 0; i < min(this.length, other.length); i++) {
      if (this[i] != other[i]) {
        return this[i] < other[i];
      }
    }
    return false;
  }
}

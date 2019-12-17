import 'dart:convert';
import 'dart:typed_data';

import '../utils.dart';
import 'hkdf.dart';

export '../utils.dart';

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

extension IntToBigInt on int {
  /// Turns this [int] into a [BigInt].
  BigInt get bi => BigInt.from(this);
}

extension StringToBigInt on String {
  /// Turns this [String] into a [BigInt].
  BigInt get bi => BigInt.parse(this);
}

BigInt bytesToNumber(Uint8List bytes) {
  return BigInt.parse(bytesToHex(bytes.reversed.toUint8List()), radix: 16);
}

Uint8List numberToBytes(BigInt number) {
  return hexToBytes(number.toRadixString(16).fillWithLeadingZeros(64));
}

final _emptyBytes = Uint8List(0);

Uint8List expandPassword(Uint8List data, int numBytes) =>
    Hkdf(_emptyBytes, data).expand(ascii.encode('SPAKE2 pw'), length: numBytes);

BigInt passwordToScalar(Uint8List password, int scalarSizeBytes, BigInt q) {
  // The oversized hash reduces bias in the result, so uniformly-random
  // passwords give nearly-uniform scalars.
  final oversized = expandPassword(password, scalarSizeBytes + 16);
  assert(oversized.length >= scalarSizeBytes);
  final i = bytesToNumber(oversized.reversed.toUint8List());
  return i % q;
}

Uint8List expandArbitraryElementSeed(Uint8List data, int numBytes) =>
    Hkdf(_emptyBytes, data).expand(
      ascii.encode('SPAKE2 arbitrary element'),
      length: numBytes,
    );

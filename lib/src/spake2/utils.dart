import 'dart:convert';
import 'dart:typed_data';

import '../utils.dart';
import 'hkdf.dart';

export '../utils.dart';

extension ListComparator on List<int> {
  /// Compares this list with the other one. The smaller list is the one with
  /// the smaller element at the first position where the elements of the two
  /// lists are not the same.
  bool operator <(List<int> other) {
    assert(length == other.length);

    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return this[i] < other[i];
      }
    }
    return false; // All elements are equal.
  }
}

extension Number on BigInt {
  static BigInt fromBytes(Uint8List bytes) =>
      BigInt.parse(bytes.reversed.toBytes().toHex(), radix: 16);

  Uint8List toBytes() =>
      Bytes(Bytes.fromHex(toRadixString(16).fillWithLeadingZeros(64)).reversed)
          .toBytes();
}

extension IntToNumber on int {
  /// Turns this [int] into a [BigInt].
  BigInt get bi => BigInt.from(this);
}

extension StringToNumber on String {
  /// Turns this [String] into a [BigInt].
  BigInt get bi => BigInt.parse(this);
}

final _emptyBytes = Uint8List(0);

Uint8List expandPassword(Uint8List data, int numBytes) =>
    Hkdf(_emptyBytes, data).expand(ascii.encode('SPAKE2 pw'), length: numBytes);

BigInt passwordToScalar(Uint8List password, int scalarSizeBytes, BigInt q) {
  // The oversized hash reduces bias in the result, so uniformly-random
  // passwords give nearly-uniform scalars.
  final oversized = expandPassword(password, scalarSizeBytes + 16);
  assert(oversized.length >= scalarSizeBytes);
  final i = Number.fromBytes(oversized.reversed.toBytes());
  return i % q;
}

Uint8List expandArbitraryElementSeed(Uint8List data, int numBytes) =>
    Hkdf(_emptyBytes, data).expand(
      ascii.encode('SPAKE2 arbitrary element'),
      length: numBytes,
    );

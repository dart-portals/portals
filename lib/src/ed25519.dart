import 'dart:math';

import 'dart:typed_data';

import 'groups.dart';
import 'utils.dart';

extension _IntToBigInt on int {
  BigInt get bi => BigInt.from(this);
}

extension _StringToBigInt on String {
  BigInt get bi => BigInt.parse(this);
}

final q = 2.bi.pow(255) - 19.bi;
final l = 2.bi.pow(252) + '27742317777372353535851937790883648493'.bi;

extension _GroupBigInt on BigInt {
  BigInt get inv => this.modPow(q - 2.bi, q);
  BigInt get dec => this - 1.bi;
  BigInt get squared => this * this;
}

final d = -121665.bi * 121666.bi.inv;
final i = BigInt.two.modPow(q.dec ~/ 4.bi, q);

BigInt xrecover(BigInt y) {
  final xx = (y.squared - 1.bi) * (d * y.squared + 1.bi).inv;
  var x = xx.modPow((q + 3.bi) ~/ 8.bi, q);

  if ((x.squared - xx) % q != 0.bi) {
    x = (x * i) % q;
  }
  if (x.isOdd) {
    x = q - x;
  }

  return x;
}

class Point {
  Point(this.x, this.y);

  final BigInt x;
  final BigInt y;

  Point operator *(BigInt a) => Point(x * a, y * a);
  Point operator %(BigInt a) => Point(x % a, y % a);

  ExtendedPoint toExtended() => ExtendedPoint(x, y, 1.bi, x * y) % q;

  bool get isOnCurve =>
      (-x.squared + y.squared - 1.bi - d * x.squared * y.squared) % q == 0.bi;

  Uint8List encode() {
    // Points are encoded as 32-bytes little-endian, b255 is sign, b2b1b0 are 0.
    // MSB of ouput equals x.b0 = x&1. Rest of output is little-endian y.
    assert(y >= 0.bi);
    assert(y < (1.bi << 255));

    final p = (x & 1.bi == 1) ? Point(x, y + 1.bi << 255) : this;

    return Uint8List.fromList(numberToBytes(p.y).reversed.toList());
  }

  factory Point.decode(Uint8List encoded) {
    assert(encoded.length == 32);

    // print('Encoded point is $encoded');
    final unclamped =
        bytesToNumber(Uint8List.fromList(encoded.reversed.toList()));
    // print('Unclamped is $unclamped');
    final clamp = (1.bi << 255) - 1.bi;
    final y = unclamped & clamp; // Clear MSB
    var x = xrecover(y);
    // print('\nx = $x');
    // print('y = $y');

    if ((x & 1.bi != 0.bi) != (unclamped & (1.bi << 255) != 0.bi)) {
      x = q - x;
    }
    final point = Point(x, y);

    // print('Decoded point is $point');
    if (!point.isOnCurve) {
      throw Exception('Decoding point that is not on curve.');
    }
    return point;
  }

  String toString() => '($x, $y)';
}

class ExtendedPoint {
  ExtendedPoint(this.x, this.y, this.z, this.t);

  final BigInt x;
  final BigInt y;
  final BigInt z;
  final BigInt t;

  ExtendedPoint operator %(BigInt a) =>
      ExtendedPoint(x % a, y % a, z % a, t % a);
  ExtendedPoint operator +(ExtendedPoint p) =>
      ExtendedPoint(x + p.x, y + p.y, z + p.z, t + p.t);

  Point toAffine() => Point(x, y) * z.inv % q;

  bool get isZero => x == 0 && y % q == z % q && y != 0;

  String toString() => '($x, $y, $z, $t)';
}

final by = 4.bi * 5.bi.inv;
final bx = xrecover(by);
final b = Point(bx, by) % q;

void debugStuff() {}

// Extended coordinates: x=X/Z, y=Y/Z, x*y=T/Z
// http://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html

class Element extends ExtendedPoint {
  Element(ExtendedPoint p) : super(p.x, p.y, p.z, p.t);

  Element operator +(ExtendedPoint other) {
    assert(other is Element);

    final a = ((y - x) * (other.y - other.x)) % q;
    final b = ((y + x) * (other.y + other.x)) % q;
    final c = (t * 2.bi * d * other.t) % q;
    final e = z * 2.bi * other.z % q;
    final f = (b - a) % q;
    final g = (e - c) % q;
    final h = (e + c) % q;
    final i = (b + a) % q;

    return Element(ExtendedPoint(f * g, h * i, g * h, f * i) % q);
  }

  // Only works if [this != other] and if the order of the points is not 1, 2,
  // 4 or 8. But it's 10 % faster than the normal +.
  Element fastAdd(ExtendedPoint other) {
    final a = ((y - x) * (other.y + other.x)) % q;
    final b = ((y + x) * (other.y - other.x)) % q;
    final c = (z * 2.bi * other.t) % q;
    final e = (t * 2.bi * other.z) % q;
    final f = (e + c) % q;
    final g = (b - a) % q;
    final h = (b + a) % q;
    final i = (e - c) % q;
    return Element(ExtendedPoint(f * g, h * i, g * h, f * i) % q);
  }

  Element doubleElement() {
    // dbl-2008-hwcd
    final a = x.squared;
    final b = y.squared;
    final c = 2.bi * z.squared;
    final d = (-a) % q;
    final j = (x + y) % q;
    final e = (j.squared - a - b) % q;
    final g = (d + b) % q;
    final f = (g - c) % q;
    final h = (d - b) % q;

    return Element(ExtendedPoint(e * f, g * h, f * g, e * h) % q);
  }

  Element scalarMult(BigInt scalar) {
    //assert(scalar >= 0.bi);
    scalar %= l;

    if (scalar == 0.bi) {
      return Element(Point(0.bi, 1.bi).toExtended());
    }
    final a = this.scalarMult(scalar >> 1).doubleElement();
    final result = (scalar & 1.bi != 0.bi) ? (a + this) : a;
    return result;
  }

  Element fastScalarMult(BigInt scalar) {
    //assert(scalar >= 0.bi);
    scalar %= l;

    if (scalar == 0.bi) {
      return Element(Point(0.bi, 1.bi).toExtended());
    }
    final a = this.fastScalarMult(scalar >> 1).doubleElement();
    return (scalar & 1.bi != 0.bi) ? a.fastAdd(this) : a;
  }

  Uint8List toBytes() => this.toAffine().encode();

  Element negate() => Element(this.scalarMult(l - 2.bi));

  Element operator -(Element other) => this + other.negate();
  operator ==(Object other) =>
      other is Element &&
      other.toBytes().toString() == this.toBytes().toString();

  factory Element.arbitraryElement(Uint8List seed) {
    // We don't strictly need the uniformity provided by hashing to an
    // oversized string (128 bits more than the field size), then reducing down
    // to q. But it's comforting, and it's the same technique we use for
    // converting passwords/seeds to scalars (which _does_ need uniformity).
    final hSeed = expandArbitraryElementSeed(seed, 256 ~/ 8 + 16);
    final y = bytesToNumber(Uint8List.fromList(hSeed.reversed.toList())) % q;

    // We try successive y values until we find a valid point.
    for (var plus = 0.bi;; plus += 1.bi) {
      final yPlus = (y + plus) % q;
      final x = xrecover(yPlus);
      final pointA = Point(x, yPlus);

      // Only about 50 % of y coordinates map to valid curve points (I think
      // the other half gives you points on the "twist").
      if (!pointA.isOnCurve) continue;

      final p = Element(pointA.toExtended());
      // Even if the point is on our curve, it may not be in our particular
      // subgroup (with order = l). The curve has order 8*l, so an arbitrary
      // point could have order 1, 2, 4, 8, 1*l, 2*l, 4*l, 8*l (everything
      // which divides the group order).
      // I may be completely wrong about this, but my brief statistical tests
      // suggest it's not too far off that there are phi(x) points with order
      // x, so:
      // * 1 element of order 1: Point(0, 1).
      // * 1 element of order 2: Point(0, -1).
      // * 2 elements of order 4.
      // * 4 elements of order 8.
      // * l-1 elements of order l (including the [base]).
      // * l-1 elements of order 2*l.
      // * 2*(l-1) elements of order 4*l.
      // * 4*(l-1) elements of order 8*l.
      //
      // So, 50 % of random points will have order 8*l, 25 % will have order
      // 4*l, 13 % order 2*l, and 13 % will have our desired order 1*l (and a
      // vanishingly small fraction will have 1/2/4/8). If we multiply any of
      // the 8*l points by 2, we're sure to get an 4*l point (and multiplying a
      // 4*l point by 2 gives us a 2*l point, and so on). Multiplying a 1*l
      // point by 2 gives us a different 1*l point. So multiplying by 8 gets us
      // from almost any point into a uniform point on the correct 1*l
      // subgroup.
      final p8 = p.scalarMult(8.bi);

      // If we got really unlucky and picked one of the 8 low-order points,
      // multiplying by 8 will get us to the identity [zero], which we check
      // for explicitly.
      if (p8.isZero) continue;

      // We're finally in the right group.
      return Element(p8);
    }
  }

  /// This strictly only accepts elements in the right subgroup.
  factory Element.fromBytes(Uint8List bytes) {
    print('Decoding element from bytes $bytes');
    final p = Element(Point.decode(bytes).toExtended());
    if (p.isZero) {
      // || !p.fastScalarMult(l).isZero) {
      throw Exception('Element is not in the right group.');
    }
    // The point is in the expected 1*l subgroup, not in the 2/4/8 groups, or
    // in the 2*l/4*l/8*l groups.
    return p;
  }
}

extension Scalar on BigInt {
  /// Scalars are encoded as 32-bytes little-endian.
  static BigInt fromBytes(Uint8List bytes) {
    assert(bytes.length == 32);
    return bytesToNumber(bytes);
  }

  static BigInt clampedFromBytes(Uint8List bytes) {
    // Ed25519 private keys clamp the scalar to ensure two things:
    // - Integer value is in [L/2,L] to avoid small-logarithm non-wrap-around.
    // - Low-order 3 bits are zero, so a small-subgroup attack won't learn any
    //   information.
    // Set the top two bits to 01, and the bottom three to 000.
    final aUnclamped = fromBytes(bytes);
    final andClamp = (1.bi << 254) - 1.bi - 7.bi;
    final orClamp = (1.bi << 254);
    final aClamped = (aUnclamped & andClamp) | orClamp;
    return aClamped;
  }

  Uint8List toBytes() {
    BigInt clamped = this % l;
    assert(0.bi <= clamped);
    assert(clamped < 2.bi.pow(256));
    return numberToBytes(clamped).reversed;
  }

  static random([Random random]) {
    random ??= Random.secure();
    // Reduce the bias to a safe level by generating 256 extra bits.
    final oversized = bytesToNumber(Uint8List.fromList([
      for (var i = 0; i < 64; i++) random.nextInt(64),
    ]));
    return oversized % l;
  }
}

final base = Element(b.toExtended());
final zero = Element(Point(0.bi, 1.bi).toExtended());

void main() {
  final random = Scalar.random();
  print('Random scalar: $random');

  final element = Element.arbitraryElement(Uint8List.fromList([43]));
  print('Element. $element');
}

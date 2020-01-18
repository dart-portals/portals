/// An implementation of the Edwards 25519 group.
///
/// The Edwards 25519 group (in short "Ed25519") is a group in the mathematical
/// sense, which means it has [Element]s and [Scalar]s. You can multiply an
/// [Element] with a [Scalar] (that's called scalar multiplication). There's
/// also an identity [zero] element with x+0 = x.
/// The Ed25519 group is cyclic and abelian, which means it has a finite amount
/// of [Element]s and scalar multiplication is associative,
/// i.e. n*(x+y) = n*x + n*y.
/// Being cyclic comes with some cool perks. Most importantly, there's a [base]
/// element (mathematically sometimes called "generator"). By repeatedly adding
/// [base] to 0, we can construct every single element of the Ed25519 group.
/// Because the group is cyclic, at some point we reach the point where we
/// started, at 0. After that, the addition of [base] just loops around in the
/// group. This happens after adding [base] to 0 for q=2^255-19 times.
/// q is called the order of the group and Ed25519 got its name because of the
/// order.
///
/// So, what exactly are the [Element]s and [Scalar]s of the group?
///
/// [Element]s are just [Point]s on this curve. From the y-coordinate, you can
/// find out the x-coordinate.
/// There are also [ExtendedPoint]s, which hold some additional information for
/// convenience (and are thus four-dimensional). You can easily convert between
/// normal [Point]s (also called "affine" points) and [ExtendedPoint]s.
/// Extended coordinates have x, y, z and t properties and x=X/Z, y=Y/Z,
/// x*y=T/Z. For more information, visit
/// http://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html.
///
/// [Scalar]s are just [BigInt]s in the inclusive range from 0 to q-1. Because
/// there are exactly as many [Scalar]s as [Element]s, there's a one-to-one
/// mapping between them. It's trivial to go from a scalar to an element (just
/// calculate 0+base*scalar), but it's hard (in the cryptographic sense) to go
/// from element to scalar.

import 'dart:math';
import 'dart:typed_data';

import 'utils.dart';

class Ed25519Exception implements Exception {
  Ed25519Exception(this.message);

  final String message;

  @override
  String toString() => message;
}

final q = 2.bi.pow(255) - 19.bi; // The order of the group.
final l = 2.bi.pow(252) + '27742317777372353535851937790883648493'.bi;
final d = -121665.bi * 121666.bi.inv;
final i = BigInt.two.modPow((q - 1.bi) ~/ 4.bi, q);

final by = 4.bi * 5.bi.inv;
final bx = _xRecover(by);
final b = Point(bx, by) % q;

final base = Element(b.toExtended());
final zero = Element(Point(0.bi, 1.bi).toExtended());

/// Recovers the x-coordiante for the given y-coordinate.
BigInt _xRecover(BigInt y) {
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

/// A two dimensional point.
class Point {
  Point(this.x, this.y);

  final BigInt x, y;

  Point operator *(BigInt n) => Point(x * n, y * n);
  Point operator %(BigInt n) => Point(x % n, y % n);

  ExtendedPoint toExtended() => ExtendedPoint(x, y, 1.bi, x * y) % q;

  /// Whether this point is on the Edwards curve.
  bool get isOnCurve =>
      (-x.squared + y.squared - 1.bi - d * x.squared * y.squared) % q == 0.bi;

  Uint8List toBytes() {
    // Points are encoded as 32-bytes little-endian, b255 is sign, b2b1b0 are 0.
    // MSB of ouput equals x.b0 = x&1. Rest of output is little-endian y.
    assert(y >= 0.bi);
    assert(y < (1.bi << 255));

    final yForEncoding = (x & 1.bi != 0.bi) ? (y + (1.bi << 255)) : y;

    return Number(yForEncoding).toBytes();
  }

  factory Point.fromBytes(Uint8List encoded) {
    assert(encoded.length == 32);

    final unclamped = Scalar.fromBytes(encoded.reversed.toBytes());
    final clamp = (1.bi << 255) - 1.bi;
    final y = unclamped & clamp; // Clear MSB
    var x = _xRecover(y);

    if ((x & 1.bi != 0.bi) != (unclamped & (1.bi << 255) != 0.bi)) {
      x = q - x;
    }
    final point = Point(x, y);

    if (!point.isOnCurve) {
      throw Ed25519Exception('Decoding point that is not on curve.');
    }
    return point;
  }

  @override
  String toString() => '($x, $y)';
}

class ExtendedPoint {
  ExtendedPoint(this.x, this.y, this.z, this.t);

  final BigInt x, y, z, t;

  ExtendedPoint operator +(ExtendedPoint p) =>
      ExtendedPoint(x + p.x, y + p.y, z + p.z, t + p.t);
  ExtendedPoint operator %(BigInt a) =>
      ExtendedPoint(x % a, y % a, z % a, t % a);

  /// Converts this extended point into a normal ("affine") [Point].
  Point toAffine() => Point(x, y) * z.inv % q;

  bool get isZero => x == 0.bi && y % q == z % q && y != 0.bi;

  @override
  String toString() => '($x, $y, $z, $t)';
}

class Element extends ExtendedPoint {
  Element(ExtendedPoint p) : super(p.x, p.y, p.z, p.t);

  @override
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

  // Faster version of multiplying with 2.
  Element doubleElement() {
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
    scalar %= l;
    if (scalar == 0.bi) return zero;

    final a = scalarMult(scalar >> 1).doubleElement();
    return (scalar & 1.bi != 0.bi) ? (a + this) : a;
  }

  Element fastScalarMult(BigInt scalar) {
    scalar %= l;
    if (scalar == 0.bi) return zero;

    final a = fastScalarMult(scalar >> 1).doubleElement();
    return (scalar & 1.bi != 0.bi) ? a.fastAdd(this) : a;
  }

  Element negate() => Element(scalarMult(l - 2.bi));

  Element operator -(Element other) => this + other.negate();

  @override
  bool operator ==(Object other) =>
      other is Element && other.toBytes().toString() == toBytes().toString();

  Uint8List toBytes() => toAffine().toBytes();

  /// This strictly only accepts elements in the right subgroup.
  factory Element.fromBytes(Uint8List bytes) {
    final p = Element(Point.fromBytes(bytes).toExtended());
    if (p.isZero) {
      // || !p.fastScalarMult(l).isZero) {
      throw Ed25519Exception('Element is not in the right group.');
    }
    // The point is in the expected 1*l subgroup, not in the 2/4/8 groups, or
    // in the 2*l/4*l/8*l groups.
    return p;
  }

  factory Element.arbitraryElement(Uint8List seed) {
    // We don't strictly need the uniformity provided by hashing to an
    // oversized string (128 bits more than the field size), then reducing down
    // to q. But it's comforting, and it's the same technique we use for
    // converting passwords/seeds to scalars (which _does_ need uniformity).
    final hSeed = expandArbitraryElementSeed(seed, 256 ~/ 8 + 16);
    final y = Number.fromBytes(hSeed.reversed.toBytes()) % q;

    // We try successive y values until we find a valid point.
    for (var plus = 0.bi;; plus += 1.bi) {
      final yPlus = (y + plus) % q;
      final x = _xRecover(yPlus);
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
}

extension Scalar on BigInt {
  /// The inversion of this scalar.
  BigInt get inv => modPow(q - 2.bi, q);

  BigInt get squared => this * this;

  /// Scalars are encoded as 32-bytes little-endian.
  static BigInt fromBytes(Uint8List bytes) {
    assert(bytes.length == 32);
    return Number.fromBytes(bytes);
  }

  static BigInt clampedFromBytes(Uint8List bytes) {
    // Ed25519 private keys clamp the scalar to ensure two things:
    // - Integer value is in [L/2,L] to avoid small-logarithm non-wrap-around.
    // - Low-order 3 bits are zero, so a small-subgroup attack won't learn any
    //   information.
    // Set the top two bits to 01, and the bottom three to 000.
    final unclamped = fromBytes(bytes);
    final andClamp = (1.bi << 254) - 1.bi - 7.bi;
    final orClamp = (1.bi << 254);
    final clamped = (unclamped & andClamp) | orClamp;
    return clamped;
  }

  Uint8List toBytes() {
    final clamped = this % l;
    assert(0.bi <= clamped);
    assert(clamped < 2.bi.pow(256));
    return Number(clamped).toBytes();
  }

  static BigInt random([Random random]) {
    random ??= Random.secure();
    // Reduce the bias to a safe level by generating some extra bits.
    final oversized = Number.fromBytes(Uint8List.fromList([
      for (var i = 0; i < 255; i++) random.nextInt(64),
    ]));
    return oversized % l;
  }
}

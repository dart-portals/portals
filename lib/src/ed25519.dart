import 'dart:math';

import 'dart:typed_data';

import 'groups.dart';

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
  final xx = q.squared.dec * (d * y.squared + 1.bi).inv;
  var x = xx.modPow((q + 3.bi) ~/ 8.bi, q);

  if ((x.squared - xx) % q != 0) {
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

  bool get isOnCurve => (-x.squared + y.squared - 1.bi - d * x.squared * y.squared) % q ==
    0.bi;

  Uint8List encode() {
    // Points are encoded as 32-bytes little-endian, b255 is sign, b2b1b0 are 0.
    // MSB of ouput equals x.b0 = x&1. Rest of output is little-endian y.
    assert(y >= 0.bi);
    assert(y < (1.bi << 255));

    if (x & 1.bi == 1) {
      p = Point(x, y + 1.bi << 255);
    }

    // TODO: return binascii.unhexlify(("%064x" % y).encode("ascii"))[::-1]
    return null;
  }

  factory Point.decode(Uint8List encoded) {
    final unclamped = null; //int(binascii.hexlify(s[:32][::-1]), 16);
    final clamp = (1.bi << 255) - 1.bi;
    final y = unclamped & clamp; // Clear MSB
    var x = xrecover(y);

    if ((x & 1.bi == 1) != (unclamped & (1 << 255))) {
      x = q - x;
    }
    final point = Point(x, y);

    if (!point.isOnCurve) {
      throw Exception('Decoding point that is not on curve.');
    }
    return point;
  }
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
}

final by = 4.bi * 5.bi.inv;
final bx = xrecover(by);
final b = Point(bx, by) % q;

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
    final g = (d - c) % q;
    final h = (d + c) % q;
    final i = (b + a) % q;

    return ExtendedPoint(f * g, h * i, g * h, f * i) % q;
  }

  ExtendedPoint doubleElement() {
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

    return ExtendedPoint(e * f, g * h, f * g, e * h) % q;
  }

  Element scalarMult(BigInt scalar) {
    assert(scalar >= 0.bi);
    scalar %= l;

    if (scalar == 0) {
      return Point(0.bi, 1.bi).toExtended();
    }
    final a = scalarMult(scalar >> 1).doubleElement();
    return (scalar & 1.bi == 1) ? (a + this) : a;
  }

  Uint8List toBytes() => this.toAffine().encode();

  Element negate() => Element(this.scalarMult(l - 2.bi));
  
  Element operator -(Element other) => this + other.negate();
  operator ==(Object other) => other is Element && other.toBytes().toString() == this.toBytes().toString();

  factory Element.arbitraryElement(Uint8List seed) {
    // We don't strictly need the uniformity provided by hashing to an
    // oversized string (128 bits more than the field size), then reducing down
    // to q. But it's comforting, and it's the same technique we use for
    // converting passwords/seeds to scalars (which _does_ need uniformity).
    final hSeed = expandArbitraryElementSeed(seed, 256 ~/ 8 + 16);
    final y = BigInt.parse(binascii.hexlify(hSeed), radix: 16) % q;

    // We try successive y values until we find a valid point.
    for (var plus = 0.bi;; plus += 1.bi) {
      final yPlus = (y + plus) % q;
      final x = xrecover(yPlus);
      final pointA = Point(x, yPlus); // No attempt to use both "positive" and "negative" x.

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
    final p = Element(Point.decode(bytes).toExtended());
    if (p.isZero || !p.scalarMult(l).isZero) {
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
    return BigInt.parse(null /* TODO: binascii.hexlify(bytes[::-1]) */,
        radix: 16);
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
    return binascii.unhexlify(('%064x' % clamped).encode('ascii'))[::-1];
  }

  static random([Random random]) {
    random ??= Random.secure();
    // Reduce the bias to a safe level by generating 256 extra bits.
    final oversized =
        BigInt.parse(binascii.hexlify(random.nextInt(64)), radix: 16);
    return oversized % l;
  }
}

final base = Element(b.toExtended());
final zero = Element(Point(0.bi, 1.bi).toExtended());

/// ==========================================================================

/// Pure Dart implementation of Ed25519 - public-key signature system.
/// For more information, please follow https://ed25519.cr.yp.to.
/// In general, code mimics behaviour of original Python implementation
/// with some extensions from ActiveState Code Recipes
/// (Python 3 Ed25519 recipe - more at https://github.com/ActiveState/code).
/// Code is not tested for security requirements, so it is good idea to use it
/// on trusted local machines!

/*
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;
import 'package:pointycastle/pointycastle.dart' show Digest;

String digestIdentifier = 'SHA-512';

void setDigestIdentifier(String id) {
  digestIdentifier = id;
}

// Magic constants
final baseX = BigInt.parse(
    "15112221349535400772501151409588531511454012693041857206046113283949847762202");
final baseY = BigInt.parse(
    "46316835694926478169428394003475163141307993866256225615783033603165251855960");
const int bits = 256;
final d = BigInt.parse(
    "37095705934669439343138083508754565189542113879843219016388785533085940283555");
final I = BigInt.parse(
    "19681161376707505956807079304988542015446066515923890162744021073123829784752");
final primeL = BigInt.parse(
    "7237005577332262213973186563042994240857116359379907606001950938285454250989");
final primeQ = BigInt.parse(
    "57896044618658097711785492504343953926634992332820282019728792003956564819949");

List<BigInt> basePoint = [baseX % primeQ, baseY % primeQ];

final ONE = BigInt.from(1);

/// Clamps the lower and upper bits as required by the specification.
/// Returns [bytes] with clamped bits.
/// Length of the [bytes] should be at least 32.
///
///     var l = new List<int>.generate(32, (int i) => i + i); // [0, ..., 60, 62]
///     bitClamp(new Uint8List.fromList(l)); // [0, ..., 60, 126]
Uint8List bitClamp(Uint8List bytes) {
  bytes = bytes.sublist(0, 32);
  bytes[0] &= 248;
  bytes[31] &= 127;
  bytes[31] |= 64;
  return bytes;
}

/// Returns [Uint8List] created from [lst].
/// Shortcut to avoid constructor duplication.
///
///     var bytes = bytesFromList([1, 2, 3]); // [1, 2, 3]
///     print(bytes.runtimeType); // Uint8List
Uint8List bytesFromList(List<int> lst) => new Uint8List.fromList(lst);

/// Converts [bytes] into a BigInt from bytes in big-endian encoding.
/// [bytes] length should be at least 32.
///
///     var l = new List<int>.generate(32, (int i) => i + i); // [0, ..., 60, 62]
///     bytesToInteger(l); // 28149809252802682310...81719888435032634998129152
BigInt bytesToInteger(List<int> bytes) {
  var result = BigInt.zero;
  for (var i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[i]) << (8 * i); // bytes.length - i - 1
  }
  return result;
}

/// Converts integer [intVal] into [x, y] point.
///
///     decodePoint(28149809252802682310); // [2063...9514, 28149809252802682310]
List<BigInt> decodePoint(BigInt intVal) {
  var y = intVal % (ONE << 255); //BigIntfrom(pow(2, (bits - 1))));
  //var y = intVal >> (bits - 1);
  var x = xRecover(y);
  if ((x & ONE) != ((intVal >> (bits - 1))) & ONE) {
    x = primeQ - x;
  }
  return [x, y];
}

/// Adds points on the Edwards curve.
/// Returns sum of points.
///
///     edwards([1,2], [1,2]); // [38630...2017, 20917...5802]
List<BigInt> edwards(List<BigInt> P, List<BigInt> Q) {
  BigInt x1, y1, x2, y2, x3, y3;
  x1 = P[0];
  y1 = P[1];
  x2 = Q[0];
  y2 = Q[1];
  x3 = (x1 * y2 + x2 * y1) * modularInverse(ONE + d * x1 * x2 * y1 * y2);
  y3 = (y1 * y2 + x1 * x2) * modularInverse(ONE - d * x1 * x2 * y1 * y2);
  return [x3 % primeQ, y3 % primeQ];
}

/// Encodes point [P] into [Uint8List].
///
///     encodePoint([1,2]); // [2, 0, ..., 0, 0, 128]
Uint8List encodePoint(List<BigInt> P) {
  var x = P[0];
  var y = P[1];
  var encoded = integerToBytes(y + ((x & ONE) << 255), 32);
  return encoded;
}

/// Returns digest message of SHA-512 hash function.
/// Digest message is result of hashing message [m].
///
///    Hash(new Uint8List(8)); // [27, 116, ..., 82, 196, 47, 27]
Uint8List Hash(Uint8List m) => new Digest(digestIdentifier).process(m);

/// Converts integer [e] into [Uint8List] with length [length].
///
///     integerToBytes(1, 32); // [0, 4, ... 0, 0, 0, 0, 0]

final _byteMask = new BigInt.from(0xff);

/// Encode a BigInt into bytes using big-endian encoding.
Uint8List integerToBytes(BigInt number, int length) {
  // Not handling negative numbers. Decide how you want to do that.
  // var size = (number.bitLength + 7) >> 3;
  var result = new Uint8List(length);
  for (var i = 0; i < length; i++) {
    result[i] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

/// Returns [bool] that that indicates if point [P] is on curve.
///
///     isOnCurve([1, 2]); // false
/*bool isOnOldCurve(List<int> P) {
  int x, y;
  x = P[0];
  y = P[1];
  var onCurve = (-x * x + y * y - 1 - d * x * x * y * y) % primeQ == 0;
  return onCurve;
}*/

bool isOnCurve(List<BigInt> P) {
  BigInt x, y;
  x = P[0];
  y = P[1];
  var val = (-x * x + y * y - ONE - d * x * x * y * y) % primeQ;
  return val == BigInt.zero;
}

/// Returns the modular multiplicative inverse of integer [z]
/// and modulo [primeQ].
///
///     modularInverse(2); // 28948022...41009864396001978282409975
BigInt modularInverse(BigInt z) => z.modInverse(primeQ);

/// Generates public key from given secret key [sk].
/// Public key is [Uint8List] with size 32.
///
///     publicKey(new Uint8List.fromList([1,2,3])); // [11, 198, ..., 184, 7]
Uint8List publicKey(Uint8List sk) {
  var skHash = Hash(sk);
  var clamped = bytesToInteger(bitClamp(skHash));
  var encoded = encodePoint(scalarMult(basePoint, clamped));
  return encoded;
}

/// Returns result of scalar multiplication of point [P] by integer [e].
///
///     scalarMult([1,2], 10); // [298...422, 480...666]
List<BigInt> scalarMult(List<BigInt> P, BigInt e) {
  if (e == BigInt.zero) {
    return [BigInt.zero, ONE];
  }
  var Q = scalarMult(P, e ~/ BigInt.from(2));
  Q = edwards(Q, Q);
  if (e & ONE > BigInt.zero) {
    Q = edwards(Q, P);
  }
  return Q;
}

/// Generates random secret key.
/// Accepts optional argument [seed] to generate random values.
/// When no arguments passed, then [Random.secure] is used to generate values.
/// Secret key is [Uint8List] with length 64.
///
///     secretKey(); // [224, 185, ..., 10, 17, 137]
///     secretKey(1024) // [225, 122, ..., 102, 232, 111]
Uint8List secretKey([int seed]) {
  Random randGen;
  if (seed == null) {
    randGen = new Random.secure();
  } else {
    randGen = new Random(seed);
  }
  var randList = new List<int>.generate(1024, (_) => randGen.nextInt(bits));
  return Hash(bytesFromList(randList));
}

/// Creates signature for message [message] by using secret key [secretKey]
/// and public key [pubKey].
/// Signature is [Uint8List] with size 64.
///
///     var m = new Uint8List(32);
///     var sk = new Uint8List(32);
///     var pk = new Uint8List(32);
///     sign(m, sk, pk); // [62, 244, 231, ..., 53, 213, 0]
Uint8List sign(Uint8List message, Uint8List secretKey, Uint8List pubKey) {
  var secretHash = Hash(secretKey);
  var secretKeyAddMsg = new List<int>.from(secretHash.sublist(32, 64));
  secretKeyAddMsg.addAll(message);
  var msgSecretAsInt = bytesToInteger(Hash(bytesFromList(secretKeyAddMsg)));
  var scalar = encodePoint(scalarMult(basePoint, msgSecretAsInt));
  var preDigest = new List<int>.from(scalar);
  preDigest.addAll(pubKey);
  preDigest.addAll(message);
  var digest = bytesToInteger(Hash(bytesFromList(preDigest)));
  var signature = new List<int>.from(scalar);
  signature.addAll(integerToBytes(
      (msgSecretAsInt + digest * bytesToInteger(bitClamp(secretHash))) % primeL,
      32));
  return bytesFromList(signature);
}

/// Verifies given signature [signature] with message [message] and
/// public key [pubKey].
/// Returns [bool] that indicates if verification is successful.
///
///     var sig = new Uint8List(32);
///     var m = new Uint8List(32);
///     var pk = new Uint8List(32);
///     verifySignature(sig, m, pk); // false
bool verifySignature(Uint8List signature, Uint8List message, Uint8List pubKey) {
  if (signature.lengthInBytes != bits / 4) {
    return false;
  }
  if (pubKey.length != bits / 8) {
    return false;
  }
  var sigSublist = signature.sublist(0, 32);
  var preDigest = new List<int>.from(sigSublist);
  preDigest.addAll(pubKey);
  preDigest.addAll(message);
  var hashInt = bytesToInteger(Hash(bytesFromList(preDigest)));
  var signatureInt = bytesToInteger(signature.sublist(32, 64));
  var signatureScalar = scalarMult(basePoint, signatureInt);
  var pubKeyScalar = scalarMult(decodePoint(bytesToInteger(pubKey)), hashInt);
  var edwardsPubKeyScalar =
      edwards(decodePoint(bytesToInteger(sigSublist)), pubKeyScalar);
  var verified = (signatureScalar.length == edwardsPubKeyScalar.length &&
      signatureScalar[0] == edwardsPubKeyScalar[0] &&
      signatureScalar[1] == edwardsPubKeyScalar[1]);
  return verified;
}

/// Recovers coordinate `x` by given coordinate [y].
/// Returns recovered `x`.
///
///     xRecover(10); // 246881771...00105170855113893569705867530
BigInt xRecover(BigInt y) {
  var xx = (y * y - ONE) * modularInverse(d * y * y + ONE);

  var x = xx.modPow((primeQ + BigInt.from(3)) ~/ BigInt.from(8), primeQ);
  if ((x * x - xx) % primeQ != BigInt.zero) {
    x = (x * I) % primeQ;
  }

  if (x % BigInt.from(2) != BigInt.zero) {
    x = primeQ - x;
  }

  return x;
}
*/

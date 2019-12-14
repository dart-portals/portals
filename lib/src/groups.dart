import 'dart:convert';
import 'dart:typed_data';

/// Interface specification for a Group.
///
/// A cyclic abelian group, in the mathematical sense, is a collection of
/// 'elements' and a (binary) operation that takes two elements and produces a
/// third. It has the following additional properties:
///
/// * there is an 'identity' element named 0, and X+0=X
/// * there is a distinguished 'generator' element G
/// * adding G to 0 'n' times is called scalar multiplication: Y=n*G
/// * this addition loops around after 'q' times, called the 'order'
/// * so (n+k*q)*X = n*X
/// * scalar multiplication is associative, n*(X+Y) = n*X+n*Y
/// * 'scalar division' is really multiplying by (q-n)
///
/// A 'scalar' is an integer in [0,q-1] inclusive. You can add scalars to each
/// other, invert them, and multiply them by elements. There is a one-to-one
/// mapping between scalars and elements. It is trivial to go from a scalar to an
/// element, but hard (in the cryptographic sense) to go from element to scalar.
/// You can ask for a random scalar, and you can convert scalars to bytes and
/// back again.
///
/// The form of an 'element' depends upon the group (there are integer-element
/// groups, and ECC groups). You can add elements together, invert them
/// (scalarmult by -1), and subtract them (invert then add). You can ask for a
/// random element (found by choosing a random scalar, then multiplying). You can
/// convert elements to bytes and back.
///
/// There is a distinguished element called 'Base', which is the generator
/// (or 'base point' in ECC groups).
///
/// Two final operations are provided. The first produces an 'arbitrary element'
/// from a seed. This is somewhat like a random element, but with the additional
/// important property that nobody knows what the corresponding scalar is. The
/// second takes a password (an arbitrary bytestring) and produces a scalar.

import 'hkdf.dart';
import 'utils.dart';

final emptyBytes = Uint8List(0);

Uint8List expandPassword(Uint8List data, int numBytes) => Hkdf(emptyBytes, data)
    .expand(Uint8List.fromList(ascii.encode('SPAKE2 pw')), length: numBytes);

BigInt passwordToScalar(Uint8List password, int scalarSizeBytes, BigInt q) {
  // The oversized hash reduces bias in the result, so uniformly-random
  // passwords give nearly-uniform scalars.
  final oversized = expandPassword(password, scalarSizeBytes + 16);
  assert(oversized.length >= scalarSizeBytes);
  final i = bytesToNumber(Uint8List.fromList(oversized.reversed.toList()));
  return i % q;
}

Uint8List expandArbitraryElementSeed(Uint8List data, int numBytes) =>
    Hkdf(emptyBytes, data).expand(
      ascii.encode('SPAKE2 arbitrary element'),
      length: numBytes,
    );

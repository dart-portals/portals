import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

Uint8List sha256(Uint8List data) => crypto.sha256.convert(data).bytes;

Uint8List password;
Uint8List identity;

class SpakeException implements Exception {}
class BadSideException extends SpakeException {}
class WrongLengthException implements SpakeException {}
class CorruptMessageException implements SpakeException {}

abstract class Group<Element, Scalar, TranscriptHash> {
  String get name;
  static const Element m;
  static const Element n;
  static const Element s;
  Scalar hashToScalar(Uint8List s);
  Scalar randomScalar<T extends Rng, CryptoRng>(T cspring);
  Scalar scalarNeg(Scalar s);
  Uint8List elementToBytes(Element e);
  Element bytesToElement(Uint8List b);
  int get elementLength;
  Element basepointMult(Scalar s);
  Element scalarmult(Element e, Scalar s);
  Element add(Element a, Element b);
}

/// Defines an Edward 25519 curve: https://en.wikipedia.org/wiki/Curve25519
class Ed25519Group implements Group<EdwardsPoint, Scalar, Sha256> {
  String get name => 'Ed25519';
  
  // python -c "import binascii, spake2; b=binascii.hexlify(spake2.ParamsEd25519.M.to_bytes()); print(', '.join(['0x'+b[i:i+2] for i in range(0,len(b),2)]))"
  // 15cfd18e385952982b6a8f8c7854963b58e34388c8e6dae891db756481a02312
  static const m = CompressedEdwardsY([
          0x15, 0xcf, 0xd1, 0x8e, 0x38, 0x59, 0x52, 0x98, 0x2b, 0x6a, 0x8f, 0x8c, 0x78, 0x54,
          0x96, 0x3b, 0x58, 0xe3, 0x43, 0x88, 0xc8, 0xe6, 0xda, 0xe8, 0x91, 0xdb, 0x75, 0x64,
          0x81, 0xa0, 0x23, 0x12,
      ])
      .decompress()
      .unwrap();

  // python -c "import binascii, spake2; b=binascii.hexlify(spake2.ParamsEd25519.N.to_bytes()); print(', '.join(['0x'+b[i:i+2] for i in range(0,len(b),2)]))"
  // f04f2e7eb734b2a8f8b472eaf9c3c632576ac64aea650b496a8a20ff00e583c3
  static const n = CompressedEdwardsY([
          0xf0, 0x4f, 0x2e, 0x7e, 0xb7, 0x34, 0xb2, 0xa8, 0xf8, 0xb4, 0x72, 0xea, 0xf9, 0xc3,
          0xc6, 0x32, 0x57, 0x6a, 0xc6, 0x4a, 0xea, 0x65, 0x0b, 0x49, 0x6a, 0x8a, 0x20, 0xff,
          0x00, 0xe5, 0x83, 0xc3,
      ])
      .decompress()
      .unwrap();

  // python -c "import binascii, spake2; b=binascii.hexlify(spake2.ParamsEd25519.S.to_bytes()); print(', '.join(['0x'+b[i:i+2] for i in range(0,len(b),2)]))"
  // 6f00dae87c1be1a73b5922ef431cd8f57879569c222d22b1cd71e8546ab8e6f1
  static const s = CompressedEdwardsY([
          0x6f, 0x00, 0xda, 0xe8, 0x7c, 0x1b, 0xe1, 0xa7, 0x3b, 0x59, 0x22, 0xef, 0x43, 0x1c,
          0xd8, 0xf5, 0x78, 0x79, 0x56, 0x9c, 0x22, 0x2d, 0x22, 0xb1, 0xcd, 0x71, 0xe8, 0x54,
          0x6a, 0xb8, 0xe6, 0xf1,
      ])
      .decompress()
      .unwrap();

  Scalar hashToScalar(Uint8List s) => ed25519HashToScalar(s);
  Scalar randomScalar<T implements Rng, CryptoRng>(T cspring) => Scalar.random(cspring);
  Scalar scalarNeg(Scalar s) => -s;
  Uint8List elementToBytes(EdwardsPoint s) => s.compress().asBytes().toVec();
  int elementLength => 32;
  
  Element bytesToElement(Uint8List b) {
    if (b.length != 32) {
      return null;
    }

    final bytes = Uint8List.fromList(b.toList());
    final cey = CompressedEdwardsY(bytes);
    cey.decompress();
  }

  Element basepointMult(Scalar s) => Ed25519BasepointPoint * s;
  Element scalarmult(Element e, Scalar s) => e * s;
  Element add(Element a, Element b) => a + b;
}

Scalar ed25519HashToScalar(Uint8List s) {
  // spake2.py does:
  //  h = HKDF(salt=b"", ikm=s, hash=SHA256, info=b"SPAKE2 pw", len=32+16)
  //  i = int(h, 16)
  //  i % q
  //c2_Scalar::hash_from_bytes::<Sha512>(&s)

  final okm = Uint8List.fromList(List.filled(32 + 16, 0));
  Hkdf<Sha256>.extract(Some(''), s)
    .expand('SPAKE2 pw', okm)
    .unwrap();

  final reducible = Uint8List.fromList(List.filled(64, 0);
  for (i, x) in okm.iter().enumerate().take(32 + 16) {
    reducible[32 + 16 - 1 - i] = x;
  }

  Scalar.fromBytesModOrderWide(reducible);
}

Uint8List ed25519HashAb(
  Uint8List passwordVec,
  Uint8List idA,
  Uint8List idB,
  Uint8List firstMsg,
  Uint8List secondMsg,
  Uint8List keyBytes,
) {
  assert(firstMsg.length == 32);
  assert(secondMsg.length == 32);

  // the transcript is fixed-length, made up of 6 32-byte values:
  // byte 0-31   : sha256(pw)
  // byte 32-63  : sha256(idA)
  // byte 64-95  : sha256(idB)
  // byte 96-127 : X_msg
  // byte 128-159: Y_msg
  // byte 160-191: K_bytes
  final transcript = Uint8List.fromList(List.filled(6 * 32, 0))
    
  ..replaceRange(0, 32, sha256(passwordVec))
  ..replaceRange(32, 64, sha256(idA))
  ..replaceRange(64, 96, sha256(idB))
  ..replaceRange(96, 128, firstMsg)
  ..replaceRange(128, 160, secondMsg)
  ..replaceRange(160, 192, keyBytes);

  return sha256(transcript);
}

Uint8List ed25519HashSymmetric(
  Uint8List passwordVec,
  Uint8List idS,
  Uint8List msgU,
  Uint8List msgV,
  Uint8List keyBytes,
) {
  assert(msgU.length == 32);
  assert(msgV.length == 32);

  // # since we don't know which side is which, we must sort the messages
  // first_msg, second_msg = sorted([msg1, msg2])
  // transcript = b"".join([sha256(pw).digest(),
  //                        sha256(idSymmetric).digest(),
  //                        first_msg, second_msg, K_bytes])

  // the transcript is fixed-length, made up of 5 32-byte values:
  // byte 0-31   : sha256(pw)
  // byte 32-63  : sha256(idSymmetric)
  // byte 64-95  : X_msg
  // byte 96-127 : Y_msg
  // byte 128-159: K_bytes
  
final transcript = Uint8List.fromList(List.filled(5 * 32, 0));

  transcript.replaceRange(0, 32, sha256(passwordVec));
  transcript.replaceRange(32, 64, sha256(idS));

  if (msgU < msgV) {
    transcript.replaceRange(64, 96, msgU);
    transcript.replaceRange(96, 128, msgV);
  } else {
    transcript.replaceRange(64, 96, msgV);
    transcript.replaceRange(96, 128, msgU);
  }

  transcript.replaceRange(128, 160, keyBytes);

  return sha256(transcript);
}

enum Side {
    A,
    B,
    Symmetric
}

class Spake2<G extends Group> {
  Side side;
  Scalar xyScalar;
  Uint8List passwordVec;
  Uint8List idA;
  Uint8List idB;
  Uint8List idS;
  Uint8List msg1;
  Scalar passwordScalar;

  Uint8List extra;

  factory Spake2.startInternal(Side side, Uint8List password,
    Uint8List idA, Uint8List idB, Uint8List idS, Scalar xyScalar) {
      final passwordScalar = hashToScalar(password);

      // a: X = B*x + M*pw
      // b: Y = B*y + N*pw
      // sym: X = B*x * S*pw
      final blinding;
      switch (side) {
        case Side.A: blinding = G.m; break;
        case Side.B: blinding = G.n; break;
        case Side.Symmetric: blinding = G.s; break;
      }
      
      final m1 = G.add(
        G.basepointMult(xyScalar),
        G.scalarmult(blinding, passwordScalar),
      );

      final msg1 = G.elementToBytes(m1);
      final passwordVec = Vec()..extendFromSlice(password);
      final idACopy = Vec()..extendFromSlice(idA);
      final idBCopy = Vec()..extendFromSlice(idB);
      final idSCopy = Vec()..extendFromSlice(idS);

      final msgAndSide = Vec();
      switch (side) {
        case Side.A: msgAndSide.push(0x41); break; // 'A'
        case Side.B: msgAndSide.push(0x42); break; // 'B'
        case Side.Symmetric: msgAndSide.push(0x53); break; // 'S'
      }
      msgAndSide.extendFromSlice(msg1);

      extra = msgAndSide;
      return Spake2(
        side,
        xyScalar,
        passwordVec,
        idACopy,
        idBCopy,
        idSCopy,
        msg1.clone(),
        passwordScalar,
      );
  }

  factory Spake2.startAInternal(Uint8List password, Uint8List idA, Uint8List idB,
      Scalar xyScalar) {
        return Spake2.startInternal(Side.A, password, idA, idB, Identity.new(''), xyScalar);
      }
  factory Spake2.startBInternal(Uint8List password, Uint8List idA, Uint8List idB,
      Scalar xyScalar) {
        return Spake2.startInternal(Side.B, password, idA, idB, Identity.new(''), xyScalar);
      }
  factory Spake2.startSymmetricInternal(Uint8List password, Uint8List idS,
      Scalar xyScalar) {
        return Spake2.startInternal(Side.A, password, Identity.new(''), Identity.new(''), idS, xyScalar);
      }

  factory startA(Uint8List password, Uint8List idA, Uint8List idB) {
    final cspring = OsRng.new().unwrap();
    final xyScalar = G.randomScalar(cspring);
    return Spake2.startAInternal(password, idA, idB, xyScalar);
  }
  factory startB(Uint8List password, Uint8List idA, Uint8List idB) {
    final cspring = OsRng.new().unwrap();
    final xyScalar = G.randomScalar(cspring);
    return Spake2.startBInternal(password, idA, idB, xyScalar);
  }
  factory startSymmetric(Uint8List password, Uint8List idS) {
    final cspring = OsRng.new().unwrap();
    final xyScalar = G.randomScalar(cspring);
    return Spake2.startSymmetricInternal(password, idS, xyScalar);
  }

  Uint8List finish(Uint8List msg2) {
    if (msg2.length != G.elementLength + 1) {
      throw WrongLengthException();
    }
    final msgSide = msg2[0];

    switch (side) {
      case Side.A: if (msgSide != 0x42) throw BadSideException(); break;
      case Side.B: if (msgSide != 0x41) throw BadSideException(); break;
      case Side.Symmetric: if (msgSide != 0x53) throw BadSideException(); break;
    }

    final msg2Rest = msg2.sublist(1);
    if (msg2Rest.isEmpty) {
      throw CorruptMessageException();
    }
    final msg2Element = G.bytesToElement(msg2Rest);

    // a: K = (Y+N*(-pw))*x
    // b: K = (X+M*(-pw))*y
    Element unblinding;
    switch (side) {
      case Side.A: unblinding = G.m; break;
      case Side.B: unblinding = G.n; break;
      case Side.Symmetric: unblinding = G.s; break;
    }

    final tmp1 = G.scalarmult(unblinding, G.scalarNeg(passwordScalar));
    final tmp2 = G.add(msg2Element, tmp1);
    final keyElement = G.scalarmult(tmp2, xyScalar);
    final keyBytes = G.elementToBytes(keyElement);

    // key = H(H(pw) + H(idA) + H(idB) + X + Y + K)
    //transcript = b"".join([sha256(pw).digest(),
    //                       sha256(idA).digest(), sha256(idB).digest(),
    //                       X_msg, Y_msg, K_bytes])
    //key = sha256(transcript).digest()
    // note that both sides must use the same order

    switch (side) {
      case Side.A:
        return ed25519HashAb(passwordVec, idA, idB, msg1.asSlice(), msg2.sublist(1), keyBytes);
      case Side.B:
        return ed25519HashAb(passwordVec, idA, idB, msg2.sublist(1), msg1.asSlice(), keyBytes);
      case Side.Symmetric:
        return ed25519HashSymmetric(passwordVec, idS, msg1, msg2.sublist(1), keyBytes);
    }
  }
}

use curve25519_dalek::constants::ED25519_BASEPOINT_POINT;
use curve25519_dalek::edwards::CompressedEdwardsY;
use curve25519_dalek::edwards::EdwardsPoint as c2_Element;
use curve25519_dalek::scalar::Scalar as c2_Scalar;
use hkdf::Hkdf;
use rand::{rngs::OsRng, CryptoRng, Rng};

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'ed25519.dart';
import 'groups.dart';
import 'utils.dart';

Uint8List sha256(List<int> data) =>
    Uint8List.fromList(crypto.sha256.convert(data).bytes);

// final m = Element.arbitraryElement(ascii.encode('M'));
// final n = Element.arbitraryElement(ascii.encode('N'));
final s = Element.arbitraryElement(ascii.encode('symmetric'));

// x = random(Zp)
// X = scalarmult(g, x)
// X* = X + scalarmult(M, int(pw))
//  y = random(Zp)
//  Y = scalarmult(g, y)
//  Y* = Y + scalarmult(N, int(pw))
// KA = scalarmult(Y* + scalarmult(N, -int(pw)), x)
// key = H(H(pw) + H(idA) + H(idB) + X* + Y* + KA)
//  KB = scalarmult(X* + scalarmult(M, -int(pw)), y)
//  key = H(H(pw) + H(idA) + H(idB) + X* + Y* + KB)

Uint8List finalizeSpake2(String idA, String idB, BigInt xMsg, BigInt yMsg,
    int kBytes, Uint8List pw) {
  return sha256(<int>[
    ...sha256(pw),
    ...sha256(utf8.encode(idA)),
    ...sha256(utf8.encode(idB)),
    ...numberToBytes(xMsg),
    ...numberToBytes(yMsg),
    kBytes,
  ]);
}

Uint8List finalizeSpake2Symmetric(
    BigInt msg1, BigInt msg2, int kBytes, Uint8List pw) {
  // Since we don't know which side is which, we must sort the messages.
  final firstMsg = msg1 < msg2 ? msg1 : msg2;
  final secondMsg = msg1 < msg2 ? msg2 : msg1;

  return sha256(<int>[
    ...sha256(pw),
    ...numberToBytes(firstMsg),
    ...numberToBytes(secondMsg),
    kBytes,
  ]);
}

/// This class manages one side of a spake2 key negotiation.
class Spake2 {
  final Uint8List password;
  BigInt pwScalar;
  BigInt xyScalar;
  Element xyElement;
  Uint8List outboundMessage;
  Uint8List inboundMessage;

  bool _started = false;
  bool _finished = false;

  Spake2(this.password) {
    pwScalar = passwordToScalar(password, 32, l);
  }

  void start([Random random]) {
    assert(!_started);
    _started = true;

    this.xyScalar = BigInt.parse(
        '636300388589822600411935121714421527614733343890922194690571496772989624724');
    //Scalar.random(random);
    this.xyElement = base.fastScalarMult(xyScalar);
    computeOutboundMessage();
  }

  void computeOutboundMessage() {
    var pwBlinding = myBlinding.fastScalarMult(pwScalar);
    var messageElem = xyElement + pwBlinding;
    this.outboundMessage = messageElem.toBytes();
  }

  Uint8List finish(Uint8List inboundMessage) {
    assert(!_finished);
    _finished = true;

    this.inboundMessage = inboundMessage;

    final inboundElement = Element.fromBytes(inboundMessage);
    assert(inboundElement.toBytes() == outboundMessage);

    final pwUnblinding = myUnblinding.scalarMult(-pwScalar);
    final kElem = (inboundElement + pwUnblinding).scalarMult(xyScalar);
    final kBytes = kElem.toBytes();
    final key = this.finalize(kBytes);
    return key;
  }

  Element get myBlinding => s;
  Element get myUnblinding => s;

  Uint8List finalize(kBytes) {
    return finalizeSpake2Symmetric(
      bytesToNumber(inboundMessage),
      bytesToNumber(outboundMessage),
      kBytes,
      password,
    );
  }
}

void main() {
  final random = Random.secure();

  final a = Spake2(utf8.encode('password'));
  a.start(random);
  print('The outbound message of a is ${a.outboundMessage}.');

  print('s = ${a.myBlinding}');

  // final b = Spake2(utf8.encode('password'));
  // b.start(random);
  // print('The outbound message of b is ${b.outboundMessage}.');

  // final aKey = a.finish(Uint8List.fromList([
  //   ...[101, 182, 161, 21, 185, 17, 230, 134, 13, 114, 232, 247, 49, 161, 24],
  //   ...[24, 165, 25, 154, 153, 79, 151, 39, 236, 193, 170, 94, 201, 91, 191],
  //   ...[107, 68],
  // ]));
  // print('The key of a is $aKey.');

  // final bKey = b.finish(b.outboundMessage);
  // print('The key of b is $bKey.');
}

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
    BigInt msg1, BigInt msg2, Uint8List kBytes, Uint8List pw) {
  // Since we don't know which side is which, we must sort the messages.
  final msg1Bytes = numberToBytes(msg1).reversed.toList();
  final msg2Bytes = numberToBytes(msg2).reversed.toList();
  final isFirstMsgSmaller = msg1Bytes < msg2Bytes;
  final firstMsg = isFirstMsgSmaller ? msg1Bytes : msg2Bytes;
  final secondMsg = isFirstMsgSmaller ? msg2Bytes : msg1Bytes;

  // print('first_msg = $firstMsg');
  // print('second_msg = $secondMsg');

  final transcript = <int>[
    ...sha256(pw),
    ...sha256([]),
    ...firstMsg,
    ...secondMsg,
    ...kBytes,
  ];
  // print('transcript:');
  // print('  pw = ${sha256(pw)}');
  // print('  idSymmetric = ${sha256([])}');
  // print('  firstMsgBytes = $firstMsg');
  // print('  secondMsgBytes = $secondMsg');
  // print('  kBytes = $kBytes');
  return sha256(transcript);
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
        '6019267352642718384477389175057995968320597738885492113584218693522637723914');
    // this.xyScalar = Scalar.random(random);
    this.xyElement = base.fastScalarMult(xyScalar);
    print('xyElement = $xyElement');
    computeOutboundMessage();
  }

  void computeOutboundMessage() {
    print('\nmyBlinding = $myBlinding');
    print('pwScalar = $pwScalar');
    var pwBlinding = myBlinding.fastScalarMult(pwScalar);
    print('\npwBlinding is $pwBlinding');
    print('\nxyElement is $xyElement');
    var messageElem = xyElement + pwBlinding;
    this.outboundMessage = messageElem.toBytes();
    print('\nmessageElem is $messageElem');
    print('messageElem affine: ${messageElem.toAffine()}');
    print('messageElem bytes are ${messageElem.toBytes()}');
  }

  Uint8List finish(Uint8List inboundMessage) {
    assert(!_finished);
    _finished = true;

    this.inboundMessage = inboundMessage;

    final inboundElement =
        Element.fromBytes(Uint8List.fromList(inboundMessage.reversed.toList()));
    //assert(inboundElement.toBytes() == outboundMessage);

    final pwUnblinding = myUnblinding.fastScalarMult(-pwScalar);
    // print('\nmyUnblinding = $myUnblinding');
    // print('\npwUnblinding = $pwUnblinding');
    // print('\nxyScalar = $xyScalar');
    // print('pwScalar = $pwScalar\n');
    // print('inboundMessage = $inboundMessage\n');
    // print('inboundElement = $inboundElement\n');
    final kElem = (inboundElement + pwUnblinding).fastScalarMult(xyScalar);
    // print('kElem = $kElem');
    final kBytes = kElem.toBytes();
    print('kBytes = $kBytes');
    final key = this.finalize(kBytes);
    return key;
  }

  Element get myBlinding => s;
  Element get myUnblinding => s;

  Uint8List finalize(Uint8List kBytes) {
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

  // final b = Spake2(utf8.encode('password'));
  // b.start(random);
  // print('The outbound message of b is ${b.outboundMessage}.');

  final aKey = a.finish(Uint8List.fromList([
    215,
    70,
    84,
    27,
    85,
    9,
    112,
    5,
    126,
    190,
    5,
    150,
    113,
    4,
    189,
    112,
    79,
    228,
    191,
    135,
    161,
    79,
    121,
    72,
    18,
    145,
    109,
    237,
    38,
    70,
    118,
    10
  ]));
  // final aKey = a.finish(b.outboundMessage);
  print('The key of a is $aKey.');

  // final bKey = b.finish(a.outboundMessage);
  // print('The key of b is $bKey.');
}

/// The Spake2 algorithm is a variation of the Diffie Hellman algorithm, but
/// instead of just negotiating a secret key between two parties that formerly
/// know nothing about each other, both parties know a shared secret with small
/// entropy.
/// Here's an explanation about how it works:
/// https://copyninja.info/blog/golang_spake2_4.html

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:meta/meta.dart';

import 'ed25519.dart';
import 'utils.dart';

Uint8List sha256(List<int> data) =>
    crypto.sha256.convert(data).bytes.toUint8List();

final s = Element.arbitraryElement(ascii.encode('symmetric'));

/// This class manages one side of a spake2 key negotiation.
class Spake2 {
  final Uint8List id;
  final Uint8List password;
  final BigInt _pwScalar;
  BigInt _xyScalar;
  Element _xyElement;
  Uint8List _outboundMessage;
  Uint8List _inboundMessage;

  bool _started = false;
  bool _finished = false;

  Spake2({@required this.id, @required this.password})
      : assert(id != null),
        assert(id.isNotEmpty),
        assert(password != null),
        assert(password.isNotEmpty),
        _pwScalar = passwordToScalar(password, 32, l);

  Uint8List start([Random random]) {
    assert(!_started);
    _started = true;

    this._xyScalar = Scalar.random(random);
    this._xyElement = base.fastScalarMult(_xyScalar);
    final pwBlinding = myBlinding.fastScalarMult(_pwScalar);
    final messageElem = _xyElement + pwBlinding;
    this._outboundMessage = messageElem.toBytes();
    return _outboundMessage;
  }

  Element get myBlinding => s;
  Element get myUnblinding => s;

  Uint8List finish(Uint8List inboundMessage) {
    assert(_started);
    assert(!_finished);
    _finished = true;

    this._inboundMessage = inboundMessage;

    final inboundElement =
        Element.fromBytes(inboundMessage.reversed.toUint8List());

    final pwUnblinding = myUnblinding.fastScalarMult(-_pwScalar);
    final kElem = (inboundElement + pwUnblinding).fastScalarMult(_xyScalar);
    final kBytes = kElem.toBytes();

    final msg1 = _inboundMessage.reversed.toUint8List();
    final msg2 = _outboundMessage.reversed.toUint8List();

    // Since this function needs to deterministically produce the same key on
    // both clients and the inbound message of one client is the outbound
    // message of the other one (and vice versa), we sort the messages.
    final isFirstMsgSmaller = msg1 < msg2;
    final firstMsg = isFirstMsgSmaller ? msg1 : msg2;
    final secondMsg = isFirstMsgSmaller ? msg2 : msg1;

    final transcript = <int>[
      ...sha256(password),
      ...sha256(id),
      ...firstMsg,
      ...secondMsg,
      ...kBytes,
    ];
    return sha256(transcript);
  }
}

import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

String sha256(String data) => crypto.sha256.convert(data.codeUnits).toString();

const a = 'a';
const b = 'b';

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

String finalizeSpake2(idA, idB, xMsg, yMsg, kBytes, pw) {
  return sha256([
    sha256(pw),
    sha256(idA),
    sha256(idB),
    xMsg,
    yMsg,
    kBytes,
  ].join());
}

String finalizeSpake2Symmetric(idSymmetric, msg1, msg2, kBytes, pw) {
  // Since we don't know which side is which, we must sort the messages.
  final firstMsg = min(msg1, msg2);
  final secondMsg = max(msg1, msg2);

  return sha256([
    sha256(pw),
    sha256(idSymmetric),
    firstMsg,
    secondMsg,
    kBytes,
  ].join());
}

/// This class manages one side of a spake2 key negotiation.
class Spake2Base {
  final pw;
  var pwScalar;
  var side;

  bool _started = false;
  bool _finished = false;

  Spake2Base(this.pw) {
    assert(password is Uint8List); // TODO:
    pwScalar = params.group.passwordToScalar(password); // TODO:
  }

  void start() {
    assert(!_started);
    _started = true;

    var g = params.group;
    this.xyScalar = g.randomScalar(Random.secure());
    this.xyElem = g.Base.scalarmult(xyScalar);
    computeOutboundMessage();
    var outboundSideAndMessage = side + outboundMessage
    return outboundSideAndMessage;
  }

  void computeOutboundMessage() {
    pwBlinding = myBlinding().scalarmult(pwScalar);
    messageElem = xyElem.add(pwBlinding);
    this.outboundMessage = messageElem.toBytes();
  }

  void finish(inboundSideAndMessage) {
    assert(!_finished);
    _finished = true;

    this.inboundMessage = extractMessage(inboundSideAndMessage);

    g = this.params.group;
    inboundElem = g.bytesToElement(inboundMessage);
    assert(inboundElem.toBytes() == outboundMessage);

    pwUnblinding = myUnblinding().scalarmult(-pwScalar);
    kElem = inboundElem.add(pwUnblinding).scalarmult(xyScalar);
    kBytes = kElem.toBytes();
    final key = this.finalize(kBytes);
    return key;
  }

  int hashParams() {
    /*
    # We can't really reconstruct the group from static data, but we'll
    # record enough of the params to confirm that we're using the same
    # ones upon restore. Otherwise the failure mode is silent key
    # disagreement. Any changes to the group or the M/N seeds should
    # cause this to change.
    g = self.params.group
    pieces = [g.arbitrary_element(b"").to_bytes(),
              g.scalar_to_bytes(g.password_to_scalar(b"")),
              self.params.M.to_bytes(),
              self.params.N.to_bytes(),
              ]
    return sha256(b"".join(pieces)).hexdigest()
    */
  }

  void serialize() {
    assert(!_started);
    return json.encode(serializeToDict());
  }

  void fromSerialized(data) {
    final d = json.decode(data);
    _deserializeFromDict(d);
  }
}

class Spake2Symmetric extends Spake2Base {
  final idSymmetric;

  Spake2Symmetric(var password, this.idSymmetric, params) {
    super(password);
  }

  void myBlinding() => params.S;
  void myUnblinding() => params.S;

  void extractMessage(String inboundSideAndMessage) {
    otherSide = inboundSideAndMessage.substring(0, 1);
    inboundMessage = inboundSideAndMessage.substring(1);
    assert(otherSide == SideSymmetric);
    return inboundMessage;
  }

  void finalize(kBytes) {
    return finalizeSpake2Symmetric(idSymmetric, inboundMessage, outboundMessage, kBytes, pw);
  }
}

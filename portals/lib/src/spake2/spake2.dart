/// The Spake2 algorithm is a variation of the Diffie Hellman algorithm, but
/// instead of just negotiating a secret key between two parties that formerly
/// know nothing about each other, both parties know a shared secret with small
/// entropy.
/// Here's an explanation about how it works:
/// https://copyninja.info/blog/golang_spake2_4.html

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:meta/meta.dart';

import 'ed25519.dart';
import 'utils.dart';

Uint8List sha256(List<int> data) =>
    crypto.sha256.convert(data).bytes.toUint8List();

final s = Element.arbitraryElement(ascii.encode('symmetric'));

/// This class manages one side of a spake2 key negotiation.
class _Spake2 {
  final Uint8List id;
  final Uint8List password;
  final BigInt _pwScalar;
  BigInt _xyScalar;
  Element _xyElement;
  Uint8List _outboundMessage;
  Uint8List _inboundMessage;

  bool _started = false;
  bool _finished = false;

  _Spake2({@required this.id, @required this.password})
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

extension _BytesSender on SendPort {
  void sendBytes(Uint8List list) => this.send(list.toList());
}

extension _BytesReceiver on StreamQueue {
  Future<Uint8List> receiveBytes() async =>
      (await this.next as List).cast<int>().toUint8List();
}

void _createSpake2(SendPort sendPort) async {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  final receivePort = StreamQueue(port);

  // Setup a Spake2 instance with id and password.
  final id = await receivePort.receiveBytes();
  final password = await receivePort.receiveBytes();
  final spake = _Spake2(id: id, password: password);

  // Start the encryption.
  sendPort.sendBytes(spake.start());

  // Finish the encryption.
  final inboundMessage = await receivePort.receiveBytes();
  final key = spake.finish(inboundMessage);
  sendPort.send(key);
  port.close();
}

class Spake2 {
  Spake2({@required this.id, @required this.password});

  final Uint8List id;
  final Uint8List password;

  ReceivePort _port;
  StreamQueue _receivePort;
  SendPort _sendPort;

  Future<Uint8List> start() async {
    _port = ReceivePort();
    Isolate.spawn(_createSpake2, _port.sendPort);
    _receivePort = StreamQueue(_port);
    _sendPort = await _receivePort.next as SendPort;

    // Send the id and password.
    _sendPort.sendBytes(id);
    _sendPort.sendBytes(password);
    return await _receivePort.receiveBytes();
  }

  Future<Uint8List> finish(Uint8List inboundMessage) async {
    _sendPort.sendBytes(inboundMessage);
    final key = await _receivePort.receiveBytes();
    _port.close();
    return key;
  }
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';

import '../utils.dart';

class PeerToPeerConnection {
  PeerToPeerConnection({@required this.socket, @required this.key})
      : _incomingData = StreamQueue(socket);

  static Future<PeerToPeerConnection> establish({
    @required Socket socket,
    @required Uint8List key,
  }) async {
    print('Connection from ${socket.address.address}:${socket.port} to '
        '${socket.remoteAddress.address}:${socket.remotePort}');
    final connection = PeerToPeerConnection(socket: socket, key: key);
    await connection.ensureEncryptionAndMeasureLatency();
    return connection;
  }

  final Socket socket;
  final Uint8List key;
  StreamQueue<Uint8List> _incomingData;

  int _latency;
  int get latency => _latency;

  Future<void> ensureEncryptionAndMeasureLatency() async {
    // Send a message containing random bytes.
    final randomBytes = [for (var i = 0; i < 32; i++) Random().nextInt(255)];
    final watch = Stopwatch()..start();
    send(randomBytes);

    // Receive the other side's random bytes and send back the reversed bytes.
    final otherRandomBytes = await receive();
    send(otherRandomBytes.reversed.toUint8List());

    // Receive the other side's reversed random bytes.
    final reversedBytes = await receive();

    if (!DeepCollectionEquality().equals(randomBytes.reversed, reversedBytes)) {
      throw Exception('Other side didn\'t encrypt content using the same key '
          'as we. That is scary.');
    }

    watch.stop();
    final doubleLatency = watch.elapsedMicroseconds;

    send(numberToBytes(doubleLatency.bi));
    final latencyOfOtherSide = bytesToNumber(await receive()).toInt();

    // Set the connection's latency to the average latency as perceived by both
    // sides.
    _latency = doubleLatency + latencyOfOtherSide;
  }

  void send(List<int> message) =>
      socket.add(SecretBox(key).encrypt(message).toUint8List());

  Future<Uint8List> receive() async =>
      SecretBox(key).detectNonceAndDecrypt(await _incomingData.next);

  Future<void> close() => socket.close();
}

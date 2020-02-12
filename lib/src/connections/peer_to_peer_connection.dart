import 'dart:io';
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
    // print('Connection from ${socket.address.address}:${socket.port} to '
    //     '${socket.remoteAddress.address}:${socket.remotePort}');
    final connection = PeerToPeerConnection(socket: socket, key: key);
    await connection.ensureEncryptionAndMeasureLatency();
    return connection;
  }

  final Socket socket;
  final Uint8List key;
  final StreamQueue<Uint8List> _incomingData;

  Future<void> ensureEncryptionAndMeasureLatency() async {
    // Exchange messages containing random bytes.
    final randomBytes = Bytes.generateRandom(32);
    send(randomBytes);
    final otherRandomBytes = await receive();

    // Exchange the other side's reversed random bytes.
    send(otherRandomBytes.reversed.toBytes());
    final reversedBytes = await receive();

    if (!DeepCollectionEquality().equals(randomBytes.reversed, reversedBytes)) {
      throw Exception('Other side didn\'t encrypt content using the same key '
          'as we. That is scary.');
    }
  }

  void send(List<int> message) {
    final encrypted = SecretBox(key).encrypt(message).toBytes();
    print('Sending encrypted $encrypted');
    socket.add(encrypted);
  }

  Future<Uint8List> receive() async {
    final encrypted = await _incomingData.next;
    print('Received encrypted $encrypted');
    return SecretBox(key).decrypt(EncryptedMessage.fromList(encrypted));
  }

  Future<void> close() => socket.close();
}

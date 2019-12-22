import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pinenacl/secret.dart';

import 'server_connection.dart';
import 'utils.dart';

class DilatedConnection {
  DilatedConnection({@required this.mailbox}) : assert(mailbox != null);

  final EncryptedMailboxConnection mailbox;
  EncryptedConnection _connection;

  Future<void> establishConnection() async {
    // This will be filled with all the data connections between both portals.
    final connections = <EncryptedConnection>[];
    final establishConnection = (Socket socket) async {
      print('Someone connected to our server at ${socket.port}');
      connections.add(await EncryptedConnection.establish(
        socket: socket,
        key: mailbox.key,
      ));
    };

    // Set up servers on all our ip addresses. When someone connects to one,
    // try to establish a connection using the above function.
    final servers = [
      if (NetworkInterface.listSupported)
        for (final interface in await NetworkInterface.list())
          for (final address in interface.addresses)
            await startServer(address, onConnected: establishConnection),
    ];

    // Send information about the servers to the other portal so that it can
    // try to connect to them.
    mailbox.send(
      phase: 'dilate',
      message: json.encode({
        'type': 'please',
        'connections': [
          for (final server in servers)
            {'address': server.address.address, 'port': server.port},
        ],
      }),
    );

    // Receive the server information from the other side and connect to all
    // of them.
    final dilateMessage = json.decode(await mailbox.receive(phase: 'dilate'));
    final serversFromOtherPortal = dilateMessage['connections'];
    connections.addAll([
      for (final server in serversFromOtherPortal)
        await EncryptedConnection.establish(
          socket: await Socket.connect(server['address'], server['port']),
          key: mailbox.key,
        ),
    ]);

    // Choose the connection with the lowest latency.
    print('Got ${connections.length} connections with latencies '
        '${connections.map((c) => c.latency).toList()}');
    final establishedConnections = connections.where((c) => c.latency != null);
    if (establishedConnections.isEmpty) {
      return;
    }
    _connection =
        establishedConnections.reduce((a, b) => a.latency < b.latency ? a : b);
  }

  static Future<ServerSocket> startServer(
    InternetAddress ip, {
    @required void Function(Socket socket) onConnected,
  }) async {
    final server = await ServerSocket.bind(ip, 0);
    server.first.then(onConnected);
    return server;
  }

  void send(Uint8List message) => _connection.send(message);
  Future<Uint8List> receive() => _connection.receive();
}

class EncryptedConnection {
  EncryptedConnection({@required this.socket, @required this.key})
      : _incomingData = StreamQueue(socket);

  static Future<EncryptedConnection> establish({
    @required Socket socket,
    @required Uint8List key,
  }) async {
    print('Connection from ${socket.address.address}:${socket.port} to '
        '${socket.remoteAddress.address}:${socket.remotePort}');
    final connection = EncryptedConnection(socket: socket, key: key);
    await connection.ensureEncryptionAndMeasureLatency();
    return connection;
  }

  final Socket socket;
  final Uint8List key;
  StreamQueue<Uint8List> _incomingData;

  int _latency;
  int get latency => _latency;

  void send(List<int> message) =>
      socket.add(SecretBox(key).encrypt(message).toUint8List());

  Future<Uint8List> receive() async =>
      SecretBox(key).detectNonceAndDecrypt(await _incomingData.next);

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
    _latency = doubleLatency ~/ 2;
    print('Latency to ${socket.port} is $latency ms');
  }
}

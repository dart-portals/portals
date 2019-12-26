import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../utils.dart';
import 'mailbox_connection.dart';
import 'peer_to_peer_connection.dart';

class DilatedConnection {
  DilatedConnection({@required this.mailbox}) : assert(mailbox != null) {
    _updates = _updatesController.stream.asBroadcastStream();
  }

  final MailboxConnection mailbox;

  bool _isLeader;
  PeerToPeerConnection _connection;

  final _updatesController = StreamController<Null>();
  Stream<Null> _updates;

  Future<void> _foundConnection(PeerToPeerConnection candidate) async {
    if (_connection != null) {
      candidate.close();
      return;
    }
    if (_isLeader) {
      _connection = candidate;
      _connection.send(utf8.encode('take-this'));
    } else
      try {
        final response = await candidate.receive();
        assert(utf8.decode(response) == 'take-this'); // TODO: error handling
        _connection = candidate;
        _updatesController.add(null);
      } on StateError {
        _connection.close();
      }
  }

  Future<void> establishConnection() async {
    final servers = [
      if (NetworkInterface.listSupported)
        for (final interface in await NetworkInterface.list())
          for (final address in interface.addresses)
            await startServer(address, onConnected: (Socket socket) async {
              // print('Someone connected to our server at ${socket.port}');
              _foundConnection(await PeerToPeerConnection.establish(
                socket: socket,
                key: mailbox.key,
              ));
            }),
    ];

    // Send information about the servers to the other portal so that it can
    // try to connect to them.
    final side = bytesToHex(generateRandomUint8List(32));
    mailbox.send(
      phase: 'dilation',
      message: json.encode({
        'side': side,
        'connection-hints': [
          for (final server in servers)
            {'address': server.address.address, 'port': server.port},
        ],
      }),
    );

    // Receive the server information from the other portal and connect to all
    // of them.
    final response = json.decode(await mailbox.receive(phase: 'dilate'));
    _isLeader = (response['side'] as String).compareTo(side) < 0;
    final serversFromOtherPortal = response['connection-hints'];

    for (final server in serversFromOtherPortal) {
      final delay = server.containsKey('delay')
          ? Duration(milliseconds: int.parse(server['delay']))
          : Duration.zero;
      Future.delayed(delay, () async {
        _foundConnection(await PeerToPeerConnection.establish(
          socket: await Socket.connect(server['address'], server['port']),
          key: mailbox.key,
        ));
      });
    }

    await _updates.first;
    print(
        'Using connection $_connection with ip ${_connection.socket.address.address} from ${_connection.socket.port} to ${_connection.socket.remotePort}.');
  }

  static Future<ServerSocket> startServer(
    InternetAddress ip, {
    @required void Function(Socket socket) onConnected,
  }) async {
    final server = await ServerSocket.bind(ip, 0);
    server.first.then(onConnected);
    return server;
  }

  Future<void> send(Uint8List message) async {
    await _updates.first;
    await _connection.send(message);
  }

  Future<Uint8List> receive() async {
    await _updates.first;
    return await _connection.receive();
  }

  void close() {
    _connection.close();
    _connection = null;
  }
}

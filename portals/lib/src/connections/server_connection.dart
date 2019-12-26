import 'dart:convert';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../errors.dart';

/// A simple connection to the server.
///
/// Initially, the portal connects to a server. Portals use this server to
/// negotiate an end-to-end encrypted connection and exchange ip address
/// inforamtion in order to be able to create a direct peer-to-peer connection.
/// /// Portals use the Magic Wormhole protocol for communicating, so if you're
/// wondering how the server works or you want to run your own server, check
/// out the Magic Wormhole server repository:
/// https://github.com/warner/magic-wormhole-mailbox-server
class ServerConnection {
  ServerConnection({@required this.url})
      : assert(url != null),
        assert(url.isNotEmpty);

  final String url;

  IOWebSocketChannel _server;
  bool get isConnected => _server != null;

  StreamQueue<dynamic> _incomingPackets;

  /// Connects to the server.
  Future<void> connect() async {
    try {
      _server = IOWebSocketChannel.connect(
        url,
        pingInterval: Duration(minutes: 1),
      );
      _incomingPackets = StreamQueue(_server.stream);
    } on WebSocketChannelException {
      throw PortalCannotConnectToServerException(url);
    } on FormatException {
      close();
      throw PortalServerCorruptException('Portal sent a non-json packet.');
    }
  }

  /// Closes the connection to the server.
  Future<void> close() async {
    await _server.sink.close();
  }

  /// Sends a packet with the given [data] to the server.
  void send(Map<String, dynamic> data) {
    assert(data != null);
    _server.sink.add(json.encode(data));
  }

  /// Receives a packet with the given [type] from the server.
  Future<Map<String, dynamic>> receive({@required String type}) async {
    assert(type != null);
    assert(type.isNotEmpty);

    try {
      while (true) {
        final data =
            json.decode(await _incomingPackets.next) as Map<String, dynamic>;
        if (data['type'] == type) {
          return data;
        }
      }
    } on TypeError {
      close();
      throw PortalServerCorruptException(
          'The server sent a packet without a type.');
    }
  }
}

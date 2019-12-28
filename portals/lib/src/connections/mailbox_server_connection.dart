import 'dart:math';

import 'package:meta/meta.dart';

import '../errors.dart';
import 'server_connection.dart';

/// A connection to a mailbox server.
///
/// The server doesn't really do anything except offering "mailboxes", which
/// clients can connect to. Mailboxes are identified using large ids. Clients
/// can send messages to a mailbox, which will then get sent to everyone
/// connected to that mailbox.
/// In order to make the communication between the clients easier, there are
/// nameplates. Nameplates are short strings that point to a single mailbox and
/// can be claimed and released by clients.
/// Typically, one client allocates and claims a nameplate. Then, the nameplate
/// is transcribed to the second client, which also claims the nameplate to
/// retrieve the id of the connected mailbox. Now, both clients can connect to
/// the mailbox using the large id. Also, they can release the nameplate to
/// allow other clients to reuse the nameplate for another mailbox.
///
/// This class wraps a regular [ServerConnection] to add some utility methods
/// for allocating, claiming and releasing nameplates, opening and closing
/// mailboxes and sending and receiving messages.
class MailboxServerConnection {
  MailboxServerConnection({
    @required this.server,
    @required this.appId,
  })  : assert(appId != null),
        assert(appId.isNotEmpty);

  final ServerConnection server;
  final String appId;

  /// Each client has a [side]. By default, we receive everything sent to the
  /// mailbox. We can use the side to filter out the messages that come from
  /// clients other than us.
  String _side;
  String get side => _side;

  void initialize() {
    // If two clients have the same side, that's bad – they'll just ignore
    // everything. So, we choose a reasonably large random string as our side.
    final random = Random();
    _side = [
      for (var i = 0; i < 32; i++) random.nextInt(16).toRadixString(16),
    ].join();
  }

  /// Binds this socket to the server by providing an app id and a side id,
  /// which we choose randomly.
  Future<void> bindAndWelcome() async {
    assert(server.isConnected);

    server.send({'type': 'bind', 'appid': appId, 'side': _side});

    // Receive the welcome message.
    try {
      final welcomeMessage = await server.receive(type: 'welcome');
      final welcome = welcomeMessage['welcome'] as Map<String, dynamic>;

      // The welcome message can optionally contain an error message. If we
      // get one, we should terminate.
      if (welcome.containsKey('error')) {
        throw PortalInternalServerErrorException(welcome['error']);
      }

      // The welcome message can optionally contain a "motd" message with
      // information for developers, like notifications about performance
      // problems, scheduled downtime or the need for money donations to keep
      // the server running.
      assert(() {
        if (welcome.containsKey('motd')) {
          print('The mailbox server at ${server.url} sent the following '
              'message:\n${welcome['motd']}');
        }
        return true;
      }());
    } on TypeError {
      throw PortalServerCorruptException(
          "The server's first packet didn't include a welcome message.");
    }
  }

  /// Allocates a new nameplate.
  Future<String> allocateNameplate() async {
    assert(server.isConnected);

    print('Allocating nameplate.');
    server.send({'type': 'allocate'});

    final allocation = await server.receive(type: 'allocated');
    String nameplate;
    try {
      nameplate = allocation['nameplate'] as String;
    } on CastError {
      throw PortalServerCorruptException(
          'The nameplate that the server responded with was not a string.');
    }
    if (nameplate == null) {
      throw PortalServerCorruptException(
          "The packet confirming the nameplate allocation didn't contain "
          'the allocated nameplate.');
    }
    return nameplate;
  }

  /// Claims a nameplate, which means that the nameplate will stay attached to
  /// its mailbox until we release it.
  Future<String> claimNameplate(String nameplate) async {
    assert(server.isConnected);

    server.send({'type': 'claim', 'nameplate': nameplate});

    final claim = await server.receive(type: 'claimed');
    String mailbox;
    try {
      mailbox = claim['mailbox'] as String;
    } on CastError {
      throw PortalServerCorruptException(
          'The mailbox id that the server responded with was not a string.');
    }
    if (mailbox == null) {
      throw PortalServerCorruptException(
          "The packet confirming the claim of the nameplate didn't contain "
          'the id of the mailbox that the nameplate points to.');
    }
    return mailbox;
  }

  /// Releases our nameplate.
  void releaseNameplate() {
    assert(server.isConnected);

    server.send({'type': 'release'});
  }

  /// Opens the mailbox attached to our nameplate.
  void openMailbox(String mailbox) {
    assert(server.isConnected);
    assert(mailbox != null);

    server.send({'type': 'open', 'mailbox': mailbox});
  }

  /// Closes the mailbox.
  void closeMailbox(Mood mood) {
    assert(mood != null);

    server.send({'type': 'close', 'mood': mood.toMoodString()});
  }

  /// Sends a message to the opened mailbox.
  void sendMessage({@required String phase, @required String message}) async {
    assert(server.isConnected);
    assert(phase != null);
    assert(message != null);

    print('${_side.substring(0, 3)}: Sending $phase message');
    server.send({'type': 'add', 'phase': phase, 'body': message});
  }

  /// Receive a message with the given [phase].
  Future<Map<String, dynamic>> receiveMessage({@required String phase}) async {
    while (true) {
      final response = await server.receive(type: 'message');
      print('${_side.substring(0, 3)}: Received, so apparently not ignored');

      if (response['side'] == _side) {
        print(
            '${_side.substring(0, 3)}: Received message of phase $phase. Ignoring because its from us.');
        continue;
      }
      if (phase == null || response['phase'] == phase) {
        print(
            '${_side.substring(0, 3)}: Received message of phase $phase. Reporting.');
        return response;
      }
      print(
          '${_side.substring(0, 3)}: Received message of phase ${response['phase']}. Discarding because listening for $phase.');
    }
  }
}

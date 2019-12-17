import 'dart:convert';

import 'package:meta/meta.dart';

import 'server_connection.dart';

class DilatedConnection {
  DilatedConnection({@required this.mailbox}) : assert(mailbox != null);

  final EncryptedMailboxConnection mailbox;

  Future<void> initialize() async {
    await _negotiateVersions();
  }

  Future<void> _negotiateVersions() async {
    // We now got a shared key. Exchange version information.
    // TODO: Use version information.
    await mailbox.send(
      phase: 'version',
      message: json.encode({'app_version': '1.0.0'}),
    );
    final version = await mailbox.receive(phase: 'version');
    print('Version is $version');
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'code_generators/code_generator.dart';
import 'code_generators/hex.dart';
import 'server_connection.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

const _defaultRelayUrl = 'ws://relay.magic-wormhole.io:4000/v1';
const _defaultCodeGenerator = HexCodeGenerator();

// TODO: handle mood
enum Mood { lonely, happy, scared, errorly }

class Portal {
  // TODO: enable timing, versions
  Portal(
    this.appId, {
    this.relayUrl = _defaultRelayUrl,
    this.codeGenerator,
  })  : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(relayUrl != null),
        assert(relayUrl.isNotEmpty);

  final String appId;
  final String relayUrl;
  final CodeGenerator codeGenerator;

  Mood _mood = Mood.lonely;
  Mood get mood => _mood;

  EncodedMailboxConnection _mailbox;

  Future<String> open() async {
    _mailbox = EncodedMailboxConnection(
      url: relayUrl,
      appId: appId,
      codeGenerator: codeGenerator,
    );
    await _mailbox.initialize();

    return _mailbox.code;
  }

  Future<Uint8List> waitForLink() async {
    return await _setupLink();
  }

  Future<Uint8List> openAndLinkTo(String code) async {
    _mailbox = EncodedMailboxConnection(
      url: relayUrl,
      appId: appId,
      codeGenerator: codeGenerator,
      code: code,
    );
    await _mailbox.initialize();

    print('Linking to $code');
    return await _setupLink();
  }

  Future<Uint8List> _setupLink() async {
    // We now got a shared key. Exchange version information.
    // TODO: Use version information.
    await _mailbox.send(
      phase: 'version',
      message: json.encode({'app_version': '1.0.0'}),
    );
    final version = await _mailbox.receive(phase: 'version');
    print('Version is $version');

    return _mailbox.keyHash;
  }
}

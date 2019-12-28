import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'client_connection.dart';
import 'code_generators/code_generator.dart';
import 'code_generators/hex.dart';
import 'server_connection.dart';

const _defaultRelayUrl = 'ws://relay.magic-wormhole.io:4000/v1';
const _defaultCodeGenerator = HexCodeGenerator();

// TODO: handle mood
enum Mood { lonely, happy, scared, errorly }

class Portal {
  Portal({
    @required this.appId,
    @required this.version,
    this.relayUrl = _defaultRelayUrl,
    this.codeGenerator = _defaultCodeGenerator,
  })  : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(relayUrl != null),
        assert(relayUrl.isNotEmpty);

  final String appId;
  final String version;
  final String relayUrl;
  final CodeGenerator codeGenerator;

  Mood _mood = Mood.lonely;
  Mood get mood => _mood;

  Uint8List _shortKey;

  Uint8List _keyHash;
  Uint8List get keyHash => _keyHash;

  MailboxConnection _mailbox;
  DilatedConnection _client;

  Future<String> open() async {
    _mailbox = MailboxConnection(
      url: relayUrl,
      appId: appId,
    );
    await _mailbox.initialize();

    _shortKey = CodeGenerator.generateShortKey();
    return codeGenerator.payloadToCode(CodePayload(
      nameplate: utf8.encode(_mailbox.nameplate),
      key: _shortKey,
    ));
  }

  Future<Uint8List> waitForLink() async {
    return await _setupLink();
  }

  Future<Uint8List> openAndLinkTo(String code) async {
    final payload = codeGenerator.codeToPayload(code);
    _shortKey = payload.key;

    _mailbox = MailboxConnection(
      url: relayUrl,
      appId: appId,
      nameplate: utf8.decode(payload.nameplate),
    );
    await _mailbox.initialize();

    // print('Linking to $code');
    return await _setupLink();
  }

  Future<Uint8List> _setupLink() async {
    // Create an encrypted connection over the mailbox and save its key hash.
    final encryptedMailbox = EncryptedMailboxConnection(
      mailbox: _mailbox,
      shortKey: _shortKey,
    );
    await encryptedMailbox.initialize();
    _keyHash = encryptedMailbox.computeKeyHash();

    // Try several connections to the other client.
    _client = DilatedConnection(mailbox: encryptedMailbox);
    await _client.establishConnection();

    return _keyHash;
  }

  void send(Uint8List message) => _client.send(message);
  Future<Uint8List> receive() => _client.receive();
}

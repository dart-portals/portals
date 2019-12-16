import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pinenacl/secret.dart';

import 'server_connection.dart';
import 'spake2/spake2.dart';
import 'utils.dart';

const _defaultRelayUrl = 'ws://relay.magic-wormhole.io:4000/v1';

// TODO: handle mood
enum Mood { lonely, happy, scared, errorly }

class Portal {
  // TODO: enable timing, versions
  Portal(this.appId, {String relayUrl = _defaultRelayUrl})
      : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(relayUrl != null),
        assert(relayUrl.isNotEmpty),
        _connection = ServerConnection(relayUrl);

  final String appId;

  ServerConnection _connection;
  EncryptedServerConnection _encryptedConnection;

  Mood _mood = Mood.lonely;
  Mood get mood => _mood;

  String _code;
  String get code => _code;

  String _side;
  String _key;

  SecretBox _box;

  Future<void> _initialize() async {
    _side = Random.secure().nextInt(123456789).toRadixString(16);

    await _connection.initialize();
    await _connection.welcomeAndBind(appId, _side);
  }

  Future<String> open() async {
    await _initialize();
    final nameplate = await _connection.allocate();
    final mailbox = await _connection.claimNameplate(nameplate);
    await _connection.openMailbox(mailbox);

    // TODO: refactor key generation to somewhere else
    _key = [
      for (var i = 0; i < 3; i++) 'abc'[Random.secure().nextInt(3)],
    ].join();
    _code = '$nameplate-$_key';
    return _code;
  }

  Future<Uint8List> waitForLink() async {
    return await _setupLink();
  }

  Future<Uint8List> openAndLinkTo(String code) async {
    assert(code != null);
    assert(code.isNotEmpty);
    assert(code.contains('-'));

    final dash = code.indexOf('-');
    final nameplate = code.substring(0, dash);
    _key = code.substring(dash + 1);
    print('Key is $_key');

    await _initialize();
    final mailbox = await _connection.claimNameplate(nameplate);
    await _connection.openMailbox(mailbox);

    print('Linking to $code');
    return await _setupLink();
  }

  Future<Uint8List> _setupLink() async {
    // Exchange spake messages.
    final spake = Spake2(id: utf8.encode(appId), password: utf8.encode(_key));
    final outbound = spake.start();
    await _connection.sendMessage(
      json.encode({'pake_v1': bytesToHex(outbound)}),
      phase: 'pake',
    );
    final inboundMessage =
        json.decode((await _connection.receiveMessage(_side))['body']);
    final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
    final sharedKey = spake.finish(inboundBytes);

    print('Shared key is $sharedKey');
    _encryptedConnection = EncryptedServerConnection(
      connection: _connection,
      key: sharedKey,
      side: _side,
    );

    // We now got a shared key. Exchange version information.
    // TODO: Use version information.
    await _encryptedConnection.sendMessage(
      json.encode({'app_version': '1.0.0'}),
      phase: 'version',
    );
    final version = await _encryptedConnection.receiveMessage(phase: 'version');
    print('Version is $version');

    return sha256(sharedKey);
  }
}

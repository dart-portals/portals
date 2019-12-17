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
  Portal(this.appId, {this.relayUrl = _defaultRelayUrl})
      : assert(appId != null),
        assert(appId.isNotEmpty),
        assert(relayUrl != null),
        assert(relayUrl.isNotEmpty);

  final String appId;
  final String relayUrl;

  Mood _mood = Mood.lonely;
  Mood get mood => _mood;

  MailboxConnection _mailbox;
  EncryptedMailboxConnection _encryptedMailbox;

  String _key;

  Future<String> open() async {
    _mailbox = MailboxConnection(url: relayUrl, appId: appId);
    await _mailbox.initialize();

    // TODO: refactor key generation to somewhere else
    _key = [
      for (var i = 0; i < 3; i++) 'abc'[Random.secure().nextInt(3)],
    ].join();
    return '${_mailbox.nameplate}-$_key';
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

    _mailbox = MailboxConnection(
      url: relayUrl,
      appId: appId,
      nameplate: nameplate,
    );
    await _mailbox.initialize();

    print('Linking to $code');
    return await _setupLink();
  }

  Future<Uint8List> _setupLink() async {
    // Exchange pake messages.
    final spake = Spake2(id: utf8.encode(appId), password: utf8.encode(_key));
    final outbound = spake.start();
    await _mailbox.send(
      phase: 'pake',
      message: json.encode({'pake_v1': bytesToHex(outbound)}),
    );
    final inboundMessage =
        json.decode((await _mailbox.receive(phase: 'pake'))['body']);
    final inboundBytes = hexToBytes(inboundMessage['pake_v1']);
    final sharedKey = spake.finish(inboundBytes);

    print('Shared key is $sharedKey');
    _encryptedMailbox = EncryptedMailboxConnection(
      mailbox: _mailbox,
      key: sharedKey,
    );

    // We now got a shared key. Exchange version information.
    // TODO: Use version information.
    await _encryptedMailbox.send(
      phase: 'version',
      message: json.encode({'app_version': '1.0.0'}),
    );
    final version = await _encryptedMailbox.receiveMessage(phase: 'version');
    print('Version is $version');

    return sha256(sharedKey);
  }
}

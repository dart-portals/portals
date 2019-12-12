import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:web_socket_channel/io.dart';
import 'package:meta/meta.dart';

const _defaultRelayUrl = 'ws://relay.magic-wormhole.io:4000/v1';

class Wormhole {
  final String appId;
  String _side;

  IOWebSocketChannel _relay;
  StreamQueue<String> _relayReceiver;

  Wormhole(this.appId)
      : assert(appId != null),
        assert(appId.isNotEmpty);

  void _send(Map<String, dynamic> data) => _relay.sink.add(json.encode(data));
  Future<Map<String, dynamic>> _receive({String type}) async {
    Map<String, dynamic> response;
    do {
      response = json.decode(await _relayReceiver.next);
      print(response);
    } while (type != null && response['type'] != type);
    return response;
  }

  Future<void> _initialize() async {
    _relay = IOWebSocketChannel.connect(_defaultRelayUrl);
    _relayReceiver = StreamQueue<String>(_relay.stream.cast<String>());

    // TODO: choose a better side string
    _side = Random.secure().nextInt(123456789).toRadixString(16);

    final welcomeMessage = await _receive(type: 'welcome');
    assert(!(welcomeMessage['welcome'] as Map<String, dynamic>)
        .containsKey('error'));

    _send({
      'type': 'bind',
      'appid': appId,
      'side': _side,
    });
  }

  Future<String> _claimNameplate(String nameplate) async {
    _send({'type': 'claim', 'nameplate': nameplate});
    final claim = await _receive(type: 'claimed');

    final mailbox = claim['mailbox'] as String;
    assert(mailbox != null);
    return mailbox;
  }

  Future<String> generateCode() async {
    await _initialize();
    _send({'type': 'allocate'});

    final allocation = await _receive(type: 'allocated');
    final nameplate = allocation['nameplate'] as String;
    assert(nameplate != null);

    final mailbox = await _claimNameplate(nameplate);
    _send({'type': 'open', 'mailbox': mailbox});

    final key = [
      for (var i = 0; i < 3; i++) 'abc'[Random.secure().nextInt(3)],
    ].join();
    return '$nameplate-$key';
  }

  Future<void> enterCode(String code) async {
    assert(code != null);
    assert(code.isNotEmpty);
    assert(code.contains('-'));

    final dash = code.indexOf('-');
    final nameplate = code.substring(0, dash);
    final key = code.substring(dash + 1);
    print('Key is $key');

    await _initialize();

    final mailbox = await _claimNameplate(nameplate);
    _send({'type': 'open', 'mailbox': mailbox});
    print('Mailbox opened');
  }

  Future<void> send(String message) async {
    _send({'type': 'add', 'phase': 'A', 'body': message});
  }

  Future<String> receive() async {
    return (await _receive(type: 'message'))['body'];
  }
}

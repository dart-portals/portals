import 'dart:convert';
import 'dart:isolate';

import 'portals.dart';

const appId = 'example.com';

void main() async {
  final portal = Portal(appId: appId, version: '1.0.0');
  final code = await portal.open();

  print(code);
  await Isolate.spawn(otherMain, code);

  final key = await portal.waitForLink();
  print('Portal linked.');

  print(utf8.decode(await portal.receive()));
}

void otherMain(String code) async {
  final portal = Portal(appId: appId, version: '1.0.0');
  print('Connecting to portal $code');

  final key = await portal.openAndLinkTo(code);
  print('Portal linked.');

  await portal.send(utf8.encode('Hi there.'));
}

import 'dart:isolate';

import 'portals.dart';

const appId = 'example.com';

void main() async {
  final portal = Portal(appId: appId, version: '1.0.0');
  final code = await portal.open();

  print(code);
  await Isolate.spawn(otherMain, code);

  final key = await portal.waitForLink();
  print('Portal linked to $key.');

  //print(await portal.receiveMessage());
}

void otherMain(String code) async {
  final portal = Portal(appId: appId, version: '1.0.0');
  print('Connecting to portal $code');

  final key = await portal.openAndLinkTo(code);
  print('Other portal linked to $key.');

  // await portal.sendMessage('Hi there.');
}

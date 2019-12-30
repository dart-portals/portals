import 'dart:convert';
import 'dart:isolate';

import 'portals.dart';
import 'src/utils.dart';

const appId = 'example.com';

void main() async {
  final portal = Portal(appId: appId);
  final phrase = await portal.open();

  print(phrase);
  await Isolate.spawn(otherMain, phrase);

  final key = await portal.waitForLink();
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  print(utf8.decode(await portal.receive()));
}

void otherMain(String phrase) async {
  final portal = Portal(appId: appId);
  print('Connecting to portal $phrase');

  final key = await portal.openAndLinkTo(phrase);
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  await portal.send(utf8.encode('Hi there.'));
}

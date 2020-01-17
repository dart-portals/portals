import 'dart:isolate';

import 'portals.dart';
import 'src/binary/sample.dart' as sample;
import 'src/utils.dart';

const appId = 'example.com';

void main() {
  sample.main();
  // portal();
}

void portal() async {
  final portal = Portal(appId: appId);
  final phrase = await portal.open();

  print(phrase);
  await Isolate.spawn(otherMain, phrase);

  final key = await portal.waitForLink();
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  print(await portal.receive());
  print(await portal.receive());
}

void otherMain(String phrase) async {
  final portal = Portal(appId: appId);
  print('Connecting to portal $phrase');

  final key = await portal.openAndLinkTo(phrase);
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  await portal.send('Hi there.');
  await portal.send(Duration(days: 42, milliseconds: 123));
}

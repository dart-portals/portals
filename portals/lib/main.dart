import 'dart:convert';
import 'dart:isolate';

import 'package:version/version.dart';

import 'portals.dart';
import 'src/utils.dart';

const appId = 'example.com';
final version = Version.parse('1.0.0');

void main() async {
  final portal = Portal(appId: appId, version: version);
  final code = await portal.open();
  print('Portal $code opened');

  await Isolate.spawn(otherMain, code);

  final key = await portal.waitForLink();
  print('Portal 1 linked using key ${bytesToHex(key)}.');
  await portal.waitUntilReady();

  print(utf8.decode(await portal.receive()));
}

void otherMain(String code) async {
  final portal = Portal(appId: appId, version: version);
  print('Connecting to portal $code');

  final key = await portal.openAndLinkTo(code);
  print('Portal 2 linked using key ${bytesToHex(key)}.');
  await portal.waitUntilReady();

  await portal.send(utf8.encode('Hi there.'));
}

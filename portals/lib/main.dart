import 'dart:convert';
import 'dart:isolate';

import 'package:version/version.dart';

import 'portals.dart';
import 'src/utils.dart';

const appId = 'example.com';

void main() async {
  final portal = Portal(appId: appId, version: Version.parse('1.0.0'));
  final code = await portal.open();

  print(code);
  await Isolate.spawn(otherMain, code);

  final key = await portal.waitForLink();
  print('Portal linked using key ${bytesToHex(key)}.');

  await Future.delayed(Duration(seconds: 2));
  print(utf8.decode(await portal.receive()));
}

void otherMain(String code) async {
  final portal = Portal(appId: appId, version: Version.parse('1.0.1'));
  print('Connecting to portal $code');

  final key = await portal.openAndLinkTo(code);
  print('Portal linked using key ${bytesToHex(key)}.');

  await Future.delayed(Duration(seconds: 2));
  await portal.send(utf8.encode('Hi there.'));
}

import 'dart:convert';
import 'dart:math';

import 'package:portals/portals.dart';

import 'src/spake2/spake2.dart';

/*void main() async {
  spake2.main();
  /*final offer = offerWormhole();
  final connecter = connectToWormhole(await offer.first);

  await offer;
  await connecter;*/
}*/

void main() {
  final random = Random.secure();

  final a = Spake2(utf8.encode('password'));
  final aOut = a.start(random);
  print('The outbound message of a is $aOut.');

  final b = Spake2(utf8.encode('password'));
  final bOut = b.start(random);
  print('The outbound message of b is $bOut.');

  final aKey = a.finish(bOut);
  print('The key of a is $aKey.');

  final bKey = b.finish(aOut);
  print('The key of b is $bKey.');
}

Stream<String> offerWormhole() async* {
  final wormhole = Portal('marcelgarus.dev');
  print('Generating wormhole code...');
  final code = await wormhole.generateCode();
  print(code);
  yield code;
  print(wormhole.receive());
}

Future<void> connectToWormhole(String code) async {
  final wormhole = Portal('marcelgarus.dev');
  print('Connecting to wormhole code...');
  await wormhole.enterCode(code);
  print('Connected.');
  await wormhole.send('Hi there.');
}

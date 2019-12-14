import 'package:magic_wormhole/magic_wormhole.dart';

import 'src/spake2.dart' as spake2;

void main() async {
  spake2.main();
  /*final offer = offerWormhole();
  final connecter = connectToWormhole(await offer.first);

  await offer;
  await connecter;*/
}

Stream<String> offerWormhole() async* {
  final wormhole = Wormhole('marcelgarus.dev');
  print('Generating wormhole code...');
  final code = await wormhole.generateCode();
  print(code);
  yield code;
  print(wormhole.receive());
}

Future<void> connectToWormhole(String code) async {
  final wormhole = Wormhole('marcelgarus.dev');
  print('Connecting to wormhole code...');
  await wormhole.enterCode(code);
  print('Connected.');
  await wormhole.send('Hi there.');
}

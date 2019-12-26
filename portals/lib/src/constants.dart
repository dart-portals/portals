import 'package:version/version.dart';

import 'code_generators/hex.dart';

const defaultRelayUrl = 'ws://relay.magic-wormhole.io:4000/v1';
const defaultCodeGenerator = HexCodeGenerator();
final portalsVersion = Version.parse('1.0.0');

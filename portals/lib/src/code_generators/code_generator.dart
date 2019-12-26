import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../utils.dart';

@immutable
class CodePayload {
  CodePayload({@required this.nameplate, @required this.key})
      : assert(nameplate != null),
        assert(nameplate.isNotEmpty),
        assert(key != null),
        assert(key.isNotEmpty);

  final Uint8List nameplate;
  final Uint8List key;
}

abstract class CodeGenerator {
  static const _keyLength = 2;

  static Uint8List generateShortKey() => generateRandomUint8List(_keyLength);

  String payloadToCode(CodePayload payload);
  CodePayload codeToPayload(String code);
}

import 'dart:typed_data';

import 'package:meta/meta.dart';

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
  String payloadToCode(CodePayload payload);
  CodePayload codeToPayload(String code);
}

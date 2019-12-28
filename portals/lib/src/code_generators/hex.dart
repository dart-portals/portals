import 'package:portals/src/spake2/utils.dart';

import 'code_generator.dart';

class HexCodeGenerator implements CodeGenerator {
  const HexCodeGenerator();

  @override
  CodePayload codeToPayload(String code) {
    final dash = code.indexOf('-');
    return CodePayload(
      nameplate: Bytes.fromHex(code.substring(0, dash)),
      key: Bytes.fromHex(code.substring(dash + 1)),
    );
  }

  @override
  String payloadToCode(CodePayload payload) =>
      '${payload.nameplate.toHex()}-${payload.key.toHex()}';
}

import '../utils.dart';
import 'phrase_generator.dart';

class HexCodeGenerator implements PhraseGenerator {
  const HexCodeGenerator();

  @override
  PhrasePayload phraseToPayload(String code) {
    final dash = code.indexOf('-');
    return PhrasePayload(
      nameplate: Bytes.fromHex(code.substring(0, dash)),
      key: Bytes.fromHex(code.substring(dash + 1)),
    );
  }

  @override
  String payloadToPhrase(PhrasePayload payload) =>
      '${payload.nameplate.toHex()}-${payload.key.toHex()}';
}

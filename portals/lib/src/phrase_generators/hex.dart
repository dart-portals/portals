import '../utils.dart';
import 'phrase_generator.dart';

class HexCodeGenerator implements PhraseGenerator {
  const HexCodeGenerator();

  @override
  PhrasePayload phraseToPayload(String phrase) {
    final dash = phrase.indexOf('-');
    return PhrasePayload(
      nameplate: Bytes.fromHex(phrase.substring(0, dash)),
      key: Bytes.fromHex(phrase.substring(dash + 1)),
    );
  }

  @override
  String payloadToPhrase(PhrasePayload payload) =>
      '${payload.nameplate.toHex()}-${payload.key.toHex()}';
}

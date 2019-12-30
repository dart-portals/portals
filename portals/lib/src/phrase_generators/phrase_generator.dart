import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../utils.dart';

@immutable
class PhrasePayload {
  PhrasePayload({@required this.nameplate, @required this.key})
      : assert(nameplate != null),
        assert(nameplate.isNotEmpty),
        assert(key != null),
        assert(key.isNotEmpty);

  final Uint8List nameplate;
  final Uint8List key;
}

abstract class PhraseGenerator {
  static const _keyLength = 2;

  static Uint8List generateShortKey() {
    final random = Random.secure();
    return [
      for (int i = 0; i < _keyLength; i++) random.nextInt(256),
    ].toBytes();
  }

  static void ensureGeneratorReversible({
    @required PhraseGenerator generator,
    @required PhrasePayload payload,
    @required String generatedPhrase,
  }) {
    assert(generator != null);
    assert(payload != null);
    assert(generatedPhrase != null);

    final recreatedPayload = generator.phraseToPayload(generatedPhrase);
    final keyFits =
        DeepCollectionEquality().equals(payload.key, recreatedPayload.key);
    final nameplateFits = DeepCollectionEquality()
        .equals(payload.nameplate, recreatedPayload.nameplate);

    if (!keyFits || !nameplateFits) {
      throw AssertionError('The phrase generator is non-reversible.\n'
          'It generated the phrase $generatedPhrase for the key '
          '${payload.key} and the nameplate ${payload.nameplate}, but when '
          'asked to convert that phrase into the original key and nameplate, '
          'it returned the key ${recreatedPayload.key} and the nameplate '
          '${recreatedPayload.nameplate}.'
          'Note that ${(!keyFits && !nameplateFits) ? 'both' : keyFits ? 'the nameplates' : 'the keys'}'
          'differ.');
    }
  }

  String payloadToPhrase(PhrasePayload payload);
  PhrasePayload phraseToPayload(String phrase);
}

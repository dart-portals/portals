import 'dart:math';
import 'dart:typed_data';

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

  String payloadToPhrase(PhrasePayload payload);
  PhrasePayload phraseToPayload(String code);
}

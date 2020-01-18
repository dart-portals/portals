import 'dart:convert' as convert;
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:portals/src/phrase_generators/phrase_generator.dart';

extension Bytes on Iterable<int> {
  String toHex() =>
      map((byte) => byte.toRadixString(16).fillWithLeadingZeros(2)).join('');

  static Uint8List fromHex(String hexString) {
    return <int>[
      for (var i = 0; i < hexString.length ~/ 2; i++)
        int.parse(hexString.substring(2 * i, 2 * i + 2), radix: 16),
    ].toBytes();
  }

  /// Turns this [Iterable<int>] into a [Uint8List].
  Uint8List toBytes() => Uint8List.fromList(toList());

  static Uint8List generateRandom(int length) {
    final random = Random.secure();
    return [
      for (var i = 0; i < length; i++) random.nextInt(256),
    ].toBytes();
  }

  /// Returns the minimum of this list.
  int get min => reduce(math.min);
}

extension LeadingZeros on String {
  /// Fill this string with leading zeros, so that the total length is at least
  /// [length].
  String fillWithLeadingZeros(int length) =>
      '${[for (var i = length - this.length; i > 0; i--) '0'].join()}$this';
}

extension FilterStreamByType<T> on Stream<T> {
  Stream<S> whereType<S extends T>() => where((item) => item is S).cast<S>();
}

extension Utf8Decode on List<int> {
  String get utf8decoded => convert.utf8.decode(this);
}

extension Utf8Encode on String {
  Uint8List get utf8encoded => convert.utf8.encode(this).toBytes();
}

extension PhraseToPayload on String {
  PhrasePayload toPhrasePayload(PhraseGenerator generator) =>
      generator.phraseToPayload(this);
}

void ifInDebugMode(void Function() run) {
  assert(() {
    run();
    return true;
  }());
}

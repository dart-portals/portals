import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Uint8List _extract(Uint8List salt, Uint8List inputKeyMaterial) {
  salt ??= List.filled(sha256.blockSize, 0);
  return Hmac(sha256, salt).convert(inputKeyMaterial).bytes;
}

Uint8List _expand(Uint8List key, Uint8List info, int length) {
  final hashLength = sha256.blockSize;

  if (length > 255 * hashLength) {
    throw Exception(
        'Cannot expand to more than ${255 * hashLength} bytes using '
        'sha256, but length is $length.');
  }

  var blocksNeeded = (length / hashLength).ceil();
  var okM = <int>[];
  var outputBlock = <int>[];

  for (var i = 0; i < blocksNeeded; i++) {
    outputBlock = Hmac(sha256, key).convert(outputBlock + info + [i + 1]).bytes;
    okM.addAll(outputBlock);
  }
  return Uint8List.fromList(okM.sublist(0, length));
}

class Hkdf {
  Uint8List _prk;

  Hkdf(Uint8List salt, Uint8List inputKeyMaterial)
      : _prk = _extract(salt, inputKeyMaterial);

  Uint8List expand(Uint8List info, {int length = 32}) =>
      _expand(_prk, info, length);
}

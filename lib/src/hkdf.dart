import 'dart:convert';
import 'dart:typed_data';

import 'package:bird_cryptography/bird_cryptography.dart';
import 'package:crypto/crypto.dart';

void main() {
  print(Hkdf('salt', 'key').expand(utf8.encode('info')));
}

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

/*
hash_len = hash().digest_size
	length = int(length)
	if length > 255 * hash_len:
		raise Exception("Cannot expand to more than 255 * %d = %d bytes using the specified hash function" %\
			(hash_len, 255 * hash_len))
	blocks_needed = length // hash_len + (0 if length % hash_len == 0 else 1) # ceil
	okm = b""
	output_block = b""
	for counter in range(blocks_needed):
		output_block = hmac.new(pseudo_random_key, buffer(output_block + info + bytearray((counter + 1,))),\
			hash).digest()
		okm += output_block
	return okm[:length]
 */

class Hkdf {
  Uint8List _prk;

  Hkdf(String salt, String inputKeyMaterial)
      : _prk = _extract(utf8.encode(salt), utf8.encode(inputKeyMaterial));

  Uint8List expand(List<int> info, {int length = 32}) =>
      _expand(_prk, info, length);
}

import 'dart:convert';
import 'dart:typed_data';

import 'binary_reader.dart';
import 'binary_writer.dart';
import 'type_adapter.dart';

export 'binary_reader.dart';
export 'binary_writer.dart';

part 'adapters/core.dart';
part 'adapters/custom.dart';
part 'adapters/typed_data.dart';

final builtInAdapters = <int, TypeAdapter<dynamic>>{
  // dart:typed_data adapters.
  -1: AdapterForByteBuffer(),
  -2: AdapterForByteData(),
  -3: AdapterForUint8List(),

  // dart:core adapters.
  -18: AdapterForNull(),
  -4: AdapterForBool(),
  -5: AdapterForDouble(),
  -6: AdapterForInt(),
  -7: AdapterForString(),
  -8: AdapterForBigInt(),
  -9: AdapterForDateTime(),
  -10: AdapterForDuration(),
  -11: AdapterForList(),
  -12: AdapterForSet(),
  -13: AdapterForMapEntry(),
  -14: AdapterForMap(),
  -15: AdapterForRegExp(),
  -16: AdapterForRunes(),
  -17: AdapterForStackTrace(),
};

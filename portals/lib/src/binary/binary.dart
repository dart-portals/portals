import 'dart:typed_data';

import 'adapters.dart';
import 'type_registry.dart';

export 'adapters.dart';
export 'type_adapter.dart';

class BytesWriter extends BinaryWriter {
  BytesWriter(TypeRegistry registry) : super(registry);

  List<int> data = <int>[];

  @override
  void writeBytes(List<int> bytes) {
    data.addAll(bytes);
  }
}

class BytesReader extends BinaryReader {
  BytesReader(this.data, TypeRegistry registry) : super(registry);

  List<int> data;

  @override
  int get availableBytes => double.infinity.toInt();

  @override
  Uint8List peekBytes(int bytes) => Uint8List.fromList(data.sublist(0, bytes));

  @override
  Uint8List readBytes(int bytes) {
    final d = data.sublist(0, bytes);
    data.removeRange(0, bytes);
    return Uint8List.fromList(d);
  }

  @override
  void skip(int bytes) => data.removeRange(0, bytes);

  @override
  int get usedBytes => data.length;
}

Uint8List serialize(dynamic object) {
  final writer = BytesWriter(defaultTypeRegistry)..write(object);
  return Uint8List.fromList(writer.data);
}

dynamic deserialize(Uint8List data) {
  return BytesReader(data, defaultTypeRegistry).read();
}

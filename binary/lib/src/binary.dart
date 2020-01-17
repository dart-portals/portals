import 'dart:typed_data';

import 'source.dart';
import 'type_registry.dart';

class BytesWriter extends BinaryWriter {
  BytesWriter(TypeRegistry registry) : super(registry);

  int offset = 0;

  // TODO: dynamically allocate more storage when needed
  final _data = ByteData(4096);
  Uint8List get data => Uint8List.view(_data.buffer, 0, offset);

  int _advance(int bytes) {
    final offsetBefore = offset;
    offset += bytes;
    return offsetBefore;
  }

  @override
  void writeUint8(int value) => _data.setUint8(_advance(1), value);

  @override
  void writeInt8(int value) => _data.setInt8(_advance(1), value);

  @override
  void writeUint16(int value) => _data.setUint16(_advance(2), value);

  @override
  void writeInt16(int value) => _data.setInt16(_advance(2), value);

  @override
  void writeUint32(int value) => _data.setUint32(_advance(4), value);

  @override
  void writeInt32(int value) => _data.setInt32(_advance(4), value);

  @override
  void writeUint64(int value) => _data.setUint64(_advance(8), value);

  @override
  void writeInt64(int value) => _data.setInt64(_advance(8), value);

  @override
  void writeFloat32(double value) => _data.setFloat32(_advance(4), value);

  @override
  void writeFloat64(double value) => _data.setFloat64(_advance(8), value);
}

class BytesReader extends BinaryReader {
  BytesReader(List<int> data, TypeRegistry registry) : super(registry) {
    _data = ByteData.view(Uint8List.fromList(data).buffer);
  }

  int offset = 0;

  ByteData _data = ByteData(4096);

  @override
  int get availableBytes => _data.lengthInBytes - offset;

  @override
  int get usedBytes => _data.lengthInBytes;

  @override
  void skip(int bytes) => _advance(bytes);

  int _advance(int bytes) {
    final offsetBefore = offset;
    offset += bytes;
    return offsetBefore;
  }

  @override
  int readUint8() => _data.getUint8(_advance(1));

  @override
  int readInt8() => _data.getInt8(_advance(1));

  @override
  int readUint16() => _data.getUint16(_advance(2));

  @override
  int readInt16() => _data.getInt16(_advance(2));

  @override
  int readUint32() => _data.getUint32(_advance(4));

  @override
  int readInt32() => _data.getInt32(_advance(4));

  @override
  int readUint64() => _data.getUint64(_advance(8));

  @override
  int readInt64() => _data.getInt64(_advance(8));

  @override
  double readFloat32() => _data.getFloat32(_advance(4));

  @override
  double readFloat64() => _data.getFloat64(_advance(8));
}

Uint8List serialize(dynamic object) {
  final writer = BytesWriter(defaultTypeRegistry)..write(object);
  return writer.data;
}

dynamic deserialize(Uint8List data) {
  return BytesReader(data, defaultTypeRegistry).read();
}

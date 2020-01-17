part of 'adapters.dart';

// Adapters for types of the dart:typed_data library.

extension TypedDataWriter on BinaryWriter {
  void writeByteList(List<int> list) {
    writeUint32(list.length);
    list.forEach(writeUint8);
  }
}

extension TypedDataReader on BinaryReader {
  List<int> readByteList() {
    final length = readUint32();
    return <int>[for (var i = 0; i < length; i++) readUint8()];
  }
}

class AdapterForUint8List extends TypeAdapter<Uint8List> {
  @override
  Uint8List read(BinaryReader reader) =>
      Uint8List.fromList(reader.readByteList());

  @override
  void write(BinaryWriter writer, Uint8List obj) => writer.writeByteList(obj);
}

part of '../adapters.dart';

// Adapters for types of the dart:typed_data library.

extension TypedDataWriter on BinaryWriter {
  void writeByteBuffer(ByteBuffer buffer, {bool writeLength = false}) {
    if (writeLength) writeUint32(buffer.lengthInBytes);
    writeBytes(buffer.asUint8List());
  }

  void writeByteData(ByteData data, {bool writeLength = false}) =>
      writeByteBuffer(data.buffer, writeLength: writeLength);

  void writeByte(int value) => writeByteData(ByteData(1)..setUint8(0, value));
  void writeWord(int value) => writeByteData(ByteData(2)..setUint16(0, value));
  void writeInt32(int value) => writeByteData(ByteData(4)..setInt32(0, value));
  void writeUint32(int value) =>
      writeByteData(ByteData(4)..setUint32(0, value));

  void writeUint8List(Uint8List value) => this
    ..writeUint32(value.length)
    ..writeBytes(value);
}

extension TypedDataReader on BinaryReader {
  ByteBuffer readByteBuffer([int length]) =>
      readBytes(length ?? readUint32()).buffer;
  ByteData readByteData([int length]) => readByteBuffer(length).asByteData();

  int readByte() => readByteData(1).getUint8(0);
  int readWord() => readByteData(2).getUint16(0);
  int readInt32() => readByteData(4).getInt32(0);
  int readUint32() => readByteData(4).getUint32(0);

  Uint8List readUint8List() => readBytes(readUint32());
}

class AdapterForByteBuffer extends TypeAdapter<ByteBuffer> {
  @override
  ByteBuffer read(BinaryReader reader) => reader.readByteBuffer();

  @override
  void write(BinaryWriter writer, ByteBuffer obj) =>
      writer.writeByteBuffer(obj);
}

class AdapterForByteData extends TypeAdapter<ByteData> {
  @override
  ByteData read(BinaryReader reader) => reader.readByteData();

  @override
  void write(BinaryWriter writer, ByteData obj) => writer.writeByteData(obj);
}

class AdapterForUint8List extends TypeAdapter<Uint8List> {
  @override
  Uint8List read(BinaryReader reader) => reader.readUint8List();

  @override
  void write(BinaryWriter writer, Uint8List obj) => writer.writeUint8List(obj);
}

/*
extension LowLevelByteCollectionsWriter on BinaryWriter {
  void writeByteBuffer(ByteBuffer buf) => writeUint8List(buf.asUint8List());
  void writeByteData(ByteData bytes) => writeBytes(bytes.buffer.asUint8List());
  void writeEndian(Endian endian) => writeBool(endian == Endian.big);
  void writeFloat32List(Float32List list) => writeByteBuffer(list.buffer);
  void writeFloat32x4(Float32x4 val) => this
    ..writeDouble(val.x)
    ..writeDouble(val.y)
    ..writeDouble(val.z)
    ..writeDouble(val.w);
  void writeFloat32x4List(Float32x4List list) => writeByteBuffer(list.buffer);
  void writeFloat64List(Float64List list) => writeByteBuffer(list.buffer);
  void writeFloat64x2(Float64x2 val) =>
      this..writeDouble(val.x)..writeDouble(val.y);
  void writeFloat64x2List(Float64x2List list) => writeByteBuffer(list.buffer);
  void writeInt8List(Int8List list) => writeByteBuffer(list.buffer);
  void writeInt16List(Int16List list) => writeByteBuffer(list.buffer);
  void writeInt32List(Int32List list) => writeByteBuffer(list.buffer);
  void writeInt32x4(Int32x4 val) =>
      this..writeInt(val.x)..writeInt(val.y)..writeInt(val.z)..writeInt(val.w);
  void writeInt32x4List(Int32x4List list) => writeByteBuffer(list.buffer);
  void writeInt64List(Int64List list) => writeByteBuffer(list.buffer);
  void writeTypedData(TypedData data) => writeByteBuffer(data.buffer);
  void writeUint8ClampedList(Uint8ClampedList list) =>
      writeByteBuffer(list.buffer);
  void writeUint8List(Uint8List list) => writeByteBuffer(list.buffer);
  void writeUint16List(Uint16List list) => writeByteBuffer(list.buffer);
  void writeUint32List(Uint32List list) => writeByteBuffer(list.buffer);
  void writeUint64List(Uint64List list) => writeByteBuffer(list.buffer);
  void writeUnmodifiableByteBufferView(UnmodifiableByteBufferView buffer) =>
      writeByteBuffer(buffer);
  void writeUnmodifiableByteDataView(UnmodifiableByteDataView data) =>
      writeByteData(data);
  // ...
}
*/

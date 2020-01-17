import 'dart:typed_data';

import 'adapters/adapters.dart';
import 'type_registry.dart';

/// The [BinaryWriter] is used to encode data to the binary format.
abstract class BinaryWriter {
  const BinaryWriter(this.registry);

  final TypeRegistry registry;

  // Methods to override.
  void writeUint8(int value);
  void writeInt8(int value);
  void writeUint16(int value);
  void writeInt16(int value);
  void writeUint32(int value);
  void writeInt32(int value);
  void writeUint64(int value);
  void writeInt64(int value);
  void writeFloat32(double value);
  void writeFloat64(double value);

  /// Finds a fitting adapter for the given [value] and then writes it.
  /// If an adapter is provided, the search for an adapter starts there.
  void write<T>(T value) {
    final adapter = registry.findAdapterByValue<T>(value);
    if (adapter == null) {
      throw Exception(
          'No adapter found for value $value of type ${value.runtimeType}.');
    }
    writeTypeId(registry.findIdOfAdapter(adapter));
    adapter.write(this, value);
  }
}

/// The [BinaryReader] is used to bring data back from the binary format.
abstract class BinaryReader {
  const BinaryReader(this.registry);

  final TypeRegistry registry;

  /// The number of bytes left in this entry.
  int get availableBytes;

  /// The number of read bytes.
  int get usedBytes;

  /// Skip n bytes.
  void skip(int bytes);

  /// Get a [Uint8List] view which contains the next [bytes] bytes.
  int readUint8();
  int readInt8();
  int readUint16();
  int readInt16();
  int readUint32();
  int readInt32();
  int readUint64();
  int readInt64();
  double readFloat32();
  double readFloat64();

  /// Reads a type id and chooses the correct adapter for that. Read using the given adapter.
  T read<T>() {
    final typeId = readTypeId();
    final adapter = registry.findAdapterById(typeId);
    return adapter.read(this);
  }
}

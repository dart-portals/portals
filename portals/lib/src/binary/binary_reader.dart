import 'dart:typed_data';

import 'adapters.dart';
import 'type_registry.dart';

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
  Uint8List readBytes(int bytes);

  /// Get a [Uint8List] view which contains the next [bytes] bytes. This does
  /// not advance the internal read position.
  Uint8List peekBytes(int bytes);

  /// Reads a type id and chooses the correct adapter for that. Read using the given adapter.
  T read<T>() {
    final typeId = readTypeId();
    final adapter = registry.findAdapterById(typeId);
    return adapter.read(this);
  }
}

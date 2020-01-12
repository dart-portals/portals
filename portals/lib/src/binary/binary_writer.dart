import 'adapters.dart';
import 'type_registry.dart';

/// The [BinaryWriter] is used to encode data to the binary format.
abstract class BinaryWriter {
  const BinaryWriter(this.registry);

  final TypeRegistry registry;

  /// Write a single byte.
  void writeBytes(List<int> bytes);

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

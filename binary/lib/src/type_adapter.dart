import 'package:meta/meta.dart';

import 'source.dart';
import 'type_registry.dart';

typedef Writer<T> = void Function(BinaryWriter writer, T obj);
typedef Reader<T> = T Function(BinaryReader reader);
typedef SubTypeAdapterBuilder<T> = TypeAdapter<T> Function();

/// Type adapters can be implemented to support non primitive values.
@immutable
abstract class TypeAdapter<T> {
  const TypeAdapter();

  Type get type => T;
  bool matches(dynamic value) => value is T;

  void write(BinaryWriter writer, T obj);
  T read(BinaryReader reader);

  void registerWithId(int typeId, {TypeRegistry registry}) {
    (registry ?? defaultTypeRegistry).registerAdapter<T>(typeId, this);
  }
}

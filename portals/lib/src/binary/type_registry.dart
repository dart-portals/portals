import 'dart:math';

import 'package:portals/src/binary/type_adapter.dart';
import 'package:portals/src/binary/type_node.dart';

import 'adapters.dart';

void debugPrint(Object object) => print(object);

class TypeRegistry {
  final _idsByAdapters = <TypeAdapter<dynamic>, int>{};
  final _adaptersById = <int, TypeAdapter<dynamic>>{};
  final _adaptersByExactType = <Type, TypeAdapter<dynamic>>{};
  final _typeTree = TypeNode<Object>.virtual();

  /// Register a [TypeAdapter] to announce it.
  void registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
    if (_idsByAdapters[adapter] == typeId) {
      debugPrint('You tried to register adapter $adapter, but its already '
          'registered under that id ($typeId).');
      return;
    }

    final adapterForType = _adaptersByExactType[adapter.type];
    if (adapterForType != null && adapterForType != adapter) {
      debugPrint('You tried to register adapter $adapter for type '
          '${adapter.type}, but for that type there is already adapter '
          '$adapterForType registered.');
    }

    final adapterForId = _adaptersById[typeId];
    if (adapterForId != null && adapterForId != adapter) {
      debugPrint('You tried to register $adapter under id $typeId, but there '
          'is already a different adapter registered under that id: '
          '$adapterForId');
    }

    _idsByAdapters[adapter] = typeId;
    _adaptersById[typeId] = adapter;
    _adaptersByExactType[adapter.type] = adapter;
    _typeTree.insert(TypeNode<T>(adapter));
  }

  void registerAdapters(Map<int, TypeAdapter<dynamic>> adapters) {
    adapters.forEach(
        (typeId, adapter) => adapter.registerWithId(typeId, registry: this));
  }

  TypeAdapter findAdapterByValue<T>(T value) {
    final adapterForExactType = _adaptersByExactType[value.runtimeType];
    if (adapterForExactType != null) {
      return adapterForExactType;
    }

    final bestMatchingAdapter = _typeTree.findAdapterByValue(value);

    debugPrint('No adapter for the exact type ${value.runtimeType} found, so '
        'we\'re encoding it as a ${bestMatchingAdapter.type}. '
        'For better performance and truly type-safe serializing, consider '
        'adding an adapter for that type by calling '
        'AdapterFor${value.runtimeType}().registerWithId'
        '(${_adaptersById.keys.reduce(max) + 1}).');

    return bestMatchingAdapter;
  }

  int findIdOfAdapter(TypeAdapter<dynamic> adapter) => _idsByAdapters[adapter];

  TypeAdapter findAdapterById(int typeId) => _adaptersById[typeId];
}

final defaultTypeRegistry = TypeRegistry()..registerAdapters(builtInAdapters);

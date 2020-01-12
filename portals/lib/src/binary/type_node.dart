import 'type_adapter.dart';

class TypeNode<T> {
  TypeNode(this.adapter);
  TypeNode.virtual() : this(null);

  final TypeAdapter<T> adapter;
  final _subtypes = <TypeNode<T>>{};

  bool matches(dynamic value) => value is T;
  bool isSupertypeOf(TypeNode<dynamic> type) => type is TypeNode<T>;

  void addSubtype(TypeNode<T> type) => _subtypes.add(type);
  void addSubtypes(Iterable<TypeNode<dynamic>> types) =>
      _subtypes.addAll(types.cast<TypeNode<T>>());

  void insert(TypeNode<T> newType) {
    final typesOverNewType =
        _subtypes.where((type) => type.isSupertypeOf(newType));

    if (typesOverNewType.isNotEmpty) {
      for (final subtype in typesOverNewType) {
        subtype.insert(newType);
      }
    } else {
      final typesUnderNewType =
          _subtypes.where((type) => newType.isSupertypeOf(type)).toList();
      _subtypes.removeAll(typesUnderNewType);
      newType.addSubtypes(typesUnderNewType);
      _subtypes.add(newType);
    }
  }

  TypeAdapter<T> findAdapterByValue(T value) {
    final matchingSubtype =
        _subtypes.firstWhere((type) => type.matches(value), orElse: () => null);
    return matchingSubtype?.findAdapterByValue(value) ?? adapter;
  }
}

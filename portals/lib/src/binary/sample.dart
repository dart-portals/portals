import 'package:meta/meta.dart';

import 'binary.dart';

class MyClass<T> {
  MyClass({@required this.id, @required this.someNumbers});

  final String id;
  final List<T> someNumbers;

  String toString() => 'MyClass($id, $someNumbers)';
}

class AdapterForMyClass<T> extends TypeAdapter<MyClass<T>> {
  const AdapterForMyClass();

  @override
  void write(BinaryWriter writer, MyClass<T> obj) {
    writer
      ..writeNumberOfFields(2)
      ..writeFieldId(0)
      ..write(obj.id)
      ..writeFieldId(1)
      ..write(obj.someNumbers);
  }

  @override
  MyClass<T> read(BinaryReader reader) {
    final numberOfFields = reader.readNumberOfFields();
    final fields = <int, dynamic>{
      for (var i = 0; i < numberOfFields; i++)
        reader.readFieldId(): reader.read(),
    };

    return MyClass<T>(
      id: fields[0],
      someNumbers: fields[1],
    );
  }
}

void main() {
  AdapterForMyClass().registerWithId(0);
  AdapterForMyClass<int>().registerWithId(1);
  AdapterForList<int>().registerWithId(2);

  final data = serialize(MyClass(id: 'some-id', someNumbers: [1, 2, 3]));
  print('Serialized to $data');
  print(deserialize(data));
}

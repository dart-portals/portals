import 'dart:isolate';

import 'package:meta/meta.dart';

import 'portals.dart';
import 'src/utils.dart';

const appId = 'example.com';

void main() {
  portal();
}

void portal() async {
  final portal = Portal(appId: appId);
  final phrase = await portal.open();

  print(phrase);
  // await Isolate.spawn(otherMain, phrase);

  final key = await portal.waitForLink();
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  print(await portal.receive());
  print(await portal.receive());
}

void otherMain(String phrase) async {
  final portal = Portal(appId: appId);
  print('Connecting to portal $phrase');

  final key = await portal.openAndLinkTo(phrase);
  print('Portal linked using key ${key.toHex()}.');

  await portal.waitUntilReady();
  await portal.send('Hi there.');
  await Future.delayed(Duration(seconds: 1));
  await portal.send(MyClass(
    id: 'hello',
    someNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
  ));
}

class MyClass<T> {
  MyClass({@required this.id, @required this.someNumbers});

  final String id;
  final List<T> someNumbers;
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

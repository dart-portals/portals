part of 'adapters.dart';

// Adapters for types of the dart:core library.

extension PrimitiveTypesWriter on BinaryWriter {
  void writeBool(bool value) => writeUint8(value ? 1 : 0);
  void writeDouble(double value) => writeFloat64(value);
  void writeInt(int value) => writeDouble(value.toDouble());

  void writeString(String value) =>
      writeByteList(Uint8List.fromList(utf8.encode(value)));
  void writeAsciiString(String value) {
    assert(value.codeUnits.every((codeUnit) => (codeUnit & ~0x7f) != 0),
        'String contains non-ASCII chars.');
    writeByteList(value.codeUnits);
  }

  void writeLength(int length) => writeUint32(length);
}

extension PrimitiveTypesReader on BinaryReader {
  bool readBool() => readUint8() != 0;
  double readDouble() => readFloat64();
  int readInt() => readDouble().toInt();

  String readString() => utf8.decode(readByteList());
  String readAsciiString() => String.fromCharCodes(readByteList());

  int readLength() => readUint32();
}

class AdapterForNull extends TypeAdapter<Null> {
  const AdapterForNull();
  void write(_, __) {}
  Null read(_) => null;
}

class AdapterForBool extends TypeAdapter<bool> {
  const AdapterForBool();
  void write(BinaryWriter writer, bool value) => writer.writeBool(value);
  bool read(BinaryReader reader) => reader.readBool();
}

class AdapterForDouble extends TypeAdapter<double> {
  const AdapterForDouble();
  void write(BinaryWriter writer, double value) => writer.writeDouble(value);
  double read(BinaryReader reader) => reader.readDouble();
}

class AdapterForInt extends TypeAdapter<int> {
  const AdapterForInt();
  void write(BinaryWriter writer, int value) => writer.writeInt(value);
  int read(BinaryReader reader) => reader.readInt();
}

class AdapterForString extends TypeAdapter<String> {
  const AdapterForString();
  void write(BinaryWriter writer, String value) => writer.writeString(value);
  String read(BinaryReader reader) => reader.readString();
}

class AdapterForBigInt extends TypeAdapter<BigInt> {
  const AdapterForBigInt();

  @override
  void write(BinaryWriter writer, BigInt value) =>
      writer.writeString(value.toRadixString(36));

  @override
  BigInt read(BinaryReader reader) =>
      BigInt.parse(reader.readString(), radix: 36);
}

class AdapterForDateTime extends TypeAdapter<DateTime> {
  const AdapterForDateTime();

  @override
  void write(BinaryWriter writer, DateTime value) =>
      writer.writeInt(value.microsecondsSinceEpoch);

  @override
  DateTime read(BinaryReader reader) =>
      DateTime.fromMicrosecondsSinceEpoch(reader.readInt());
}

class AdapterForDuration extends TypeAdapter<Duration> {
  const AdapterForDuration();

  @override
  void write(BinaryWriter writer, Duration value) =>
      writer.writeInt(value.inMicroseconds);

  @override
  Duration read(BinaryReader reader) =>
      Duration(microseconds: reader.readInt());
}

class AdapterForList<T> extends TypeAdapter<List<T>> {
  const AdapterForList();

  @override
  void write(BinaryWriter writer, List<T> list) {
    writer.writeLength(list.length);
    list.forEach(writer.write);
  }

  @override
  List<T> read(BinaryReader reader) {
    final length = reader.readLength();
    return <T>[
      for (var i = 0; i < length; i++) reader.read<T>(),
    ];
  }
}

class AdapterForSet<T> extends TypeAdapter<Set<T>> {
  const AdapterForSet();

  @override
  void write(BinaryWriter writer, Set<T> theSet) =>
      const AdapterForList().write(writer, theSet.toList());

  @override
  Set<T> read(BinaryReader reader) => AdapterForList<T>().read(reader).toSet();
}

class AdapterForMapEntry<K, V> extends TypeAdapter<MapEntry<K, V>> {
  const AdapterForMapEntry();

  @override
  void write(BinaryWriter writer, MapEntry<K, V> entry) {
    writer..write(entry.key)..write(entry.value);
  }

  @override
  MapEntry<K, V> read(BinaryReader reader) {
    return MapEntry(reader.read<K>(), reader.read<V>());
  }
}

class AdapterForMap<K, V> extends TypeAdapter<Map<K, V>> {
  const AdapterForMap();

  @override
  void write(BinaryWriter writer, Map<K, V> map) {
    writer.writeLength(map.length);
    map.entries.forEach((entry) => const AdapterForMapEntry().write);
  }

  @override
  Map<K, V> read(BinaryReader reader) {
    final length = reader.readLength();
    return Map<K, V>.fromEntries({
      for (var i = 0; i < length; i++) const AdapterForMapEntry().read(reader),
    });
  }
}

class AdapterForRegExp extends TypeAdapter<RegExp> {
  const AdapterForRegExp();

  @override
  void write(BinaryWriter writer, RegExp regExp) {
    writer
      ..writeString(regExp.pattern)
      ..writeBool(regExp.isCaseSensitive)
      ..writeBool(regExp.isMultiLine)
      ..writeBool(regExp.isUnicode)
      ..writeBool(regExp.isDotAll);
  }

  @override
  RegExp read(BinaryReader reader) {
    return RegExp(
      reader.readString(),
      caseSensitive: reader.readBool(),
      multiLine: reader.readBool(),
      unicode: reader.readBool(),
      dotAll: reader.readBool(),
    );
  }
}

class AdapterForRunes extends TypeAdapter<Runes> {
  @override
  void write(BinaryWriter writer, Runes runes) =>
      writer.writeString(runes.string);

  @override
  Runes read(BinaryReader reader) => reader.readString().runes;
}

class AdapterForStackTrace extends TypeAdapter<StackTrace> {
  @override
  void write(BinaryWriter writer, StackTrace stackTrace) =>
      writer.writeString(stackTrace.toString());

  @override
  StackTrace read(BinaryReader reader) =>
      StackTrace.fromString(reader.readString());
}

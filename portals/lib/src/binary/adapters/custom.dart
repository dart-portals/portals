part of '../adapters.dart';

const reservedTypeIds = 2048;

// Custom types.

extension CustomTypeWriter on BinaryWriter {
  void writeTypeId(int typeId) => writeWord(typeId + reservedTypeIds);
  void writeNumberOfFields(int numberOfFields) => writeWord(numberOfFields);
  void writeFieldId(int fieldId) => writeWord(fieldId);
}

extension CustomTypeReader on BinaryReader {
  int readTypeId() => readWord() - reservedTypeIds;
  int readNumberOfFields() => readWord();
  int readFieldId() => readWord();
}

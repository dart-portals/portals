part of 'adapters.dart';

const reservedTypeIds = 2048;

// Custom types.

extension CustomTypeWriter on BinaryWriter {
  void writeTypeId(int typeId) => writeUint16(typeId + reservedTypeIds);
  void writeNumberOfFields(int numberOfFields) => writeUint16(numberOfFields);
  void writeFieldId(int fieldId) => writeUint16(fieldId);
}

extension CustomTypeReader on BinaryReader {
  int readTypeId() => readUint16() - reservedTypeIds;
  int readNumberOfFields() => readUint16();
  int readFieldId() => readUint16();
}

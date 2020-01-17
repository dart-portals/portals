import 'package:meta/meta.dart';

class BinaryType {
  const BinaryType({@required this.legacyFields});

  final Set<int> legacyFields;
}

class BinaryField {
  const BinaryField(this.id, {@required this.defaultValue});

  final int id;
  final dynamic defaultValue;
}

import 'package:web_socket_channel/status.dart';

class CloseReason {
  static const _codeOffset = 1040;

  final int rawWebsocketCode;
  bool get hasCustomCode => rawWebsocketCode >= _codeOffset;
  int get code => hasCustomCode ? rawWebsocketCode - _codeOffset : null;

  final String reason;

  CloseReason._(this.rawWebsocketCode, this.reason);

  CloseReason.normal([String reason])
      : this._(normalClosure, reason ?? 'Goodbye!');

  CloseReason.invalidData()
      : this.error(invalidFramePayloadData, 'Invalid data');

  CloseReason.error(int code, String reason)
      : this._(code + _codeOffset, reason);
}

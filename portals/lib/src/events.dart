import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class PortalEvent {}

class PortalServerReached extends PortalEvent {}

class PortalOpened extends PortalEvent {
  PortalOpened({@required this.code});

  final String code;
}

class PortalClosed extends PortalEvent {}

class PortalLinked extends PortalEvent {
  PortalLinked({@required this.sharedKeyHash});

  final Uint8List sharedKeyHash;
}

class PortalUnlinked extends PortalEvent {}

class PortalReady extends PortalEvent {}

class PortalDataReceived extends PortalEvent {}

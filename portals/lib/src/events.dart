import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class PortalEvent {}

class PortalOpening extends PortalEvent {}

class PortalServerReached extends PortalEvent {}

class PortalOpened extends PortalEvent {
  PortalOpened({@required this.phrase});

  final String phrase;
}

class PortalClosed extends PortalEvent {}

class PortalLinked extends PortalEvent {
  PortalLinked({@required this.key});

  final Uint8List key;
}

class PortalUnlinked extends PortalEvent {}

class PortalConnecting extends PortalEvent {}

class PortalConnected extends PortalEvent {}

class PortalDataReceived extends PortalEvent {}

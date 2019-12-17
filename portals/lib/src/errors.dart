import 'package:meta/meta.dart';

class PortalException implements Exception {
  PortalException({
    @required this.summary,
    @required this.description,
    @required this.suggestedFix,
  });

  final String summary;
  final String description;
  final String suggestedFix;

  String get _summary => '$summary\n\n';

  String get _description => '$description\n\n';

  String get _suggestedFix => '$suggestedFix\n';

  String toString() {
    return [
      _summary,
      _description,
      _suggestedFix,
    ].join();
  }
}

class PortalServerException extends PortalException {
  PortalServerException({
    @required String summary,
    @required String description,
    @required String suggestedFix,
  }) : super(
          summary: summary,
          description: description,
          suggestedFix: suggestedFix,
        );
}

class PortalCannotConnectToServerException extends PortalServerException {
  PortalCannotConnectToServerException()
      : super(
          summary: 'The portal cannot connect to the server.',
          description: 'Initially, the portal connects to a server. However, '
              'we cannot connect to it.',
          suggestedFix: 'Host your own server! And make sure you have '
              'internet.',
        );
}

/*
┅┅┅┅┅┅┅┅┅ PORTAL ERROR ┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅
The following error occurred while opening a portal:
The code generator is non-reversible.

The code generator MyFancyCodeGenerator was asked to generate a code for the
following input:
  nameplate: [21]
  key: [12, 21, 32, 34, 90, 0, 21, 21, ..., 21, 21, 43, 54, 11, 98, 8]
It responded with the code "hello-there".
However, when being asked to decode that code back into a nameplate and key,
it responded with the following:
  nameplate: [21]
  key: [12, 21, 32, 34, 91, 0, 21, 21, ..., 21, 21, 43, 54, 11, 98, 8]
Note that the key differs at the byte at position 4.

Make sure that when letting the code generator generate a code for a given
nameplate and key, it produces the same nameplate and key when given the
generated code.
┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅
*/

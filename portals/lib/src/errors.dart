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

class PortalCannotConnectToServerException extends PortalException {
  PortalCannotConnectToServerException(String url)
      : super(
          summary: 'The portal cannot connect to the server.',
          description: 'Initially, the portal connects to a server. Portals '
              'use this server to negotiate an end-to-end encrypted '
              'connection and exchange ip address information in order to be '
              'able to create a peer-to-peer connection.\n'
              'However, this portal can\'t connect to the server.',
          suggestedFix: 'First, make sure you have access to the internet. '
              "The server that\'s used is hosted at $url. "
              'Check if you can reach it manually.\n'
              'For more reliable connections under big loads, consider '
              'running your own server. Portals use the Magic Wormhole '
              'protocol, so running a wormhole server as described at '
              'https://github.com/warner/magic-wormhole-mailbox-server '
              'should be sufficient.',
        );
}

class PortalInternalServerErrorException extends PortalException {
  PortalInternalServerErrorException(dynamic error)
      : super(
          summary: 'The server notified us of a server-side error while we '
              'were connecting.',
          description: error,
          suggestedFix: 'For a more reliable server, consider running your '
              'own server as described at '
              'https://github.com/warner/magic-wormhole-mailbox-server.',
        );
}

class PortalServerCorruptException extends PortalException {
  PortalServerCorruptException(String description)
      : super(
          summary: 'The server seems to be corrupt.',
          description: description,
          suggestedFix: 'For a more reliable server, consider running your '
              'own server as described at '
              'https://github.com/warner/magic-wormhole-mailbox-server.',
        );
}

class OtherPortalCorruptException extends PortalException {
  OtherPortalCorruptException(String description)
      : super(
          summary: 'The other portal seems to be corrupt.',
          description: description,
          suggestedFix: '',
        );
}

class PortalEncryptionFailedException extends PortalException {
  PortalEncryptionFailedException()
      : super(
          summary: 'The encryption for this portal failed.',
          description: 'During linking, portals try to negotiate a shared '
              'encryption key to use for further end-to-end encryption. That '
              'failed. Possibly someone tried to interfere.',
          suggestedFix: 'You could try again, thereby giving both the other '
              'legitimate portal and a possible attacker another chance.',
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

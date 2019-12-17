import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'utils.dart';

const _width = 60;

extension _RepeatedString on String {
  String operator *(int n) => [for (int i = 0; i < 10; i++) this].join();
}

enum Context { duringOpen }

extension _ContextToString on Context {
  String toDescriptiveString() {
    switch (this) {
      case Context.duringOpen:
        return 'while opening a portal';
      default:
        return 'during an unknown operation';
    }
  }
}

class _PortalInterrupt {
  final bool isError;
  final Context context;
  final String summary;
  final String description;
  final String suggestedFix;

  _PortalInterrupt({
    @required this.isError,
    @required this.context,
    @required this.summary,
    @required this.description,
    @required this.suggestedFix,
  });

  String get _type => isError ? 'error' : 'exception';

  String get _context =>
      'The following $_type was thrown ${context.toDescriptiveString()}:\n';

  String get _summary => '$summary\n\n';

  String get _description => '$description\n\n';

  String get _suggestedFix => '$suggestedFix\n';

  String toString() {
    return [
      _context,
      _summary,
      _description,
      _suggestedFix,
    ].join();
  }
}

abstract class PortalError extends Error {
  PortalError({
    Context context,
    String summary,
    String description,
    String suggestedFix,
  }) : _interrupt = _PortalInterrupt(
          isError: true,
          context: context,
          summary: summary,
          description: description,
          suggestedFix: suggestedFix,
        );

  final _PortalInterrupt _interrupt;

  String toString() => _interrupt.toString();
}

class PortalException implements Exception {
  PortalException({
    Context context,
    String summary,
    String description,
    String suggestedFix,
  }) : _interrupt = _PortalInterrupt(
          isError: false,
          context: context,
          summary: summary,
          description: description,
          suggestedFix: suggestedFix,
        );

  final _PortalInterrupt _interrupt;

  String toString() => _interrupt.toString();
}

class NonReversibleCodeGenerator extends PortalError {
  NonReversibleCodeGenerator({
    @required Uint8List actualNameplate,
    @required Uint8List actualKey,
    @required String code,
    @required Uint8List recreatedNameplate,
    @required Uint8List recreatedKey,
  }) : super(
          context: Context.duringOpen,
          summary: 'The code generator is non-reversible.',
          description:
              'The code generator MyFancyCodeGenerator was asked to generate '
              'a code for the following input:\n'
              '  nameplate: $actualNameplate\n'
              '  key: $actualKey\n'
              'It responded with the code "$code".\n'
              'However, when being asked to decode that code back into a '
              'nameplate and key, it responded with the following:\n'
              '  nameplate: $recreatedNameplate\n'
              '  key: $recreatedKey\n'
              'Note that the key differs at the byte at position TODO.',
          suggestedFix:
              'Make sure that when letting the code generator generate a code '
              'for a given nameplate and key, it produces the same nameplate '
              'and key when given the generated code.',
        );
}

void throwSampleError() {
  throw NonReversibleCodeGenerator(
    actualNameplate: [21].toUint8List(),
    actualKey: [12, 21, 32, 34, 90, 0, 21, 21, 43, 54, 11, 98, 8].toUint8List(),
    code: 'hello-world',
    recreatedNameplate: [21].toUint8List(),
    recreatedKey:
        [12, 21, 32, 39, 90, 0, 21, 21, 43, 54, 11, 98, 8].toUint8List(),
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

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

/// Each time [requireValue] is called, repeatedly calls the [producer] until
/// the returned value [isValid]. Uses the [disposer] to dispose of obsolete
/// values.
class LazyValue<T> {
  LazyValue({
    @required this.producer,
    @required this.disposer,
    @required this.isValid,
  })  : assert(producer != null),
        assert(disposer != null),
        assert(isValid != null);

  final Future<T> Function() producer;
  final void Function(T value) disposer;
  final bool Function(T value) isValid;

  bool _isProducing = false;
  T _value;
  bool get _isValueValid => _value != null && isValid(_value);
  final _waitQueue = Queue<Completer<T>>();

  Future<T> requireValue() {
    if (_isValueValid) {
      return Future.value(_value);
    }

    final completer = Completer<T>();
    _waitQueue.add(completer);

    if (!_isProducing) {
      _produceValue();
    }

    return completer.future;
  }

  Future<void> _produceValue() async {
    _isProducing = true;
    while (!_isValueValid) {
      dispose();
      _value = await producer();
    }
    _isProducing = false;

    for (final completer in _waitQueue) {
      completer.complete(_value);
    }
  }

  void dispose() {
    if (_value != null) {
      disposer(_value);
    }
    _value = null;
  }
}

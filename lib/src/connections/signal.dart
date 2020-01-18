import 'dart:async';
import 'dart:collection';

class Signal {
  final _waitQueue = Queue<Completer<void>>();

  Future<void> waitForSignal() {
    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void signal() {
    for (final completer in _waitQueue) {
      completer.complete();
    }
    _waitQueue.clear();
  }
}

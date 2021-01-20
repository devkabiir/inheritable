import 'dart:async';

import 'package:inheritable/inheritable.dart';

bool _equals(Object a, Object b) {
  return a != b;
}

/// Creates a [PredicateAspect] for [T] that skips all changes to [T] until
/// given [duration] is exhausted.
///
/// Notifies at least after [duration] for the latest [T] that doesn't match
/// last notified value of [T] specified by [shouldNotify]
///
/// Specify [leading] if the first change in [T] should be immediately available.
///
/// **CAUTION**, Specifying [leading] inside the `build` method will always
/// rebuild without debouncing for [duration]. When using the leading value,
/// save the aspect in a stateful variable.
///
/// During testing, Exhaust the last timer, this is due to the fact that we support both,
/// stateful debounce aspect and inline aspect, which means debounced aspects can be
/// saved as stateful variables and also used inline in `build` method.
///
/// When used inline, [Timer] instances are reset automatically. When used in a
/// stateful variable, they must be exhausted during testing
///
/// See
///   - [ShouldNotify]
PredicateAspect<T> debounce<T>(
  Duration duration, {
  ShouldNotify<T> shouldNotify = _equals,
  bool leading = false,
}) {
  assert(leading != null);
  assert(shouldNotify != null);
  assert(duration != null);
  bool _exhausted = false;
  T _lastValue;

  Timer timer;
  void stop() {
    _exhausted = true;
    timer = null;
  }

  return ({T prev, T next}) {
    _lastValue ??= leading ? next : prev;

    /// After notifying for leading change, stop notifying for it
    /// This will either cause a rebuild, which re-starts the timer
    /// Or we start it now
    if (leading) {
      return !(leading = false);
    }

    /// Don't notify until exhausted
    if (!_exhausted) {
      // Restart timer
      timer?.cancel();
      timer = Timer(duration, stop);
      return false;
    }

    // Allows restarting timer for next run
    _exhausted = false;

    if (shouldNotify(next, _lastValue)) {
      _lastValue = next;
      return true;
    }

    return false;
  };
}

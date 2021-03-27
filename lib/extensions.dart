import 'package:flutter/widgets.dart';

import 'inheritable.dart';

extension BoolAspectOf<T> on Aspect<bool, T> {
  Aspect<R, T> map<R>({required R onTrue, required R onFalse, Key? key}) {
    return AspectChianingFn(this).map(
      (b) => b ? onTrue : onFalse,
      key,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class NoAspectWidget<T> extends StatefulWidget {
  const NoAspectWidget({Key? key}) : super(key: key);
  @override
  _NoAspectState<T> createState() => _NoAspectState<T>();
}

class _NoAspectState<T> extends State<NoAspectWidget<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final value = NoAspect<T>(key).of(context);
    final text = widgetMetaFactory(key.value, value, _buildCount += 1);

    return Text(text);
  }
}

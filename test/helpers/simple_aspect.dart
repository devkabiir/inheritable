/// Simple widget that uses the provided aspect for it's state.
import 'package:flutter/widgets.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

/// Simple widget that uses the provided aspect
class SimpleAspectWidget<T> extends StatefulWidget {
  final InheritableAspect<T> aspect;
  const SimpleAspectWidget(
    this.aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SimpleAspectWidgetState<T> createState() => _SimpleAspectWidgetState<T>();
}

class _SimpleAspectWidgetState<T> extends State<SimpleAspectWidget<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);

    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

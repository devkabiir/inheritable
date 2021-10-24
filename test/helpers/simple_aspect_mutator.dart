import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class SimpleAspectMutatorWidget<T> extends StatefulWidget {
  final MutableInheritableAspect<T> _aspect;
  const SimpleAspectMutatorWidget(
    this._aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SimpleAspectMutatorWidgetState<T> createState() =>
      _SimpleAspectMutatorWidgetState<T>();
}

class _SimpleAspectMutatorWidgetState<T>
    extends State<SimpleAspectMutatorWidget<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final text = widgetMetaFactory(key.value, '', _buildCount += 1);

    return TextButton(
      key: Key('${widget.key}-button'),
      onPressed: () => widget._aspect.apply(context),
      child: Text(text),
    );
  }
}

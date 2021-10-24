import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class SomeAspectWidget<T> extends StatefulWidget {
  final Set<DependableAspect<T>> _aspects;
  const SomeAspectWidget(
    this._aspects, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SomeAspectWidgetState<T> createState() => _SomeAspectWidgetState<T>();
}

class _SomeAspectWidgetState<T> extends State<SomeAspectWidget<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget._aspects.some().of(context);
    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class SomeChainedAspectWidget<T> extends StatefulWidget {
  final Set<DependableAspect<T>> _aspects;
  const SomeChainedAspectWidget(
    this._aspects, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SomeChainedAspectWidgetState<T> createState() =>
      _SomeChainedAspectWidgetState<T>();
}

class _SomeChainedAspectWidgetState<T>
    extends State<SomeChainedAspectWidget<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget._aspects
        .some()
        .map((it) => it.toString())
        .where(({required prev, required next}) => prev != next)
        .of(context);
    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

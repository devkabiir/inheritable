import 'package:flutter/material.dart';
import 'package:inheritable/composition.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class DebounceAspectWidget<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  final Duration duration;
  final bool leading;
  final PredicateAspect<A> compare;

  static const defaultDelay = Duration(milliseconds: 200);
  static bool _equals({required Object? prev, required Object? next}) {
    return next != prev;
  }

  const DebounceAspectWidget(
    this.aspect, {
    required ValueKey<String> key,
    this.compare = _equals,
    this.leading = false,
    this.duration = defaultDelay,
  }) : super(key: key);

  @override
  _DebounceAspectWidgetState<A, T> createState() =>
      _DebounceAspectWidgetState<A, T>();
}

class _DebounceAspectWidgetState<A, T>
    extends State<DebounceAspectWidget<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;
  late Aspect<A, T> aspect;

  @override
  void initState() {
    super.initState();

    aspect = widget.aspect.where(
      debounce(
        widget.duration,
        leading: widget.leading,
        shouldNotify: widget.compare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aspect = this.aspect.of(context);

    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);

    return Text(text);
  }
}

class InlineDebounceAspectWidget<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  final Duration duration;
  final PredicateAspect<A> compare;

  static const defaultDelay = Duration(milliseconds: 200);
  static bool _equals({required Object? prev, required Object? next}) {
    return next != prev;
  }

  const InlineDebounceAspectWidget(
    this.aspect, {
    required ValueKey<String> key,
    this.compare = _equals,
    this.duration = defaultDelay,
  }) : super(key: key);

  @override
  _InlineDebounceAspectWidgetState<A, T> createState() =>
      _InlineDebounceAspectWidgetState<A, T>();
}

class _InlineDebounceAspectWidgetState<A, T>
    extends State<InlineDebounceAspectWidget<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect
        .where(
          debounce(
            widget.duration,
            leading: false,
            shouldNotify: widget.compare,
          ),
        )
        .of(context);

    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);

    return Text(text);
  }
}

import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class RemovableAspectWidget<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  const RemovableAspectWidget(
    this.aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _RemovableAspectWidgetState<A, T> createState() =>
      _RemovableAspectWidgetState<A, T>();
}

class _RemovableAspectWidgetState<A, T>
    extends State<RemovableAspectWidget<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);
    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextButton(
            key: const Key('remove-aspect-button'),
            onPressed: () => context.aspect.remove(widget.aspect),
            child: const Text('remove-aspect'),
          ),
        ),
        Flexible(child: Text(text)),
      ],
    );
  }
}

class RemovableAspectViaKeyWidget<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  const RemovableAspectViaKeyWidget(
    this.aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _RemovableAspectViaKeyWidgetState<A, T> createState() =>
      _RemovableAspectViaKeyWidgetState<A, T>();
}

class _RemovableAspectViaKeyWidgetState<A, T>
    extends State<RemovableAspectViaKeyWidget<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);
    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextButton(
            key: const Key('remove-aspect-via-key-button'),
            // ignore: deprecated_member_use_from_same_package
            onPressed: () => context.aspect.removeKey<T>(widget.aspect.key!),
            child: const Text('remove-aspect'),
          ),
        ),
        Flexible(child: Text(text)),
      ],
    );
  }
}

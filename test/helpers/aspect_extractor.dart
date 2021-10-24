import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

/// Widget that extracts an aspect from [T] via the provided extract function
class AspectExtractorWidget<A, T> extends StatefulWidget {
  final ExtractAspect<A, T> _extractor;

  /// Given extractor, uses it to listen to changes to value provided by that fn.
  const AspectExtractorWidget(
    this._extractor, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _AspectExtractorWidgetState<A, T> createState() =>
      _AspectExtractorWidgetState<A, T>();
}

class _AspectExtractorWidgetState<A, T>
    extends State<AspectExtractorWidget<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = Aspect(widget._extractor, key).of(context);
    final text = widgetMetaFactory(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

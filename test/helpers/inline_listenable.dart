import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers.dart';

class InlineListenableAspectWidget extends StatefulWidget {
  const InlineListenableAspectWidget({Key? key}) : super(key: key);
  @override
  _InlineListenableAspectWidgetState createState() =>
      _InlineListenableAspectWidgetState();
}

class _InlineListenableAspectWidgetState
    extends State<InlineListenableAspectWidget> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount += 1;

    return ValueListenableBuilder<User?>(
      valueListenable:
          const Aspect<String?, User?>(User.lastName, Key('user-lname'))
              .listenable
              .of(context),
      builder: (context, user, child) {
        return Text(
          widgetMetaFactory(key.value, user?.lname, _buildCount),
        );
      },
    );
  }
}

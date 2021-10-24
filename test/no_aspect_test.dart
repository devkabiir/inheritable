import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';
import 'helpers/no_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('NoAspect', () {
    testWidgets('Notifies dependents unconditionally with NoAspect',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      const noaspect = NoAspectWidget<User>(key: ValueKey('no-aspect'));

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable(
            key: const Key('test-key'),
            value: user,
            child: Column(
              key: const Key('column'),
              children: [
                TextButton(
                  key: const Key('button'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state'),
                ),
                const Flexible(child: noaspect),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'no-aspect', aspect: '$user', buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'no-aspect', aspect: '$user', buildCount: 2),
          findsOneWidget);
    });
  });
}

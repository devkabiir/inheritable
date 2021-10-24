import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';
import 'helpers/removable_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('remove', () {
    testWidgets(
        'Allows removing dependent aspect without causing build for enclosing context',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final removableAspectW = RemovableAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('removable-aspect'),
      );

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
                Flexible(child: removableAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'removable-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('remove-aspect-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);
    });

    testWidgets(
        'Allows removing dependent aspect (via key) without causing build for enclosing context',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final removableAspectViaKeyW = RemovableAspectViaKeyWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('removable-aspect-via-key'),
      );

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
                Flexible(child: removableAspectViaKeyW),
              ],
            ),
          );
        },
      );

      final originalState =
          widgetMetaFinder(key:'removable-aspect-via-key', aspect:'last',buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('remove-aspect-via-key-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);
    });
  });
}

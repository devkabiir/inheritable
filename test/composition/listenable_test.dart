import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import '../helpers/helpers.dart';
import '../helpers/inline_listenable.dart';
import '../helpers/some_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('listenable', () {
    testWidgets(
        'Notifies ValueListeners without causing build for enclosing BuildContext',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      int notifyCount = 0;
      void didNotify() {
        notifyCount += 1;
      }

      final userListener = Aspect((User u) => u.lname, const Key('user-lname'))
          .listenable
        ..addListener(didNotify);

      addTearDown(() async {
        await tester.disposeWidgets();
        userListener
          ..removeListener(didNotify)
          ..dispose();
      });

      final someChainedAspectW = SomeChainedAspectWidget(
        {userListener},
        key: const ValueKey('some-chained-aspect'),
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
                Flexible(child: someChainedAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'some-chained-aspect', aspect: user, buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(userListener.hasListeners, isTrue);
      expect(notifyCount, isZero);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(notifyCount, 1);
      expect(originalState, findsOneWidget);
    });

    testWidgets('Does not fire ValueListeners if not attached to BuildContext',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      int notifyCount = 0;
      void didNotify() {
        notifyCount += 1;
      }

      final userListener = const Aspect(User.lastName, Key('user-lname'))
          .listenable
        ..addListener(didNotify);

      addTearDown(() async {
        await tester.disposeWidgets();
        userListener
          ..removeListener(didNotify)
          ..dispose();
      });

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable<User?>(
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
                Flexible(
                  key: const Key('flexible'),
                  child: Builder(
                    key: const Key('builder'),
                    builder: (context) {
                      return ValueListenableBuilder<User?>(
                        valueListenable: userListener,
                        builder: (context, user, child) =>
                            Text('ValueListenableBuilder: ${user?.lname}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(userListener.hasListeners, isTrue);
      expect(notifyCount, 0);
      expect(find.text('ValueListenableBuilder: null'), findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(notifyCount, 0);
      expect(find.text('ValueListenableBuilder: null'), findsOneWidget);
    });

    testWidgets(
        'Allows inline usage for ValueListenableBuilder without causing build for enclosing BuildContext',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      addTearDown(() async {
        await tester.disposeWidgets();
      });

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable<User?>(
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
                const Flexible(
                  child: InlineListenableAspectWidget(
                    key: Key('inline-listenable-aspect'),
                  ),
                ),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'inline-listenable-aspect', aspect: 'last', buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'inline-listenable-aspect', aspect: 'last2', buildCount: 1),
          findsOneWidget);
    });
  });
}

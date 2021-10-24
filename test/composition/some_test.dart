import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import '../helpers/helpers.dart';
import '../helpers/some_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('some', () {
    testWidgets('Notifies some-aspect dependents', (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someAspectW = SomeAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname')),
        },
        key: const ValueKey('some-aspect'),
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
                Flexible(child: someAspectW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Notifies some-aspect dependents with different aspect type unconditionally',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someAspectW = SomeAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect(
            (User u) => u.lname.hashCode,
            const Key('user-lname-hashCode'),
          ),
        },
        key: const ValueKey('some-aspect'),
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
                Flexible(child: someAspectW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Notifies some-aspect dependents conditionally [where not equals]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someAspectW = SomeAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname'))
              .where(({required next, required prev}) {
            return next != 'last2';
          }),
        },
        key: const ValueKey('some-aspect'),
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
                Flexible(child: someAspectW),
              ],
            ),
          );
        },
      );

      final originalState =
          widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);
    });

    testWidgets('Notifies some-aspect dependents conditionally [where equals]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someAspectW = SomeAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname'))
              .where(({required next, required prev}) => next == 'last2'),
        },
        key: const ValueKey('some-aspect'),
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
                Flexible(child: someAspectW),
              ],
            ),
          );
        },
      );

      final originalState =
          widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsNothing);
      expect(widgetMetaFinder(key: 'some-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });

    testWidgets('Notifies some-chained-aspect dependents', (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someChainedAspectW = SomeChainedAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname')),
        },
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

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'some-chained-aspect', aspect: user, buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'some-chained-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Notifies some-chained-aspect dependents with different aspect type unconditionally',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someChainedAspectW = SomeChainedAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect(
            (User u) => u.lname.hashCode,
            const Key('user-lname-hashCode'),
          ),
        },
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

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'some-chained-aspect', aspect: user, buildCount: 1),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(
              key: 'some-chained-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Notifies some-chained-aspect dependents conditionally [where not equals]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someChainedAspectW = SomeChainedAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname'))
              .where(({required next, required prev}) {
            return next != 'last2';
          }),
        },
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
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);
    });

    testWidgets(
        'Notifies some-chained-aspect dependents conditionally [where equals]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final someChainedAspectW = SomeChainedAspectWidget(
        {
          Aspect((User u) => u.fname, const Key('user-fname')),
          Aspect((User u) => u.lname, const Key('user-lname'))
              .where(({required next, required prev}) => next == 'last2'),
        },
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
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsNothing);
      expect(
          widgetMetaFinder(
              key: 'some-chained-aspect', aspect: user, buildCount: 2),
          findsOneWidget);
    });
  });
}

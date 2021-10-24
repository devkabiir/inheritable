import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import '../helpers/debounce_aspect.dart';
import '../helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('debounce', () {
    testWidgets(
        'Notifies dependents after debounce duration for changes [leading:false]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final debounceAspectW = DebounceAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('debounce-aspect'),
        leading: false,
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
                  key: const Key('button-1'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state-1'),
                ),
                TextButton(
                  key: const Key('button-2'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last3';
                    });
                  },
                  child: const Text('change-state-2'),
                ),
                Flexible(child: debounceAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'debounce-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.pump(DebounceAspectWidget.defaultDelay);
      await tester.tap(find.byKey(const Key('button-2')));
      expect(user.lname, 'last3');
      await tester.pump();
      expect(originalState, findsNothing);
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last3', buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Notifies dependents after debounce duration for changes [leading:true]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final debounceAspectW = DebounceAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('debounce-aspect'),
        leading: true,
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
                  key: const Key('button-1'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state-1'),
                ),
                TextButton(
                  key: const Key('button-2'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last3';
                    });
                  },
                  child: const Text('change-state-2'),
                ),
                TextButton(
                  key: const Key('button-3'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last4';
                    });
                  },
                  child: const Text('change-state-3'),
                ),
                Flexible(child: debounceAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'debounce-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();

      expect(tester.takeException(), isNull);

      /// Since leading:true, the first change is available immediately
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);

      await tester.pump(
        Duration(
            milliseconds:
                DebounceAspectWidget.defaultDelay.inMilliseconds ~/ 2),
      );

      await tester.tap(find.byKey(const Key('button-2')));
      expect(user.lname, 'last3');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last3', buildCount: 3),
          findsNothing);
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);

      await tester.pump(DebounceAspectWidget.defaultDelay);
      await tester.tap(find.byKey(const Key('button-3')));
      expect(user.lname, 'last4');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsNothing);
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last4', buildCount: 3),
          findsOneWidget);
    });

    testWidgets(
        'Does not require exhausting timer for debounce duration for changes [leading:false]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final inlineDebounceAspectW = InlineDebounceAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('inline-debounce-aspect'),
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
                  key: const Key('button-1'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state-1'),
                ),
                TextButton(
                  key: const Key('button-2'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last3';
                    });
                  },
                  child: const Text('change-state-2'),
                ),
                TextButton(
                  key: const Key('button-3'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last4';
                    });
                  },
                  child: const Text('change-state-3'),
                ),
                Flexible(child: inlineDebounceAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'inline-debounce-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();

      expect(tester.takeException(), isNull);

      await tester.pump(
        Duration(
            milliseconds:
                InlineDebounceAspectWidget.defaultDelay.inMilliseconds ~/ 2),
      );

      await tester.tap(find.byKey(const Key('button-2')));
      expect(user.lname, 'last3');
      await tester.pump();
      expect(originalState, findsOneWidget);

      await tester.pump(InlineDebounceAspectWidget.defaultDelay);
      await tester.tap(find.byKey(const Key('button-3')));
      expect(user.lname, 'last4');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'inline-debounce-aspect', aspect: 'last4', buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Does not notify dependents after debounce duration for no-changes [leading:false]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final debounceAspectW = DebounceAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('debounce-aspect'),
        leading: false,
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
                  key: const Key('button-1'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state-1'),
                ),
                TextButton(
                  key: const Key('button-2'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last3';
                    });
                  },
                  child: const Text('change-state-2'),
                ),
                TextButton(
                  key: const Key('button-3'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last4';
                    });
                  },
                  child: const Text('change-state-3'),
                ),
                TextButton(
                  key: const Key('button-4'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last';
                    });
                  },
                  child: const Text('change-state-4'),
                ),
                Flexible(child: debounceAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'debounce-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.pump(
        Duration(
            milliseconds:
                DebounceAspectWidget.defaultDelay.inMilliseconds ~/ 2),
      );

      await tester.tap(find.byKey(const Key('button-2')));
      expect(user.lname, 'last3');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last3', buildCount: 3),
          findsNothing);
      expect(originalState, findsOneWidget);

      /// Skips this change, timer has not exhausted
      await tester.tap(find.byKey(const Key('button-3')));
      expect(user.lname, 'last4');
      await tester.pump();
      expect(originalState, findsOneWidget);

      /// Skips this change, because it's the same
      await tester.pump(DebounceAspectWidget.defaultDelay);
      await tester.tap(find.byKey(const Key('button-4')));
      expect(user.lname, 'last');
      await tester.pump();
      expect(originalState, findsOneWidget);
    });

    testWidgets(
        'Does not notify dependents after debounce duration for no-changes [leading:true]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final debounceAspectW = DebounceAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('debounce-aspect'),
        leading: true,
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
                  key: const Key('button-1'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state-1'),
                ),
                TextButton(
                  key: const Key('button-2'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last3';
                    });
                  },
                  child: const Text('change-state-2'),
                ),
                TextButton(
                  key: const Key('button-3'),
                  onPressed: () {
                    setState(() {
                      user = User()
                        ..fname = 'first'
                        ..lname = 'last4';
                    });
                  },
                  child: const Text('change-state-3'),
                ),
                Flexible(child: debounceAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'debounce-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();

      expect(tester.takeException(), isNull);

      /// Since leading:true, the first change is available immediately
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);

      await tester.pump(
        Duration(
            milliseconds:
                DebounceAspectWidget.defaultDelay.inMilliseconds ~/ 2),
      );

      await tester.tap(find.byKey(const Key('button-2')));
      expect(user.lname, 'last3');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last3', buildCount: 3),
          findsNothing);
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);

      /// Skips this change, timer has not exhausted
      await tester.tap(find.byKey(const Key('button-3')));
      expect(user.lname, 'last4');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);

      /// Skips this change, because it's the same
      await tester.pump(DebounceAspectWidget.defaultDelay);
      await tester.tap(find.byKey(const Key('button-1')));
      expect(user.lname, 'last2');
      await tester.pump();
      expect(
          widgetMetaFinder(
              key: 'debounce-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);
    });
  });
}

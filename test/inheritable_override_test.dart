import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';
import 'helpers/simple_aspect.dart';
import 'helpers/simple_aspect_mutator.dart';

Future<void> main([List<String>? args]) async {
  group('Inheritable.override', () {
    testWidgets('Provides overridden value to aspect by aspect equality',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspect =
          Aspect((User u) => u.lname, const Key('user-lname'));

      final overriddenAspectW = SimpleAspectWidget(
        overriddenAspect,
        key: const ValueKey('overridden-aspect'),
      );

      final nonOverriddenAspectW = SimpleAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname2')),
        key: const ValueKey('non-overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              AspectOverride(overriddenAspect, 'overridden-last-name')
            },
            strict: false,
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
                Flexible(child: overriddenAspectW),
                Flexible(child: nonOverriddenAspectW),
              ],
            ),
          );
        },
      );

      final nonOverriddenOriginalState = widgetMetaFinder(
          key: 'non-overridden-aspect', aspect: 'last', buildCount: 1);
      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-aspect',
          aspect: 'overridden-last-name',
          buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsOneWidget);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsNothing);
      expect(
          widgetMetaFinder(
              key: 'non-overridden-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);
      expect(overriddenOriginalState, findsOneWidget);
    });

    testWidgets('Provides overridden value to aspect by aspect key',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspectW = SimpleAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('overridden-aspect'),
      );

      final nonOverriddenAspectW = SimpleAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname2')),
        key: const ValueKey('non-overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              const AspectOverride<String, User>.key(
                Key('user-lname'),
                'overridden-last-name',
              )
            },
            strict: false,
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
                Flexible(child: overriddenAspectW),
                Flexible(child: nonOverriddenAspectW),
              ],
            ),
          );
        },
      );

      final nonOverriddenOriginalState = widgetMetaFinder(
          key: 'non-overridden-aspect', aspect: 'last', buildCount: 1);
      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-aspect',
          aspect: 'overridden-last-name',
          buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsOneWidget);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsNothing);
      expect(
          widgetMetaFinder(
              key: 'non-overridden-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);
      expect(overriddenOriginalState, findsOneWidget);
    });

    testWidgets(
        'Does not override value for aspect by aspect key [mutation = true]',
        (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspectW = SimpleAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname')),
        key: const ValueKey('overridden-aspect'),
      );

      final nonOverriddenAspectW = SimpleAspectWidget(
        Aspect((User u) => u.lname, const Key('user-lname2')),
        key: const ValueKey('non-overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              const AspectOverride<String, User>.key(
                Key('user-lname'),
                'overridden-last-name',
                mutation: true,
              )
            },
            strict: false,
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
                Flexible(child: overriddenAspectW),
                Flexible(child: nonOverriddenAspectW),
              ],
            ),
          );
        },
      );

      final nonOverriddenOriginalState = widgetMetaFinder(
          key: 'non-overridden-aspect', aspect: 'last', buildCount: 1);
      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-aspect', aspect: 'last', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsOneWidget);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(nonOverriddenOriginalState, findsNothing);
      expect(
          widgetMetaFinder(
              key: 'non-overridden-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'overridden-aspect', aspect: 'last2', buildCount: 2),
          findsOneWidget);
    });

    testWidgets(
        'Provides overridden [onMutate] to [mutation] aspect by aspect equality without Inheritable.mutable in scope',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspect = AspectMutation(
        (w) => User()
          ..fname = 'new-fname'
          ..lname = 'new-lname',
      );

      final overriddenAspectW = SimpleAspectMutatorWidget(
        overriddenAspect,
        key: const ValueKey('overridden-mutable-aspect'),
      );

      final overriddenOnMutate = <String>[];

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              AspectOverride.mutation(
                overriddenAspect,
                (u) => setState(() => overriddenOnMutate
                    .add('call ${overriddenOnMutate.length + 1}')),
              )
            },
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );

      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-mutable-aspect', aspect: '', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(overriddenOnMutate, []);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(Key('${overriddenAspectW.key}-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(overriddenOriginalState, findsOneWidget);
      expect(overriddenOnMutate, ['call 1']);
    });

    testWidgets(
        'Provides overridden value to [mutation] aspect by key without Inheritable.mutable in scope',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspect = AspectMutation(
        (w) => User()
          ..fname = 'new-fname'
          ..lname = 'new-lname',
        const Key('overridden-aspect'),
      );

      final overriddenAspectW = SimpleAspectMutatorWidget(
        overriddenAspect,
        key: const ValueKey('overridden-mutable-aspect'),
      );

      final overriddenOnMutate = <String>[];

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              AspectOverride<ValueChanged<User>, User>.key(
                overriddenAspect.key!,
                (u) => setState(() => overriddenOnMutate
                    .add('call ${overriddenOnMutate.length + 1}')),
                mutation: true,
              )
            },
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );

      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-mutable-aspect', aspect: '', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(overriddenOnMutate, []);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(Key('${overriddenAspectW.key}-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(overriddenOriginalState, findsOneWidget);
      expect(overriddenOnMutate, ['call 1']);
    });

    testWidgets(
        'Does not override [onMutate] for [mutation] aspect by aspect key [mutation = false] without Inheritable.mutable in scope',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspect = AspectMutation(
        (w) => User()
          ..fname = 'new-fname'
          ..lname = 'new-lname',
        const Key('overridden-aspect'),
      );

      final overriddenAspectW = SimpleAspectMutatorWidget(
        overriddenAspect,
        key: const ValueKey('overridden-mutable-aspect'),
      );

      final overriddenOnMutate = <String>[];

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              AspectOverride<ValueChanged<User>, User>.key(
                overriddenAspect.key!,
                (u) => setState(() => overriddenOnMutate
                    .add('call ${overriddenOnMutate.length + 1}')),
                mutation: false,
              )
            },
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );

      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-mutable-aspect', aspect: '', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(overriddenOnMutate, []);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(Key('${overriddenAspectW.key}-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(overriddenOriginalState, findsOneWidget);
      expect(overriddenOnMutate, []);
    });

    testWidgets(
        'Throws when provided value for aspect is not of expected type (aspect equality by key)',
        (tester) async {
      final overriddenAspectW = SimpleAspectWidget(
        Aspect((User? u) => u?.lname, const Key('user-lname')),
        key: const ValueKey('overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            key: const Key('test-key'),
            value: null,
            overrides: {
              const AspectOverride<int, User?>.key(
                Key('user-lname'),
                123,
              )
            },
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isStateError);
    });

    testWidgets(
        'Throws when provided value for aspect is not of expected type (aspect equality)',
        (tester) async {
      final overriddenAspect =
          Aspect((User? u) => u?.lname, const Key('user-lname'));
      final overriddenAspectW = SimpleAspectWidget(
        overriddenAspect,
        key: const ValueKey('overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            key: const Key('test-key'),
            value: null,
            overrides: {AspectOverride<int, User?>(overriddenAspect, 123)},
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isStateError);
    });

    testWidgets(
        'Throws when provided value for [mutation] aspect is not of expected type (aspect equality by key)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final overriddenAspect = AspectMutation(
        (w) => User()
          ..fname = 'new-fname'
          ..lname = 'new-lname',
        const Key('overridden-aspect'),
      );

      final overriddenAspectW = SimpleAspectMutatorWidget(
        overriddenAspect,
        key: const ValueKey('overridden-mutable-aspect'),
      );

      final overriddenOnMutate = <String>[];

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override(
            key: const Key('test-key'),
            value: user,
            overrides: {
              AspectOverride<ValueChanged<String>, User>.key(
                overriddenAspect.key!,
                (u) => setState(() => overriddenOnMutate
                    .add('call ${overriddenOnMutate.length + 1}')),
                mutation: true,
              )
            },
            strict: false,
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: overriddenAspectW),
              ],
            ),
          );
        },
      );
      final overriddenOriginalState = widgetMetaFinder(
          key: 'overridden-mutable-aspect', aspect: '', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(overriddenOnMutate, []);
      expect(overriddenOriginalState, findsOneWidget);

      await tester.tap(find.byKey(Key('${overriddenAspectW.key}-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isStateError);
      expect(overriddenOriginalState, findsOneWidget);
      expect(overriddenOnMutate, []);
    });

    testWidgets('Override aspect with [>] operator', (tester) async {
      const aspect = Aspect(User.firstName);

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            strict: false,
            value: null,
            overrides: {
              aspect > 'overridden-value',
            },
            child: Builder(
              builder: (context) => Text(aspect.of(context)!),
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('overridden-value'), findsOneWidget);
    });

    testWidgets('Override aspect with [>] operator overrides [map] construct',
        (tester) async {
      const aspect = Aspect(User.firstName);

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            strict: false,
            value: null,
            overrides: {
              aspect > 'overridden-value',
            },
            child: Builder(
              builder: (context) => Text(aspect
                  .map<String?>((s) => s.hashCode.toString())
                  .of(context)!),
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('overridden-value'.hashCode.toString()), findsNothing);
      expect(find.text('overridden-value'), findsOneWidget);
    });

    testWidgets(
        'Override aspect with [>] operator overrides aspect default value',
        (tester) async {
      final aspect = const Aspect(User.firstName).withDefault('first-name');

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            strict: false,
            value: null,
            overrides: {
              aspect > 'overridden-value',
            },
            child: Builder(
              builder: (context) => Text(aspect.of(context)!),
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('overridden-value'), findsOneWidget);
    });

    testWidgets(
        'Override aspect with [>] operator overrides [map] construct & aspect default value',
        (tester) async {
      final aspect = const Aspect(User.firstName).withDefault('first-name');

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.override<User?, User?>(
            strict: false,
            value: null,
            overrides: {
              aspect > 'overridden-value',
            },
            child: Builder(
              builder: (context) => Text(aspect.map<String?>((s) {
                return s.hashCode.toString();
              }).of(context)!),
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('overridden-value'.hashCode.toString()), findsNothing);
      expect(find.text('first-name'.hashCode.toString()), findsNothing);
      expect(find.text('first-name'), findsNothing);
      expect(find.text('overridden-value'), findsOneWidget);
    });
  });
}

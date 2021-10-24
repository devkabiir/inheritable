import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/aspect_extractor.dart';
import 'helpers/helpers.dart';
import 'helpers/simple_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('Inheritable.supply', () {
    testWidgets(
        '[strict:true] Notifies dependents for multiple Inheritables (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = AspectExtractorWidget(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = AspectExtractorWidget(
        (int fullName) => fullName,
        key: const ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(value: user),
              Inheritable<String>(value: user.lname),
              Inheritable<int>(value: User.fullName(user).hashCode),
            ],
            child: Column(
              key: const Key('column'),
              children: [
                const Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last'.hashCode, buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-types) with duplicate type',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = AspectExtractorWidget(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = AspectExtractorWidget(
        (int fullName) => fullName,
        key: const ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(value: user),
              Inheritable<User?>(value: user),
              Inheritable<String>(value: user.lname),
              Inheritable<int>(value: User.fullName(user).hashCode),
            ],
            child: Column(
              key: const Key('column'),
              children: [
                const Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
        '[strict:true] Notifies dependents for multiple Inheritables (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(
                key: const Key('key2'),
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(key: const Key('key3'), value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);

      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last', buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-keys) with duplicate key',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(key: const Key('key3'), value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
        '[strict:true] Notifies dependents for multiple Inheritables (unique-by-nullable-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(
                key: const Key('key2'),
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);

      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last', buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-nullable-keys) with duplicate null key',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User>(
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User>(value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
        '[strict:false] Notifies dependents for multiple Inheritables (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: false,
            inheritables: [
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(
                key: const Key('key2'),
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(key: const Key('key3'), value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);

      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last', buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        '[strict:true] Notifies dependents using [by] construct for multiple Inheritables (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final firstNameW = SimpleAspectWidget(
        const Aspect(User.firstName).by((w) => w.key == const Key('key1')),
        key: const ValueKey('first-name'),
      );
      final lastNameW = SimpleAspectWidget(
        const Aspect(User.lastName).by((w) => w.key == const Key('key2')),
        key: const ValueKey('last-name'),
      );
      final fullNameW = SimpleAspectWidget(
        const Aspect(User.fullName).by((w) => w.key == const Key('key3')),
        key: const ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>(
                key: const Key('key1'),
                value: User()
                  ..fname = 'this will be first'
                  ..lname = 'not used',
              ),
              Inheritable<User?>(
                key: const Key('key2'),
                value: User()
                  ..fname = 'not used'
                  ..lname = 'this will be last',
              ),
              Inheritable<User?>(key: const Key('key3'), value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);

      expect(
          widgetMetaFinder(
              key: 'first-name', aspect: 'this will be first', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'last-name', aspect: 'this will be last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last', buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        '[strict:false] Notifies dependents for multiple Inheritables (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = AspectExtractorWidget(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = AspectExtractorWidget(
        (int fullName) => fullName,
        key: const ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: false,
            inheritables: [
              Inheritable<User?>(value: user),
              Inheritable<String>(value: user.lname),
              Inheritable<int>(value: User.fullName(user).hashCode),
            ],
            child: Column(
              key: const Key('column'),
              children: [
                const Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last'.hashCode, buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        'Can supply [strict:true] multiple Inheritable.mutable (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = AspectExtractorWidget(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = AspectExtractorWidget(
        (int fullName) => fullName,
        key: const ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>.mutable(onMutate: (_) {}, value: user),
              Inheritable<String>.mutable(onMutate: (_) {}, value: user.lname),
              Inheritable<int>.mutable(
                onMutate: (_) {},
                value: User.fullName(user).hashCode,
              ),
            ],
            child: Column(
              key: const Key('column'),
              children: [
                const Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last'.hashCode, buildCount: 1),
          findsOneWidget);
    });

    testWidgets(
        'Can supply [strict:true] multiple Inheritable.mutable (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = AspectExtractorWidget(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = AspectExtractorWidget(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = AspectExtractorWidget(
        User.fullName,
        key: ValueKey('full-name'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Inheritable.supply(
            strict: true,
            inheritables: [
              Inheritable<User?>.mutable(
                key: const Key('key1'),
                onMutate: (_) {},
                value: User()
                  ..fname = 'will be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>.mutable(
                key: const Key('key2'),
                onMutate: (_) {},
                value: User()
                  ..fname = 'will also be'
                  ..lname = 'overridden',
              ),
              Inheritable<User?>(key: const Key('key3'), value: user),
            ],
            child: Column(
              key: const Key('column'),
              children: const [
                Flexible(child: firstNameW),
                Flexible(child: lastNameW),
                Flexible(child: fullNameW),
              ],
            ),
          );
        },
      );

      expect(tester.takeException(), isNull);

      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last', buildCount: 1),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last', buildCount: 1),
          findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/aspect_extractor.dart';
import 'helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('Inheritable.mutable', () {
    testWidgets(
        'Notifies parent for mutable value change [parent-rejects-change]',
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
          return Inheritable<User?>.mutable(
            key: const Key('test-key'),
            value: user,
            onMutate: Inheritable.ignoreMutation,
            child: Column(
              key: const Key('column'),
              children: [
                Builder(
                  builder: (context) => TextButton(
                    key: const Key('button'),
                    onPressed: () {
                      context.aspect.update(
                        User()
                          ..fname = 'first'
                          ..lname = 'last2',
                      );
                    },
                    child: Text(
                      'change-state of User.lname:${context.aspect(User.lastName)}',
                    ),
                  ),
                ),
                const Flexible(child: firstNameW),
                const Flexible(child: lastNameW),
                const Flexible(child: fullNameW),
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
      expect(find.text('change-state of User.lname:last'), findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();

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
      expect(find.text('change-state of User.lname:last'), findsOneWidget);
    });

    testWidgets(
        'Notifies parent for mutable value change [parent-accepts-change]',
        (tester) async {
      User? user = User()
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
          return Inheritable<User?>.mutable(
            key: const Key('test-key'),
            value: user,
            onMutate: (next) {
              setState(() {
                user = next;
              });
            },
            child: Column(
              key: const Key('column'),
              children: [
                Builder(
                  builder: (context) => TextButton(
                    key: const Key('button'),
                    onPressed: () {
                      context.aspect.update<User?>(
                        User()
                          ..fname = 'first'
                          ..lname = 'last2',
                      );
                    },
                    child: Text(
                      'change-state of User.lname:${context.aspect(User.lastName)}',
                    ),
                  ),
                ),
                const Flexible(child: firstNameW),
                const Flexible(child: lastNameW),
                const Flexible(child: fullNameW),
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
      expect(find.text('change-state of User.lname:last'), findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
          widgetMetaFinder(key: 'first-name', aspect: 'first', buildCount: 1),
          findsOneWidget);
      expect(widgetMetaFinder(key: 'last-name', aspect: 'last2', buildCount: 2),
          findsOneWidget);
      expect(
          widgetMetaFinder(
              key: 'full-name', aspect: 'first last2', buildCount: 2),
          findsOneWidget);
      expect(find.text('change-state of User.lname:last2'), findsOneWidget);
    });
  });
}

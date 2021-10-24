import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/aspect_extractor.dart';
import 'helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('notification', () {
    testWidgets('Notifies dependents based on aspect equality', (tester) async {
      var user = User()
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
    });

    testWidgets(
        'Notifies dependents based on aspect equality for single aspect that is iterable',
        (tester) async {
      var user = User()
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
      const bothFieldW = AspectExtractorWidget(
        User.bothField,
        key: ValueKey('both-field'),
      );

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
                const Flexible(child: firstNameW),
                const Flexible(child: lastNameW),
                const Flexible(child: fullNameW),
                const Flexible(child: bothFieldW),
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
      expect(
          widgetMetaFinder(
              key: 'both-field', aspect: ['first', 'last'], buildCount: 1),
          findsOneWidget);

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
      expect(
          widgetMetaFinder(
              key: 'both-field', aspect: ['first', 'last2'], buildCount: 2),
          findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('Smoke Test', () {
    testWidgets('Throws for unsatisfied dependency', (tester) async {
      final defaultObj = Object();
      var dependency = defaultObj;

      await tester.pumpStatefulWidget(
        (context, setState) => dependency = Inheritable.of<User>(context,
            aspect: const NoAspect<User>(null), nullOk: false)!,
      );

      expect(tester.takeException(), isA<StateError>());
      expect(dependency, defaultObj);
    });

    testWidgets('Returns null for unsatisfied dependency [nullOk]',
        (tester) async {
      final defaultObj = Object();
      Object? dependency = defaultObj;

      await tester.pumpStatefulWidget(
        (context, setState) {
          dependency = Inheritable.of<User>(context,
              aspect: const NoAspect<User>(null), nullOk: true);
          return Text(
            (dependency as Inheritable<User>?)?.toString() ?? 'nothing',
          );
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nothing'), findsOneWidget);
      expect(dependency, isNull);
    });

    testWidgets('Throws for unsatisfied mutable dependency', (tester) async {
      final defaultObj = Object();
      Object? dependency = defaultObj;

      await tester.pumpStatefulWidget(
        (context, setState) => dependency = Inheritable.of<User>(context,
            aspect: const NoAspect<User>(null), nullOk: false, mutable: true)!,
      );

      expect(tester.takeException(), isA<StateError>());
      expect(dependency, defaultObj);
    });

    testWidgets('Returns null for unsatisfied dependency [nullOk]',
        (tester) async {
      final defaultObj = Object();
      Object? dependency = defaultObj;

      await tester.pumpStatefulWidget(
        (context, setState) {
          dependency = Inheritable.of<User>(context,
              aspect: const NoAspect<User>(null), nullOk: true, mutable: true);
          return Text(
              (dependency as Inheritable<User>?)?.toString() ?? 'nothing');
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nothing'), findsOneWidget);
      expect(dependency, isNull);
    });

    testWidgets('Throws when [mutation] aspect is used to access value',
        (tester) async {
      final overriddenAspect = AspectMutation(
        (w) => User()
          ..fname = 'new-fname'
          ..lname = 'new-lname',
        const Key('overridden-aspect'),
      );

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Text(
            overriddenAspect.of(context).toString(),
          );
        },
      );

      expect(tester.takeException(), isA<UnsupportedError>());
    });

    testWidgets('Renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Inheritable(
            key: const Key('test-key'),
            value: User()
              ..fname = 'first'
              ..lname = 'last',
            child: Builder(
              builder: (context) {
                final fullName =
                    context.aspect((User u) => '${u.fname} ${u.lname}');
                return Text(fullName!);
              },
            ),
          ),
        ),
      );

      await tester.idle();
      expect(tester.takeException(), isNull);
      expect(find.text('first last'), findsOneWidget);
    });
  });
}

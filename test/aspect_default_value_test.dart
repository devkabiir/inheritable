import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('Default Value', () {
    testWidgets('Allows providing aspect default value', (tester) async {
      final aspect = const Aspect(User.firstName).withDefault('first-name');

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Text(aspect.of(context)!);
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('first-name'), findsOneWidget);
    });

    testWidgets('Allows providing aspect default value via context',
        (tester) async {
      final aspect = const Aspect(User.firstName).withDefaultFor(
          (context) => Theme.of(context).appBarTheme.runtimeType.toString());

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Text(aspect.of(context)!);
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('AppBarTheme'), findsOneWidget);
    });

    testWidgets('Allows providing default value at use', (tester) async {
      const aspect = Aspect(User.firstName);

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Text(aspect.of(context, defaultValue: 'use-time')!);
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('use-time'), findsOneWidget);
    });

    testWidgets('Uses aspect default value in chaining [map]', (tester) async {
      final aspect = const Aspect(User.firstName).withDefault('first-name');

      await tester.pumpStatefulWidget(
        (context, setState) {
          return Text(aspect
              .map<String?>((fname) => fname.hashCode.toString())
              .of(context)!);
        },
      );

      expect(tester.takeException(), isNull);
      expect(find.text('first-name'.hashCode.toString()), findsOneWidget);
    });
  });
}

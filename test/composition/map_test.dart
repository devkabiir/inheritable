import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import '../helpers/helpers.dart';
import '../helpers/simple_aspect.dart';

Future<void> main([List<String>? args]) async {
  group('map', () {
    testWidgets('Notifies chained-aspect dependents [map]', (tester) async {
      var user = User()
        ..fname = 'first'
        ..lname = 'last';

      final chainedAspectW = SimpleAspectWidget(
        Aspect<String, User>(
          (User u) => u.fname,
          const Key('user-fname-lower'),
        ).map((fname) => fname.toLowerCase()),
        key: const ValueKey('chained-aspect'),
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
                        ..fname = 'First'
                        ..lname = 'last2';
                    });
                  },
                  child: const Text('change-state'),
                ),
                Flexible(child: chainedAspectW),
              ],
            ),
          );
        },
      );

      final originalState = widgetMetaFinder(
          key: 'chained-aspect', aspect: 'first', buildCount: 1);
      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);

      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(originalState, findsOneWidget);
    });
  });
}

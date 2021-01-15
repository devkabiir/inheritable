import 'package:elistapp/inheritable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class User {
  String fname;
  String lname;

  static String firstName(User user) => user.fname;
  static String lastName(User user) => user.lname;
  static String fullName(User user) => '${user.fname} ${user.lname}';

  static List<String> bothField(User user) {
    return user.both;
  }

  static String displayW<A>(String key, A aspect, int buildCount) =>
      '$key: $aspect [$buildCount]';

  static Finder stateW<A>(String key, A aspect, int buildCount) =>
      find.text(displayW<A>(key, aspect, buildCount));

  List<String> get both => [fname, lname];

  @override
  operator ==(Object other) =>
      other is User && fname == other.fname && lname == other.lname;

  @override
  int get hashCode => [fname, lname].hashCode;

  @override
  String toString() {
    return 'User($fname $lname)';
  }
}

extension on WidgetTester {
  Future<void> pumpStatefulWidget(StatefulWidgetBuilder builder) {
    return pumpWidget(
      MaterialApp(
        key: const Key('material-app'),
        home: Scaffold(
          key: const Key('scaffold'),
          body: StatefulBuilder(
            key: const Key('stateful-builder'),
            builder: builder,
          ),
        ),
      ),
    );
  }
}

Future<void> main([List<String> args]) async {
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
              return Text(fullName);
            },
          ),
        ),
      ),
    );
    await tester.idle();
    expect(tester.takeException(), isNull);
    expect(find.text('first last'), findsOneWidget);
  });

  testWidgets('Notifies dependents based on aspect equality', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _SingleAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _SingleAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _SingleAspectW(
      User.fullName,
      key: ValueKey('full-name'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last', 1), findsOneWidget);
    expect(User.stateW('full-name', 'first last', 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last2', 2), findsOneWidget);
    expect(User.stateW('full-name', 'first last2', 2), findsOneWidget);
  });

  testWidgets(
      'Notifies dependents based on aspect equality for single aspect that is iterable',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _SingleAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _SingleAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _SingleAspectW(
      User.fullName,
      key: ValueKey('full-name'),
    );
    const bothFieldW = _SingleAspectW(
      User.bothField,
      key: ValueKey('both-field'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last', 1), findsOneWidget);
    expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    expect(User.stateW('both-field', ['first', 'last'], 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last2', 2), findsOneWidget);
    expect(User.stateW('full-name', 'first last2', 2), findsOneWidget);
    expect(User.stateW('both-field', ['first', 'last2'], 2), findsOneWidget);
  });

  testWidgets('Notifies dependents unconditionally with NoAspect',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const noaspect = _NoAspect<User>(key: ValueKey('no-aspect'));

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
              const Flexible(child: noaspect),
            ],
          ),
        );
      },
    );

    expect(tester.takeException(), isNull);
    expect(User.stateW('no-aspect', '$user', 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(User.stateW('no-aspect', '$user', 2), findsOneWidget);
  });

  testWidgets('Disallows dependents without any aspect', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const nullAspect = _NullAspect<User>(key: ValueKey('null-aspect'));

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
              const Flexible(child: nullAspect),
            ],
          ),
        );
      },
    );

    expect(tester.takeException(), isUnsupportedError);
    expect(User.stateW('null-aspect', '$user', 1), findsNothing);
  });

  testWidgets('Notifies some-aspect dependents', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someAspectW = _SomeAspectW(
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
              FlatButton(
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
    expect(User.stateW('some-aspect', user, 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(User.stateW('some-aspect', user, 2), findsOneWidget);
  });

  testWidgets(
      'Notifies some-aspect dependents with different aspect type unconditionally',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someAspectW = _SomeAspectW(
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
              FlatButton(
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
    expect(User.stateW('some-aspect', user, 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(User.stateW('some-aspect', user, 2), findsOneWidget);
  });

  testWidgets(
      'Notifies some-aspect dependents conditionally [where not equals]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someAspectW = _SomeAspectW(
      {
        Aspect((User u) => u.fname, const Key('user-fname')),
        Aspect((User u) => u.lname, const Key('user-lname'))
            .where(({next, prev}) {
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
              FlatButton(
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

    final originalState = User.stateW('some-aspect', user, 1);
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

    final someAspectW = _SomeAspectW(
      {
        Aspect((User u) => u.fname, const Key('user-fname')),
        Aspect((User u) => u.lname, const Key('user-lname'))
            .where(({next, prev}) => next == 'last2'),
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
              FlatButton(
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

    final originalState = User.stateW('some-aspect', user, 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsNothing);
    expect(User.stateW('some-aspect', user, 2), findsOneWidget);
  });

  testWidgets('Notifies chained-aspect dependents [map]', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final chainedAspectW = _ChainableAspectW(
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
              FlatButton(
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

    final originalState = User.stateW('chained-aspect', 'first', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);
  });

  testWidgets('Notifies some-chained-aspect dependents', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someChainedAspectW = _SomeChainedAspectW(
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
              FlatButton(
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
    expect(User.stateW('some-chained-aspect', user, 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(User.stateW('some-chained-aspect', user, 2), findsOneWidget);
  });

  testWidgets(
      'Notifies some-chained-aspect dependents with different aspect type unconditionally',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someChainedAspectW = _SomeChainedAspectW(
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
              FlatButton(
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
    expect(User.stateW('some-chained-aspect', user, 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(User.stateW('some-chained-aspect', user, 2), findsOneWidget);
  });

  testWidgets(
      'Notifies some-chained-aspect dependents conditionally [where not equals]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final someChainedAspectW = _SomeChainedAspectW(
      {
        Aspect((User u) => u.fname, const Key('user-fname')),
        Aspect((User u) => u.lname, const Key('user-lname'))
            .where(({next, prev}) {
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
              FlatButton(
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

    final originalState = User.stateW('some-chained-aspect', user, 1);
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

    final someChainedAspectW = _SomeChainedAspectW(
      {
        Aspect((User u) => u.fname, const Key('user-fname')),
        Aspect((User u) => u.lname, const Key('user-lname'))
            .where(({next, prev}) => next == 'last2'),
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
              FlatButton(
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

    final originalState = User.stateW('some-chained-aspect', user, 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsNothing);
    expect(User.stateW('some-chained-aspect', user, 2), findsOneWidget);
  });

  testWidgets(
      'Notifies parent for mutable value change [parent-rejects-change]',
      (tester) async {
    final user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _SingleMutableAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _SingleMutableAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _SingleMutableAspectW(
      User.fullName,
      key: ValueKey('full-name'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable<User>.mutable(
          key: const Key('test-key'),
          value: user,
          onChange: (_) {},
          child: Column(
            key: const Key('column'),
            children: [
              Builder(
                builder: (context) => FlatButton(
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
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last', 1), findsOneWidget);
    expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    expect(find.text('change-state of User.lname:last'), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last', 1), findsOneWidget);
    expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    expect(find.text('change-state of User.lname:last'), findsOneWidget);
  });

  testWidgets(
      'Notifies parent for mutable value change [parent-accepts-change]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _SingleMutableAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _SingleMutableAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _SingleMutableAspectW(
      User.fullName,
      key: ValueKey('full-name'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable<User>.mutable(
          key: const Key('test-key'),
          value: user,
          onChange: (next) {
            setState(() {
              user = next;
            });
          },
          child: Column(
            key: const Key('column'),
            children: [
              Builder(
                builder: (context) => FlatButton(
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
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last', 1), findsOneWidget);
    expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    expect(find.text('change-state of User.lname:last'), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(User.stateW('first-name', 'first', 1), findsOneWidget);
    expect(User.stateW('last-name', 'last2', 2), findsOneWidget);
    expect(User.stateW('full-name', 'first last2', 2), findsOneWidget);
    expect(find.text('change-state of User.lname:last2'), findsOneWidget);
  });

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

    final someChainedAspectW = _SomeChainedAspectW(
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
              FlatButton(
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

    final originalState = User.stateW('some-chained-aspect', user, 1);
    expect(tester.takeException(), isNull);
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

    final userListener = Aspect((User u) => u.lname, const Key('user-lname'))
        .listenable
      ..addListener(didNotify);

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
                    return ValueListenableBuilder<User>(
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

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
                child: _InlineListenableAspect(
                  key: Key('inline-listenable-aspect'),
                ),
              ),
            ],
          ),
        );
      },
    );

    expect(tester.takeException(), isNull);
    expect(User.stateW('inline-listenable-aspect', 'last', 1), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(User.stateW('inline-listenable-aspect', 'last2', 1), findsOneWidget);
  });

  testWidgets(
      'Allows removing dependent aspect without causing build for enclosing context',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final removableAspectW = _RemovableAspectW(
      Aspect((User u) => u.lname, const Key('user-lname')),
      key: const ValueKey('removable-aspect'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
              Flexible(child: removableAspectW),
            ],
          ),
        );
      },
    );

    final originalState = User.stateW('removable-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-aspect-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);
  });

  testWidgets(
      'Allows removing dependent aspect (via key) without causing build for enclosing context',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final removableAspectViaKeyW = _RemovableAspectViaKeyW(
      Aspect((User u) => u.lname, const Key('user-lname')),
      key: const ValueKey('removable-aspect-via-key'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable(
          key: const Key('test-key'),
          value: user,
          child: Column(
            key: const Key('column'),
            children: [
              FlatButton(
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
              Flexible(child: removableAspectViaKeyW),
            ],
          ),
        );
      },
    );

    final originalState = User.stateW('removable-aspect-via-key', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-aspect-via-key-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);
  });
}

class _InlineListenableAspect extends StatefulWidget {
  const _InlineListenableAspect({Key key}) : super(key: key);
  @override
  _InlineListenableAspectState createState() => _InlineListenableAspectState();
}

class _InlineListenableAspectState extends State<_InlineListenableAspect> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount += 1;

    return ValueListenableBuilder<User>(
      valueListenable:
          const Aspect(User.lastName, Key('user-lname')).listenable.of(context),
      builder: (context, user, child) => Text(
        User.displayW(key.value, user.lname, _buildCount),
      ),
    );
  }
}

class _NoAspect<T> extends StatefulWidget {
  const _NoAspect({Key key}) : super(key: key);
  @override
  _NoAspectState<T> createState() => _NoAspectState<T>();
}

class _NoAspectState<T> extends State<_NoAspect<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final value = NoAspect<T>(key).of(context);
    final text = User.displayW(key.value, value, _buildCount += 1);

    return Text(text);
  }
}

class _NullAspect<T> extends StatefulWidget {
  const _NullAspect({Key key}) : super(key: key);
  @override
  _NullAspectState<T> createState() => _NullAspectState<T>();
}

class _NullAspectState<T> extends State<_NullAspect<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final value = Inheritable.of<T>(context)?.value;
    final text = User.displayW(key.value, value, _buildCount += 1);

    return Text(text);
  }
}

class _SingleAspectW<A, T> extends StatefulWidget {
  final SingleAspect<A, T> _extract;
  const _SingleAspectW(
    this._extract, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SingleAspectWState<A, T> createState() => _SingleAspectWState<A, T>();
}

class _SingleAspectWState<A, T> extends State<_SingleAspectW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = Aspect(widget._extract, key).of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _SomeAspectW<T> extends StatefulWidget {
  final Set<InheritableAspect<T>> _aspects;
  const _SomeAspectW(
    this._aspects, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SomeAspectWState<T> createState() => _SomeAspectWState<T>();
}

class _SomeAspectWState<T> extends State<_SomeAspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget._aspects.some().of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _SomeChainedAspectW<T> extends StatefulWidget {
  final Set<InheritableAspect<T>> _aspects;
  const _SomeChainedAspectW(
    this._aspects, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SomeChainedAspectWState<T> createState() => _SomeChainedAspectWState<T>();
}

class _SomeChainedAspectWState<T> extends State<_SomeChainedAspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget._aspects
        .some()
        .map((it) => it.toString())
        .where(({prev, next}) => prev != next)
        .of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _ChainableAspectW<T> extends StatefulWidget {
  final InheritableAspect<T> aspect;
  const _ChainableAspectW(
    this.aspect, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _ChainableAspectWState<T> createState() => _ChainableAspectWState<T>();
}

class _ChainableAspectWState<T> extends State<_ChainableAspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);

    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _SingleMutableAspectW<A, T> extends StatefulWidget {
  final SingleAspect<A, T> _extract;
  const _SingleMutableAspectW(
    this._extract, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _SingleMutableAspectWState<A, T> createState() =>
      _SingleMutableAspectWState<A, T>();
}

class _SingleMutableAspectWState<A, T>
    extends State<_SingleMutableAspectW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = Aspect(widget._extract, key).of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _RemovableAspectW<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  const _RemovableAspectW(
    this.aspect, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _RemovableAspectWState<A, T> createState() => _RemovableAspectWState<A, T>();
}

class _RemovableAspectWState<A, T> extends State<_RemovableAspectW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FlatButton(
            key: const Key('remove-aspect-button'),
            onPressed: () => context.aspect.remove(widget.aspect),
            child: const Text('remove-aspect'),
          ),
        ),
        Flexible(child: Text(text)),
      ],
    );
  }
}

class _RemovableAspectViaKeyW<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  const _RemovableAspectViaKeyW(
    this.aspect, {
    @required ValueKey<String> key,
  }) : super(key: key);

  @override
  _RemovableAspectViaKeyWState<A, T> createState() =>
      _RemovableAspectViaKeyWState<A, T>();
}

class _RemovableAspectViaKeyWState<A, T>
    extends State<_RemovableAspectViaKeyW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FlatButton(
            key: const Key('remove-aspect-via-key-button'),
            onPressed: () => context.aspect.removeKey<T>(widget.aspect.key),
            child: const Text('remove-aspect'),
          ),
        ),
        Flexible(child: Text(text)),
      ],
    );
  }
}

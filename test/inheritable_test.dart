import 'package:flutter/foundation.dart';
import 'package:inheritable/composition.dart';
import 'package:inheritable/inheritable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class User {
  late String fname;
  late String lname;

  static String? firstName(User? user) => user?.fname;
  static String? lastName(User? user) => user?.lname;
  static String? fullName(User? user) => '${user?.fname} ${user?.lname}';

  static List<String>? bothField(User? user) {
    return user?.both;
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
  int get hashCode => hashValues(fname, lname);

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

  /// Causes widgets to be removed/disposed
  /// This has a similar effect to routing to a different page
  Future<void> disposeWidgets() async {
    await pumpWidget(const SizedBox());
    return pumpAndSettle().then((_) => null);
  }
}

class Variant<T> extends TestVariant<T> {
  @override
  final Set<T> values;

  Variant(this.values);

  @override
  String describeValue(T value) {
    return value.toString();
  }

  T? _currentValue;
  T get currentValue => _currentValue!;

  @override
  Future<T?> setUp(T value) async {
    _currentValue = value;
    return null;
  }

  @override
  Future<void> tearDown(T value, Object memento) async {
    _currentValue = null;
  }
}

void assertHasDebugProperties<T>(
    InheritableAspect<T> obj, List<Matcher> matchers) {
  final props = DiagnosticPropertiesBuilder();
  // ignore: invalid_use_of_protected_member
  obj.debugFillProperties(props);

  for (var matcher in matchers) {
    final matchState = <dynamic, dynamic>{};

    expect(
      props.properties.any((prop) => matcher.matches(prop, matchState)),
      isTrue,
      reason: matcher
          .describe(
            StringDescription('Expected ')
                .addDescriptionOf(obj)
                .add(' to have debug property that is '),
          )
          .toString(),
    );
  }
}

typedef AspectImplementationSpecificProps = Map<String, List<Matcher>> Function(
    InheritableAspect<User?> aspect);
Future<void> main([List<String>? args]) async {
  group('Has proper debug properties', () {
    final aspects = [
      const Aspect(User.firstName, Key('firstName')),
      const Aspect(User.firstName, Key('firstName')).listenable,
    ];

    final mixins = <AspectImplementationSpecificProps>[
      (aspect) {
        return {
          'default': <Matcher>[
            isA<ObjectFlagProperty<String>>()
                .having((prop) => prop.name, 'name', 'debug-label')
                .having((prop) => prop.value, 'value', aspect.debugLabel),
            isA<ObjectFlagProperty<Key>>()
                .having((prop) => prop.name, 'name', 'key')
                .having((prop) => prop.value, 'value', aspect.key),
            isA<ObjectFlagProperty<Type>>()
                .having((prop) => prop.name, 'name', 'implementation')
                .having((prop) => prop.value, 'value', aspect.runtimeType),
            isA<ObjectFlagProperty<Type>>()
                .having((prop) => prop.name, 'name', 'inheritable')
                .having((prop) => prop.value.toString(), 'value', 'User?'),
          ]
        };
      },
      (Object a) {
        final implProps = <String, List<Matcher>>{};
        if (a is Aspect) {
          implProps['Aspect'] = [
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'chained')
                .having((prop) => prop.value, 'value', false),
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'defaultValue')
                .having((prop) => prop.value, 'value', false),
          ];
        }
        return implProps;
      },
      (Object a) {
        final implProps = <String, List<Matcher>>{};
        if (a is DependableAspect) {
          implProps['DependableAspect'] = [
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'dependable')
                .having((prop) => prop.value, 'value', true),
          ];
        }
        return implProps;
      },
      (Object a) {
        final implProps = <String, List<Matcher>>{};
        if (a is EquatableAspect) {
          implProps['EquatableAspect'] = [
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'equatable')
                .having((prop) => prop.value, 'value', true),
          ];
        }
        return implProps;
      },
      (Object a) {
        final implProps = <String, List<Matcher>>{};
        if (a is DelegatingAspect) {
          implProps['DelegatingAspect'] = [
            isA<StringProperty>()
                .having((prop) => prop.name, 'name', 'delegate')
                .having((prop) => prop.value, 'value', a.delegate.toString()),
          ];
        }
        return implProps;
      },
      (Object a) {
        final implProps = <String, List<Matcher>>{};
        if (a is ValueListenable) {
          implProps['ListenableAspect'] = [
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'notifier.disposed')
                .having((prop) => prop.value, 'value', false),
            isA<FlagProperty>()
                .having((prop) => prop.name, 'name', 'hasListeners')
                .having((prop) => prop.value, 'value', false),
            isA<ObjectFlagProperty<User?>>()
                .having((prop) => prop.name, 'name', 'value')
          ];
        }
        return implProps;
      },
    ];
    for (var aspect in aspects) {
      final implementation = aspect.runtimeType.toString().split('<').first;

      final specificProps = mixins
          .map((impl) => impl(aspect))
          .reduce((prev, next) => prev..addAll(next));

      for (var impl in specificProps.keys) {
        test('(specific properties) [$implementation][$impl]', () {
          assertHasDebugProperties(aspect, specificProps[impl]!);
        });
      }
    }
  });

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

  testWidgets('Notifies dependents based on aspect equality', (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _ExtractAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _ExtractAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _ExtractAspectW(
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

    const firstNameW = _ExtractAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _ExtractAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _ExtractAspectW(
      User.fullName,
      key: ValueKey('full-name'),
    );
    const bothFieldW = _ExtractAspectW(
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

    final originalState = User.stateW('some-chained-aspect', user, 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(originalState, findsNothing);
    expect(User.stateW('some-chained-aspect', user, 2), findsOneWidget);
  });

  group('Inheritable.supply', () {
    testWidgets(
        '[strict:true] Notifies dependents for multiple Inheritables (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = _ExtractMutableAspectW(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = _ExtractMutableAspectW(
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
      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(
          User.stateW('full-name', 'first last'.hashCode, 1), findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-types) with duplicate type',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = _ExtractMutableAspectW(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = _ExtractMutableAspectW(
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

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-keys) with duplicate key',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    });

    testWidgets(
        '[strict:true] Throws for multiple Inheritables (unique-by-nullable-keys) with duplicate null key',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    });

    testWidgets(
        '[strict:true] Notifies dependents using [by] construct for multiple Inheritables (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      final firstNameW = _AspectW(
        const Aspect(User.firstName).by((w) => w.key == const Key('key1')),
        key: const ValueKey('first-name'),
      );
      final lastNameW = _AspectW(
        const Aspect(User.lastName).by((w) => w.key == const Key('key2')),
        key: const ValueKey('last-name'),
      );
      final fullNameW = _AspectW(
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
          User.stateW('first-name', 'this will be first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'this will be last', 1), findsOneWidget);
      expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    });

    testWidgets(
        '[strict:false] Notifies dependents for multiple Inheritables (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = _ExtractMutableAspectW(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = _ExtractMutableAspectW(
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
      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(
          User.stateW('full-name', 'first last'.hashCode, 1), findsOneWidget);
    });

    testWidgets(
        'Can supply [strict:true] multiple Inheritable.mutable (unique-by-types)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      final lastNameW = _ExtractMutableAspectW(
        (String lname) => lname,
        key: const ValueKey('last-name'),
      );
      final fullNameW = _ExtractMutableAspectW(
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
      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(
          User.stateW('full-name', 'first last'.hashCode, 1), findsOneWidget);
    });

    testWidgets(
        'Can supply [strict:true] multiple Inheritable.mutable (unique-by-keys)',
        (tester) async {
      final user = User()
        ..fname = 'first'
        ..lname = 'last';

      const firstNameW = _ExtractMutableAspectW(
        User.firstName,
        key: ValueKey('first-name'),
      );
      const lastNameW = _ExtractMutableAspectW(
        User.lastName,
        key: ValueKey('last-name'),
      );
      const fullNameW = _ExtractMutableAspectW(
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

      expect(User.stateW('first-name', 'first', 1), findsOneWidget);
      expect(User.stateW('last-name', 'last', 1), findsOneWidget);
      expect(User.stateW('full-name', 'first last', 1), findsOneWidget);
    });
  });

  testWidgets(
      'Notifies parent for mutable value change [parent-rejects-change]',
      (tester) async {
    final user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _ExtractMutableAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _ExtractMutableAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _ExtractMutableAspectW(
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
    User? user = User()
      ..fname = 'first'
      ..lname = 'last';

    const firstNameW = _ExtractMutableAspectW(
      User.firstName,
      key: ValueKey('first-name'),
    );
    const lastNameW = _ExtractMutableAspectW(
      User.lastName,
      key: ValueKey('last-name'),
    );
    const fullNameW = _ExtractMutableAspectW(
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

    addTearDown(() async {
      await tester.disposeWidgets();
      userListener
        ..removeListener(didNotify)
        ..dispose();
    });

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

    final originalState = User.stateW('some-chained-aspect', user, 1);
    expect(tester.takeException(), isNull);
    expect(userListener.hasListeners, isTrue);
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

    final userListener = const Aspect(User.lastName, Key('user-lname'))
        .listenable
      ..addListener(didNotify);

    addTearDown(() async {
      await tester.disposeWidgets();
      userListener
        ..removeListener(didNotify)
        ..dispose();
    });

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
              Flexible(
                key: const Key('flexible'),
                child: Builder(
                  key: const Key('builder'),
                  builder: (context) {
                    return ValueListenableBuilder<User?>(
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
    expect(userListener.hasListeners, isTrue);
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

    addTearDown(() async {
      await tester.disposeWidgets();
    });

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

  testWidgets(
      'Notifies dependents after debounce duration for changes [leading:false]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final debounceAspectW = _DebounceAspectW(
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

    final originalState = User.stateW('debounce-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.pump(_DebounceAspectW.defaultDelay);
    await tester.tap(find.byKey(const Key('button-2')));
    expect(user.lname, 'last3');
    await tester.pump();
    expect(originalState, findsNothing);
    expect(User.stateW('debounce-aspect', 'last3', 2), findsOneWidget);
  });

  testWidgets(
      'Notifies dependents after debounce duration for changes [leading:true]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final debounceAspectW = _DebounceAspectW(
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

    final originalState = User.stateW('debounce-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();

    expect(tester.takeException(), isNull);

    /// Since leading:true, the first change is available immediately
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);

    await tester.pump(
      Duration(milliseconds: _DebounceAspectW.defaultDelay.inMilliseconds ~/ 2),
    );

    await tester.tap(find.byKey(const Key('button-2')));
    expect(user.lname, 'last3');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last3', 3), findsNothing);
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);

    await tester.pump(_DebounceAspectW.defaultDelay);
    await tester.tap(find.byKey(const Key('button-3')));
    expect(user.lname, 'last4');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last2', 2), findsNothing);
    expect(User.stateW('debounce-aspect', 'last4', 3), findsOneWidget);
  });

  testWidgets(
      'Does not require exhausting timer for debounce duration for changes [leading:false]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final inlineDebounceAspectW = _InlineDebounceAspectW(
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

    final originalState = User.stateW('inline-debounce-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.pump(
      Duration(
          milliseconds:
              _InlineDebounceAspectW.defaultDelay.inMilliseconds ~/ 2),
    );

    await tester.tap(find.byKey(const Key('button-2')));
    expect(user.lname, 'last3');
    await tester.pump();
    expect(originalState, findsOneWidget);

    await tester.pump(_InlineDebounceAspectW.defaultDelay);
    await tester.tap(find.byKey(const Key('button-3')));
    expect(user.lname, 'last4');
    await tester.pump();
    expect(User.stateW('inline-debounce-aspect', 'last4', 2), findsOneWidget);
  });

  testWidgets(
      'Does not notify dependents after debounce duration for no-changes [leading:false]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final debounceAspectW = _DebounceAspectW(
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

    final originalState = User.stateW('debounce-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.pump(
      Duration(milliseconds: _DebounceAspectW.defaultDelay.inMilliseconds ~/ 2),
    );

    await tester.tap(find.byKey(const Key('button-2')));
    expect(user.lname, 'last3');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last3', 3), findsNothing);
    expect(originalState, findsOneWidget);

    /// Skips this change, timer has not exhausted
    await tester.tap(find.byKey(const Key('button-3')));
    expect(user.lname, 'last4');
    await tester.pump();
    expect(originalState, findsOneWidget);

    /// Skips this change, because it's the same
    await tester.pump(_DebounceAspectW.defaultDelay);
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

    final debounceAspectW = _DebounceAspectW(
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

    final originalState = User.stateW('debounce-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(originalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();

    expect(tester.takeException(), isNull);

    /// Since leading:true, the first change is available immediately
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);

    await tester.pump(
      Duration(milliseconds: _DebounceAspectW.defaultDelay.inMilliseconds ~/ 2),
    );

    await tester.tap(find.byKey(const Key('button-2')));
    expect(user.lname, 'last3');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last3', 3), findsNothing);
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);

    /// Skips this change, timer has not exhausted
    await tester.tap(find.byKey(const Key('button-3')));
    expect(user.lname, 'last4');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);

    /// Skips this change, because it's the same
    await tester.pump(_DebounceAspectW.defaultDelay);
    await tester.tap(find.byKey(const Key('button-1')));
    expect(user.lname, 'last2');
    await tester.pump();
    expect(User.stateW('debounce-aspect', 'last2', 2), findsOneWidget);
  });

  testWidgets('Provides overridden value to aspect by aspect equality',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final overriddenAspect =
        Aspect((User u) => u.lname, const Key('user-lname'));

    final overriddenAspectW = _OverridenAspectW(
      overriddenAspect,
      key: const ValueKey('overridden-aspect'),
    );

    final nonOverriddenAspectW = _OverridenAspectW(
      Aspect((User u) => u.lname, const Key('user-lname2')),
      key: const ValueKey('non-overridden-aspect'),
    );

    await tester.pumpStatefulWidget(
      (context, setState) {
        return Inheritable.override(
          key: const Key('test-key'),
          value: user,
          overrides: {AspectOverride(overriddenAspect, 'overridden-last-name')},
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

    final nonOverriddenOriginalState =
        User.stateW('non-overridden-aspect', 'last', 1);
    final overriddenOriginalState =
        User.stateW('overridden-aspect', 'overridden-last-name', 1);
    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsOneWidget);
    expect(overriddenOriginalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsNothing);
    expect(User.stateW('non-overridden-aspect', 'last2', 2), findsOneWidget);
    expect(overriddenOriginalState, findsOneWidget);
  });

  testWidgets('Provides overridden value to aspect by aspect key',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final overriddenAspectW = _OverridenAspectW(
      Aspect((User u) => u.lname, const Key('user-lname')),
      key: const ValueKey('overridden-aspect'),
    );

    final nonOverriddenAspectW = _OverridenAspectW(
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

    final nonOverriddenOriginalState =
        User.stateW('non-overridden-aspect', 'last', 1);
    final overriddenOriginalState =
        User.stateW('overridden-aspect', 'overridden-last-name', 1);
    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsOneWidget);
    expect(overriddenOriginalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsNothing);
    expect(User.stateW('non-overridden-aspect', 'last2', 2), findsOneWidget);
    expect(overriddenOriginalState, findsOneWidget);
  });

  testWidgets(
      'Does not override value for aspect by aspect key [mutation = true]',
      (tester) async {
    var user = User()
      ..fname = 'first'
      ..lname = 'last';

    final overriddenAspectW = _OverridenAspectW(
      Aspect((User u) => u.lname, const Key('user-lname')),
      key: const ValueKey('overridden-aspect'),
    );

    final nonOverriddenAspectW = _OverridenAspectW(
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

    final nonOverriddenOriginalState =
        User.stateW('non-overridden-aspect', 'last', 1);
    final overriddenOriginalState = User.stateW('overridden-aspect', 'last', 1);
    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsOneWidget);
    expect(overriddenOriginalState, findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nonOverriddenOriginalState, findsNothing);
    expect(User.stateW('non-overridden-aspect', 'last2', 2), findsOneWidget);
    expect(User.stateW('overridden-aspect', 'last2', 2), findsOneWidget);
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

    final overriddenAspectW = _OverridenMutableAspectW(
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

    final overriddenOriginalState =
        User.stateW('overridden-mutable-aspect', '', 1);
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

    final overriddenAspectW = _OverridenMutableAspectW(
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

    final overriddenOriginalState =
        User.stateW('overridden-mutable-aspect', '', 1);
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

    final overriddenAspectW = _OverridenMutableAspectW(
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

    final overriddenOriginalState =
        User.stateW('overridden-mutable-aspect', '', 1);
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
    final overriddenAspectW = _OverridenAspectW(
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
    final overriddenAspectW = _OverridenAspectW(
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

    final overriddenAspectW = _OverridenMutableAspectW(
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
    final overriddenOriginalState =
        User.stateW('overridden-mutable-aspect', '', 1);
    expect(tester.takeException(), isNull);
    expect(overriddenOnMutate, []);
    expect(overriddenOriginalState, findsOneWidget);

    await tester.tap(find.byKey(Key('${overriddenAspectW.key}-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isStateError);
    expect(overriddenOriginalState, findsOneWidget);
    expect(overriddenOnMutate, []);
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
            builder: (context) => Text(
                aspect.map<String?>((s) => s.hashCode.toString()).of(context)!),
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
}

class _InlineListenableAspect extends StatefulWidget {
  const _InlineListenableAspect({Key? key}) : super(key: key);
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

    return ValueListenableBuilder<User?>(
      valueListenable:
          const Aspect<String?, User?>(User.lastName, Key('user-lname'))
              .listenable
              .of(context),
      builder: (context, user, child) {
        return Text(
          User.displayW(key.value, user?.lname, _buildCount),
        );
      },
    );
  }
}

class _NoAspect<T> extends StatefulWidget {
  const _NoAspect({Key? key}) : super(key: key);
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

class _ExtractAspectW<A, T> extends StatefulWidget {
  final ExtractAspect<A, T> _extract;
  const _ExtractAspectW(
    this._extract, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _ExtractAspectWState<A, T> createState() => _ExtractAspectWState<A, T>();
}

class _ExtractAspectWState<A, T> extends State<_ExtractAspectW<A, T>> {
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
  final Set<DependableAspect<T>> _aspects;
  const _SomeAspectW(
    this._aspects, {
    required ValueKey<String> key,
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
  final Set<DependableAspect<T>> _aspects;
  const _SomeChainedAspectW(
    this._aspects, {
    required ValueKey<String> key,
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
        .where(({required prev, required next}) => prev != next)
        .of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _ChainableAspectW<T> extends StatefulWidget {
  final InheritableAspect<T> aspect;
  const _ChainableAspectW(
    this.aspect, {
    required ValueKey<String> key,
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

class _ExtractMutableAspectW<A, T> extends StatefulWidget {
  final ExtractAspect<A, T> _extract;
  const _ExtractMutableAspectW(
    this._extract, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _ExtractMutableAspectWState<A, T> createState() =>
      _ExtractMutableAspectWState<A, T>();
}

class _ExtractMutableAspectWState<A, T>
    extends State<_ExtractMutableAspectW<A, T>> {
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
    required ValueKey<String> key,
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
          child: TextButton(
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
    required ValueKey<String> key,
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
          child: TextButton(
            key: const Key('remove-aspect-via-key-button'),
            // ignore: deprecated_member_use_from_same_package
            onPressed: () => context.aspect.removeKey<T>(widget.aspect.key!),
            child: const Text('remove-aspect'),
          ),
        ),
        Flexible(child: Text(text)),
      ],
    );
  }
}

class _DebounceAspectW<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  final Duration duration;
  final bool leading;
  final PredicateAspect<A> compare;

  static const defaultDelay = Duration(milliseconds: 200);
  static bool _equals({required Object? prev, required Object? next}) {
    return next != prev;
  }

  const _DebounceAspectW(
    this.aspect, {
    required ValueKey<String> key,
    this.compare = _equals,
    this.leading = false,
    this.duration = defaultDelay,
  }) : super(key: key);

  @override
  _DebounceAspectWState<A, T> createState() => _DebounceAspectWState<A, T>();
}

class _DebounceAspectWState<A, T> extends State<_DebounceAspectW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;
  late Aspect<A, T> aspect;

  @override
  void initState() {
    super.initState();

    aspect = widget.aspect.where(
      debounce(
        widget.duration,
        leading: widget.leading,
        shouldNotify: widget.compare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aspect = this.aspect.of(context);

    final text = User.displayW(key.value, aspect, _buildCount += 1);

    return Text(text);
  }
}

class _InlineDebounceAspectW<A, T> extends StatefulWidget {
  final Aspect<A, T> aspect;
  final Duration duration;
  final PredicateAspect<A> compare;

  static const defaultDelay = Duration(milliseconds: 200);
  static bool _equals({required Object? prev, required Object? next}) {
    return next != prev;
  }

  const _InlineDebounceAspectW(
    this.aspect, {
    required ValueKey<String> key,
    this.compare = _equals,
    this.duration = defaultDelay,
  }) : super(key: key);

  @override
  _InlineDebounceAspectWState<A, T> createState() =>
      _InlineDebounceAspectWState<A, T>();
}

class _InlineDebounceAspectWState<A, T>
    extends State<_InlineDebounceAspectW<A, T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect
        .where(
          debounce(
            widget.duration,
            leading: false,
            shouldNotify: widget.compare,
          ),
        )
        .of(context);

    final text = User.displayW(key.value, aspect, _buildCount += 1);

    return Text(text);
  }
}

class _OverridenAspectW<T> extends StatefulWidget {
  final InheritableAspect<T> _aspect;
  const _OverridenAspectW(
    this._aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _OverridenAspectWState<T> createState() => _OverridenAspectWState<T>();
}

class _OverridenAspectWState<T> extends State<_OverridenAspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget._aspect.of(context);
    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

class _OverridenMutableAspectW<T> extends StatefulWidget {
  final MutableInheritableAspect<T> _aspect;
  const _OverridenMutableAspectW(
    this._aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _OverridenMutableAspectWState<T> createState() =>
      _OverridenMutableAspectWState<T>();
}

class _OverridenMutableAspectWState<T>
    extends State<_OverridenMutableAspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final text = User.displayW(key.value, '', _buildCount += 1);
    return TextButton(
      key: Key('${widget.key}-button'),
      onPressed: () => widget._aspect.apply(context),
      child: Text(text),
    );
  }
}

class _AspectW<T> extends StatefulWidget {
  final InheritableAspect<T> aspect;
  const _AspectW(
    this.aspect, {
    required ValueKey<String> key,
  }) : super(key: key);

  @override
  _AspectWState<T> createState() => _AspectWState<T>();
}

class _AspectWState<T> extends State<_AspectW<T>> {
  ValueKey<String> get key => widget.key as ValueKey<String>;

  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);

    final text = User.displayW(key.value, aspect, _buildCount += 1);
    return Text(text);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

/// Given meta about a widget, generates an easy to identify string
String widgetMetaFactory<A>(String key, A aspect, int buildCount) =>
    '$key: $aspect [$buildCount]';

/// Given meta about a widget, generates a finder for that widget
Finder widgetMetaFinder<A>(
        {required String key, required A aspect, required int buildCount}) =>
    find.text(widgetMetaFactory<A>(key, aspect, buildCount));

class User {
  late String fname;
  late String lname;

  static String? firstName(User? user) => user?.fname;
  static String? lastName(User? user) => user?.lname;
  static String? fullName(User? user) => '${user?.fname} ${user?.lname}';

  static List<String>? bothField(User? user) {
    return user?.both;
  }

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

extension WidgetTesterHelpers on WidgetTester {
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

// typedef AspectPropertyTestCases = Map<String, List<Matcher>>;
typedef AspectPropertyMatcherFactory<T> = Map<String, List<Matcher>> Function(
    InheritableAspect<T> aspect);

void assertHasDebugProperties<T>(
    InheritableAspect<T> obj, List<Matcher> matchers) {
  final props = DiagnosticPropertiesBuilder();
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_overriding_member
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

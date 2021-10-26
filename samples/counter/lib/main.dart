import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class Counter {
  /// Exposed public member that provides direct access to state.
  static final state = Aspect((Counter state) => state._count)
      .withPatch((value, next) => Counter(next));

  /// Redux like actions
  static final incrementor = AspectMutation<Counter>(
    (inheritable) {
      var count = inheritable.valueFor<int>(Counter.state);

      return Counter(count + 1);
    },
  );

  static final decrementor = AspectMutation<Counter>(
    (inheritable) {
      var count = inheritable.valueFor<int>(Counter.state);

      return Counter(count - 1);
    },
  );

  /// Internal private variable that holds the state.
  final int _count;

  const Counter(this._count);

  @override
  int get hashCode => _count;

  @override
  bool operator ==(Object other) {
    return other is Counter && _count == other._count;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Counter currentState;

  @override
  void initState() {
    super.initState();

    currentState = const Counter(0);
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            AspectBuilder<int, Counter>(
              aspect: Counter.state,
              builder: (context, count, _) => Text(
                '$count',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              // var currentCount =
              //     Counter.state.of(context, rebuild: false, defaultValue: 0)!;
              // Counter.state.replace(currentCount + 1).apply(context);

              Counter.incrementor.apply(context);
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          );
        },
      ),
    );

    final inheritable = Inheritable<Counter>.mutable(
      value: currentState,
      onMutate: (next) => setState(() => currentState = next),
      child: scaffold,
    );

    return inheritable;
  }
}

import 'package:flutter/material.dart';
import 'package:inheritable/inheritable.dart' hide AspectBuilder;
import 'package:inheritable/inheritable.dart' as i;
import 'state.dart';

void main() => runApp(const AppRoot(IAppState()));

mixin RebuildCounter<W extends StatefulWidget> on State<W> {
  static final Map<Key, int> _trackCount = {};

  int get currentBuildCount => _trackCount[widget.key] ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackCount[widget.key!] = currentBuildCount + 1;
  }
}

class AppRoot extends StatelessWidget {
  final IAppState initialState;
  const AppRoot(this.initialState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, _) {
        // This is very good example of inheritable's abilities
        // This state is going to be reset everytime App widget rebuilds,
        // However because nothing depends on any aspect of AppState,
        // This doesn't get rebuilt.
        var state = initialState;
        return StatefulBuilder(
          builder: (context, setState) {
            return Inheritable<IAppState>.mutable(
              value: state,
              onMutate: (next) {
                setState(() {
                  state = next;
                });
              },
              child: const AppRouter(),
            );
          },
        );
      },
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter() : super(key: const Key('AppRouter'));
  @override
  _AppRouterState createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> with RebuildCounter<AppRouter> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Route changed $currentBuildCount times'),
          Expanded(
            // The animated switcher actually builds the previous route and the
            // next route when animating between them.
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 4),
              transitionBuilder: (child, animation) =>
                  const FadeUpwardsPageTransitionsBuilder().buildTransitions(
                      null,
                      null,
                      animation,
                      ReverseAnimation(animation),
                      child),
              child: IAppState.Route.of(context)! == Routes.dashboard
                  ? AppDashboard(Key('$AppDashboard'))
                  : AppSettings(Key('$AppSettings')),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDashboard extends StatefulWidget {
  const AppDashboard(Key key) : super(key: key);

  @override
  _AppDashboardState createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard>
    with RebuildCounter<AppDashboard> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      key: const Key('Dashboard scaffold'),
      title: 'Dashboard',
      body: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Content has been built $currentBuildCount times'),
              const Text('Current route is:'),
              AspectBuilderWithRebuildCounter(
                key: const Key('Dashboard route'),
                aspect: IAppState.Route,
                builder: (context, route, _) => Text(route!.toString()),
              ),
              Builder(
                builder: (context) => TextButton.icon(
                  onPressed: () =>
                      IAppState.Route.replace(Routes.settings).apply(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Change state'),
                ),
              ),
              AspectBuilderWithRebuildCounter(
                key: const Key('Dashboard UseDarkMode'),
                aspect: IAppSettings.UseDarkMode,
                builder: (context, bool? check, _) => CheckboxListTile(
                  title: const Text('Use dark mode?'),
                  value: check!,
                  onChanged: null,
                ),
              ),
              AspectBuilderWithRebuildCounter(
                key: const Key('Dashboard KeepLoggedIn'),
                aspect: IAppSettings.KeepLoggedIn,
                builder: (context, bool? check, _) => CheckboxListTile(
                  title: const Text('Keep logged in?'),
                  value: check!,
                  onChanged: null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppSettings extends StatefulWidget {
  const AppSettings(Key key) : super(key: key);

  @override
  _AppSettingsState createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings>
    with RebuildCounter<AppSettings> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      key: const Key('Settings scaffold'),
      title: 'Settings',
      body: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Content has been built $currentBuildCount times'),
              const Text('Current route is:'),
              AspectBuilderWithRebuildCounter(
                key: const Key('Settings route'),
                aspect: IAppState.Route,
                builder: (context, route, _) => Text(route!.toString()),
              ),
              Builder(
                builder: (context) => TextButton.icon(
                  onPressed: () =>
                      IAppState.Route.replace(Routes.dashboard).apply(context),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View state'),
                ),
              ),
              AspectBuilderWithRebuildCounter(
                key: const Key('Settings UseDarkMode'),
                aspect: IAppSettings.UseDarkMode,
                builder: (context, bool? check, _) => CheckboxListTile(
                  title: const Text('Use dark mode?'),
                  value: check!,
                  onChanged: (next) =>
                      IAppSettings.UseDarkMode.replace(next!).apply(context),
                ),
              ),
              AspectBuilderWithRebuildCounter(
                key: const Key('Settings KeepLoggedIn'),
                aspect: IAppSettings.KeepLoggedIn,
                builder: (context, bool? check, _) => CheckboxListTile(
                  title: const Text('Keep logged in?'),
                  value: check!,
                  onChanged: (next) =>
                      IAppSettings.KeepLoggedIn.replace(next!).apply(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AspectBuilderWithRebuildCounter<A, T> extends StatefulWidget {
  /// Required aspect dependency of widget/s built by [builder]
  final TransformingAspect<A, T> aspect;

  /// Widget builder that get's [aspect] fed into it
  final AspectWidgetBuilder<A?> builder;

  const AspectBuilderWithRebuildCounter({
    required this.aspect,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  _AspectBuilderWithRebuildCounterState<A, T> createState() =>
      _AspectBuilderWithRebuildCounterState();
}

class _AspectBuilderWithRebuildCounterState<A, T>
    extends State<AspectBuilderWithRebuildCounter<A, T>>
    with RebuildCounter<AspectBuilderWithRebuildCounter<A, T>> {
  @override
  Widget build(BuildContext context) {
    final aspect = widget.aspect.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        shape: const BeveledRectangleBorder(
          side: BorderSide(color: Colors.grey, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Built $currentBuildCount times'),
              Builder(
                builder: (context) => widget.builder(context, aspect, null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppScaffold extends StatefulWidget {
  final String title;
  final WidgetBuilder body;
  const AppScaffold({required this.title, required this.body, required Key key})
      : super(key: key);

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with RebuildCounter<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Built $currentBuildCount times'),
      ),
      body: Card(child: Builder(builder: widget.body)),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:inheritable/inheritable.dart';

@immutable
class IAppSettings {
  final bool useDarkMode;
  final bool keepLoggedIn;

  static final UseDarkMode = Aspect(
    (IAppState state) => state.prefs.settings.useDarkMode,
    const Key('AppSettings.UseDarkMode'),
  ).withPatch(
    (state, next) => state.copyWith(
      prefs: state.prefs.copyWith(
        settings: state.prefs.settings.copyWith(useDarkMode: next),
      ),
    ),
  );

  static final KeepLoggedIn = Aspect(
    (IAppState state) => state.prefs.settings.keepLoggedIn,
    const Key('AppSettings.KeepLoggedIn'),
  ).withPatch(
    (state, next) => state.copyWith(
      prefs: state.prefs.copyWith(
        settings: state.prefs.settings.copyWith(keepLoggedIn: next),
      ),
    ),
  );

  const IAppSettings({this.useDarkMode = true, this.keepLoggedIn = true});

  IAppSettings copyWith({bool? useDarkMode, bool? keepLoggedIn}) =>
      IAppSettings(
        useDarkMode: useDarkMode ?? this.useDarkMode,
        keepLoggedIn: keepLoggedIn ?? this.keepLoggedIn,
      );
}

@immutable
class UserPreferences {
  final IAppSettings settings;
  const UserPreferences({this.settings = const IAppSettings()});

  UserPreferences copyWith({IAppSettings? settings}) =>
      UserPreferences(settings: settings ?? this.settings);
}

enum Routes {
  dashboard,
  settings,
}

@immutable
class IAppState {
  // Various other nested states;

  /// Prefs
  final UserPreferences prefs;

  final Routes route;

  static final Preferences = Aspect((IAppState state) => state.prefs);
  static final Route = Aspect((IAppState state) => state.route)
      .withPatch((state, next) => state.copyWith(route: next));

  const IAppState({
    this.prefs = const UserPreferences(),
    this.route = Routes.dashboard,
  });

  IAppState copyWith(
          {UserPreferences? prefs, Routes? route, bool? useDebounce}) =>
      IAppState(
        prefs: prefs ?? this.prefs,
        route: route ?? this.route,
      );
}

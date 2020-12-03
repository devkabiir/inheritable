import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Given [T] extract certain aspect [A] from [it] and return that.
///
/// You can return anything as long as it satisfies type [A]
typedef SingleAspect<A, T> = A Function(T it);

/// {@macro Aspect.multi}
typedef MultiAspect<A, T> = Iterable<A> Function(T it);

/// {@macro Aspect.indexed}
typedef IndexedAspect<A, T> = A Function(T it, {int at});

/// {@macro Aspect.iterate}
typedef RandomAccessIndexedAspect<A, T> = Iterable<A> Function(T it, {int at});

/// {@macro Aspect.list}
typedef EfficientLengthIndexedAspect<A, T> = List<A Function()> Function(T it);

/// Given [T] return whether you should be notified or not.
typedef PredicateAspect<T> = bool Function(T it);

/// Modifiers that signal [Aspect.multi] and variants to take certain actions when yielded
///
/// It is up to the implementation of an [Aspect] how to use these and whether to
/// skip it altogether.
enum AspectModifier {
  /// {@template AspectModifier.skip}
  /// Use when you don't want to be notified when a certain aspect has a certain
  /// value. This can also be used in place of [absent] for "absent" values you
  /// want to skip-over.
  /// {@endtemplate}
  skip,

  /// {@template AspectModifier.absent}
  /// Use when you want to be notified when a certain aspect has "absent" value.
  ///
  /// "absent" here refers to any value you consider to be `null`, invalid or just
  /// absent 🤷‍♂️ but still want to be notified for it.
  ///
  /// Notified here refers to rebuilding your widget.
  /// {@endtemplate}
  absent,

  // TODO: Spec for AspectModifier.unsatisfied
  unsatisfied,

  /// {@template AspectModifier.forceNotify}
  /// Always notify regardless of the value.
  ///
  /// This is the default behaviour of
  /// many different kinds of [InheritedWidget] implementation if they do not provide
  /// sufficiently correct implementation of
  /// [InheritedWidget.updateShouldNotify]. Similarly if
  /// [InheritedModel.updateShouldNotifyDependent] is not doing sufficient
  /// comparisons or comparisons that do not matter for your use-case or aspect
  /// are still being performed.
  ///
  /// Note that once this value is `yield`ed, you immediately get notified
  /// regardless of whether there are more aspects remaining for comparison or not.
  /// {@endtemplate}
  forceNotify,
}

/// An aspect of [T]
abstract class Aspect<T> {
  static bool _handleAspectModifiers<A>(A aspect, A Function() other) {
    /// Skip notifying, go to next aspect
    if (Aspect.skip == aspect) {
      return false;
    }

    /// Force notification, don't go to next aspect
    if (Aspect.forceNotify == aspect) {
      return true;
    }

    /// Also works for [Aspect.absent]
    return aspect != other();
  }

  /// {@macro AspectModifier.forceNotify}
  static const forceNotify = AspectModifier.forceNotify;

  /// {@macro AspectModifier.absent}
  static const absent = AspectModifier.absent;

  /// {@macro AspectModifier.skip}
  static const skip = AspectModifier.skip;

  /// Constant constructor for subclasses
  const Aspect();

  /// Unconditionally notify listener
  static NoAspect<T> none<T>() => NoAspect<T>();

  /// Create an aspect of [T] that is of type [A]
  ///
  /// The provided function will be provided [T] and it should take only 1
  /// aspect from it.
  static _SingleAspect<A, T> single<A, T>(SingleAspect<A, T> extract) =>
      _SingleAspect<A, T>(extract);

  /// {@template Aspect.multi}
  /// Acquire multiple aspects from [T]
  ///
  /// Use this variant of [Aspect] when you want to be notified if __any__ of the
  /// required aspect changes it's value.
  ///
  /// Ideally [extract] should `yield` each new aspect in fixed-order such that
  /// repeatedly calling it on same [T] would produce an
  /// [Iterable] with elements at same index to be equivalent derived by [Object.==].
  /// If a certain aspect is required but currently absent, [extract] should `yield`
  /// [Aspect.absent] in it's place.
  ///
  /// For Example:
  /// ```dart
  ///     Aspect.multi<User>((u) sync* {
  ///       if (user.fullName!=null && user.fullName.isNotEmpty) {
  ///         yield user.fullName;
  ///       }
  ///       // The value is invalid but you still want to be notified
  ///       // In this case you may want to show 'Guest' in place of fullName
  ///       else yield Aspect.absent;
  ///
  ///       if(user.email!=null && user.email.isNotEmpty){
  ///         yield user.email;
  ///       }
  ///       // The value is invalid and you don't want to be notified
  ///       // In this case you won't be notified if the user sets there email to empty string, your widget will still show the old valid email
  ///       else yield Aspect.skip;
  ///
  ///       // Don't care what the value is, you'd rather do the validation each time yourself and rebuild your widget
  ///       // However, one [Object.==] comparison is still performed to avoid rebuilds for same values
  ///       yield user.nickname;
  ///     })
  /// ```
  /// **Note**: [Aspect.multi] and it's variants are only useful if you also use
  /// [AspectModifier]
  ///
  /// See
  ///  - [AspectModifier] - For a list of available aspect modifiers and their behaviours.
  ///  - [Aspect.indexed] - Efficient variant of this but requires predefined length.
  ///  - [Aspect.iterate] - Efficient variant of [Aspect.indexed] without
  ///    requiring predefined length.
  ///  - [Aspect.list] - Convenience balance of the above two.
  /// {@endtemplate}
  static _MultiAspect<A, T> multi<A, T>(
    MultiAspect<A, T> extract,
  ) =>
      _MultiAspect(extract);

  /// {@template Aspect.indexed}
  /// Indexed variant of [Aspect.multi] in which [index] will be supplied along [it].
  ///
  /// Note that two versions of [Aspect.indexed] with same [length] must return
  /// same element at [index] or one of [AspectModifier]
  ///
  /// ```dart
  ///     Object _userAspects(User user, {at}) {
  ///       switch(at ?? 0) {
  ///         case 0:
  ///           return user.firstName;
  ///         case 1:
  ///           return user.lastName;
  ///         default:
  ///           throw UnsupportedError('Unsupported index $at');
  ///       }
  ///     }
  /// ```
  /// {@endtemplate}
  static _IndexedAspect<A, T> indexed<A, T>(
          int length, IndexedAspect<A, T> extract) =>
      _IndexedAspect(length, extract);

  /// {@template Aspect.iterate}
  ///
  /// Variant of [Aspect.indexed] which produces all aspects of [T] unless [at] is
  /// specified, in which case only a single aspect at that index is required and
  /// is accessed as `_userAspects(user, 1).first` for the following example,
  /// which would yield `user.lastName` only.
  ///
  ///
  /// If [at] is not supported, this should throw.
  /// ```dart
  ///     Iterable<Object> _userAspects(User u, {at}) sync* {
  ///       const length = 3;
  ///       at ??= 0;
  ///       switch (at) {
  ///         case 0:
  ///           yield u.firstName;
  ///           continue lastName;
  ///         lastName: case 1:
  ///           yield u.lastName;
  ///           continue fullName;
  ///         fullName: case 2:
  ///           yield '${u.firstName} ${u.lastName}';
  ///           break;
  ///         case length:
  ///         default:
  ///           throw RangeError.range(at, 0, length - 1);
  ///      }
  ///     }
  /// ```
  /// {@endtemplate}
  static _RandomAccessIndexedAspect<A, T> iterate<A, T>(
          RandomAccessIndexedAspect<A, T> extract) =>
      _RandomAccessIndexedAspect(extract);

  /// {@template Aspect.list}
  /// Efficient Variant of [Aspect.indexed] whose length of aspects is calculated efficiently.
  ///
  /// ```dart
  ///     List<Object> _userAspects(User user) {
  ///       return [user.firstName, user.lastName];
  ///     }
  /// ```
  /// This also does a [length] comparison of extractors produced by [extract]
  /// for old and new values for an early bailout.
  ///
  /// Since [extract] should return a [List] and list always has efficient
  /// length. This enforces the extract to be efficient.
  /// {@endtemplate}
  static _EfficientLengthIndexedAspect<A, T> list<A, T>(
          int length, EfficientLengthIndexedAspect<A, T> extract) =>
      _EfficientLengthIndexedAspect(length, extract);

  /// Assuming [newValue] & [oldValue] is always different, return whether this
  /// aspect owner should be notified.
  bool shouldNotify(T newValue, T oldValue);

  /// {@template Aspect.of}
  /// Convenience method for when an [Aspect] is already known.
  ///
  /// Provide [rebuild] (defaults to `true`) if you want to control whether
  /// [context] should depend on the nearest enclosing [Inheritable] of [T].
  ///
  /// {@endtemplate}
  ///
  /// Contrary to similar static `of` methods, this is an instance method, since
  /// the return value depends on the [Aspect] implementation itself and it cannot be a generic
  /// parameter on the [Aspect] class. Since it would not allow using `Aspect<T>`
  /// in many places.
  ///
  /// Subclasses may also provide additional configuration via named parameters.
  /// Subclasses may also use the above doc template.
  Object of(BuildContext context, {bool rebuild = true});
}

class NoAspect<T> extends Aspect<T> {
  const NoAspect();

  @override
  int get hashCode => T.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is NoAspect<T>;
  }

  /// Always returns true
  @override
  shouldNotify(newValue, oldValue) => true;

  /// {@macro Aspect.of}
  ///
  ///
  /// {@template Aspect.of.defaultValue}
  ///
  /// Optionally provide [defaultValue] when there is no [Inheritable] of [T] in
  /// the given [context]. Otherwise this will return `null`
  /// {@endtemplate}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }
}

// TODO: detect and disallow closures. Prefer static/instance methods
class _SingleAspect<A, T> extends Aspect<T> {
  final SingleAspect<A, T> _extract;

  const _SingleAspect(this._extract) : assert(_extract != null);

  A call(T it) => _extract(it);

  @override
  int get hashCode => _extract.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _SingleAspect<A, T> && _extract == other._extract;
  }

  @override
  shouldNotify(newValue, oldValue) => this(newValue) != this(oldValue);

  /// {@macro Aspect.of}
  ///
  /// If this can handle `null` values, specify [handleNull] (defaults to `false`).
  ///
  /// If `null` is a valid value, specify [nullOk] (defaults to `true`).
  ///
  /// {@macro Aspect.of.defaultValue}
  @override
  A of(
    context, {
    rebuild = true,
    bool nullOk = true,
    bool handleNull = false,
    A defaultValue,
  }) {
    final T model =
        Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value;

    if (!nullOk && model == null) {
      throw StateError('Unsatisfied dependency Inheritable<$T> for $context');
    }

    return model == null && !handleNull ? defaultValue : this(model);
  }
}

/// {@template _RandomAccessIndexedAspect}
/// Efficient variant of [IndexedAspect] that doesn't need to know the length
/// of aspects and utilizes [RandomAccessIndexedAspect]
///
/// A convenient version of this is [EfficientLengthIndexedAspect]
/// {@endtemplate}
class _RandomAccessIndexedAspect<A, T> extends Aspect<T> {
  final RandomAccessIndexedAspect<A, T> _extract;

  const _RandomAccessIndexedAspect(this._extract);

  @override
  bool shouldNotify(T newValue, T oldValue) {
    int i = 0;
    return _extract(newValue).any((aspect) {
      return Aspect._handleAspectModifiers(
        aspect,
        () => _extract(oldValue, at: i++),
      );
    });
  }

  /// {@macro Aspect.of}
  ///
  /// {@macro Aspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }
}

/// {@template _EfficientLengthIndexedAspect}
/// Efficient variant of [IndexedAspect] which does a [length] comparison of
/// extractors for old and new values before extracting aspects.
///
/// This enforces the given [EfficientLengthIndexedAspect] to be actually efficient.
/// {@endtemplate}
class _EfficientLengthIndexedAspect<A, T> extends Aspect<T> {
  /// {@macro _IndexedAspect.length}
  final int length;
  final EfficientLengthIndexedAspect<A, T> _extractors;

  const _EfficientLengthIndexedAspect(this.length, this._extractors);

  @override
  bool shouldNotify(T newValue, T oldValue) {
    final newExtractors = _extractors(newValue);
    final oldExtractors = _extractors(oldValue);

    /// Early bailout for length mismatch
    if (length != newExtractors.length || length != oldExtractors.length) {
      return true;
    }

    int i = 0;
    return newExtractors.any((aspect) {
      return Aspect._handleAspectModifiers(
        aspect,
        () => oldExtractors[i++],
      );
    });
  }

  /// {@macro Aspect.of}
  ///
  /// {@macro Aspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }
}

/// {@template _IndexedAspect}
/// Efficient variant of [Aspect.multi] which utilizes [index] and [length] to
/// further reduce [IndexedAspect] executions.
///
/// The provided [IndexedAspect] is given a chance to be efficient by giving it
/// an index parameter.
///
/// A convenient version of this is [RandomAccessIndexedAspect]
/// {@endtemplate}
class _IndexedAspect<A, T> extends Aspect<T> {
  /// {@template _IndexedAspect.length}
  /// Maximum number of aspects this will extract
  ///
  /// Must satisfy `length >= 0`
  /// {@endtemplate}
  final int length;

  final IndexedAspect<A, T> _extract;

  const _IndexedAspect(this.length, this._extract) : assert(length >= 0);

  Iterable<A> call(T it) sync* {
    for (int i = 0; i < length; i++) {
      yield _extract(it, at: i);
    }
  }

  @override
  int get hashCode => _extract.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _IndexedAspect<A, T> &&
            length == other.length &&
            _extract == other._extract);
  }

  @override
  bool shouldNotify(T newValue, T oldValue) {
    int i = 0;
    return this(newValue).any((aspect) {
      return Aspect._handleAspectModifiers(
        aspect,
        () => _extract(oldValue, at: i++),
      );
    });
  }

  /// {@macro Aspect.of}
  ///
  /// {@macro Aspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }
}

class _MultiAspect<A, T> extends Aspect<T> {
  final MultiAspect<A, T> _extract;

  const _MultiAspect(this._extract);

  // Optimization: for an aspect that is iterable vs multi aspects, This is more
  // efficient as it redirects to the underlying _extract's generator if
  // possible while otherwise it would iterate through all elements, which is
  // what an iterable aspect is supposed to be vs multi aspects.
  // Maybe this isn't required? & maybe it is. Regardless a separate type helps
  // at least in distinguishing the intent.
  Iterable<A> call(T it) sync* {
    /// yield* forwards to the iterable's generator compared to yield which would
    /// cause a lazy iterable to be iterated once before yielding all elements at once
    yield* _extract(it);
  }

  @override
  int get hashCode => _extract.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _MultiAspect<A, T> && _extract == other._extract);
  }

  @override
  bool shouldNotify(T newValue, T oldValue) {
    final newAspects = this(newValue).toList(growable: false);
    final oldAspects = this(oldValue).toList(growable: false);

    if (newAspects.length != oldAspects.length) {
      return true;
    }

    int i = 0;
    return newAspects.any((aspect) {
      return Aspect._handleAspectModifiers(
        aspect,
        () => oldAspects[i++],
      );
    });
  }

  /// {@macro Aspect.of}
  ///
  /// {@macro Aspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }
}

/// Similar to [InheritedModel] provides a way to listen to certain aspects of
/// [T] via [SingleAspect].
///
/// This moves the decision of whether a dependent should be updated or not to
/// itself. As opposed to many other unconditional implementations of [InheritedWidget]
///
/// This uses a generic [Aspect] to determine whether a dependent should be notified.
///
/// You can provide any implementation of [Aspect] or use one of the built-ins
/// such as [Aspect.single], [Aspect.multi].
///
/// Note that, contrary to [InheritedModel], this does not allow depending
/// without specifying a valid aspect. A valid aspect is determined by
/// [isSupportedAspect].
class Inheritable<T> extends InheritedModel<Aspect<T>> {
  /// Get the nearest enclosing [Inheritable] for [T] to [context].
  static Inheritable<T> of<T>(BuildContext context,
      {Aspect<T> aspect, bool rebuild = true}) {
    if (!rebuild) {
      return context
          .getElementForInheritedWidgetOfExactType<Inheritable<T>>()
          ?.widget as Inheritable<T>;
    }

    return InheritedModel.inheritFrom<Inheritable<T>>(
      context,
      aspect: aspect,
    );
  }

  /// Structured or primitive value this holds.
  ///
  /// Prefer using an immutable object with correct implementations of
  /// [Object.==] and [Object.hashCode]
  final T value;

  /// Callback when a decedent requests that the [value] may be changed by [update]
  ///
  /// Owners of this widget may choose to implement this or
  /// completely ignore it. In which case all requests will be ignored as well.
  final void Function(UpdateAspect<T> update) onRequestUpdate;

  /// Create an access point in widget tree to supply [value] to descendants.
  ///
  /// Optionally specify [onRequestUpdate]
  const Inheritable({
    this.value,
    Key key,
    Widget child,
    this.onRequestUpdate,
  }) : super(key: key, child: child);

  @override
  bool isSupportedAspect(Object aspect) => aspect is Aspect<T>;

  @override
  bool updateShouldNotify(Inheritable<T> oldWidget) {
    return !identical(this, oldWidget) &&
        !identical(value, oldWidget.value) &&
        value != oldWidget.value;
  }

  @override
  bool updateShouldNotifyDependent(
      Inheritable<T> oldWidget, Set<Aspect<T>> dependencies) {
    return dependencies.any(
      (aspect) => aspect.shouldNotify(value, oldWidget.value),
    );
  }

  @override
  _InheritableElement<T> createElement() => _InheritableElement<T>(this);
}

/// Perform updates on [it]
typedef UpdateAspect<T> = void Function(T it);

class _InheritableElement<T> extends InheritedModelElement<Aspect<T>> {
  _InheritableElement(Inheritable<T> widget) : super(widget);

  @override
  Inheritable<T> get widget => super.widget as Inheritable<T>;

  void _updateAspect(UpdateAspect<T> update) {
    widget.onRequestUpdate?.call(update);
  }

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final Set<Aspect<T>> dependencies =
        getDependencies(dependent) as Set<Aspect<T>>;

    /// If [dependent] has already requested unconditional notifications,
    /// skip adding [aspect].
    if (dependencies != null && dependencies.isEmpty) return;

    /// [dependent] is requesting unconditional notifications.
    if (aspect == null) {
      InformationCollector collector;
      assert(() {
        collector = () sync* {
          yield DiagnosticsProperty<Widget>(
            'The ${dependent.widget.runtimeType} requesting notifications was',
            dependent.widget,
            style: DiagnosticsTreeStyle.dense,
          );
        };
        return true;
      }());
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: UnsupportedError('No aspect was specified'),
          stack: StackTrace.current,
          library: 'inherited aspect',
          context: ErrorDescription('While depending on Inheritable<$T>'),
          informationCollector: collector,
        ),
      );
      setDependencies(dependent, HashSet<Aspect<T>>());
    } else {
      assert(aspect is Aspect<T>);
      setDependencies(dependent,
          (dependencies ?? HashSet<Aspect<T>>())..add(aspect as Aspect<T>));
    }
  }
}

extension InheritAspectForState<W extends StatefulWidget, S extends State<W>>
    on S {
  /// {@macro BuildContextAspect.call}
  ///
  /// This should __not be__ used in [build] method. Use `context.aspect` instead.
  /// This is provided as a convenience to be used in other [State] instance
  /// methods except [build]
  _BuildContextAspect get aspect {
    assert(
      !context.debugDoingBuild,
      "Prefer using context.aspect instead of directly accessing aspect, this is to make sure you don't perform unnecessary rebuilds caused by a dependency on [Inheritable] of one of your descendants.",
    );
    return context.aspect;
  }
}

extension InheritAspect on BuildContext {
  /// {@macro BuildContextAspect.call}
  _BuildContextAspect get aspect {
    bool _isDisposed = false;
    return _BuildContextAspect(<R>(tryBlock) {
      assert(
        !_isDisposed,
        'Tried using same aspect multiple times, you may be holding a reference to [context.aspect] or [State.aspect]. Prefer using [context.aspect(<aspect>)] directly where used instead of holding a reference to it',
      );
      try {
        return tryBlock(this);
      } finally {
        _isDisposed = true;
      }
    });
  }
}

extension SumAspect<A, T> on PredicateAspect<T> {
  PredicateAspect<T> operator &(PredicateAspect<T> other) =>
      (it) => this(it) && other(it);
}

extension EitherAspect<A, T> on PredicateAspect<T> {
  PredicateAspect<T> operator |(PredicateAspect<T> other) =>
      (it) => this(it) || other(it);
}

extension AggregateAspect<A, T> on SingleAspect<A, T> {
  /// Create a new [Aspect] for [T] that requires this value as well
  /// as [other]
  MultiAspect<Object, T> operator +(SingleAspect<Object, T> other) {
    return (it) sync* {
      yield this(it);
      yield other(it);
    };
  }
}

extension TupleAspect<A1, A2, T> on SingleAspect<A1, T> {
  ///     (A1, A2)
  operator *(SingleAspect<A2, T> other) {}
}

extension AggregateAspects<A, T> on MultiAspect<A, T> {
  /// Create a new [Aspect] for [T] that requires all values from this as
  /// well as [other]
  ///
  ///  An interesting syntax would be able to return a tuple of all aspects
  ///
  /// ```dart
  ///     final fullName = context.aspect(User.fname + User.lname); // (String, String)
  ///     fullName.join(' ') // "fname lname"
  /// ```
  MultiAspect<Object, T> operator +(SingleAspect<Object, T> other) {
    final MultiAspect<A, T> that = this;
    return (it) sync* {
      yield* that(it);
      if (other is MultiAspect<Object, T>) {
        yield* other(it);
      } else {
        yield other(it);
      }
    };
  }
}

/// Short lived object that is used as a helper for a nicer api
class _BuildContextAspect {
  final R Function<R>(R Function(BuildContext context) tryBlock) _dispose;
  _BuildContextAspect(this._dispose);

  /// {@template BuildContextAspect.call}
  ///
  /// You immediately get access to aspect [A] of [T]
  ///
  /// Specify [handleNull], if you want to handle `null` values for
  /// [Inheritable.model] in [extract]. A `null` value could also mean unsatisfied
  /// dependency of [Inheritable].
  ///
  ///
  /// {@endtemplate}
  A call<A, T>(SingleAspect<A, T> extract,
      {bool handleNull = false, bool nullOk = true}) {
    return _dispose((context) {
      return _SingleAspect<A, T>(extract)
          .of(context, handleNull: handleNull, nullOk: nullOk);
    });
  }

  /// {@macro BuildContextAspect.call}
  A get<A, T>(SingleAspect<A, T> extract,
      {bool handleNull = false, bool nullOk = true}) {
    return call(extract, handleNull: handleNull, nullOk: nullOk);
  }

  ///{@template _BuildContextAspect.update}
  /// Perform updates on [T]. Widgets listening to aspects modified by [update]
  /// will automatically be notified. If there is no enclosing [Inheritable] for [T]
  /// this does nothing.
  ///
  /// If there are no widgets listening to modifications made by [update]
  /// nothing will happen.
  /// {@endtemplate}
  void update<T>(UpdateAspect<T> update) {
    return _dispose<void>((context) {
      (context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
              as _InheritableElement<T>)
          ?._updateAspect(update);
    });
  }

  /// {@macro _BuildContextAspect.update}
  void set<T>(UpdateAspect<T> update) => this.update(update);

  /// Contrary to [aspect] this gives you access to [T], since that's more type safe
  /// but only notifies you of changes when [predicate] returns `true`
  ///
  /// You can also specify [defaultValue] when there is no enclosing
  /// [Inheritable.model] of [T]
  T when<T>(PredicateAspect<T> predicate, {T defaultValue}) {
    return _dispose((context) {
      return Aspect.multi<Object, T>((it) sync* {
        yield predicate(it) ? Aspect.forceNotify : Aspect.skip;
      }).of(context, defaultValue: defaultValue);
    });
  }

  /// {@macro Aspect.indexed}
  T indexed<A, T>(int length, IndexedAspect<A, T> extract, {T defaultValue}) {
    return _dispose((context) {
      return Aspect.indexed(length, extract)
          .of(context, defaultValue: defaultValue);
    });
  }

  /// Most efficient variant of [multi] but least convenient [RandomAccessIndexedAspect]
  ///
  ///
  T iterate<A, T>(RandomAccessIndexedAspect<A, T> extract, {T defaultValue}) {
    return _dispose((context) {
      return _RandomAccessIndexedAspect(extract)
          .of(context, defaultValue: defaultValue);
    });
  }

  /// Efficiently extract list of aspects from nearest enclosing [Inheritable]
  /// of [T]
  T list<A, T>(
    int length,
    EfficientLengthIndexedAspect<A, T> extract, {
    T defaultValue,
  }) {
    return _dispose((context) {
      return _EfficientLengthIndexedAspect(length, extract)
          .of(context, defaultValue: defaultValue);
    });
  }

  /// {@template _BuildContextAspect.all}
  ///
  /// Unconditionally get notifications for [T].
  ///
  /// Optionally specify a [defaultValue].
  ///
  /// This is inefficient in that [T] is only resolved at runtime.
  /// So if you have many widgets depending on [T] unconditionally
  /// prefer using [InheritedWidget] directly or use constant variant of
  /// [NoAspect] for example
  ///
  ///     Inheritable.of<YourValue>(_context, aspect: const NoAspect<YourValue>())
  ///
  /// {@endtemplate}
  T all<T>({T defaultValue}) {
    return none(defaultValue: defaultValue);
  }

  /// {@macro _BuildContextAspect.all}
  T none<T>({T defaultValue}) {
    return _dispose((context) {
      return NoAspect<T>().of(context, defaultValue: defaultValue);
    });
  }

  /// There exists multiple different object supertypes that all can supply
  /// similar or same aspect, which [extractors] will try to get that aspect. The
  /// first extractor to do so should return the value and all remaining
  /// extractors will be skipped over. If an extractor doesn't find the correct
  /// aspect it should use [Aspect.skip] only to clarify it's intent.
  A from<A, T>(Iterable<SingleAspect<A, T>> extractors) {
    throw UnimplementedError();
  }

  /// Contrary to [aspect] this gives you access to [T], since that's more type safe
  T multi<A, T>(MultiAspect<A, T> extract, {T defaultValue}) {
    return _dispose((context) {
      return Aspect.multi(extract).of(context, defaultValue: defaultValue);
    });
  }
}

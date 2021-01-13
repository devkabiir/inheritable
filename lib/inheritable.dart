import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// Given [T] extract certain aspect [A] from [it] and return that.
///
/// You can return anything as long as it satisfies type [A]
typedef SingleAspect<A, T> = A Function(T it);

/// Given [T] return whether you should be notified or not.
typedef PredicateAspect<T> = bool Function({T prev, T next});

/// Given new and old values of [T], return whether to notify the dependent
typedef ShouldNotify<T> = bool Function(T newValue, T oldValue);

/// An aspect of [T]
abstract class InheritableAspect<T> with Diagnosticable {
  /// Uniquely identifying local key for this aspect.
  /// This used by [hashCode] and [==]. This allows [InheritableAspect] implementations to
  /// accept and hold closures in object instances and still have a unique
  /// object identity.
  ///
  /// Same key can also be used to replace an aspect used by a widget.
  Key get key;

  /// Debug-mode label for this aspect
  final String debugLabel;

  /// Constant constructor for subclasses
  const InheritableAspect([this.debugLabel]);

  /// {@macro InheritableAspect.none}
  static NoAspect<T> none<T>([Key key]) => NoAspect<T>(key);

  /// Create an aspect of [T] that is of type [A]
  ///
  /// The provided function will be provided [T] and it should take only 1
  /// aspect from it.
  static Aspect<A, T> single<A, T>(SingleAspect<A, T> extract, [Key key]) =>
      Aspect<A, T>(extract, key);

  /// Assuming [newValue] & [oldValue] is always different, return whether this
  /// aspect owner should be notified.
  bool shouldNotify(T newValue, T oldValue);

  /// {@template InheritableAspect.of}
  /// Convenience method for when an [InheritableAspect] is already known.
  ///
  /// Provide [rebuild] (defaults to `true`) if you want to control whether
  /// [context] should depend on the nearest enclosing [Inheritable] of [T].
  ///
  /// {@endtemplate}
  ///
  /// Contrary to similar static `of` methods, this is an instance method, since
  /// the return value depends on the [InheritableAspect] implementation itself and it cannot be a generic
  /// parameter on the [InheritableAspect] class. Since it would not allow using `InheritableAspect<T>`
  /// in many places.
  ///
  /// Subclasses may also provide additional configuration via named parameters.
  /// Subclasses may also use the above doc template.
  ///
  /// The default implementation returns the nearest enclosing [Inheritable] of
  /// [T] satisfying this aspect or `null`
  Object of(BuildContext context, {bool rebuild = true}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild);
  }

  @override
  get hashCode => hashValues(InheritableAspect, T, key);

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        (other is InheritableAspect<T> && key == other.key);
  }

  @override
  @visibleForOverriding
  debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        ObjectFlagProperty.has('implementation', runtimeType),
      )
      ..add(
        ObjectFlagProperty('debug-label', debugLabel, ifNull: 'no-debug-label'),
      )
      ..add(ObjectFlagProperty.has('inheritable', T))
      ..add(ObjectFlagProperty('key', key, ifNull: 'no-key'));
  }

  /// Ensure that this [InheritableAspect] has a valid [key]. This is to make
  /// sure aspects that are intended to behave differently using for same
  /// [BuildContext] don't override each other.
  ///
  /// You will be provided with a [fallback] key which usually will be
  /// [BuildContext.widget]'s key
  ///
  /// Implementers should return [this] if no change is necessary, otherwise
  /// return a copy of this with same configuration and provided [fallback] key.
  ///
  /// Consider the following example
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   final fname = context.aspect((User u)=> u.fname);
  ///   final lname = context.aspect((User u)=> u.lname);
  ///
  ///   return Text(fname + '' + lname);
  /// }
  /// ```
  ///
  /// Here the intended behaviour of both aspects is to rebuild the widget
  /// whenever any of them changes. However neither of them have sufficient
  /// identity differentiation, thus `lname` aspect will override `fname` and
  /// the widget will only re-build for `lname` changes.
  /// This is due to the fact that by default [InheritableAspect.key] is only
  /// unique among implementations, which most of them use closures and closures
  /// in dart are not canonicalizable, thus both `fname` and `lname` will have
  /// the same key.
  ///
  /// Alternative solution for this is to change above to following code
  ///
  /// ```dart
  /// // final fname = context.aspect((User u)=> u.fname);
  /// // final lname = context.aspect((User u)=> u.lname);
  /// final u = {
  ///   Aspect((User u) => u.fname),
  ///   Aspect((User u) => u.lname),
  /// }.some().value.of(context);
  ///
  /// // return Text(fname + '' + lname);
  /// return Text(u.fname + '' + u.lname);
  /// ```
  ///
  /// This will create a single new [InheritableAspect] which will cause a
  /// rebuild when either of `fname` & `lname` change. Because there is only 1
  /// aspect, there will be no conflicts of keys.
  ///
  /// This is similar to `copyWith` method pattern although intended only for internal use.
  @visibleForOverriding
  @protected
  InheritableAspect<T> ensureHasKey({Key fallback});
}

extension InheritableAspectChainable<T> on InheritableAspect<T> {
  /// {@template InheritableAspect.map}
  /// Use [mapper] to be notified for [T] when it
  /// s mapped value changes
  /// {@endtemplate}
  Aspect<R, T> map<R>(R Function(T) mapper, [Key key]) {
    return Aspect<R, T>.custom(
      (newValue, oldValue) =>
          shouldNotify(newValue, oldValue) &&
          mapper(newValue) != mapper(oldValue),
      mapper,
      key ?? this.key,
    );
  }

  /// {@template InheritableAspect.where}
  /// Use [predicate] whether to be notified for [T]
  /// {@endtemplate}
  Aspect<T, T> where(PredicateAspect<T> predicate, [Key key]) {
    return Aspect<T, T>.custom(
      (newValue, oldValue) =>
          shouldNotify(newValue, oldValue) &&
          predicate(next: newValue, prev: oldValue),
      (it) => it,
      key ?? this.key,
    );
  }

  /// Returns an [InheritableAspect] that notifies when [other] and `this` both say [shouldNotify].
  Aspect<T, T> operator &(InheritableAspect<T> other) => Aspect<T, T>.custom(
        (newValue, oldValue) =>
            shouldNotify(newValue, oldValue) &
            other.shouldNotify(newValue, oldValue),
        (it) => it,
        key,
      );

  /// Returns an [InheritableAspect] that notifies when either [other] or `this` say [shouldNotify].
  Aspect<T, T> operator |(InheritableAspect<T> other) => Aspect<T, T>.custom(
        (newValue, oldValue) =>
            shouldNotify(newValue, oldValue) |
            other.shouldNotify(newValue, oldValue),
        (it) => it,
        key,
      );
}

extension InheritableAspectIterable<T> on Iterable<InheritableAspect<T>> {
  /// Creates an aspect that notifies if _some_ of the aspects from this notify
  InheritableAspect<T> some() {
    InheritableAspect<T> value = first;
    skip(1).forEach((element) {
      value = value | element;
    });

    return value;
  }

  /// Creates an aspect that notifies only when _all_ of the aspects from this notify. You won't be
  /// notified if _some_ or none of the aspects have changed.
  ///
  /// __CAUTION__: This is very tricky to use.
  InheritableAspect<T> all() {
    InheritableAspect<T> value = first;
    skip(1).forEach((element) {
      value = value & element;
    });

    return value;
  }
}

/// {@template InheritableAspect.none}
/// Convenience [InheritableAspect] implementation to achieve similar effect as
/// that of [InheritedWidget]
///
/// This aspect notifies as soon as [T] changes
/// {@endtemplate}
class NoAspect<T> extends InheritableAspect<T> {
  @override
  final Key key;

  /// {@macro InheritableAspect.none}
  const NoAspect(this.key) : super('NoAspect');

  @override
  get hashCode => hashValues(NoAspect, T, key);

  @override
  operator ==(Object other) {
    return identical(this, other) || other is NoAspect<T> && key == other.key;
  }

  /// Always returns true
  @override
  shouldNotify(newValue, oldValue) => newValue != oldValue;

  /// {@macro InheritableAspect.of}
  ///
  ///
  /// {@template InheritableAspect.of.defaultValue}
  ///
  /// Optionally provide [defaultValue] when there is no [Inheritable] of [T] in
  /// the given [context]. Otherwise this will return `null`
  /// {@endtemplate}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    return key != null ? this : NoAspect(fallback);
  }
}

class _ValueAspect<T> extends InheritableAspect<T> {
  final InheritableAspect<T> delegate;

  @override
  get key => delegate.key;

  _ValueAspect(this.delegate) : super('ValueAspect of ${delegate.debugLabel}');

  @override
  bool shouldNotify(T newValue, T oldValue) {
    return delegate.shouldNotify(newValue, oldValue);
  }

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    return _ValueAspect(delegate.ensureHasKey(fallback: fallback));
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value ??
        defaultValue;
  }

  @override
  get hashCode => delegate.hashCode;

  @override
  operator ==(Object other) {
    return delegate == other;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
        .add(ObjectFlagProperty('delegate', delegate, ifNull: 'no-delegate'));
  }
}

class _ListenableAspect<T> extends InheritableAspect<T>
    implements ValueListenable<T>, ChangeNotifier {
  final notifier = ChangeNotifier();
  InheritableAspect<T> delegate;

  _ListenableAspect(this.delegate)
      : super('ListenableAspect of ${delegate.debugLabel}');

  @override
  get key => delegate.key;

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    delegate = delegate.ensureHasKey(fallback: fallback);
    return this;
  }

  @override
  get hashCode => delegate.hashCode;

  @override
  operator ==(Object other) {
    return delegate == other;
  }

  @override
  bool shouldNotify(T newValue, T oldValue) {
    if (delegate.shouldNotify(newValue, oldValue)) {
      _value = newValue;
      notifyListeners();
    }

    // Never cause a build
    return false;
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  ///
  /// Common use case include using inline with [ValueListenableBuilder]
  ///
  /// ```dart
  ///
  /// ValueListenableBuilder<User>(
  ///   listenable: Aspect((User u) => u.fname).listenable.of(context),
  ///  // <other-parameters>
  /// )
  /// ```
  ///
  /// Alternatively saving the listenable in a stateful variable such as as a
  /// member of [State] class
  ///
  /// ```dart
  /// final user = Aspect((User u) => u.fname).listenable;
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   user.addListener(maybeReBuildForFirstName);
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   user.removeListener(maybeReBuildForFirstName);
  ///   super.dispose();
  /// }
  ///
  /// void maybeReBuildForFirstName() {
  ///   if (user.value.fname.trim().isNotEmpty) {
  ///     setState(() {});
  ///   }
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Text(user.value.fname);
  /// }
  ///
  /// ```
  @override
  ValueListenable<T> of(context, {rebuild = true, T defaultValue}) {
    _value = Inheritable.of<T>(
          context,
          aspect: this,
          rebuild: rebuild,
        )?.value ??
        defaultValue;

    return this;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(ObjectFlagProperty('delegate', delegate, ifNull: 'no-delegate'))
      ..add(
        FlagProperty(
          'hasListeners',
          value: hasListeners,
          ifTrue: 'hasListeners',
          ifFalse: 'noListeners',
        ),
      )
      ..add(
        ObjectFlagProperty(
          'value',
          value,
          ifNull: 'no-value',
        ),
      );
  }

  @override
  void addListener(listener) {
    notifier.addListener(listener);
  }

  @override
  void dispose() {
    notifier.dispose();
  }

  @override
  bool get hasListeners => notifier.hasListeners;

  @override
  void notifyListeners() {
    notifier.notifyListeners();
  }

  @override
  void removeListener(listener) {
    notifier.removeListener(listener);
  }

  T _value;
  @override
  T get value => _value;
}

extension ValueAspect<T> on InheritableAspect<T> {
  /// Create an [InheritableAspect] that overrides the [InheritableAspect.of]
  /// implementation of [this] to return value of [T]
  _ValueAspect<T> get value => _ValueAspect(this);
}

extension ListenableAspect<T> on InheritableAspect<T> {
  /// Create a [ValueListenable] implementation of [InheritableAspect] that
  /// overrides the [InheritableAspect.shouldNotify] of [this] to notify it's
  /// listeners without causing a build for enclosing [BuildContext]
  ///
  /// The returned [InheritableAspect] should ideally be held onto by stateful
  /// variable.
  ///
  /// The [ChangeNotifier] won't fire unless the [of] method has satisfactory
  /// [Inheritable] of [T].
  _ListenableAspect<T> get listenable => _ListenableAspect(this);
}

class Aspect<A, T> extends InheritableAspect<T> {
  @override
  final Key key;
  final A Function(T) mapper;

  final ShouldNotify<T> _shouldNotifyImpl;

  const Aspect(this.mapper, [this.key])
      : _shouldNotifyImpl = null,
        super('ChainableAspect');

  const Aspect.custom(this._shouldNotifyImpl, this.mapper, [this.key])
      : assert(mapper != null),
        super('ChainableAspect.custom');

  bool _defaultShouldNotifyImpl(T newValue, T oldValue) {
    return mapper(newValue) != mapper(oldValue);
  }

  ShouldNotify<T> get shouldNotifyImpl =>
      _shouldNotifyImpl ?? _defaultShouldNotifyImpl;

  @override
  bool shouldNotify(T newValue, T oldValue) {
    return shouldNotifyImpl(newValue, oldValue);
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  @override
  A of(context, {rebuild = true, A defaultValue}) {
    final obj =
        Inheritable.of<T>(context, aspect: this, rebuild: rebuild)?.value;
    return obj is T ? mapper(obj) : defaultValue;
  }

  @override
  get hashCode => hashValues(Aspect, A, T, key);

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        (other is Aspect<A, T> && key == other.key);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      FlagProperty(
        'custom',
        value: _shouldNotifyImpl != null,
        ifTrue: 'is custom',
        ifFalse: 'is default',
      ),
    );
  }

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    return key != null
        ? this
        : _shouldNotifyImpl != null
            ? Aspect<A, T>.custom(
                _shouldNotifyImpl,
                mapper,
                fallback,
              )
            : Aspect<A, T>(mapper, fallback);
  }
}

extension ChainableAspectChianingFn<R, T> on Aspect<R, T> {
  /// Use [other] to map the already mapped value by [mapper] for notifications of [T]
  Aspect<RR, T> map<RR>(RR Function(R) other, [Key key]) {
    return Aspect<RR, T>(
      (t) => other(mapper(t)),
      key ?? this.key,
    );
  }

  /// {@macro InheritableAspect.where}
  Aspect<R, T> where(PredicateAspect<R> predicate, [Key key]) {
    return Aspect<R, T>.custom(
      (newValue, oldValue) =>
          shouldNotify(newValue, oldValue) &
          predicate(next: mapper(newValue), prev: mapper(oldValue)),
      mapper,
      key ?? this.key,
    );
  }

  /// Returns an [InheritableAspect] that notifies when [other] and `this` both say [shouldNotify].
  Aspect<R, T> operator &(InheritableAspect<T> other) => Aspect<R, T>.custom(
        (newValue, oldValue) =>
            shouldNotify(newValue, oldValue) &
            other.shouldNotify(newValue, oldValue),
        mapper,
        key,
      );

  /// Returns an [InheritableAspect] that notifies when either [other] or `this` say [shouldNotify].
  Aspect<R, T> operator |(InheritableAspect<T> other) => Aspect<R, T>.custom(
        (newValue, oldValue) =>
            shouldNotify(newValue, oldValue) |
            other.shouldNotify(newValue, oldValue),
        mapper,
        key,
      );
}

extension WhereAspect<T> on PredicateAspect<T> {
  Aspect<T, T> toChainable([Key key]) {
    return Aspect<T, T>.custom(
      (newValue, oldValue) => this(next: newValue, prev: oldValue),
      (it) => it,
      key,
    );
  }
}

/// Similar to [InheritedModel] provides a way to listen to certain aspects of
/// [T].
///
/// This moves the decision of whether a dependent should be updated or not to
/// itself. As opposed to many other unconditional implementations of [InheritedWidget]
///
/// This uses a generic [InheritableAspect] to determine whether a dependent should be notified.
///
/// You can provide any implementation of [InheritableAspect] or use one of the built-ins
/// such as [Aspect].
///
/// Note that, contrary to [InheritedModel], this does not allow depending
/// without specifying a valid aspect. A valid aspect is determined by
/// [isSupportedAspect].
class Inheritable<T> extends InheritedWidget {
  /// Get the nearest enclosing [Inheritable] for [T] to [context].
  ///
  /// {@template Inheritable.of.nullOk}
  ///
  /// Specify [nullOk] if `null` should be returned when the enclosing [context]
  /// does not have [Inheritable] of [T].
  ///
  /// {@endtemplate}
  static Inheritable<T> of<T>(BuildContext context,
      {InheritableAspect<T> aspect, bool rebuild = true, bool nullOk = true}) {
    if (aspect == null)
      throw UnsupportedError(
        'Cannot depend on Inheritable<$T> without specifying an aspect',
      );
    final result = _findInheritableSupportingAspect<T>(context, aspect);

    if (result == null) {
      if (!nullOk) {
        throw StateError(
          'Unsatisfied dependency Inheritable<$T> for ${context.widget} for aspect: $aspect',
        );
      } else {
        return null;
      }
    }

    if (rebuild) {
      context.dependOnInheritedElement(
        result,
        aspect: aspect.ensureHasKey(
          fallback: context.widget.key ??
              Key('InheritableAspect<$T>(${aspect.debugLabel})'),
        ),
      );
    }

    return result.widget;
  }

  static _InheritableElement<T> _findInheritableSupportingAspect<T>(
      BuildContext context, InheritableAspect<T> aspect) {
    if (context == null) return null;

    _InheritableElement<T> start;

    final inheritable =
        context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
            as _InheritableElement<T>;
    final mutable = context
            .getElementForInheritedWidgetOfExactType<_MutableInheritable<T>>()
        as _InheritableElement<T>;

    // If we have both implementations available, prefer the one with higher depth
    if (inheritable != null && mutable != null) {
      final mutableAboveInheritable = inheritable
          .getElementForInheritedWidgetOfExactType<_MutableInheritable<T>>();

      if (mutable == mutableAboveInheritable) {
        start = inheritable;
      } else {
        start = mutable;
      }
    } else if (inheritable != null && mutable == null) {
      start = inheritable;
    } else {
      start = mutable;
    }

    if (start == null) return null;

    if (start.widget.isSupportedAspect(aspect)) return start;

    // Go up ancestor, if there is any.
    /// Copied logic from [InheritedModel._findModels]
    // TODO: This might not actually be required, investigate, whether flutter devs added this on a fluke.
    Element parent;
    start.visitAncestorElements((Element ancestor) {
      parent = ancestor;
      return false;
    });

    return _findInheritableSupportingAspect<T>(parent, aspect);
  }

  /// Structured or primitive value this holds.
  ///
  /// Prefer using an immutable object with correct implementations of
  /// [Object.==] and [Object.hashCode]
  final T value;

  /// Create an access point in widget tree to supply [value] to descendants.
  ///
  /// Optionally specify [onRequestUpdate]
  const Inheritable({
    this.value,
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  /// Mutable variant of [Inheritable], users are to provide [update] to allow
  /// value to change.
  ///
  /// However dependents have no say whether a supplied update should be
  /// performed not.
  const factory Inheritable.mutable({
    @required ValueChanged<T> onChange,
    T value,
    Key key,
    Widget child,
  }) = _MutableInheritable<T>;

  /// Whether given [aspect] is supported by this. By default all non-null
  /// aspects are supported
  bool isSupportedAspect(InheritableAspect<T> aspect) =>
      aspect is InheritableAspect<T>;

  @override
  bool updateShouldNotify(Inheritable<T> oldWidget) {
    return value != oldWidget.value;
  }

  /// Similar to [InheritedModel.updateShouldNotifyDependent]
  bool updateShouldNotifyDependent(
      Inheritable<T> oldWidget, Iterable<InheritableAspect<T>> dependencies) {
    return dependencies.any(
      (aspect) => aspect.shouldNotify(value, oldWidget.value),
    );
  }

  @override
  _InheritableElement<T> createElement() => _InheritableElement<T>(this);
}

/// Mutable version on [Inheritable], allows dependents to make changes to the
/// [value] held by this
mixin MutableInheritable<T> on Inheritable<T> {
  /// Update the [value] to new value.
  ///
  /// Whether or not the update actually takes place is entirely up to the parent
  /// of this widget
  set value(T newValue);

  /// Get the nearest enclosing [MutableInheritable] of [T] from [context].
  ///
  /// This is useful for updating the [Inheritable.value].
  ///
  /// Note that this does not _depend_ on [MutableInheritable].
  ///
  /// If you're already depending on nearest enclosing [Inheritable] of [T] and the
  /// widget controlling nearest [MutableInheritable] of [T] _does_ update the value, you will be
  /// notified of the update.
  ///
  /// Returns `null` if there is none.
  ///
  /// Most commonly the following will be fine.
  ///
  /// ```dart
  /// MutableInheritable.of<User>(context).value = User('new', 'user');
  /// ```
  static MutableInheritable<T> of<T>(BuildContext context) {
    return context
        ?.getElementForInheritedWidgetOfExactType<_MutableInheritable<T>>()
        ?.widget as MutableInheritable<T>;
  }
}

class _MutableInheritable<T> extends Inheritable<T>
    implements MutableInheritable<T> {
  final ValueChanged<T> onChange;

  const _MutableInheritable({
    @required this.onChange,
    T value,
    Key key,
    Widget child,
  })  : assert(
          onChange != null,
          'Prefer creating an Inheritable if all changes will be rejected',
        ),
        super(value: value, key: key, child: child);
  @override
  set value(T newValue) {
    onChange(newValue);
  }
}

class _InheritableElement<T> extends InheritedElement {
  _InheritableElement(Inheritable<T> widget) : super(widget);

  @override
  Inheritable<T> get widget => super.widget as Inheritable<T>;

  bool removeAspect(Element dependent, InheritableAspect<T> aspect) {
    return removeKey(dependent, aspect?.key);
  }

  bool removeAllAspects(Element dependent, Set<InheritableAspect<T>> aspects) {
    return removeAllKeys(
      dependent,
      {...?aspects?.map((a) => a.key)},
    );
  }

  bool removeKey(Element dependent, Key key) {
    final Map<Key, InheritableAspect<T>> dependencies =
        getDependencies(dependent) as Map<Key, InheritableAspect<T>>;

    if (dependencies == null || dependencies.isEmpty || key == null)
      return false;

    final removed = dependencies.remove(key) != null;

    setDependencies(dependent, dependencies);

    return removed;
  }

  bool removeAllKeys(Element dependent, Set<Key> keys) {
    final Map<Key, InheritableAspect<T>> dependencies =
        getDependencies(dependent) as Map<Key, InheritableAspect<T>>;

    if (dependencies == null ||
        dependencies.isEmpty ||
        keys == null ||
        keys.isEmpty) return false;

    keys = Set.of(keys);

    dependencies.removeWhere((k, _) => keys.remove(k));

    setDependencies(dependent, dependencies);

    return keys.isEmpty;
  }

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final Map<Key, InheritableAspect<T>> dependencies =
        (getDependencies(dependent) as Map<Key, InheritableAspect<T>>) ??
            <Key, InheritableAspect<T>>{};

    if (aspect is InheritableAspect<T>) {
      // This allow replacing aspects by using same key
      dependencies[aspect.key] = aspect;
      setDependencies(dependent, dependencies);
    } else {
      /// [dependent] is requesting unconditional notifications.
      /// Disallow that.

      InformationCollector collector;
      assert(() {
        collector = () sync* {
          yield DiagnosticsProperty<Widget>(
            'The ${dependent.widget.runtimeType} requesting dependency was',
            dependent.widget,
            style: DiagnosticsTreeStyle.dense,
          );
        };
        return true;
      }());
      final error = FlutterErrorDetails(
        exception: UnsupportedError('No aspect was specified'),
        stack: StackTrace.current,
        library: 'inheritable',
        context: ErrorDescription('While depending on Inheritable<$T>'),
        informationCollector: collector,
      );
      throw error;
    }
  }

  @override
  void notifyDependent(Inheritable<T> oldWidget, Element dependent) {
    final Map<Key, InheritableAspect<T>> dependencies =
        getDependencies(dependent) as Map<Key, InheritableAspect<T>>;
    if (dependencies == null || dependencies.isEmpty) return;
    if (widget.updateShouldNotifyDependent(oldWidget, dependencies.values))
      dependent.didChangeDependencies();
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

/// Short lived object that is used as a helper for a nicer api
class _BuildContextAspect {
  final R Function<R>(R Function(BuildContext context) tryBlock) _dispose;
  _BuildContextAspect(this._dispose);

  /// {@template BuildContextAspect.call}
  ///
  /// You immediately get access to aspect [A] of [T]
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  ///
  /// {@endtemplate}
  A call<A, T>(SingleAspect<A, T> extract, {A defaultValue, Key key}) {
    return _dispose((context) {
      return Aspect<A, T>(extract, key).of(
        context,
        defaultValue: defaultValue,
      );
    });
  }

  /// Update the nearest enclosing [T] to [next].
  ///
  /// If there is no [MutableInheritable], this will have no effect.
  ///
  /// See: [MutableInheritable.of]
  void update<T>(T next) {
    return _dispose((context) {
      MutableInheritable.of<T>(context)?.value = next;
    });
  }

  /// {@macro BuildContextAspect.call}
  A get<A, T>(SingleAspect<A, T> extract, {A defaultValue, Key key}) {
    return call(extract, defaultValue: defaultValue, key: key);
  }

  /// Contrary to [aspect] this gives you access to [T], since that's more type safe
  /// but only notifies you of changes when [predicate] returns `true`
  ///
  /// You can also specify [defaultValue] when there is no enclosing
  /// [Inheritable.model] of [T]
  T where<T>(PredicateAspect<T> predicate, {T defaultValue, Key key}) {
    return _dispose((context) {
      return predicate.toChainable(key).of(context, defaultValue: defaultValue);
    });
  }

  bool remove<T>(InheritableAspect<T> aspect) {
    return _dispose((context) {
      final element =
          context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
              as _InheritableElement<T>;
      return element?.removeAspect(context as Element, aspect) ?? false;
    });
  }

  bool removeAll<T>(Set<InheritableAspect<T>> aspects) {
    return _dispose((context) {
      final element =
          context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
              as _InheritableElement<T>;
      return element?.removeAllAspects(context as Element, aspects) ?? false;
    });
  }

  bool removeKey<T>(Key key) {
    return _dispose((context) {
      final element =
          context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
              as _InheritableElement<T>;
      return element?.removeKey(context as Element, key) ?? false;
    });
  }

  bool removeAllKeys<T>(Set<Key> keys) {
    return _dispose((context) {
      final element =
          context.getElementForInheritedWidgetOfExactType<Inheritable<T>>()
              as _InheritableElement<T>;
      return element?.removeAllKeys(context as Element, keys) ?? false;
    });
  }

  /// {@template _BuildContextAspect.none}
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
  ///     Inheritable.of<YourValue>(context, aspect: const NoAspect<YourValue>())
  ///
  /// {@endtemplate}
  T none<T>({T defaultValue, Key key}) {
    return _dispose((context) {
      return InheritableAspect.none<T>(key).of(
        context,
        defaultValue: defaultValue,
      );
    });
  }
}

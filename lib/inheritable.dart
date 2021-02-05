import 'dart:collection';
import 'dart:core';
import 'dart:core' as core;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// Given [T] extract certain aspect [A] from [it] and return that.
///
/// You can return anything as long as it satisfies type [A]
typedef ExtractAspect<A, T> = A Function(T it);

/// Given [T] return whether you should be notified or not.
typedef PredicateAspect<T> = bool Function({T prev, T next});

/// Provides a default implementation of [DependableAspect.didUpdateWidget]
mixin ShouldNotifyAspect<A, T> on DependableAspect<T> {
  @override
  didUpdateWidget({next, prev}) {
    return shouldNotify(next.valueFor<A>(this), prev.valueFor<A>(this));
  }

  /// Assuming [newValue] & [oldValue] is always different, return whether this
  /// aspect owner should be notified.
  bool shouldNotify(A newValue, A oldValue);
}

/// Adds static return type [A] to the [of] method.
///
/// Provide a convenient [transform] method for external use.
mixin TransformingAspect<A, T> on InheritableAspect<T> {
  /// Given [value], transform it into usable form
  A transform(T value);

  @override
  A of(BuildContext context, {rebuild = true});
}

/// An [InheritableAspect] that allows providing a defaultValue in it's [of] method
mixin DefaultAspectofContext<A, T> on TransformingAspect<A, T> {
  /// {@macro InheritableAspect.of}
  ///
  /// {@template InheritableAspect.of.defaultValue}
  ///
  /// Optionally provide [defaultValue] to use instead of returning `null` when
  /// no value could be produced.
  /// {@endtemplate}
  @override
  A of(BuildContext context, {rebuild = true, A defaultValue});
}

abstract class AspectOverride<A, T> {
  /// Value which will be provided by [Inheritable] of [T]
  final A override;

  /// Constant constructor for sub-classes
  const AspectOverride.constant(this.override);

  /// Override the given [aspect] to always produce [value]
  const factory AspectOverride(InheritableAspect<T> aspect, A value) =
      _AspectOverrideByEquality<A, T>;

  /// Override any [InheritableAspect] of [T] that has the same [key].
  ///
  /// It is also possible to override [AspectMutation] by specifying a matching
  /// [key] and a [ValueChanged] override.
  ///
  /// In case the [key] is used to match a [AspectMutation], [mutation] must
  /// also be `true`.
  const factory AspectOverride.key(Key key, A override, {bool mutation}) =
      _AspectOverrideByKey<A, T>;

  /// Override [onMutate] for [aspect]
  static AspectOverride<ValueChanged<T>, T> mutation<T>(
          MutableInheritableAspect<T> aspect, ValueChanged<T> onMutate) =>
      _AspectOverrideMutation(aspect, onMutate);

  @core.override
  @visibleForOverriding
  get hashCode;

  @core.override
  @visibleForOverriding
  operator ==(Object other);
}

class _AspectOverrideMutation<T, A extends ValueChanged<T>>
    extends AspectOverride<A, T> {
  /// [InheritableAspect] to override
  final InheritableAspect<T> aspect;

  const _AspectOverrideMutation(this.aspect, A override)
      : assert(aspect != null),
        super.constant(override);

  @override
  get hashCode => aspect.hashCode;

  @override
  operator ==(Object other) {
    return aspect == other;
  }
}

class _AspectOverrideByEquality<A, T> extends AspectOverride<A, T> {
  /// [InheritableAspect] to override
  final InheritableAspect<T> aspect;

  const _AspectOverrideByEquality(this.aspect, A override)
      : assert(aspect != null),
        assert(aspect is! MutableInheritableAspect,
            'Prefer using AspectOverride.mutation instead.'),
        super.constant(override);

  @override
  get hashCode => aspect.hashCode;

  @override
  operator ==(Object other) {
    return aspect == other;
  }
}

class _AspectOverrideByKey<A, T> extends AspectOverride<A, T> {
  /// Key by which to override [InheritableAspect]
  final Key key;

  /// Flag to specify whether [AspectMutation] is required.
  final bool mutation;

  const _AspectOverrideByKey(this.key, A override, {this.mutation = false})
      : assert(key != null),
        assert(mutation != null),
        super.constant(override);

  @override
  get hashCode => key.hashCode;

  @override
  operator ==(Object other) {
    return key == other ||
        (other is InheritableAspect<T> &&
            key == other.key &&
            (mutation == other is MutableInheritableAspect<T>));
  }
}

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
  static Aspect<A, T> extract<A, T>(ExtractAspect<A, T> extract, [Key key]) =>
      Aspect<A, T>(extract, key);

  /// Specify whether given [inheritable] satisfies this aspect.
  ///
  /// You can think of [satisfiedBy] as the "init" phase of depending on
  /// [inheritable] of [T]. For subsequent updates, [didUpdateWidget] is used instead.
  bool satisfiedBy(Inheritable<T> inheritable) => inheritable is Inheritable<T>;

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
  get hashCode => throw UnimplementedError('Try using EquatableAspect or '
      '@override get hashCode => hashValues(runtimeType, key);');

  @override
  operator ==(Object other) => throw UnimplementedError(
      'Try using EquatableAspect or '
      '@override operator ==(dynamic other) => identical(this, other) || (runtimeType == other.runtimeType && key == other.key);');

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
      ..add(ObjectFlagProperty('key', key,
          ifNull: 'no-key', ifPresent: key.toString()));
  }
}

/// Allow using `this` as a dependency, which means, dependent widgets will be
/// have option to rebuild whenever this aspect changes.
///
/// Most notable implementation is [Aspect] which is immutable dependency on an
/// [Inheritable] of [T]. On the contrary [Aspect.mutable]
mixin DependableAspect<T> on InheritableAspect<T> {
  /// Ensure that this [InheritableAspect] has a valid [key]. This is to make
  /// sure aspects that are intended to behave differently using for same
  /// [BuildContext] don't override each other.
  ///
  /// You will be provided with a [fallback] key which usually will be
  /// [BuildContext.widget]'s key. Implementations are expected to handle `null` [fallback] key.
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

  /// Called by [Inheritable] of [T] when it decides to notify it's dependents.
  /// This is only called after [Inheritable] of [T] has been updated at least
  /// once. For the first time, aka "init" phase, [satisfiedBy] is called instead.
  bool didUpdateWidget({Inheritable<T> next, Inheritable<T> prev});

  @override
  @visibleForOverriding
  debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      FlagProperty(
        'dependable',
        value: true,
        showName: true,
        ifFalse: 'non-dependable',
      ),
    );
  }
}

/// Support partially replacing certain fields of `this`
mixin ClonableAspect<T> on InheritableAspect<T> {
  /// Create a new instance of `this` aspect with the specified fields replaced.
  ///
  /// Implementations of this method are expected to return `this` if no fields
  /// are replaced.
  InheritableAspect<T> clone({Key key});
}

/// Provides default implementations for [Object.==] && [Object.hashCode].
///
///
/// This is separated out from [InheritableAspect] base class because,
/// requirement on internal library implementations of [Object.hashCode] &&
/// [Object.==] can be explicitly specified in the type-system.
///
/// This library internally uses [_hash] && [_equals] instead of
/// [Object.hashCode] && [Object.==] to force consistency.
abstract class EquatableAspect<T> extends InheritableAspect<T> {
  const EquatableAspect([String debugLabel]) : super(debugLabel);

  static final Expando<int> _cache = Expando('InheritableAspect.hashCode');

  int _hash() => _cache[this] ??= hashValues(runtimeType, key);
  bool _equals(dynamic other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType && key == other.key);

  @override
  int get hashCode => _hash();
  @override
  bool operator ==(Object other) => _equals(other);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
        .add(FlagProperty('equatable', value: true, ifTrue: 'isEquatable'));
  }
}

/// Delegates all methods of [InheritableAspect] to [delegate].
///
/// [Object.hashCode] and [Object.==] are not delegated.
mixin DelegatingAspect<T> on ClonableAspect<T> {
  /// [InheritableAspect] which is responsible for handling all invocations,
  /// unless overridden.
  InheritableAspect<T> get delegate;

  @override
  Key get key => delegate.key;

  @override
  bool satisfiedBy(Inheritable<T> inheritable) {
    return delegate.satisfiedBy(inheritable);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
        .add(StringProperty('delegate', delegate.toString(), quoted: false));
  }

  /// Convenience method to create a new copy of [delegate] with key. This is
  /// useful in [clone] implementations where [key] is always delegated to [delegate].
  ///
  /// This will throw [UnsupportedError] if [delegate] or [replacement] isn't [ClonableAspect]
  InheritableAspect<T> cloneDelegate(
      {Key key, InheritableAspect<T> replacement}) {
    if ([key, replacement].whereType<Object>().isEmpty) return delegate;

    final resolved = replacement ?? delegate;
    if (resolved is ClonableAspect<T>) return resolved.clone(key: key);

    throw UnsupportedError(
        'Resolved delegate is not ClonableAspect: $resolved');
  }

  @override
  DelegatingAspect<T> clone({Key key, InheritableAspect<T> delegate});

  @override
  of(context, {rebuild = true}) =>
      throw UnimplementedError('InheritableAspect.of must not be delegated');
}

mixin PreDelegatingAspect<T> on DelegatingAspect<T> {
  /// Predicate that is given priority over [delegate.satisfiedBy]
  bool predicate(Inheritable<T> inheritable);

  @override
  bool satisfiedBy(Inheritable<T> inheritable) {
    return predicate(inheritable) && super.satisfiedBy(inheritable);
  }
}

mixin PostDelegatingAspect<T> on DelegatingAspect<T> {
  /// Predicate that is evaluated _after_ [delegate.satisfiedBy]
  bool predicate(Inheritable<T> inheritable);

  @override
  bool satisfiedBy(Inheritable<T> inheritable) {
    return super.satisfiedBy(inheritable) && predicate(inheritable);
  }
}

/// Delegates [didUpdateWidget] to [delegate] only when [predicate] is satisfied.
///
/// In case [delegate] isn't [DependableAspect], [didUpdateWidget] will always
/// return `false`.
mixin DelegatingDependableAspect<T>
    on DependableAspect<T>, DelegatingAspect<T> {
  /// Determine whether [inheritable] satisfies `this` for each
  /// [didUpdateWidget] invocation.
  bool predicate(Inheritable<T> inheritable) => true;

  @override
  bool didUpdateWidget({Inheritable<T> next, Inheritable<T> prev}) {
    if (predicate(next)) {
      final dynamic delegate = this.delegate;

      return delegate is DependableAspect<T> &&
          delegate.didUpdateWidget(next: next, prev: prev);
    }

    return false;
  }

  @override
  DelegatingAspect<T> ensureHasKey({Key fallback}) {
    final dynamic delegate = this.delegate;
    if (delegate is DependableAspect<T>)
      return clone(delegate: delegate.ensureHasKey(fallback: fallback));

    return clone(key: key ?? fallback);
  }

  /// Convenience method to create a new copy of [delegate] with key. This is
  /// useful in [clone] implementations where [key] is always delegated to [delegate].
  InheritableAspect<T> ensureDelegateHasKey(
      [InheritableAspect<T> replacement, Key key]) {
    final dynamic delegate = replacement ?? this.delegate;
    if (delegate is DependableAspect<T>)
      return delegate.ensureHasKey(fallback: key);

    throw UnsupportedError('Delegate is not DependableAspect: $delegate');
  }
}

typedef InheritableAspectSatisfied<T> = bool Function(
    Inheritable<T> inheritable);

class _ByInheritableAspect<A, T> extends EquatableAspect<T>
    with
        ClonableAspect<T>,
        DelegatingAspect<T>,
        DependableAspect<T>,
        PreDelegatingAspect<T>,
        DelegatingDependableAspect<T>,
        TransformingAspect<A, T> {
  @override
  final InheritableAspect<T> delegate;
  final InheritableAspectSatisfied<T> _predicate;

  _ByInheritableAspect(this.delegate, this._predicate)
      : assert(delegate != null),
        assert(_predicate != null),
        super('_ByInheritableAspect of ${delegate.debugLabel}');

  @override
  bool predicate(Inheritable<T> inheritable) {
    return _predicate(inheritable);
  }

  @override
  A transform(T value) {
    final dynamic delegate = this.delegate;
    if (delegate is TransformingAspect<A, T>) return delegate.transform(value);

    throw UnsupportedError('Delegate does not support [transform]');
  }

  @override
  A of(BuildContext context, {bool rebuild = true}) {
    final dynamic result =
        Inheritable.of(context, aspect: this, rebuild: rebuild)
            ?.valueFor(delegate);
    if (result is A || result == null) return result as A;

    throw UnsupportedError(
        'Expected delegate to produce a value of type $A but instead got `${result.runtimeType}`');
  }

  @override
  _ByInheritableAspect<A, T> clone({
    Key key,
    InheritableAspect<T> delegate,
    InheritableAspectSatisfied<T> predicate,
  }) {
    if ([key, delegate, predicate].whereType<Object>().isEmpty) return this;

    return _ByInheritableAspect(
      ensureDelegateHasKey(delegate, key),
      predicate ?? _predicate,
    );
  }
}

extension ByPredicateAspect<T> on InheritableAspect<T> {
  /// {@template InheritableAspect.by}
  /// Add a pre-condition to choosing the correct [Inheritable] of [T] when
  /// are multiple [Inheritable] of [T] in the enclosing context.
  ///
  /// For example, If there exists an overriding-hierarchy for `String` such that
  /// ```dart
  /// Inheritable<String>(
  ///   key: Key('my-key'),
  ///   value: 'A',
  ///   child: Inheritable<String>(
  ///     value: 'B',
  ///     child: MyWidget(),
  ///   )
  /// )
  /// ```
  ///
  /// Ordinarily, value `'B'` overrides value `'A'`, but it can be accessed and
  /// depended upon using following construct.
  ///
  /// ```dart
  /// final result = aspect.by((w) => w.key == 'my-key');
  /// ```
  ///
  /// Here [by] runs on the [Inheritable] itself whereas other similar constructs run
  /// on [Inheritable.value].
  ///
  /// {@endtemplate}
  InheritableAspect<T> by(InheritableAspectSatisfied<T> fn) {
    return _ByInheritableAspect<T, T>(this, fn);
  }
}

extension ByPredicateTypedAspect<A, T> on TransformingAspect<A, T> {
  /// {@macro InheritableAspect.by}
  TransformingAspect<A, T> by(InheritableAspectSatisfied<T> fn) {
    return _ByInheritableAspect<A, T>(this, fn);
  }
}

extension InheritableAspectChainable<T> on DependableAspect<T> {
  /// {@template InheritableAspect.map}
  /// Use [mapper] to be notified for [T] when it
  /// s mapped value changes
  /// {@endtemplate}
  Aspect<R, T> map<R>(R Function(T) mapper, [Key key]) {
    return Aspect<R, T>._(
      ({next, prev, aspect}) =>
          didUpdateWidget(prev: prev, next: next) &&
          next.valueFor(aspect, mapper) != prev.valueFor(aspect, mapper),
      mapper,
      key ?? this.key,
    );
  }

  Aspect<T, T> withPatch(T Function(T) patch, [Key key]) {
    return Aspect._(
      ({next, prev, aspect}) => didUpdateWidget(prev: prev, next: next),
      (t) => t,
      key ?? this.key,
      null,
      patch,
    );
  }

  /// Add default value to this, if no satisfiable [Inheritable] of [T] can be found
  Aspect<T, T> withDefault(T value, [Key key]) {
    return Aspect._(
      ({next, prev, aspect}) => didUpdateWidget(prev: prev, next: next),
      (t) => t,
      key ?? this.key,
      (_) => value,
    );
  }

  /// Add default value to this based on provided [BuildContext], if no satisfiable [Inheritable] of [T] can be found.
  Aspect<T, T> withDefaultFor(DefaultInheritableAspectOfContext<T> fn,
      [Key key]) {
    return Aspect._(
      ({next, prev, aspect}) => didUpdateWidget(prev: prev, next: next),
      (t) => t,
      key ?? this.key,
      fn,
    );
  }

  /// {@template InheritableAspect.where}
  /// Use [predicate] whether to be notified for [T]
  /// {@endtemplate}
  Aspect<T, T> where(PredicateAspect<T> predicate, [Key key]) {
    return Aspect<T, T>._(
      ({next, prev, aspect}) =>
          didUpdateWidget(prev: prev, next: next) &&
          predicate(next: next.valueFor(aspect), prev: prev.valueFor(aspect)),
      (it) => it,
      key ?? this.key,
    );
  }

  /// {@template InheritableAspect.whereType}
  /// Notify for [T] only if it's also [R]
  /// {@endtemplate}
  Aspect<R, T> whereType<R extends T>([Key key]) {
    return Aspect._(
      ({prev, next, aspect}) =>
          didUpdateWidget(prev: prev, next: next) &&
          (next.valueFor(aspect) is R),
      (t) => AspectChianingFn._whereType<T, T, R>(t, (t) => t),
      key ?? this.key,
    );
  }

  /// {@template InheritableAspect.override}
  /// Override value produced by this with [value]
  /// {@endtemplate}
  AspectOverride<T, T> operator >(T value) {
    return AspectOverride(this, value);
  }

  /// {@template InheritableAspect.override.mutation}
  /// Override mutation callback for this. This overrides the [onMutate]
  /// for [Inheritab.mutable] or [Inheritable.onMutate] for any aspects
  /// identified by `this.key`.
  ///
  /// The created [AspectOverride] depends on `this.key`, which if `null` it will throw.
  /// {@endtemplate}
  AspectOverride<ValueChanged<T>, T> operator <(ValueChanged<T> onMutate) {
    return AspectOverride.key(key, onMutate, mutation: true);
  }

  /// Returns an [InheritableAspect] that notifies when [other] and `this` both say [shouldNotify].
  Aspect<T, T> operator &(DependableAspect<T> other) => Aspect<T, T>._(
        ({prev, next, aspect}) =>
            didUpdateWidget(next: next, prev: prev) &
            other.didUpdateWidget(next: next, prev: prev),
        (it) => it,
        key,
      );

  /// Returns an [InheritableAspect] that notifies when either [other] or `this` say [shouldNotify].
  Aspect<T, T> operator |(DependableAspect<T> other) => Aspect<T, T>._(
        ({next, prev, aspect}) =>
            didUpdateWidget(next: next, prev: prev) |
            other.didUpdateWidget(next: next, prev: prev),
        (it) => it,
        key,
      );
}

extension InheritableAspectIterable<T> on Iterable<DependableAspect<T>> {
  /// Creates an aspect that notifies if _some_ of the aspects from this notify
  _ValueAspect<T> some() {
    DependableAspect<T> value = first;
    skip(1).forEach((element) {
      value = value | element;
    });

    return value.value;
  }

  /// Creates an aspect that notifies only when _all_ of the aspects from this notify. You won't be
  /// notified if _some_ or none of the aspects have changed.
  ///
  /// __CAUTION__: This is very tricky to use.
  _ValueAspect<T> all() {
    DependableAspect<T> value = first;
    skip(1).forEach((element) {
      value = value & element;
    });

    return value.value;
  }
}

/// {@template InheritableAspect.none}
/// Convenience [InheritableAspect] implementation to achieve similar effect as
/// that of [InheritedWidget]
///
/// This aspect notifies as soon as [T] changes
/// {@endtemplate}
class NoAspect<T> extends EquatableAspect<T>
    with
        DependableAspect<T>,
        ShouldNotifyAspect<T, T>,
        ClonableAspect<T>,
        TransformingAspect<T, T>,
        DefaultAspectofContext<T, T> {
  @override
  final Key key;

  /// {@macro InheritableAspect.none}
  const NoAspect(this.key) : super('NoAspect');

  /// Always returns true
  @override
  shouldNotify(newValue, oldValue) => newValue != oldValue;

  @override
  T transform(T value) {
    return value;
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)
            ?.valueFor<T>(this) ??
        defaultValue;
  }

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    return key != null ? this : NoAspect(fallback);
  }

  @override
  InheritableAspect<T> clone({Key key}) {
    return NoAspect<T>(key);
  }
}

class _ValueAspect<T> extends EquatableAspect<T>
    with
        DependableAspect<T>,
        ClonableAspect<T>,
        DelegatingAspect<T>,
        TransformingAspect<T, T>,
        DelegatingDependableAspect<T> {
  @override
  final InheritableAspect<T> delegate;

  _ValueAspect(this.delegate) : super('ValueAspect of ${delegate.debugLabel}');

  @override
  DelegatingAspect<T> clone({Key key, InheritableAspect<T> delegate}) {
    return _ValueAspect(cloneDelegate(replacement: delegate, key: key));
  }

  @override
  T transform(T value) {
    return value;
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  @override
  T of(context, {rebuild = true, T defaultValue}) {
    return Inheritable.of<T>(context, aspect: this, rebuild: rebuild)
            ?.valueFor<T>(this) ??
        defaultValue;
  }
}

class _ListenableAspect<T> extends EquatableAspect<T>
    with
        ClonableAspect<T>,
        DependableAspect<T>,
        DelegatingAspect<T>,
        DelegatingDependableAspect<T>,
        TransformingAspect<ValueListenable<T>, T>
    implements ValueListenable<T>, ChangeNotifier {
  final notifier = ChangeNotifier();
  InheritableAspect<T> _delegate;

  @override
  InheritableAspect<T> get delegate => _delegate;

  _ListenableAspect(this._delegate)
      : super('ListenableAspect of ${_delegate.debugLabel}');

  @override
  DelegatingAspect<T> ensureHasKey({Key fallback}) {
    _delegate = ensureDelegateHasKey(null, fallback);
    return this;
  }

  @override
  bool didUpdateWidget({prev, next}) {
    if (super.didUpdateWidget(prev: prev, next: next)) {
      _value = next.valueFor<T>(this);
      notifyListeners();
    }

    // Never cause a build
    return false;
  }

  @override
  transform(T value) {
    return this;
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
        )?.valueFor<T>(this) ??
        defaultValue;

    return this;
  }

  @override
  DelegatingAspect<T> clone({Key key, InheritableAspect<T> delegate}) {
    _delegate = cloneDelegate(key: key, replacement: delegate);

    return this;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        FlagProperty(
          'notifier.disposed',
          value: _isDisposed,
          ifFalse: 'notifier not disposed',
        ),
      )
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

  bool _isDisposed = false;
  @override
  void dispose() {
    assert((() => _isDisposed = true)());

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

typedef DefaultInheritableAspectOfContext<A> = A Function(BuildContext context);

typedef DidUpdateWidget<T> = bool Function({
  Inheritable<T> next,
  Inheritable<T> prev,
  InheritableAspect<T> aspect,
});

/// An Aspect that allows updating it's value.
/// The resultant type is plain base type [InheritableAspect]. This is due to
/// the fact that once an aspect is converted in to this type, it can no longer
/// be used for it's original purpose or can it be?
mixin MutableInheritableAspect<T> on InheritableAspect<T> {
  /// Given [inheritable], return what the next [Inheritable] of [T] should be.
  T mutate(MutableInheritable<T> inheritable);

  /// Apply [mutate] to nearest enclosing [Inheritable.mutable] of [T] to given [context]
  void apply(BuildContext context);

  @override
  of(context, {rebuild = true}) {
    throw UnsupportedError(
      'Cannot use MutableInheritableAspect as dependency. '
      'If you meant to use it as mutation use [apply]. '
      'Only InheritableAspects that are not MutableInheritableAspect can be used as dependency.',
    );
  }
}

extension ReplaceMutableInheritable<T> on InheritableAspect<T> {
  /// Creates an [AspectMutation] that unconditionally requests [T] to be
  /// replaced by [next].
  ///
  /// The newly created [AspectMutation] uses `this.key`, which means it is
  /// possible to override it by using `AspectOverride.key`.
  AspectMutation<T> replace(T next) => AspectMutation((_) => next, key);
}

extension PatchMutableInheritable<A, T> on PatchableAspect<A, T> {
  /// Creates an [AspectMutation] that unconditionally requests [A] of [T] to be
  /// replaced by [next].
  ///
  /// The newly created [AspectMutation] uses `this.key`, which means it is
  /// possible to override it by using `AspectOverride.key`.
  AspectMutation<T> replace(A next) => AspectMutation((_) => patch(next), key);
}

// TODO: an Inheritable.mutable can be used to deny updates from certain
// aspects.
// For example Inheritable.mutable.isSupportedAspect would return true but when
// requesting update, it wouldn't do anything

/// Given [inheritable] return the next [Inheritable.valueFor] of [T]
typedef InheritableMutation<T> = T Function(Inheritable<T> inheritable);

class AspectMutation<T> extends EquatableAspect<T>
    with ClonableAspect<T>, MutableInheritableAspect<T> {
  @override
  final Key key;

  final InheritableMutation<T> mutation;

  const AspectMutation(this.mutation, [this.key])
      : assert(mutation != null),
        super('AspectMutation');

  @override
  T mutate(Inheritable<T> inheritable) {
    return mutation(inheritable);
  }

  @override
  void apply(BuildContext context) {
    final inheritable =
        Inheritable.of<T>(context, aspect: this, rebuild: false);

    final ValueChanged<T> Function(T) _defaultTransform =
        inheritable is MutableInheritable<T> ? null : (_) => null;

    inheritable?.valueFor
        ?.call<ValueChanged<T>>(this, _defaultTransform)
        ?.call(mutate(inheritable));
  }

  @override
  AspectMutation<T> clone({Key key, InheritableMutation<T> mutation}) {
    if ([key, mutation].whereType<Object>().isEmpty) return this;

    return AspectMutation(mutation ?? this.mutation, key ?? this.key);
  }
}

mixin PatchableAspect<A, T> on TransformingAspect<A, T> {
  /// Given a new [A] of [T], return the patched [T]
  T patch(A next);
}

class Aspect<A, T> extends EquatableAspect<T>
    with
        ClonableAspect<T>,
        DependableAspect<T>,
        TransformingAspect<A, T>,
        PatchableAspect<A, T> {
  @override
  final Key key;
  final A Function(T) mapper;
  final T Function(A) _patch;
  final DidUpdateWidget<T> _didUpdateWidgetImpl;
  final DefaultInheritableAspectOfContext<A> _defaultValue;

  /// Create an [InheritableAspect] of [T] that depends on [Inheritable] of [T]
  /// for any changes of [A] produced by [fn].
  const Aspect(A Function(T) fn, [Key key]) : this._(null, fn, key, null);

  /// Create an aspect [A] of [T] using [transform],
  /// which can optionaly be later patched using [patch].
  const Aspect.patchable({
    @required T Function(A) patch,
    Key key,
    A Function(T) transform,
  }) : this._(null, transform, key, null, patch);

  const Aspect._(this._didUpdateWidgetImpl, this.mapper,
      [this.key, this._defaultValue, this._patch])
      : assert(mapper != null),
        super('Aspect');

  bool _defaultDidUpdateWidgetImpl(
      {Inheritable<T> next, Inheritable<T> prev, InheritableAspect<T> aspect}) {
    return next.valueFor<A>(aspect, mapper) != prev.valueFor<A>(aspect, mapper);
  }

  DidUpdateWidget<T> get didUpdateWidgetImpl =>
      _didUpdateWidgetImpl ?? _defaultDidUpdateWidgetImpl;

  @override
  bool didUpdateWidget({prev, next}) {
    return didUpdateWidgetImpl(next: next, prev: prev, aspect: this);
  }

  @override
  A transform(T value) {
    return mapper(value);
  }

  @override
  T patch(A next) {
    if (_patch != null) return _patch(next);

    throw StateError('This aspect is not Patchable');
  }

  /// {@macro InheritableAspect.of}
  ///
  /// {@macro InheritableAspect.of.defaultValue}
  @override
  A of(context, {rebuild = true, A defaultValue}) {
    final obj = Inheritable.of<T>(context, aspect: this, rebuild: rebuild)
        ?.valueFor(this, mapper);

    return obj ?? _defaultValue?.call(context) ?? defaultValue;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        FlagProperty(
          'chained',
          value: _didUpdateWidgetImpl != null,
          ifTrue: 'is chained',
          ifFalse: 'not chained',
        ),
      )
      ..add(
        FlagProperty(
          'defaultValue',
          value: _defaultValue != null,
          ifTrue: 'has default value',
          ifFalse: 'no default value',
        ),
      );
  }

  @override
  Aspect<A, T> clone({
    Key key,
    final A Function(T) mapper,
    final T Function(A) patch,
    final DidUpdateWidget<T> didUpdateWidget,
    final DefaultInheritableAspectOfContext<A> defaultValue,
  }) {
    if ([key, mapper, patch, didUpdateWidget, defaultValue]
        .whereType<Object>()
        .isEmpty) return this;

    return Aspect._(
      didUpdateWidget ?? didUpdateWidgetImpl,
      mapper ?? this.mapper,
      key ?? this.key,
      defaultValue ?? _defaultValue,
      patch ?? _patch,
    );
  }

  @override
  InheritableAspect<T> ensureHasKey({Key fallback}) {
    return key != null ? this : clone(key: fallback);
  }
}

// TODO: Extract out TransformingAspect applicable extension methods
extension AspectChianingFn<R, T> on Aspect<R, T> {
  /// Use [other] to map the already mapped value by [mapper] for notifications of [T]
  Aspect<RR, T> map<RR>(RR Function(R) other, [Key key]) {
    return Aspect<RR, T>._(
      null,
      (t) => other(mapper(t)),
      key ?? this.key,
      (_) => _defaultValue != null ? other?.call(_defaultValue?.call(_)) : null,
    );
  }

  /// Allow patching [R] of [T] using [patch]
  Aspect<R, T> withPatch(T Function(R) patch, [Key key]) {
    return clone(key: key, patch: patch);
  }

  /// Add default value to this, if no satisfiable [Inheritable] of [T] can be found
  Aspect<R, T> withDefault(R value, [Key key]) {
    return clone(key: key, defaultValue: (_) => value);
  }

  /// Add default value to this based on provided [BuildContext], if no satisfiable [Inheritable] of [T] can be found.
  Aspect<R, T> withDefaultFor(DefaultInheritableAspectOfContext<R> fn,
      [Key key]) {
    return clone(key: key, defaultValue: fn);
  }

  /// {@macro InheritableAspect.where}
  Aspect<R, T> where(PredicateAspect<R> predicate, [Key key]) {
    return clone(
      key: key,
      didUpdateWidget: ({next, prev, aspect}) =>
          didUpdateWidgetImpl(next: next, prev: prev, aspect: aspect) &
          predicate(
            next: next.valueFor(this, mapper),
            prev: prev.valueFor(this, mapper),
          ),
    );
  }

  static RR _whereType<T, R, RR extends R>(
      T value, ExtractAspect<R, T> mapper) {
    final mapped = mapper(value);

    if (mapped is RR) {
      return mapped;
    }

    return null;
  }

  /// {@macro InheritableAspect.whereType}
  Aspect<RR, T> whereType<RR extends R>([Key key]) {
    return Aspect<RR, T>._(
      ({next, prev, aspect}) =>
          didUpdateWidgetImpl(next: next, prev: prev, aspect: aspect) &
          (next is RR),
      (t) => _whereType<T, R, RR>(t, mapper),
      key ?? this.key,
      (_) => _defaultValue != null && R == RR ? _defaultValue(_) as RR : null,
    );
  }

  /// {@macro InheritableAspect.override}
  AspectOverride<R, T> operator >(R value) {
    return AspectOverride(this, value);
  }

  /// Returns an [InheritableAspect] that notifies when [other] and `this` both say [shouldNotify].
  Aspect<R, T> operator &(DependableAspect<T> other) => clone(
        didUpdateWidget: ({next, prev, aspect}) =>
            didUpdateWidgetImpl(next: next, prev: prev, aspect: aspect) &
            other.didUpdateWidget(next: next, prev: prev),
      );

  /// Returns an [InheritableAspect] that notifies when either [other] or `this` say [shouldNotify].
  Aspect<R, T> operator |(DependableAspect<T> other) => clone(
        didUpdateWidget: ({next, prev, aspect}) =>
            didUpdateWidgetImpl(next: next, prev: prev, aspect: aspect) |
            other.didUpdateWidget(next: next, prev: prev),
      );
}

typedef AspectWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T aspect,
  Widget child,
);

/// Convenience widget to get [aspect] as part of the [build] method
class AspectBuilder<A, T> extends StatelessWidget {
  /// Required aspect dependency of widget/s built by [builder]
  final TransformingAspect<A, T> aspect;

  /// Widget builder that get's [aspect] fed into it
  final AspectWidgetBuilder<A> builder;

  /// Child widget that doesn't depend on [aspect]
  final Widget child;

  /// Default value when [aspect] returns `null`
  final A defaultValue;

  /// Create a widget that provides [aspect] to it's decedents.
  ///
  /// Optionally specify [defaultValue]
  ///
  /// Example:
  /// ```dart
  /// AspectBuilder(
  ///   aspect: Aspect((User u) => u.fname),
  ///   builder: (context, fname) => Text(fname),
  /// )
  /// ```
  const AspectBuilder({
    @required this.aspect,
    @required this.builder,
    this.child,
    this.defaultValue,
    Key key,
  })  : assert(aspect != null),
        assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, aspect.of(context) ?? defaultValue, child);
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
  // TODO: if Inheritable is allowed to extend, provide Inheritable.inheriFrom
  static Inheritable<T> of<T>(
    BuildContext context, {
    InheritableAspect<T> aspect,
    bool rebuild = true,
    bool nullOk = true,
    bool mutable = false,
  }) {
    assert(mutable != null);
    if (aspect == null)
      throw UnsupportedError(
        'Cannot depend on Inheritable<$T> without specifying an aspect',
      );
    final result =
        _findInheritableSupportingAspect<T>(context, aspect, mutable: mutable);

    if (result == null) {
      if (!nullOk) {
        throw StateError(
          'Unsatisfied dependency Inheritable<$T> for ${context.widget} for aspect: $aspect',
        );
      } else {
        return null;
      }
    }

    assert(!rebuild || aspect is DependableAspect<T>,
        'Only DependableAspect can cause rebuilds');
    if (rebuild && aspect is DependableAspect<T>) {
      context.dependOnInheritedElement(
        result,
        aspect: aspect.ensureHasKey(
          fallback: context.widget.key ?? Key('InheritableAspect<$T>($aspect)'),
        ),
      );
    }

    return result.widget;
  }

  static _InheritableElement<T> _findEnclosingInheritableElement<T>(
      BuildContext context) {
    if (context == null) return null;

    _InheritableElement<T> result;

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
        result = inheritable;
      } else {
        result = mutable;
      }
    } else if (inheritable != null && mutable == null) {
      result = inheritable;
    } else {
      result = mutable;
    }

    return result;
  }

  static _InheritableElement<T> _findInheritableSupportingAspect<T>(
    BuildContext context,
    InheritableAspect<T> aspect, {
    bool mutable = false,
  }) {
    if (context == null) return null;

    final element = _findEnclosingInheritableElement<T>(context);

    if (element == null) return null;

    if (element.widget.isSupportedAspect(aspect) &&
        (!mutable || element.widget is MutableInheritable<T>)) return element;

    // Go up ancestor, if there is any.
    /// Copied logic from [InheritedModel._findModels]
    // TODO: This might not actually be required, investigate, whether flutter devs added this on a fluke.
    Element parent;
    element.visitAncestorElements((Element ancestor) {
      parent = ancestor;
      return false;
    });

    return _findInheritableSupportingAspect<T>(
      parent,
      aspect,
      mutable: mutable,
    );
  }

  static Set<Object> newOverridesSet<T>(Set<AspectOverride<Object, T>> other) {
    if (other == null) return {};
    bool hashKeysOnly;
    return HashSet(
      isValidKey: (obj) => obj != null,
      hashCode: (Object obj) {
        // after the first time, we don't care for other objects
        hashKeysOnly ??= obj is _AspectOverrideByKey;
        if (hashKeysOnly && obj is InheritableAspect<T>) {
          return obj.key.hashCode;
        }

        return obj.hashCode;
      },
      equals: (Object a, Object b) => a == b,
    )..addAll(other);
  }

  /// Structured or primitive value this holds.
  ///
  /// Prefer using an immutable object with correct implementations of
  /// [Object.==] and [Object.hashCode]
  final T _value;

  final Set<Object> _overrides;

  /// Ant overrides for this [Inheritable]
  Set<AspectOverride<Object, T>> get overrides => Set.from(_overrides);

  const Inheritable._({
    T value,
    Key key,
    Set<Object> overrides,
    Widget child,
  })  : _value = value,
        _overrides = overrides ?? const {},
        super(key: key, child: child ?? const SizedBox.shrink());

  /// Create an access point in widget tree to supply [value] to descendants.
  ///
  /// Optionally specify [onRequestUpdate]
  const Inheritable({
    T value,
    Key key,
    Widget child,
  }) : this._(
          value: value,
          key: key,
          overrides: const {},
          child: child,
        );

  /// Convenience method to supply multiple [Inheritable]s holding different
  /// values to [child]
  ///
  /// For example supply both a `User` and their `UserPreferences` to child.
  ///
  /// ```dart
  /// Inheritable.supply(
  ///   inheritables: [
  ///     Inheritable<User>(value: _currentUser),
  ///     Inheritable<UserPreferences>(value: _preferences),
  ///   ]
  ///   child: MyWidget(),
  /// )
  /// ```
  ///
  /// It is possible to use [Inheritable.mutable] or [Inheritable.override] as well.
  ///
  ///
  /// This is equivalent to
  /// ```dart
  /// Inheritable<A>(
  ///   value: A(),
  ///   child: Inheritable<B>(
  ///     value: B(),
  ///     child: MyWidget(),
  ///   )
  /// )
  /// ```
  ///
  /// Optionally specify [strict] (defaults to `true`) to verify all [inheritables] can be uniquely
  /// used as dependency. This checks the `runtimeType` and `key` combination of
  /// all inheritables, upon finding a duplicate, this will throw. It is
  /// primarily used to detect un-intentional [Inheritable] overrides, as well
  /// as allowing two [Inheritable]s of the same type to co-exist.
  ///
  /// [strict] is only used in debug mode.

  static Widget supply({
    List<Inheritable<Object>> inheritables,
    Widget child,
    bool strict = true,
  }) {
    Widget result = child;
    Map<Type, Set<Key>> _;

    // TODO: Add further optimizations to Inheritable.supply
    for (var inheritable in inheritables.reversed) {
      assert(!strict ||
          (() {
            _ ??= <Type, Set<Key>>{};
            final type = inheritable.runtimeType;
            final key = inheritable.key;
            final keys = _[type] ??= HashSet(
              equals: (a, b) => a == b,
              hashCode: (a) => a.hashCode,
              isValidKey: (_) => true, // null is also valid
            );

            if (keys.contains(key)) {
              throw StateError(
                'Found duplicate inheritable [$type] with key [$key] in $keys. '
                'This is essentially overriding access to the original inheritable. '
                'Specify a key to distinguish between them, it can then be used by '
                '[InheritableAspect.didUpdateWidget] or [InheritableAspect.satisfiedBy]',
              );
            } else {
              keys.add(key);
            }

            return true;
          })());

      result = inheritable.copyWith(child: result);
    }

    assert((() {
      _ = null;
      return true;
    })());

    return result;
  }

  /// Create an [Inheritable] that overrides [T] with given [value] for the widget sub-tree.
  ///
  /// Providing [onChange] will create [Inheritable.mutable] instead.
  ///
  /// Specify [strict] to catch unnecessary uses of this method.
  /// When specified, an assertion error is thrown if the overriding value type and the base type are same.
  /// However [strict] is only used in debug mode, it has no effect in release mode.
  ///
  /// Example:
  /// ```dart
  /// Inheritable.override<T, SubType>(
  ///   value: SubType(),
  ///   chid: MyWidget(),
  /// )
  /// ```
  ///
  /// This is just a convenience method, there is nothing special about
  /// subtyping. The same effect can be achieved by
  /// ```dart
  /// Inheritable<T>(  // Specify base type explicitly
  ///  value: SubType(), // Provide a subtype instance
  ///  child: MyWidget(),
  /// )

  /// ```
  static Inheritable<T> override<T, SubType extends T>({
    SubType value,
    Key key,
    Set<AspectOverride<Object, T>> overrides,
    ValueChanged<T> onMutate,
    Widget child,
    bool strict = true,
  }) {
    assert(
      T != Object && T != dynamic,
      'Underspecified types are most likely a mistake. This can happen when forgetting to pass type arguments to Inheritable constructors. '
      'Try being more specific using Inheritable<T>() or Inheritable<T>.mutable or Inheritable.override<T, TT>.',
    );

    assert(
      !strict ||
          T != SubType ||
          onMutate != null ||
          overrides != null && overrides.isNotEmpty,
      'Provided value is not allowed in strict mode',
    );

    if (onMutate != null) {
      return _MutableInheritable<T>._(
        onMutate: onMutate,
        value: value,
        key: key,
        overrides: newOverridesSet(overrides),
        child: child,
      );
    }

    return Inheritable<T>._(
      value: value,
      key: key,
      overrides: newOverridesSet(overrides),
      child: child,
    );
  }

  /// Convenience method when [Inheritable.mutable] should ignore all mutations
  static void ignoreMutation(Object obj) {}

  /// Mutable variant of [Inheritable], users are to provide [onMutate] to allow
  /// value to change.
  ///
  /// However dependents have no say whether a supplied value should be
  /// updated or not.
  const factory Inheritable.mutable({
    @required ValueChanged<T> onMutate,
    T value,
    Key key,
    Widget child,
  }) = _MutableInheritable<T>;

  /// Create a new [Inheritable] of [T] with it's properties changed with the
  /// supplied values
  ///
  /// Returns `this` if all parameters are null.
  Inheritable<T> copyWith({
    Key key,
    T value,
    Set<AspectOverride<Object, T>> overrides,
    Widget child,
  }) {
    if ([key, value, overrides, child].whereType<Object>().isEmpty) return this;

    return Inheritable<T>._(
      key: key ?? this.key,
      value: value ?? _value,
      overrides: overrides != null ? newOverridesSet(overrides) : _overrides,
      child: child ?? this.child,
    );
  }

  static A _defaultTransform<A, T>(T value) => value as A;

  /// Get the value for given [aspect]. This checks for any [overrides], and
  /// provides the overridden value if there is one, or [_value] by [transform]
  ///
  /// Optionally provide [transform]. By default [_value] is simply casted
  A valueFor<A>(InheritableAspect<T> aspect, [A Function(T) transform]) {
    assert(isSupportedAspect(aspect));
    final maybeOverride = _overrides.lookup(aspect);

    if (maybeOverride != null && maybeOverride is AspectOverride<Object, T>) {
      if (maybeOverride.override is A || maybeOverride.override == null)
        return maybeOverride.override as A;
      else
        throw StateError(
          'Invalid override provided for $aspect of $this, '
          'expected value of type $A but got ${maybeOverride.override.runtimeType}',
        );
    }

    if (_value == null) return null;

    if (aspect is TransformingAspect<A, T>) {
      transform ??= aspect.transform;
    }

    return (transform ?? _defaultTransform)(_value);
  }

  /// Whether given [aspect] is supported by this. By default all non-null
  /// aspects are supported
  bool isSupportedAspect(InheritableAspect<T> aspect) =>
      aspect is InheritableAspect<T> &&
      // ignore: iterable_contains_unrelated_type
      (_overrides.contains(aspect) || aspect.satisfiedBy(this));

  @core.override
  bool updateShouldNotify(Inheritable<T> oldWidget) {
    return _value != oldWidget._value ||
        setEquals(_overrides, oldWidget._overrides);
  }

  /// Similar to [InheritedModel.updateShouldNotifyDependent]
  bool updateShouldNotifyDependent(
    Inheritable<T> oldWidget,
    Iterable<DependableAspect<T>> dependencies,
  ) {
    return dependencies.any(
      (aspect) => aspect.didUpdateWidget(prev: oldWidget, next: this),
    );
  }

  @core.override
  _InheritableElement<T> createElement() => _InheritableElement<T>(this);
}

/// Mutable version on [Inheritable], allows dependents to make changes to the
/// [value] held by this
mixin MutableInheritable<T> on Inheritable<T> {
  /// Applies given [aspect]'s mutation to `this`
  void mutateBy(MutableInheritableAspect<T> aspect);

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
  static MutableInheritable<T> of<T>(BuildContext context,
      [InheritableAspect<T> aspect]) {
    /// We don't use [Inheritable._findEnclosingInheritableElement<T>(context)]
    /// here because [Inheritable] is not accepted in this case

    return Inheritable._findInheritableSupportingAspect<T>(context, aspect,
            mutable: true)
        ?.widget as MutableInheritable<T>;
  }
}

class _MutableInheritable<T> extends Inheritable<T>
    implements MutableInheritable<T> {
  final ValueChanged<T> onMutate;

  const _MutableInheritable._({
    @required this.onMutate,
    T value,
    Key key,
    Set<Object> overrides,
    Widget child,
  })  : assert(
          onMutate != null,
          'Prefer creating an Inheritable if all changes will be rejected',
        ),
        super._(value: value, key: key, overrides: overrides, child: child);

  const _MutableInheritable({
    ValueChanged<T> onMutate,
    T value,
    Key key,
    Widget child,
  }) : this._(
          onMutate: onMutate,
          value: value,
          key: key,
          child: child,
        );

  @override
  A valueFor<A>(InheritableAspect<T> aspect, [A Function(T p1) transform]) {
    if (aspect is MutableInheritableAspect<T>) {
      assert(<A>[] is List<ValueChanged<T>>);
      return super.valueFor(aspect, transform ?? (_) => onMutate as A);
    }

    return super.valueFor(aspect, transform);
  }

  @override
  void mutateBy(MutableInheritableAspect<T> aspect) {
    valueFor<ValueChanged<T>>(aspect)?.call(aspect.mutate(this));
  }

  /// Create a new [Inheritable] of [T] with it's properties changed with the
  /// supplied values
  ///
  /// Returns `this` if all parameters are null.
  @override
  Inheritable<T> copyWith({
    Key key,
    T value,
    Set<AspectOverride<Object, T>> overrides,
    Widget child,
    ValueChanged<T> onMutate,
  }) {
    if ([key, value, onMutate, child, overrides].whereType<Object>().isEmpty)
      return this;

    return _MutableInheritable<T>._(
      key: key ?? this.key,
      value: value ?? _value,
      overrides: overrides != null
          ? Inheritable.newOverridesSet(overrides)
          : _overrides,
      onMutate: onMutate ?? this.onMutate,
      child: child ?? this.child,
    );
  }
}

class _InheritableElement<T> extends InheritedElement {
  _InheritableElement(Inheritable<T> widget) : super(widget);

  @override
  Inheritable<T> get widget => super.widget as Inheritable<T>;

  int _hashAspect<T>(InheritableAspect<T> aspect) {
    if (aspect is EquatableAspect<T>) return aspect._hash();
    return aspect.hashCode;
  }

  bool _equalsAspect<T>(InheritableAspect<T> a, InheritableAspect<T> b) {
    if (a is EquatableAspect<T>) return a._equals(b);

    return a == b;
  }

  @factory
  Map<Key, DependableAspect<T>> _newMap() {
    return HashMap();
  }

  bool removeAspect(Element dependent, InheritableAspect<T> aspect) {
    return removeKey(dependent, aspect?.key);
  }

  bool removeAllAspects(Element dependent,
      [Set<InheritableAspect<T>> aspects]) {
    return removeAllKeys(
      dependent,
      // if it's null, remove all aspects
      aspects?.map((a) => a.key)?.toSet(),
    );
  }

  bool removeKey(Element dependent, Key key) {
    final dependencies = getDependencies(dependent);

    if (dependencies == null || dependencies.isEmpty || key == null)
      return false;

    assert(dependencies.containsKey(key));
    final removed = dependencies.remove(key) != null;
    return removed;
  }

  bool removeAllKeys(Element dependent, [Set<Key> keys]) {
    if (keys != null && keys.isEmpty) return false;

    final dependencies = getDependencies(dependent);

    if (dependencies == null || dependencies.isEmpty) return false;

    if (keys == null) {
      /// Probably faster than clearing the map.
      /// This also de-references the map and let's it be gc'd automatically
      setDependencies(dependent, _newMap());
      return true;
    }

    keys = Set.of(keys);

    dependencies.removeWhere((k, _) => keys.remove(k));

    return keys.isEmpty;
  }

  @override
  Map<Key, DependableAspect<T>> getDependencies(Element dependent) {
    return super.getDependencies(dependent) as Map<Key, DependableAspect<T>>;
  }

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final dependencies = getDependencies(dependent) ?? _newMap();

    if (aspect is DependableAspect<T>) {
      // This allow replacing aspects by using same key
      dependencies[aspect.key] = aspect;
      setDependencies(dependent, dependencies);
    } else {
      /// [dependent] is requesting unconditional notifications. Or the aspect
      /// can't be used for depending on `this`
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
        exception: UnsupportedError('Given aspect $aspect is not supported'),
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
    final dependencies = getDependencies(dependent);
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
  A call<A, T>(ExtractAspect<A, T> extract, {A defaultValue, Key key}) {
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
      AspectMutation((Inheritable<T> _) => next).apply(context);
    });
  }

  /// {@macro BuildContextAspect.call}
  A get<A, T>(ExtractAspect<A, T> extract, {A defaultValue, Key key}) {
    return call(extract, defaultValue: defaultValue, key: key);
  }

  /// Contrary to [aspect] this gives you access to [T], since that's more type safe
  /// but only notifies you of changes when [predicate] returns `true`
  ///
  /// You can also specify [defaultValue] when there is no enclosing
  /// [Inheritable.model] of [T]
  T where<T>(PredicateAspect<T> predicate, {T defaultValue, Key key}) {
    return _dispose((context) {
      return NoAspect<T>(key)
          .where(predicate)
          .of(context, defaultValue: defaultValue);
    });
  }

  /// Removes the given [aspect] from enclosing [BuildContext].
  ///
  /// Returns whether removal was successful.
  ///
  /// `true`: Removed [aspect].
  ///
  /// `false`: Did not remove [aspect] or it did not already exist.
  bool remove<T>(InheritableAspect<T> aspect) {
    return _dispose((context) {
      final element =
          Inheritable._findInheritableSupportingAspect<T>(context, aspect);

      return element?.removeAspect(context as Element, aspect) ?? false;
    });
  }

  /// Remove the given set of [aspects] from enclosing [BuildContext]. If
  /// unspecified, removes all previously registered aspects.
  ///
  /// Returns whether removal was successful.
  ///
  /// `true`: Removed given [aspects] or all of them.
  ///
  /// `false`: Removed some of the [aspects] or none of them.
  // TODO: write test for context.removeAll
  @visibleForTesting
  bool removeAll<T>([Set<InheritableAspect<T>> aspects]) {
    return _dispose((context) {
      final _aspects = List.of(aspects);
      for (var i = 0; i < _aspects.length; i++) {
        final element = Inheritable._findInheritableSupportingAspect<T>(
          context,
          _aspects[i],
        );
        if (element != null) {
          final supportedAspects = <InheritableAspect<T>>{
            _aspects.removeAt(i),
            for (var j = 0; j < _aspects.length; j++)
              if (element.widget.isSupportedAspect(_aspects[j]))
                _aspects.removeAt(j),
          };
          if (supportedAspects.length == 1) {
            element.removeAspect(context as Element, supportedAspects.single);
          } else {
            element.removeAllAspects(context as Element, supportedAspects);
          }
        }
      }

      return _aspects.isEmpty;
    });
  }

  /// Removes the aspect corresponding to given [key] from enclosing [BuildContext].
  ///
  /// Returns whether removal was successful.
  ///
  /// `true`: Removed aspect for [key].
  ///
  /// `false`: Did not remove aspect for [key] or it did not already exist.
  @Deprecated(
    'Does not support all implementations of Inheritable, only tries to '
    'remove key from the first found Inheritable, this behaviour might be '
    'surprising if the aspect was not even supported. '
    'Prefer using [remove] instead',
  )
  bool removeKey<T>(Key key) {
    assert(
      T != dynamic,
      'Specify the exact type of Inheritable, dynamic is probably not what you want',
    );
    return _dispose((context) {
      final element = Inheritable._findEnclosingInheritableElement<T>(context);
      return element?.removeKey(context as Element, key) ?? false;
    });
  }

  /// Remove aspects corresponding to the given set of [keys] from enclosing [BuildContext]. If
  /// unspecified, removes all previously registered aspects.
  ///
  /// Returns whether removal was successful.
  ///
  /// `true`: Removed aspects for given [keys] or all of them.
  ///
  /// `false`: Removed some of the aspects for [keys] or none of them.
  @Deprecated(
    'Does not support all implementations of Inheritable, only tries to '
    'remove keys from the first found Inheritable, this behaviour might be '
    'surprising if the aspect was not even supported. '
    'Prefer using [removeAll] instead.',
  )
  // TODO: write test for context.removeAllKeys
  bool removeAllKeys<T>([Set<Key> keys]) {
    assert(
      T != dynamic,
      'Specify the exact type of Inheritable, dynamic is probably not what you want',
    );
    return _dispose((context) {
      final element = Inheritable._findEnclosingInheritableElement<T>(context);
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

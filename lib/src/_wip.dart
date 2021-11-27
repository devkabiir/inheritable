import 'package:flutter/widgets.dart';

import '../inheritable.dart';

/// An [InheritableAspect] that has a default value set prior to calling [of] method
@visibleForTesting
mixin HasDefaultAspect<A, T> on TransformingAspect<A, T> {
  /// The default value for this when no satisfiable [Inheritable] of [T] can be found
  A get defaultValue;
}
@visibleForTesting

/// An [InheritableAspect] that has allows setting default value prior to calling [of] method
mixin SetDefaultAspect<A, T> on TransformingAspect<A, T> {
  /// Set the default value for this when no satisfiable [Inheritable] of [T]
  /// can be found
  set defaultValue(A value);
}

// ignore: unused_element
abstract class _DefaultAspectValue<A, T> extends InheritableAspect<T>
    with
        DependableAspect<T>,
        ShouldNotifyAspect<A, T>,
        TransformingAspect<A, T>,
        SetDefaultAspect<A, T>,
        DefaultAspectofContext<A, T> {
  // ignore: unused_field
  final InheritableAspect<T> _delegate;

  _DefaultAspectValue(this._delegate)
      : super('DefaultAspectValue of ${_delegate.debugLabel}');
}

@visibleForTesting
abstract class AsyncInheritableAspect<Snapshot, T> extends InheritableAspect<T>
    with
        DependableAspect<T>,
        ShouldNotifyAspect<AsyncSnapshot<Snapshot>, T>,
        TransformingAspect<AsyncSnapshot<Snapshot>, T> {}

@visibleForTesting
class AsyncAspectBuilder<A, T> extends StatelessWidget {
  final TransformingAspect<AsyncSnapshot<A>, T> aspect;
  final AsyncWidgetBuilder<A> builder;

  const AsyncAspectBuilder({
    required this.builder,
    required this.aspect,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, aspect.of(context)!);
  }
}

@visibleForTesting
mixin StatefulInheritableAspect<T> on InheritableAspect<T> {
  @mustCallSuper
  void initState() {}

  @protected
  void setState([VoidCallback update]);

  @mustCallSuper
  void dispose() {}
}
@visibleForTesting
mixin LazyAspect<T> on StatefulInheritableAspect<T> {
  T get value => evaluate();
  T evaluate();
}

// class User {
//   int id;
// }

// abstract class UserLineItemsAspect extends InheritableAspect<User>
//     with
//         StatefulInheritableAspect<User>,
//         LazyAspect<User>,
//         MemoizedLazyAspect<User> {
//   int get pageNo;
//   static final _map = <int, List<String>>{};

//   @override
//   bool satisfiedBy(Inheritable<User> inheritable) {
//     final result =
//         super.satisfiedBy(inheritable) && inheritable.value?.id != null;

//     _map[inheritable.value.id] ??= <String>[];

//     return result;
//   }
// }
@visibleForTesting
mixin MemoizedLazyAspect<T> on LazyAspect<T> {
  T? _memoized;
  @override
  get value => _memoized ??= super.value;

  void expire() {
    _memoized = null;
  }

  @override
  void dispose() {
    expire();
    super.dispose();
  }
}
@visibleForTesting
mixin DisposableAspect<T> on InheritableAspect<T> {
  /// Dispose off any resources used by `this`
  ///
  /// An example can be seen in [_ListenableAspect], which keeps track of
  /// separate [ChangeNotifier]s based on [BuildContext]. Primarily used by [AspectListenableBuilder]
  @mustCallSuper
  void dispose(AutoDisposeAspectResourcesElement context) {}
}
@visibleForTesting
mixin AutoDisposeAspectResources<E extends ComponentElement> on Widget {
  @override
  E createElement() {
    switch (E) {
      case StatelessElement:
        return AutoDisposeAspectResourcesStatelessElement(
            this as StatelessWidget) as E;
      case StatefulElement:
        return AutoDisposeAspectResourcesStatefulElement(this as StatefulWidget)
            as E;
      default:
        throw UnsupportedError('$E is not a supported element type');
    }
  }
}
@visibleForTesting
mixin AutoDisposeAspectResourcesElement on Element {
  late Map<DisposableAspect<Object>, Object> _aspectsInUse;

  void addResourceForAspect<R>(DisposableAspect<Object> aspect, R resource) =>
      _aspectsInUse[aspect] = resource as Object;

  R getResourceForAspect<R>(DisposableAspect<Object> aspect) =>
      _aspectsInUse[aspect] as R;

  @override
  void mount(Element? parent, newSlot) {
    _aspectsInUse = {};
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _aspectsInUse.forEach((a, _) => a.dispose(this));
    // ignore: cascade_invocations
    _aspectsInUse.clear();

    super.unmount();
  }
}

@visibleForTesting
class AutoDisposeAspectResourcesStatelessElement extends StatelessElement
    with AutoDisposeAspectResourcesElement {
  AutoDisposeAspectResourcesStatelessElement(StatelessWidget widget)
      : super(widget);
}

@visibleForTesting
class AutoDisposeAspectResourcesStatefulElement extends StatefulElement
    with AutoDisposeAspectResourcesElement {
  AutoDisposeAspectResourcesStatefulElement(StatefulWidget widget)
      : super(widget);
}

@visibleForTesting
class AspectListenableBuilder<A, T> extends StatelessWidget
    with AutoDisposeAspectResources<StatelessElement> {
  const AspectListenableBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

// enum DiffAspectState {
//   added,
//   changed,
//   removed,
// }

/// This is probably too specific and should not be part of the package
/// But this can be part of the example
// abstract class DiffAspect<T> extends InheritableAspect<T> {
//   Set<SingleAspect<DiffAspectState, T>> get aspects;

//   Set<SingleAspect<DiffAspectState, T>> _added;
//   Set<SingleAspect<DiffAspectState, T>> get added;
//   Set<SingleAspect<DiffAspectState, T>> _changed;
//   Set<SingleAspect<DiffAspectState, T>> get changed;
//   Set<SingleAspect<DiffAspectState, T>> _removed;
//   Set<SingleAspect<DiffAspectState, T>> get removed;

//   @override
//   bool shouldNotify(T newValue, T oldValue) {
//     bool notify = false;
//     _added.clear();
//     _changed.clear();
//     _removed.clear();

//     for (var aspect in aspects) {
//       final state = aspect(newValue);
//       if (state != aspect(oldValue)) {
//         switch (state) {
//           case DiffAspectState.added:
//             _added.add(aspect);
//             break;
//           case DiffAspectState.changed:
//             break;
//           case DiffAspectState.removed:
//             break;
//           default:
//             throw UnsupportedError('DiffAspectState: $state is not supported');
//         }
//         _changed.add(aspect);
//         notify = true;
//       }
//     }

//     return notify;
//   }
// }

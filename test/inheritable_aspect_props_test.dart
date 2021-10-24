import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inheritable/inheritable.dart';

import 'helpers/helpers.dart';

Future<void> main([List<String>? args]) async {
  group('Has proper debug properties', () {
    final aspects = [
      const Aspect(User.firstName, Key('firstName')),
      const Aspect(User.firstName, Key('firstName')).listenable,
    ];

    final mixinsTestCases = <AspectPropertyMatcherFactory<User?>>[
      /// Common for all implementations
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

      /// Aspect
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

      /// DependableAspect
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

      /// EquatableAspect
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

      /// DelegatingAspect
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

      /// ListenableAspect
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

      final specificProps = mixinsTestCases
          .map((impl) => impl(aspect))
          .reduce((prev, next) => prev..addAll(next));

      for (var impl in specificProps.keys) {
        test('(specific properties) [$implementation][$impl]', () {
          assertHasDebugProperties(aspect, specificProps[impl]!);
        });
      }
    }
  });
}

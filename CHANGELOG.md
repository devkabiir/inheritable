# Changelog

## 1.0.0

- Improve tests
- Flutter 2.5 & Dart 2.14
- Fix flutter/flutter#83104 via a workaround

## 1.0.0-beta.1

- Switch to NNBD (Dart 2.12)
- Add composition unility `debounce`
- Add ability to override aspects by key or equality
- Add ability to mutate using aspect
- A `DependableAspect` is required to cause a rebuild
- Add `PatchableAspect` to allow low-effort value patching

## 1.0.0-dev.1

- First public release
- Introduce `Inheritable`, Allows access to immutable value or selective
  aspects. Only notifies dependents if the selected aspect changes.
- Introduce `Inheritable.mutable`, Allows access to immutable/mutable value or
  selective aspects. Allows updating the value provided by it. Compatible with
  `Inheritable.of(context)` usage.

# Inheritable [pre-release]

Efficient by default, zero-dependency, declarative state/dependency management for flutter.

## Examples

Consider the following mutable value of `User`

```dart
class User {
    String fname;
    String lname;

    // <proper Object.hashCode & Object.== implementations>

    @override
    String toString() {
        return 'User($fname $lname)';
}
```

Assume that there is widget to show the user's full name in ALL_CAPS.

```dart
class UserName extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final fullName = context.aspect((User u) => '${u.fname} ${u.lname}'.trim().toUpperCase());
        return Text(fullName);
    }
}
```

This `UserName` widget is being used something like

```dart
    @override
    Widget build(BuildContext context) {
        return Inheritable(
            value: User()..fname = 'John'..lname = 'Doe ',
            child: const UserName(),
        );
    }

```

For a `User(John Doe )`, the Widget would display `JOHN DOE`. The widget is
currently listening for changes to the nearest `User`, if the user changes to
`User(JOHN DOE)` which is essentially the same as what the widget would display
anyway, `Inheritable` skips informing the widget about that change. However if
the user were to change to `User(John Doe2)`, the final result display to the
user would change to `JOHN DOE2`, which is different from the last value, here
`Inheritable` will rebuild the `UserName` widget.

In the previous example the `UserName` widget was using all available aspects of
`User` i.e. `fname` and `lname`. Now consider,

```dart
class UserFirstName extends StatelessWidget {

    @override
    Widget build(BuildContext context) {
        final fName = context.aspect((User u) => u.fname.trim().toUpperCase());
        return Text(fName);
    }
}
```

Similar to `UserName`, `UserFirstName` is being used something like

```dart
    @override
    Widget build(BuildContext context) {
        return Inheritable(
            value: User()..fname = 'John'..lname = 'Doe ',
            child: const UserFirstName(),
        );
    }
```

Now `UserFirstName` would display `JOHN`, if the user were to change to
`User(John Doe2)`, the `UserFirstName` would not be notified, since it only
_cares_ about the first name and `Inheritable` know about this. Not only that,
Inheritable also knows that `UserFirstName` doesn't care about being notified
until the _trimmed_ and **ALL_CAPS** value of `User.fname` changes to something other
than `JOHN`.

Checkout the tests for more examples.

## Description

Inheritable was initially made for an internal app, but extracted out to be a
separate open-source package.

Inheritable is based on the pre-existing `InheritableModel` of flutter. The
concepts are very similar.

Inheritable however has some advantages

- Moves the decision of whether or not a widget should rebuild to itself. Even
  if the value held by `Inheritable` changes, along with the aspect, it's
  still up to the dependent to decide whether to rebuild.

- Optionally allow sending updates e.g. `context.aspect.update(User()..fname = 'Josh' ..lname = 'Doe')`

  Notice that `update` directly takes the value you want to update, If there
  is a `Inheritable.mutable` available, it supplies the new value to it.
  That's all. Just like whether to rebuild or not is up to the dependent,
  whether to update the value or not is up to the owner of that value.

- Update a value without depending on it. From the above examples
  `UserFirstName` could send an update for `User.lname` to be changed. However
  `UserFirstName` has only declared `User.fname` as a dependency. So
  `User.lname` will be updated without causing rebuild for `UserFirstName`. This
  allows for interesting scenarios such as sending data to siblings, parents or
  children widgets

- Dynamically add aspects to listen for changes

- Stop listening to changes at a later point.

- Reuse aspects in multiple widgets. Once could create the following aspect and
  pass it around to multiple widgets
  `var fname = Aspect((Useru) => u.fname)`
  The widget would then simply do `fname.of(context)` to get the value.
  Generally these would be dumb widgets that are only used for presentation
  purposes of a certain value type for example `AllCapitalText(fname)` would be
  a widget that requires some string aspect of some value, and display that in ALL_CAPS

- Replace existing dependencies using `Key`. e.g.
  `var fname = Aspect((Useru) => u.fname, key: Key('user.fname'))`
  A widget using `fname` could later replace it by simply doing
  `context.aspect((User u) => u.lname, key: fname.key);`
  The widget would then stop listening for `fname` changes and start listening for
  `lname` changes. This works because the keys for both aspects are same.

- Chaining aspects. One could also do

  ```dart
  var result  = Aspect((User u) => u.lname)
                .where((lname) => lname!=null)
                .map((lname) => lname.trim().toUpperCase())
  ```

  In the above case, you are filtering the values of `User.lname` to not be
  `null`. When it's `null` you simply won't be notified, it short-circuits the
  chain, so the `map` won't execute. When it's not `null`,
  only then it will be `mapped`, compared to last value, and you'd be notified
  if it was different.
  You would then pass the result around or immediately use it like `result.of(context)`

- Composable: create/remove/reuse `Inheritable`s and `Aspect`s. It is encouraged
  to create custom implementations of `InheritableAspect`, such as a custom
  `SpreadsheetCellAspect` rebuilds a cell if any one of the cells in it's
  formula changes, So for a cell with value `A1 + B1`, it will only rebuild if
  `A1 | B1` changes. And if you aren't building offstage widgets, it would make your
  spreadsheet even more efficient.

- User definable behaviour for aspects. See `Aspect` and `NoAspect`
  implementations of `InheritableAspect`

- Get asynchronous values in a synchronous fashion

- Get Static/Compile-time errors for aspects that couldn't exist on a value.
  Contrary to `InheritableModel`'s example use case instead of specifying
  `"fname"` aspect you specify `(User u) => u.fname` which wouldn't work if
  `User` didn't have `fname`, but `"fname"` would've silently be allowed, until
  you get a runtime error.

- Short-circuit unnecessary work.

The idea behind `Inheritable` is that you specify your dependencies _"declaratively_"
in a type-safe manner. More often than not I see dependencies being
registered/declared/requested in a non-auto-completable fashion. If it's
type-safe, it can be auto-completed

Allow Presentation of a value via multiple widgets without causing unnecessary
rebuilds. A `User` could be presented by `UFistName` & `ULastName` widgets. While
it's possible to create InheritedWidget for `User.fname` and `User.lname`
separately both of them will have same `runtimeType`. Which turns out to be a
limitation of `InheritedWidget`. It doesn't allow multiple `InheritedWidget`s of
same `runtimeType` to be available at the same time. Which, if you think about it,
is fine, because the users often don't know how to distinctively request for 1
of them and not the other.

Since you'd either have to create 1
`InheritedWidget<String>` subclass for supplying `String` values to widgets (which
would fail, since the last widget in hierarchy overrides the `String` value) or create 2
separate classes `InheritedWidget<UserFirstName>` &
`InheritedWidget<UserLastName>` which is too verbose and very little reusability.

A single default implementation of `Inheritable` would be
enough in this case. However it would be possible to even go further and define
custom behaviour using custom implementations of `Inheritable` to allow various
hierarchies, but it remains to be decided whether I want to support that and to
what extent. Custom implementations of `InheritableAspect` should be enough in
most cases. Allowing custom `Inheritable` implementations would only complicate things.

## Notes

- Keys are useful but not required in most common cases

- "Dependency" is used in the sense of state management, and no in the sense of
  dependency-injection. However is could be made possible to use `Inheritable`
  for such use cases

- Using `Inheritable` won't magically make you app perform better and rebuild
  efficiently, However it will _allow_ you to do just that.
  It depends on how well you understand flutter, dart, inheritable & most importantly your use case.

## Roadmap

- [ ] Complete test suite
- [ ] Whether to support custom implementations of `Inheritable`
- [ ] Add examples
- [ ] Update README with more examples and use cases

## License

MIT

# Disco

A modern, convenient and safe way to do scoped DI in Flutter.

The documentation is currently a work in progress.

## Features

- Scoped DI
- Service locator
- Testable
- Independent of state management solutions
  - This library focuses on DI, so that state management solutions can
  focus on the reactivity.

## Usage

### Argument type

Write the argument type right next to the parameter instead of with generics.

DO:

```dart
final numberProvider = Provider.withArgument((context, int arg) => arg * 2);
```

AVOID:

```dart
final numberProvider = Provider.withArgument<int, int>((context, arg) => arg * 2);
```

### Examples

There are multiple examples on the repository (the `examples` folder and the
single `example` inside the disco package).

## Additional information

This library can be used in combination with many existing packages.

### State management

This package is not opinionated about reactivity: feel free to use your
state management solution of choice (as long as it is compatible with the
concepts of the library).

#### Compatible solutions

Compatible state management solutions are those whose signals/observables can
be created locally and passed as arguments/props, such as
[`solidart`](https://pub.dev/packages/flutter_solidart) (NB: its providers up to
version `2.0.0-dev.2` will be replaced with the ones present in `disco`),
[`bloc`](https://pub.dev/packages/flutter_bloc) (NB: the usage of `BlocProvider`
should be replaced with the providers present in this library), and many more.

Our repository includes one example with `solidart` and one with `bloc`.

#### Incompatible solutions

State management solution entirely leveraging global state, such as
[`riverpod`](https://pub.dev/packages/riverpod), are not compatible with this
library. Also those solutions constrained by typical type-base providers
(i.e. `Provider<SomeType>`), such as
[`provider`](https://pub.dev/packages/provider), are not compatible, since
both of them handle everything (including the reactivity) through dependency
injection instead of creating instances of signals/observables that can be
managed manually.

### Contributions

The purpose of this package is to simplify dependency injection for everyone.
PRs are welcome, especially for documentation and more examples. Another goal of
this library is to be simple. PRs introducing new features
or breaking changes will have to be explained in detail.

---
title: Providers
description: How to create and use providers
---

A provider is a tool that helps manage and inject dependencies in an application, making it easier to share data or services across different parts of the app.

**NB:** When we use the term "provider", it can refer to either the `Provider` class of this library or the value it contains, depending on the context.

## Providers

Declare a new provider either as a global `final` variable or a `final` static field.

**NB:** while the providers are declared globally, they **do not function globally**. They are just used as IDs when registered in a scope.

Example with a global `final` variable.

```dart
/// global scope
final numberProvider = Provider((context) => 5);
```

If there is only a provider per class, you can also create a `final` static field. This comes down to personal preference.

```dart
class MyDatabase {
  static provider = Provider((context) => MyDatabase());
}
```

### Injection of other providers with context

Providers can leverage the context to inject other providers. The context will be relative to the scope in which they are provided.

```dart
final doubleNumberProvider = Provider.withArgument((context) {
  final number = numberProvider.of(context);
  return number * 2;
});
```

## Providers with argument

Providers need to be provided before they can be injected in the widget tree. Sometimes, they need an initial argument so that they can be instantiated correctly. This is possible with `Provider.withArgument`.

```dart
// NB: we renamed the `context` to `_` because it is unused.
final numberPlusArgProvider = Provider.withArgument((_, int arg) {
  return 5 + arg;
});
```

An example where this might make more sense would be an application with multi-account support, where the database is loaded per user, and the filepath of the database contains the user ID:

```dart
// NB: we renamed the `context` to `_` because it is unused.
class MyDatabase {
  static provider = Provider((_, String userId) => MyDatabase.fromId(id));
}
```

This `MyDatabase.provider` has to be provided in a subtree (of the widget tree) belonging to the currently logged user.

### Injection of other providers with context

Providers can both take an argument and rely on context.

```dart
final doubleNumberPlusArgProvider = Provider.withArgument((context, int arg) {
  final number = numberProvider.of(context);
  return number * 2 + arg;
});
```

## Dispose and lazy parameters

When defining a provider, we need to pass the positional `create` argument, which is a function used to generate the value contained by the provider.

There are also two optional named parameters that can be specified.

| Parameter | Default | Description |
| -------------- | ------- | ----------- |
| `dispose`      | null    | The function to call when the scope containing the provider gets disposed. It is used to dispose correctly the value held by the provider. |
| `lazy`         | `DiscoConfig.lazy`, which defaults to true | The values of the providers provided in a scope are created lazily.|


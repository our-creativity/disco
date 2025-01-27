---
title: Scoped DI
description: How to use Disco providers and understanding scoping.
---

Providers have to be provided before they can be injected.

Let us consider two providers of the previous page for this section.

```dart
final numberProvider = Provider((context) => 5);

final doubleNumberPlusArgProvider = Provider.withArgument((context, int arg) {
  final number = numberProvider.of(context);
  return number * 2 + arg;
});
```

### How to scope

Scoping means that the provider must be specified within a `ProviderScope` before it can be injected.

In case the provider does not take an argument, we scope it the following way:

```dart
ProviderScope(
  providers: [numberProvider]
  child: // ...
)
```

In case the provider takes an argument, we need to specify it when providing it.

```dart
ProviderScope(
  providers: [doubleNumberPlusArgProvider(10)]
  child: // ...
)
```

### How to inject

Injecting is the act of retrieving a dependency. It is done with the methods `of(context)` and `maybeOf(context)`, the latter one being safer because it returns null instead of throwing if the provider is not found in any scopes. If you are unsure about which one to use, for simplicity you should probably stick to `of(context)` (and maybe set up an error monitoring solution to automatically detect invalid injections).

We inject the two providers above by using the `numberProvider.of(context)` and `doubleNumberPlusArgProvider.of(context)`.

### Full example

Try and guess what the displayed text will be before reading the solution.

```dart
runApp(
  MaterialApp(
    home: Scaffold(
      body: ProviderScope(
        providers: [numberProvider],
        child: ProviderScope(
          providers: [doubleNumberPlusArgProvider(10)],
          child: Builder(
            builder: (context) {
              final number = numberProvider.of(context);
              final doubleNumberPlusArg = doubleNumberPlusArgProvider.of(context);
              return Text('$number $doubleNumberPlusArg');
            },
          ),
        ),
      ),
    ),
  ),
);
```

The solution is "5 20".

## Scoping correctly

Some providers might have a dependency on other providers or as an argument. It is important that the following considerations are made.

### Context

Note that the scope containing `doubleNumberPlusArgProvider` needs to be a descendant of the one containing `numberProvider`. This is because `doubleNumberPlusArgProvider` uses the context to find the value of `numberProvider`. The following will thus **not** work:

```dart
// bad example
ProviderScope(
  providers: [
    numberProvider,
    doubleNumberPlusArgProvider(10),
  ],
  child: // ...
)
```

Placing the `ProviderScope` containing `doubleNumberPlusArgProvider` above the one containing `numberProvider` would also not work. It needs to be like in the full example above.

### Argument

Let's recall the example from the previous page.

```dart
class MyDatabase {
  static final provider = Provider((context, String userId) => MyDatabase.fromId(id));
}
```

The `MyDatabase.provider` should be provided in a subtree (of the widget tree) belonging to the currently logged user. If you provide it too high up in the widget tree (above the currently logged user logic) it will not be possible to change database, because the `ProviderScope` where `MyDatabase.provider` is provided is never disposed. In practice, this particular error is unlikely due to the `userId` being first available in the currently logged user logic. However, this kind of scenario needs to be considered.

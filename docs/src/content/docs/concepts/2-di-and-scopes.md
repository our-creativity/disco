---
title: DI and Scopes
description: How to provide values and how to inject them
---

Providers have to be provided before they can be injected.

Let us recall the two providers of the previous page for this section. 

```dart
// NB: we renamed the `context` to `_` because it is unused.
final numberProvider = Provider((_) => 5);

// NB: in this provider the `context` is used
final doubleNumberPlusArgProvider = Provider.withArgument((context, int arg) {
  final number = numberProvider.of(context);
  return number * 2 + arg;
});
```

### How to provide

"Providing a provider" is a bit of a play on words. In this context, providing means that the provider must be specified within a `ProviderScope` before it can be injected.

In case the provider does not take an argument, we provide it the following way:

```dart
ProviderScope(
  providers: [numberProvider]
  child: // ...
)
```

In case the provider takes an argument we need to specify it when providing it.

```dart
ProviderScope(
  providers: [doubleNumberPlusArgProvider(10)]
  child: // ...
)
```

### How to inject

Injection is the act of retrieving a dependency. It is done with the methods `of(context)` and `maybeOf(context)`, the latter one being safer because if the provider is not found in any scopes it returns null instead of throwing. If you are unsure about which one to use, we recommend you use `of(context)` (and maybe set up an error monitoring solution to detect invalid injection).

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

Some providers might have a dependency on other providers or an an argument. It is important that the following considerations are made.

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

Placing the ProviderScope containing `doubleNumberPlusArgProvider` above the one containing `numberProvider` would also not work.

### Argument

Let's recall the example from the previous page.

```dart
class MyDatabase {
  static provider = Provider((context, String userId) => MyDatabase.fromId(id));
}
```

This `MyDatabase.provider` should be provided in a subtree (of the widget tree) belonging to the currently logged user. If you provide it too high up in the widget tree (before the account switching logic) it will not be possible to change database, because the `ProviderScope` where `MyDatabase.provider` is provided is never disposed. In practice, this particular error is unlikely due to the `userId` being first available in the account switching logic. However, this kind of scenario needs to be considered.
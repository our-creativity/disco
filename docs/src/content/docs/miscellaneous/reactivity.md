---
title: Reactivity
description: How to handle reactivity in combination with this library.
---

This library does not feature reactivity. You can use a state management library of you choice, as long as it does not use global state. Below follows an example with [Solidart](https://pub.dev/packages/flutter_solidart)'s signals (`Signal` and `Compute`) and `SignalBuilder` widget:

```dart
// the context is not used, so let's just write `_`
final counterProvider = Provider(
  (_) => Signal(0),
);

// reacts to changes of counterProvider
final doubleCounterProvider = Provider(
  (context) => Computed(() => counterProvider.of(context).value * 2),
);

runApp(
  MaterialApp(
    home: Scaffold(
      body: ProviderScope(
        providers: [counterProvider],
        child: ProviderScope(
          providers: [doubleCounterProvider],
          child: SignalBuilder(
            builder: (context, child) {
              final counter = counterProvider.of(context);
              final doubleCounter = doubleCounterProvider.of(context);
              return Column(
                children: [
                  Text('${counter.value} ${doubleCounter.value}'),
                  OutlinedButton(
                    child: Text("+1"),
                    onPressed: () {
                      counter.value += 1;
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  ),
);
```

Every time the +1 button is clicked, the `counter` is incremented by one, and the `doubleCounter` by two.

Note that our repository includes a full example with Bloc, one with ChangeNotifier and one with Solidart.

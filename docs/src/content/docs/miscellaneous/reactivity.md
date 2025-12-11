---
title: Reactivity
description: How to handle reactivity in combination with Disco.
---

Disco does not feature reactivity. You can use a state management library of you choice, as long as it does not use global state.

### Example

Below follows an example with [Solidart](https://pub.dev/packages/flutter_solidart)'s signals (`Signal` and `Computed`) and `SignalBuilder` widget:

```dart
final counterProvider = Provider((context) => Signal(0));

// The internal Computed reacts to changes of counterProvider's inner Signal.
final doubleCounterProvider = Provider((context) {
 return Computed(() => counterProvider.of(context).value * 2);
});

runApp(
  MaterialApp(
    home: Scaffold(
      body: ProviderScope(
        providers: [counterProvider, doubleCounterProvider],
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
);
```

Every time the +1 button is clicked, the `counter` is incremented by one, and the `doubleCounter` by two.

### More examples

Our repository also includes a full example with Bloc, one with ChangeNotifier and one with Solidart.

---
title: Testing
description: How to use overrides for testing.
---

Testing is done with overrides. You will need to place a `ProviderScopeOverride` (preferably as the root widget) and then specify the `overrides`, which is a list containing the providers followed by `.overrideWithValue(T value)`.

Note that you can **only** use one `ProviderScopeOverride` per test.

The text displayed in the following example will be "100".

```dart
testWidgets(
    '''ProviderScopeOverride should override providers''',
    (tester) async {
  final numberProvider = Provider<int>((context) => 0);
  await tester.pumpWidget(
    ProviderScopeOverride(
      overrides: [
        numberProvider.overrideWithValue(100),
      ],
      child: MaterialApp(
        home: ProviderScope(
          providers: [
            numberProvider,
          ],
          child: Builder(
            builder: (context) {
              final number = numberProvider.of(context);
              return Text(number.toString());
            },
          ),
        ),
      ),
    ),
  );
  expect(find.text('100'), findsOneWidget);
});
```

Testing is possible also with providers that take an argument, and it is done same exact way. The text displayed in the following example will be "16".

```dart
testWidgets(
    '''ProviderScopeOverride should override argument providers''',
    (tester) async {
  final numberProvider = Provider.withArgument((context, int arg) => arg * 2);
  await tester.pumpWidget(
    ProviderScopeOverride(
      overrides: [
        numberProvider.overrideWithValue(8),
      ],
      child: MaterialApp(
        home: ProviderScope(
          providers: [
            numberProvider(1),
          ],
          child: Builder(
            builder: (context) {
              final number = numberProvider.of(context);
              return Text(number.toString());
            },
          ),
        ),
      ),
    ),
  );
  expect(find.text('16'), findsOneWidget);
});
```

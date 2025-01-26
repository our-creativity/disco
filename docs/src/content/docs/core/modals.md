---
title: Modals
description: How to access providers inside modals.
---

A modal spawns a new widget tree, making injecting providers not possible out of the box.

This library offers `ProviderScopePortal`, which gives access to all the providers that were created in the main widget tree.

Note that you have to pass it the context of the main tree for it to work. Also, a `context` that is a descendant of `ProviderScopePortal` needs to be used. This is why in the following example we created a `Builder` and used its argument `innerContext` to inject the provider.

```dart
final numberContainerProvider = Provider((_) => 1);

Future<void> showNumberDialog({required BuildContext context}) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return ProviderScopePortal(
        mainContext: context,
        child: Builder(
          builder: (innerContext) {
            final numberContainer =
                numberContainerProvider.of(innerContext);
            return Text('$numberContainer');
          },
        ),
      );
    },
  );
}

runApp(
  MaterialApp(
    home: Scaffold(
      body: ProviderScope(
        providers: [numberContainerProvider],
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showNumberDialog(context: context);
              },
              child: const Text('show dialog'),
            );
          },
        ),
      ),
    ),
  ),
);
```

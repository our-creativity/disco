## Quick look at Provider and Riverpod

Let’s walk through how Provider and Riverpod work, focusing on what their pain points are.

### Glimpse into Provider

The [`Provider`](https://pub.dev/packages/provider) package and libraries built on top of it, such as [Bloc (BlocProvider component)](https://pub.dev/packages/flutter_bloc#blocprovider]), let you scope dependencies using the widget tree. However, **they rely entirely on types** to resolve injections.

This means you can only have **one provider per type** in a branch of the tree.

```dart
void main() {
  runApp(
    Provider<Model>(
      create: (_) => Model(),
      child: MaterialApp(
        home: MyWidget(),
      ),
    ),
  );
}

/// In the subtree of MyWidget.
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reads the first Model above this widget in the tree
    final model = context.read<Model>();
    // return ...
  }
}
```

If you want two different `Model` instances, you can't just write:

```dart
/// In the subtree of MyWidget.
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reads the first Model above this widget in the tree
    final model = context.read<Model>();
    // This one also reads the first Model it finds instead of reading the second one in the tree...
    final secondModel = context.read<Model>();
    // return ...
  }
}
```

You are forced to create wrapper types like `PrimaryModel`, `SecondaryModel`, etc., to distinguish between different providers. This clutters your codebase and increases boilerplate.

### Glimpse into Riverpod

Libraries like [`Riverpod`](https://pub.dev/packages/riverpod) solve the above limitation by allowing **multiple providers of the same type**, using globally defined provider *instances* as identifiers:

```dart
final modelProvider = Provider((ref) => Model());
final secondModelProvider = Provider((ref) => Model());
```

The `ref` is a special object that allow to access providers.

Note that **the state for these providers is not local** — it's managed from a single, top-level `ProviderScope`:

```dart
void main() {
  runApp(
    // The state for all providers is handled here, not in the providers themselves.
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

Without this `ProviderScope`, it is not possible to access any provider.

In order to access a provider, you must use specialized widgets (`ConsumerWidget`, `ConsumerStatefulWidget`) instead of Flutter's native ones.

#### Parameterized Providers and Lifecycle Management in Riverpod

Riverpod offers powerful modifiers like `family` and `autoDispose` to enhance provider flexibility and lifecycle:

* **`family`** enables **parameterized providers** allowing multiple instances of the same provider with different parameters:

  ```dart
  final userProvider = Provider.family<User, int>((ref, userId) {
    return fetchUser(userId);
  });
  ```

  This provides the illusion of scoped instances but with important caveats:

  * All instances remain **globally stored** within the single top-level `ProviderScope`.
  * Lifecycle is **not tightly bound to the widget tree**, complicating disposal and resource management.
  * Breaks the Flutter principle of *“let the tree define scope.”*

* **`autoDispose`** automatically cleans up providers when no longer used by any widget:

  ```dart
  final userProvider = Provider.autoDispose<User>((ref) {
    return fetchUser();
  });
  ```

  However:

  * It still operates inside the global `ProviderScope`, so it’s **not true local scoping**.
  * Providers are **not removed while any widget is listening**, potentially extending their lifecycle beyond expectations.
  * May cause unexpected disposal and recreation during fast navigation or widget rebuilds.

Together, `family` and `autoDispose` enhance flexibility and resource handling in Riverpod but don’t offer true widget-tree-based scoping and lifecycle guarantees.
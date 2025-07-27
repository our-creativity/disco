[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Coverage](https://codecov.io/gh/our-creativity/disco/graph/badge.svg?token=Z19R32RJ22)](https://codecov.io/gh/our-creativity/disco)
[![GitHub issues](https://img.shields.io/github/issues/our-creativity/disco)](https://github.com/our-creativity/disco/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/our-creativity/disco.svg)](https://gitHub.com/our-creativity/disco/pull/)
[![pub.dev Version (including pre-releases)](https://img.shields.io/pub/v/disco?include_prereleases)](https://pub.dev/packages/disco)
[![GitHub stars](https://img.shields.io/github/stars/our-creativity/disco)](https://gitHub.com/our-creativity/disco/stargazers/)

# Disco

Disco is a Flutter library that provides scoped dependency injection in a way that is:
- **production-ready**
- **simple to use**
- **type-safe**
- designed with **Flutter-friendly syntax**
- **testable**
- **independent** of state management solutions

The full documentation can be consulted [here](https://disco.mariuti.com).

**Note:** this package is intentionally small and feature-complete, so you might not see frequent updates — but don’t worry; it is still actively maintained, and you can get help anytime from the community/devs if needed.

## Table of content

- [Simple usage example](#simple-usage-example)
- [What makes this library unique](#what-makes-this-library-unique)
- [Trade-offs](#trade-offs)
- [Examples](#examples)
- [Additional information](#additional-information)

## Simple usage example

The package supports many features, like providers that accept arguments. But to keep things simple, here is a basic example to get you started:

1. Create a provider at the top level.

    ```dart
    final modelProvider = Provider((context) => Model());
    ```

    **Note:** the state is never stored globally, directly in the Provider instance; see this provider solely as a type-safe identifier.

2. Insert a `ProviderScope` at the desired point in the widget tree to define the scope of the provider and make it accessible to the corresponding subtree.

    ```dart
    ProviderScope(
      providers: [modelProvider],
      child: MyWidget(),
    )
    ```

    **Note:** the actual state for the provider is created and stored inside the `ProviderScope` instance where the provider is referenced.
    This way, when the ProviderScope gets disposed, the state gets disposed — making it ideal for managing **local state**.

3. Inject the provider directly inside a new stateless widget or a stateful widget's state.

    ```dart
    class InjectingWidget extends StatelessWidget {

      const InjectingWidget({super.key});

      @override
      Widget build(BuildContext context) {
        final model = modelProvider.of(context);
        // return .. (use model here)
      }
    }
    ```

    **Note:** the `ProviderScope` defined in step 2 needs to be an ancestor of this `InjectingWidget` widget.

<details>
<summary><strong>If the widget tree structure is still not clear</strong>, click <strong>here</strong> to expand</summary>

### Expanded: Widget tree structure

To make things clear, here is the widget tree structure from the example above, shown in the most detailed form:

* `modelProvider` — a globally defined provider

* `main` — the entry point of every Dart application, also global

  * ... — setup widget(s)

    * `ProviderScope` — *`modelProvider` is provided here*

      * `MyWidget` — the child defined in the second code snippet if you notice carefully

        * ... — widget(s)

          * `InjectingWidget` — *`modelProvider` is injected here*

            * ... — widget(s)

</details>

## What makes this library unique

Disco takes a fundamentally different approach to dependency injection in Flutter. It is — **to our knowledge** — the **first and only solution** that supports **multiple providers of the same type** (without wrapper types or string identifiers) while staying **purely local**, aligned with the **natural structure of the Flutter widget tree**.

Provider and Riverpod — the two most popular DI libraries built around providers — have significantly influenced the design and philosophy of this library.

<details>
<summary><strong>To get a glimpse into Provider and Riverpod</strong>, click <strong>here</strong> to expand</summary>

### Expanded: Quick look at Provider and Riverpod

Let’s walk through what this actually means and how Provider and Riverpod work, so we can draw a meaningful comparison.

#### Glimpse into Provider

The [`Provider`](https://pub.dev/packages/provider) package (and libraries built on top of it like [Bloc (BlocProvider component)](https://pub.dev/packages/flutter_bloc#blocprovider])) let you scope dependencies using the widget tree. However, **they rely entirely on types** to resolve injections.

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

#### Glimpse into Riverpod

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

##### Parameterized Providers and Lifecycle Management in Riverpod

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

Together, `family` and `autoDispose` enhance flexibility and resource handling in Riverpod but don’t offer true local, widget-tree-based scoping and lifecycle guarantees.

</details>

### Disco: The best of both worlds

Disco **combines** the **type flexibility of Riverpod** with the **explicit scoping of Provider** — while reducing the downsides of both to a minimum.

#### Providers as identifiers

You define providers as top-level identifiers. They can be of the same generic type, as in the example below.

```dart
final modelProvider = Provider((context) => Model());
final secondModelProvider = Provider((context) => Model());
```

Disco uses the **provider instance**, not the return type, to locate dependencies — allowing multiple providers of the same type *without confusion*.

#### Scoped where you need it

You insert a `ProviderScope` **where** you want the providers to be active — no global registry required.

```dart
ProviderScope(
  providers: [modelProvider, secondModelProvider],
  child: MyWidget(),
)
```

This is **true scoping**, fully aligned with the widget tree.

#### Clean and type-safe injection

No special widget base class is needed. Just call the `of` (or `maybeOf` if optional) method of the provider:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = modelProvider.of(context);
    final secondModel = secondModelProvider.of(context);

    return Text(model.toString() + " " + secondModel.toString());
  }
}
```

You can inject providers in **any** `StatelessWidget` or `StatefulWidget`.

## Trade-offs

Below is a summary of the trade-offs between the main provider-based dependency injection packages — Provider and Riverpod — and Disco.

| Feature / DI Library               | Provider     | Riverpod                           | Disco                                  |
| ------------------------------- | -------------- | ------------------------------------ | ---------------------------------------- |
| **Multiple providers of same type** | ❌ Type is leveraged           | ✅ Provider instance is leveraged | ✅ Provider instance is leveraged   |
| **Lifecycle management**            | ✅ Widget tree    | ❌ Top-level `ProviderScope` by default, or manual | ✅ Widget tree |
| **Works with default Flutter widgets**      | ✅ Compatible             | ❌ `ConsumerWidget` required        | ✅  Compatible                                      |
| **Local state endorsed**            | ✅ Yes             | ❌ No                                   | ✅ Yes                                       |
| **Reactivity methods included**             | ✅ `context.watch`              | ✅ `ref.watch`, `ref.listen`                                       | ❌ Totally unopinionated on purpose¹  |
| **Mutable state support**           | ⚠️ Usually done via `ChangeNotifier`       | ✅ Built-in                                                           | ⚠️ Allows mutable inner state via observables/signals             |
| **Compile-time safety**             | ❌ Runtime error if provider not found | ✅ No runtime error possible                          | ❌ Runtime error if provider not found² |
| **Fallback support**                | ❌ Not available; try-catch block necessary                                        | ✅ No need                                        | ✅ `maybeOf(context)` for optional injection                      |
| **Modal compatibility**             | ⚠️ Needs to specify all required providers one by one                  | ✅ Scoped globally, no special handling needed                                                    | ✅ Needs `ProviderPortal`, which is a portal to the main tree (all providers are available)      |
| **API simplicity**                  | ✅ Simple                             | ⚠️ Requires learning `WidgetRef`, `ConsumerWidget`, ... | ✅ Extremely simple                   |
| **Ease of integration into state management** | ❌ Requires wiring | ❌ Requires wiring   | ✅ No integration needed, works out of the box |

¹ In Disco's defense regarding the **Reactivity methods included** point:

- Including a `watch` method, like Provider and Riverpod do, is not necessary. Instead of using `watch`, an observable/signal can be injected and its relative widget can be used to react to changes. This reduces this library's codebase, prevents possible bugs and allows the state-management library of your choice to be used for the reactivity.

² In Disco's defense regarding the **Compile-time safety** point:

- Total compile-time safety is not possible with an approach leveraging scoped DI, which is a pattern ubiquitously used in Flutter and third-party libraries (think about how many times you have already read `MediaQuery.of(context)`, `GoRouter.of(context)`, ...).
- Disco providers also have a `maybeOf(context)` method, which can help if the presence of a provider cannot be guaranteed.
- The throwable includes precise information in its stack trace to deduce the missing provider: filepath, line and column.

## Examples

There are multiple examples on the repository:

- [basic](https://disco.mariuti.com/examples/basic/) A basic example showing the basic usage of Disco.
- [solidart](https://disco.mariuti.com/examples/solidart/) An example showcasing the power of the `ProviderScope` widgets combined with solidart reactivity.
- [bloc](https://disco.mariuti.com/examples/bloc/) An example showcasing how to provide a light/dark theme Cubit with Disco.
- [auto_route](https://disco.mariuti.com/examples/auto-route/) An example showing how to share a provider between multiple pages without scoping the entire app.
- [preferences](https://disco.mariuti.com/examples/preferences/) An example showing how to provide async objects with Disco.

## Additional information

### State management

Like already mentioned in the trade-offs section, this package is not opinionated about reactivity: feel free to use your
state management solution of choice (as long as it is compatible with the
concepts of the library).

#### Compatible solutions

Compatible state management solutions are those whose signals/observables can be created locally and passed as arguments, such as
- [`solidart`](https://pub.dev/packages/flutter_solidart) (a solution maintained by the creators of `disco` built to work really well alongside it),
- `ValueNotifier`/`ChangeNotifier` (Flutter's, for those looking to use the bare minimum),
- [`bloc`](https://pub.dev/packages/flutter_bloc) (a popular state management library)
  - **Note:** the usage of `BlocProvider` should be replaced with the providers present in this library.
  - **Note:** using `SignalBuilder` from Solidart with `disco` feels more ergonomic than combining Bloc's `BlocBuilder` with `disco`. If you want a no-boilerplate setup, we recommend going with Solidart instead of Bloc.

#### Incompatible solutions

State management solution entirely leveraging or endorsing global state, such as [`riverpod`](https://pub.dev/packages/riverpod), are not compatible with this library.

### Contributions

PRs are welcome, especially for documentation and more examples.
New features or breaking changes will have to be motivated.

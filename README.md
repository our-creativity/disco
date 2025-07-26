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
- [What is unique about this library](#what-is-unique-about-this-library)
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

## What is unique about this library

The **key difference** between Disco and other established scoped solutions is that **Disco does not rely solely on types** for providing and injecting dependencies; **by contrast**, it uses **globally defined provider instances as identifiers**. This allows for much greater flexibility, especially defining **multiple providers of the same type**.

<details>
<summary><strong>For precise steps on how to use multiple providers of the same type</strong>, click <strong>here</strong> to expand</summary>

### Expanded: Multiple providers of the same type

1. Define multiple providers of the same generic type at the top level.

    ```dart
    final modelProvider = Provider((context) => Model());
    final secondModelProvider = Provider((context) => Model());
    ```

2. Insert a `ProviderScope` at the desired point in the widget tree to define the scope of the providers and make them accessible to the corresponding subtree.

    ```dart
    ProviderScope(
      providers: [modelProvider, secondModelProvider],
      child: MyWidget(),
    )
    ```

3. Inject the provider directly inside a new stateless widget or a stateful widget's state.

    ```dart
    class InjectingWidget extends StatelessWidget {

      const InjectingWidget({super.key});

      @override
      Widget build(BuildContext context) {
        final model = modelProvider.of(context);
        final secondModel = secondModelProvider.of(context);
        // return .. (use model and secondModel here)
      }
    }
    ```

Of course, the providers don’t need to be defined in the same scope to be used together, and they don’t need to be injected in the same widget either. This setup is just meant to demonstrate what’s possible.

</details>

### Typical Scoped DI vs Disco: Side-by-side comparison

Let's consider the — by far — most popular scoped DI package: [Provider](https://pub.dev/packages/provider). It requires you to declare providers directly in the widget tree using something like `Provider(create: (_) => Model())`, and later retrieve them with `context.read<Model>()`. This approach works but is limited — it injects the *first instance of the given type* it finds, which can be restrictive.

The table below highlights the core conceptual difference: traditional DI solutions inject based on **type**, whereas Disco injects based on **provider instances**. If Disco followed the same method-style API as the Provider package, it might look like `context.read(modelProvider)`. This conceptual syntax is not the actual one, but is a bit more intuitive in direct comparisons.

| Solution/Injection             | Inject `Model`                    | Inject second `Model`               |
|--------------------------------|-----------------------------------|-------------------------------------|
| Provider package               | `context.read<Model>()`           | Not possible                        |
| Disco (Conceptual Syntax)      | `context.read(modelProvider)`     | `context.read(secondModelProvider)` |
| Disco (Actual Syntax)          | `modelProvider.of(context)`       | `secondModelProvider.of(context)`   |

Note that Disco intentionally flips the order — the provider comes first — to better align with Flutter conventions (the `.of(context)` part).

Injecting different providers of the same type is not possible with [Provider](https://pub.dev/packages/provider) or other scoped DI libraries in the ecosystem — unless you resort to defining separate wrapper types like `MyModelWrapper1` and `MyModelWrapper2`; such process, however, adds complexity and can make the code harder to reason about.

### Comparison with global solutions

While many existing solutions support multiple providers of the same type (without wrapper types, string identifiers or similar), they typically rely on globally-scoped-endorsed approaches (such as [Riverpod](https://pub.dev/packages/riverpod)). In contrast, **Disco** is — to our knowledge — the **first and only solution** to support multiple providers of the same type **purely through local scoping that aligns with the widget tree structure**  without introducing wrapper types, string identifiers, or similar.

## Trade-offs

### Pros

The pros of Disco are:

- The providers are scoped.
  - The widget tree is fully leveraged.
    - This keeps the architecture simple.
- No global state is possible.
  - Circular dependencies are impossible.
- Multiple providers of the same type are possible.
  - There is no need to create wrapper types or rely on IDs such as strings.
- The API is very simple and feels natural to Flutter.
  - Providers are equipped with `of(context)` and `maybeOf(context)` methods.
  - All you need is `BuildContext`. There is no additional class needed to inject the providers.
- The removal of a provider has an impact on its providing and each of its injections.
  - Each of them is immediately characterized by a static error.
- The values held by the providers are immutable.
  - While immutable, some instances allow for inner mutation.
    - This is great: observables and signals can be passed down.
- No reactivity is included.
  - This library focuses on DI, so that state management solutions can focus on the reactivity.
  - To include reactivity, provide a built-in or third-party observable/signal to the provider (e.g. `Signal`, `ChangeNotifier`, `Cubit`, ...).

### Cons

The cons of this library are:

- Providers might need to be lifted up or down in the widget tree, as requirements change.
- Modals spawn new widget trees, causing disconnection with the providers in the main tree.
  - A special widget must be used to restore access to the providers in the main widget tree.
- It is not fully compile-time safe.
  - The injection of a provider that cannot be found in any scope results in a runtime error.

In Disco's defense regarding the last point:

- Total compile-time safety is not possible with an approach leveraging scoped DI, which is a pattern ubiquitously used in Flutter and third-party libraries (think about how many times you have already read `MediaQuery.of(context)`, `GoRouter.of(context)`, ...).
- Disco providers also have a `maybeOf(context)` method, which can help if the presence of a provider cannot be guaranteed.
- The throwable includes precise information in its stack trace to deduce the missing provider: filepath, line and column.

### Keep in mind

As the authors of Disco, we believe this to be the most effective strategy for DI in Flutter. However, every solution has trade-offs. You can limit the impact of these trade-offs by running tests, doing code reviews, and following other crucial practices.

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

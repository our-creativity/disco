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

Make sure you do not miss [what is unique about this library](#what-is-unique-about-this-library).

The full documentation can be consulted [here](https://disco.mariuti.com).

**Note:** this package is intentionally small and feature-complete, so you might not see frequent updates — but don’t worry; it is still actively maintained, and you can get help anytime from the community/devs if needed.

## Simple usage example

The package supports many features, like providers that accept arguments. But to keep things simple, here is a basic example to get you started:

1. Create a provider top level.

    ```dart
    final modelProvider = Provider((context) => Model());
    ```

    **Note:** the state is never stored globally, directly in the Provider instance; see this provider solely as a type-safe identifier.

2. Scope/provide the provider.

    ```dart
    class ProvidingWidget extends StatelessWidget {
      
      const ProvidingWidget({super.key});

      @override
      Widget build(BuildContext context) {
        return ProviderScope(
          providers: [modelProvider],
          child: MyWidget(),
        );
      }
    }
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

    * `ProvidingWidget`

      * `ProviderScope` — *`modelProvider` is provided here*

        * `MyWidget`

          * ... — widget(s)

            * `InjectingWidget` — *`modelProvider` is injected here*

              * ... — widget(s)

</details>

## What is unique about this library

The **key difference between Disco and other established solutions** is that Disco **does not rely solely on types** for providing and injecting dependencies.

This part dives a bit deeper into technical details. Let's consider the popular [Provider](https://pub.dev/packages/provider) package; it requires you to declare providers directly in the widget tree using something like `Provider(create: (_) => Model())`, and later retrieve them with `context.read<Model>()`. This approach works but is limited — it injects the *first instance of the given type* it finds, which can be restrictive.

Disco, by contrast, uses **globally defined provider instances as identifiers**. This allows for much greater flexibility, including defining **multiple providers of the same type**. For example:

1. Multiple providers of the same type can be defined globally.

    ```dart
    final modelProvider = Provider((context) => Model());
    final secondModelProvider = Provider((context) => Model());
    ```

2. Providers of the same type can be provided in the same scope:

    ```dart
    class ProvidingWidget extends StatelessWidget {
      
      const ProvidingWidget({super.key});

      @override
      Widget build(BuildContext context) {
        return ProviderScope(
          providers: [modelProvider, secondModelProvider],
          child: MyWidget(),
        );
      }
    }
    ```

3. Provers of the same type can also be injected together:

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

This kind of setup is not possible with Provider or other scoped DI libraries in the ecosystem — unless you resort to defining separate wrapper types like `MyModelWrapper1` and `MyModelWrapper2`, which adds complexity and makes the code harder to reason about.

<details>
<summary><strong>If the difference between injection by type and injection by instance is still not clear</strong>, click <strong>here</strong> to expand</summary>

### Expanded: Comparing Injection: Typical Scoped DI vs. Disco

The table below highlights the core conceptual difference: traditional DI solutions inject based on **type**, whereas Disco injects based on **provider instances**. If Disco followed the same method-style API, it might look like `context.read(modelProvider)` — which is more intuitive in direct comparisons.

| Injection Task        | Typical Scoped DI (e.g., Provider) | Disco (Conceptual Syntax)           | Disco (Actual Syntax)            |
|-----------------------|------------------------------------|-------------------------------------|----------------------------------|
| Inject `Model`        | `context.read<Model>()`            | `context.read(modelProvider)`       | `modelProvider.of(context)`      |
| Inject second `Model` | Not possible                       | `context.read(secondModelProvider)` | `secondModelProvider.of(context)` |

Note that Disco intentionally flips the order — the provider comes first — to better align with Flutter conventions (`.of(context)`) and improve clarity. This makes it immediately obvious **what** you are injecting. This syntax is also slightly better for autocomplete and inlay hints display a more concise type.

</details>

### Examples

There are multiple examples on the repository:

- [basic](https://disco.mariuti.com/examples/basic/) A basic example showing the basic usage of Disco.
- [solidart](https://disco.mariuti.com/examples/solidart/) An example showcasing the power of the `ProviderScope` widgets combined with solidart reactivity.
- [bloc](https://disco.mariuti.com/examples/bloc/) An example showcasing how to provide a light/dark theme Cubit with Disco.
- [auto_route](https://disco.mariuti.com/examples/auto-route/) An example showing how to share a provider between multiple pages without scoping the entire app.
- [preferences](https://disco.mariuti.com/examples/preferences/) An example showing how to provide async objects with Disco.

## Additional information

This library can be used in combination with many existing packages.

### State management

This package is not opinionated about reactivity: feel free to use your
state management solution of choice (as long as it is compatible with the
concepts of the library).

#### Compatible solutions

Compatible state management solutions are those whose signals/observables can be created locally and passed as arguments, such as
- [`solidart`](https://pub.dev/packages/flutter_solidart) (a solution maintained by the creators of `disco` built to work really well alongside it),
- `ValueNotifier`/`ChangeNotifier` (Flutter's, for those looking to use the bare minimum),
- [`bloc`](https://pub.dev/packages/flutter_bloc) (a popular state management library)
  - **Note:** the usage of `BlocProvider` should be replaced with the providers present in this library.
  - **Note:** using `SignalBuilder` from Solidart with `disco` feels more ergonomic than combining Bloc's `BlocBuilder` with `disco`. If you want a no-boilerplate setup, we recommend going with Solidart instead of Bloc.

Our repository includes one example with `solidart` and one with `bloc`.

#### Incompatible solutions

State management solution entirely leveraging or endorsing global state, such as [`riverpod`](https://pub.dev/packages/riverpod), are not compatible with this library.

### Contributions

The purpose of this package is to simplify dependency injection for everyone.
PRs are welcome, especially for documentation and more examples.
Another goal of this library is to be simple.
PRs introducing new features or breaking changes will have to be explained in detail.

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

## Simple usage example

The package supports many features, such as providers accepting arguments. The full documentation also includes service locator setup examples.

Here is a simple example:

1. Create a provider top level.

    ```dart
    final modelProvider = Provider((context) => Model());
    ```

    **Note:** the state is never stored directly in the Provider instance; see this provider merely as a type-safe identifier.

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

    **Note:** the actual state for the provider is created and stored inside the `ProviderScope` where the provider is referenced.
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

### Widget tree structure

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

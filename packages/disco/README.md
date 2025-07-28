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

## Table of contents

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
        return Text(model.toString());
      }
    }
    ```

    **Note:** the `ProviderScope` defined in step 2 needs to be an ancestor of this `InjectingWidget` widget.

## What makes this library unique

**Disco** draws inspiration from both [Provider](https://pub.dev/packages/provider) and [Riverpod](https://pub.dev/packages/riverpod) — the two most widely used DI libraries in Flutter, both built around the concept of providers — while aiming to overcome their respective limitations. These libraries have significantly shaped how developers manage state and dependencies: **Provider** supports a simple, **widget-tree–aligned scoping model**, but does not allow multiple providers of the same type. **Riverpod**, by contrast, supports **multiple providers of the same type**, but relies on a globally structured architecture that breaks away from the widget tree.

**Disco** builds on the strengths of both while taking a different path. It is — **to our knowledge** — the **first and only solution** that supports **multiple providers of the same type** (without wrapper types or string keys) using a model that remains **fully local and naturally integrated into the Flutter widget tree** — while reducing the downsides of both to a minimum.

If you would like to explore in detail the pain points of Provider and Riverpod, and how Disco compares, see our page [Comparison with alternatives](https://disco.mariuti.com/miscellaneous/comparison-with-alternatives/).

## Trade-offs

Below is a comparison of the trade-offs between the primary provider-based dependency injection packages — Provider and Riverpod — and Disco, this new alternative.

> Note that many state management libraries rely on these packages for dependency injection; for example, [Bloc offers `BlocProvider`](https://pub.dev/packages/flutter_bloc#blocprovider), which builds on top of Provider.

| Feature / DI Library               | Provider     | Riverpod                           | Disco                                  |
| ------------------------------- | -------------- | ------------------------------------ | ---------------------------------------- |
| **Multiple providers of same type** | ❌ Type is leveraged           | ✅ Provider instance is leveraged | ✅ Provider instance is leveraged   |
| **Lifecycle management**            | ✅ Widget tree    | ❌ Top-level `ProviderScope` by default, or manual | ✅ Widget tree |
| **Works with default Flutter widgets**      | ✅ Compatible             | ❌ `ConsumerWidget` required        | ✅  Compatible                                      |
| **Local state endorsed**            | ✅ Yes             | ❌ No                                   | ✅ Yes                                       |
| **Circular dependencies possible**    | ✅ Never             | ❌ Yes, if the app is not carefully architected        | ✅ Never   |
| **Reactivity methods included**             | ✅ `context.watch`              | ✅ `ref.watch`, `ref.listen`                                       | ❌ Deliberately unopinionated¹  |
| **Mutable state support**           | ⚠️ Usually done via `ChangeNotifier`       | ✅ Built-in                                                           | ⚠️ Allows mutable inner state via observables/signals             |
| **Compile-time safety**             | ❌ Runtime error if provider not found | ✅ No runtime error possible                          | ❌ Runtime error if provider not found² |
| **Fallback support**                | ❌ Not available; try-catch block necessary                                        | ✅ No need                                        | ✅ `maybeOf(context)` for optional injection                      |
| **Modal compatibility**             | ⚠️ Needs to specify all required providers one by one                  | ✅ Scoped globally, no special handling needed                                                    | ✅ Needs `ProviderPortal`, which is a portal to the main tree (all providers are available)      |
| **API simplicity**                  | ✅ Simple                             | ⚠️ Requires learning `WidgetRef`, `ConsumerWidget`, ... | ✅ Very simple                   |
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

As mentioned earlier in the trade-offs section, this package is not opinionated about reactivity: feel free to use your
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

### Development Activity

This package is intentionally small and feature-complete, so you might not see frequent updates — but don’t worry; it is still actively maintained, and you can get help anytime from the community/devs if needed.
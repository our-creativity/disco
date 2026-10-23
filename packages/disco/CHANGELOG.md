## 3.0.0

- **BREAKING**: An argumentless provider has to be called to be inserted into a `ProviderScope`, i.e. `providers: [myProvider()]` instead of `providers: [myProvider]`. This makes the syntax the same for providers with argument and those without.
- **BREAKING**: The `context` a provider receives in its `create` now always belongs to the `ProviderScope` providing it, and no longer to the widget that happens to inject it first. A provider can therefore no longer inject a provider of a `ProviderScope` placed below its own: this used to make the value depend on where it was injected first, and possibly on a value disposed before it. The same holds for the other inherited widgets read in `create` (e.g. `Theme.of`, `Navigator.of`, `Localizations.of`): they are now resolved where the `ProviderScope` is placed. In particular, a `ProviderScope` placed above `MaterialApp` cannot see the `Theme`, the `Navigator` or the localizations of the app:

  ```dart
  final routerProvider = Provider((context) => AppRouter(Navigator.of(context)));

  ProviderScope(
    providers: [routerProvider()],
    child: MaterialApp(
      home: Builder(
        builder: (context) {
          // Before: worked, since `create` got the context of this Builder.
          // Now: throws, since there is no Navigator above the ProviderScope.
          // (`Theme.of` does not throw: it silently returns the default theme.)
          routerProvider.of(context);
          return const HomePage();
        },
      ),
    ),
  )
  ```

  Migrate by placing the `ProviderScope` below `MaterialApp` (e.g. `MaterialApp(home: ProviderScope(providers: [routerProvider()], child: const HomePage()))`), or by reading the inherited widget where the value is used instead of in `create`. See [Inherited widgets in `create`](https://disco.mariuti.com/core/scoped-di/#inherited-widgets-in-create).
- **BREAKING**: `provider.overrideWithValue(value)` is deprecated in favor of `provider.overrideWith(provider)`, which overrides a provider entirely (and not just its value). The mock is a regular provider, with its own `create` and `dispose`. Argument providers are overridden with argument providers, which receive the argument specified in the widget tree. Migrate by replacing `provider.overrideWithValue(value)` with `provider.overrideWith(Provider((_) => value))`.
- **FEAT**: The laziness of a provider can now also be chosen where the provider is inserted into a `ProviderScope`, e.g. `providers: [myProvider(lazy: false)]` or `myArgProvider(arg, lazy: false)`. The first non-null option wins: the `lazy` given in the `ProviderScope` takes precedence over the `lazy` given when defining the provider, which takes precedence over `DiscoConfig.lazy` (default `true`). The laziness is resolved when the `ProviderScope` is mounted, so `DiscoConfig.lazy` no longer has to be set before the providers are defined. See [Lazy creation of the values](https://disco.mariuti.com/core/providers/#lazy-creation-of-the-values).
- **FEAT**: A non-lazy provider can inject the other providers of its own scope, no matter the order in which they are declared. The mock of an overridden provider follows the laziness of the original provider (the `lazy` of the mock is ignored).
- **FIX**: `Provider.withArgument` now defaults `lazy` to `DiscoConfig.lazy`, like `Provider` does, instead of always defaulting to `true`.
- **BREAKING**: The order in which the providers of a `ProviderScope` are declared no longer matters, therefore `ProviderForwardReferenceError` has been removed. Only actual cycles are rejected, with the new `ProviderCircularDependencyError`. See [Scoping correctly with context](https://disco.mariuti.com/core/scoped-di/#scoping-correctly-with-context).
- **FEAT**: The value of an overridden provider now lives in the very same `ProviderScope` where the value of the original provider would have lived, i.e. a mock has the exact same lifecycle as the provider it replaces. See [Testing](https://disco.mariuti.com/core/testing/).
- **FEAT**: The values of a `ProviderScope` are disposed in the reverse order of their creation, so that a value is always disposed before the values it depends on. A throwing `dispose` no longer prevents the remaining values from being disposed.
- **FEAT**: Inserting a provider into (or removing one from) the `providers` list of a mounted `ProviderScope` used to be silently ignored; it is now reported as an error in debug mode. See [Immutability](https://disco.mariuti.com/core/immutability/#the-set-of-providers-is-fixed).
- **FIX**: A provider injecting an overridden provider of the same scope got the original provider instead of its override.
- **FIX**: The value of an overridden provider is no longer created (it used to be created, and disposed, whenever the original provider was not lazy).
- **FIX**: A mock passed to `overrideWith` can now inject other providers.
- **FIX**: Reusing the same mock to override more than one provider no longer makes those providers share a single value.
- **CHORE**: `ProviderScope.providers` and `ProviderScope.overrides` are no longer part of the public API, as exactly one of them was always null.
- **CHORE**: The bookkeeping of `ProviderScopeState` (its maps of providers and values, and its lookup and creation methods) and `ProviderScopeOverrideState.providerScopeState` are now library-private.
- **CHORE**: Rename `InstantiableProvider` to `ValueBinding`.

## 2.0.0

- **FEAT**: Allow providers in the same `ProviderScope` to depend on previously declared providers. This simplifies the development experience. This friendlier syntax does not introduce circular dependencies.
- **FEAT**: Add `debugName` parameter to providers for easier debugging, allowing better identification of providers in error messages and logs.
- **FEAT**: Introduce the new `disco_lint` package to help avoid common mistakes and simplify repetitive tasks.

## 1.0.3+1

- **CHORE**: Improve documentation.
- **CHORE**: Fix automatic deployment to pub.dev (GitHub workflow).

## 1.0.3

- **FIX**: Disposal of provider with arguments.

## 1.0.2

- **FIX**: A bug prevented users to inject providers with arguments from a `ProviderScope` which was placed inside a `ProviderScopePortal`.

## 1.0.1

- **FIX**: A bug prevented users to inject providers from a `ProviderScope` which was placed inside a `ProviderScopePortal`.

## 1.0.0+1

- **CHORE**: Update README.md

## 1.0.0

- Added comprehensive documentation (see [Disco homepage](https://disco.mariuti.com)) with numerous examples.

## 0.0.2

- Fix imports, simplify file names and correct repository URL.

## 0.0.1

- Initial version. The providers were moved from the package solidart.
  - [Compile-time safer providers](https://github.com/nank1ro/solidart/pull/101)
  - [Provider Scope](https://github.com/nank1ro/solidart/pull/103)

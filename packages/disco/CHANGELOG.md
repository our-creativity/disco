## 3.0.0

- **BREAKING**: A provider has to be called to be inserted into a `ProviderScope`, i.e. `providers: [myProvider()]` instead of `providers: [myProvider]`. This makes the syntax the same for both providers and argument providers.
- **BREAKING**: `provider.overrideWithValue(value)` has been replaced by `provider.overrideWith(provider)`, which overrides a provider entirely (and not just its value). The mock is a regular provider, with its own `create`, `dispose` and `lazy` parameters. Argument providers are overridden with argument providers, which receive the argument specified in the widget tree.

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

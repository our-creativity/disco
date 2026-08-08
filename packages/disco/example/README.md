# disco (example)

An example that uses Disco. Every page demonstrates a different feature, and a
"lifecycle log" panel shows when the values of the providers get created and
disposed.

| Page | Shows |
| --- | --- |
| Home | A plain provider scoped to the page, injected with `of(context)` |
| Providers with arguments | `Provider.withArgument`, `dispose`, and injecting a provider of an ancestor scope |
| Nested scopes | Two scopes providing the same provider: the nearest one wins |
| Modals | `ProviderScopePortal`, and what happens in a dialog without it |
| Lazy and eager providers | `lazy: false` versus the default lazy creation |
| Recreating a scope | Forcing a new value by changing the `key` of a `ProviderScope` |
| Missing providers | `of` throwing a `ProviderWithoutScopeError`, versus `maybeOf` returning `null` |

Overriding providers with `overrideWith` is meant for testing only, therefore
it is demonstrated in `test/disco_test.dart` instead.

## Run

```sh
flutter run
```

## Test

```sh
flutter test
```

---
title: Configuration
description: How to set up the application-wide configuration for Disco.
---

Disco aims to be minimally opinionated. To customize the default configuration, set the desired preferences using `DiscoConfig` before calling `runApp`. For example:

```dart
DiscoConfig.lazy = false;
runApp(
  // ...
);
```

### All options

| Option         | Default | Description |
| -------------- | ------- | ----------- |
| `lazy`         | true    | Whether the values of the providers are created lazily. It is only used for the providers whose laziness is specified neither when they are inserted into a `ProviderScope` (e.g. `myProvider(lazy: false)`) nor when they are defined (e.g. `Provider(create, lazy: false)`). See [Lazy creation of the values](https://disco.mariuti.com/core/providers/#lazy-creation-of-the-values). |

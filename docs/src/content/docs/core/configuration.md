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
| `lazy`         | true    | The values of the providers provided in a `ProviderScope` are created lazily. |

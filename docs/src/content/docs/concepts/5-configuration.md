---
title: Configuration
description: How to set up application-wide configuration
---

Disco is as little opinionated as possible. If you want to change the default configuration, set the right preferences with `DiscoConfig` before calling `runApp`. For example:

```dart
DiscoConfig.lazy = false;
runApp(
  // ...
);
```

### All options

| Option         | Default | Description |
| ---------------| ------- | ------------|
| `lazy`           | true    | The values of the providers provided in a `ProviderScope` are created lazily. |

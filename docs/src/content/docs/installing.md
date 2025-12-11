---
title: Installing
description: How to install Disco, either by command line or manually.
---

### Install via command line or VSCode extension

To add Disco to your project, open a terminal in your project’s root directory and run:

```nu
flutter pub add disco
```

You can also use the VSCode extension (>Dart: Add Dependency).

### Install manually

Alternatively, you can add Disco manually by updating your `pubspec.yaml` file as follows:

```yaml {4,8}
name: # your app name

environment:
  sdk: ^3.10.0 # Dart SDK version must be >=3.6.0 to support disco
  flutter: ">=3.27.0"

dependencies:
  disco: ^1.0.0
  flutter:
    sdk: flutter
```

After updating the file, run `flutter pub get` in your terminal to fetch the dependencies.

## Linter

Disco provides an analyzer package called `disco_lint` to help you avoid common mistakes and simplify repetitive tasks (e.g. `Wrap with ProviderScope`).
Be sure to have the Dart SDK version `>= 3.10.0` and the Flutter SDK `>= 3.38.0`.

Then edit your `analysis_options.yaml` file and add these lines of code:

```yaml
plugins:
  disco_lint: ^1.0.0
```

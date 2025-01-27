---
title: Installing
description: How to install Disco, either by command line or manually.
---

**NB:** Disco leverages Pub workspaces, a feature introduced in Dart SDK 3.6.0. This version of Dart is paired with Flutter 3.27.0, both released on December 11, 2024.

### Install via command line or VSCode extension

To add Disco to your project, open a terminal in your project’s root directory and run:

```nu
flutter pub add disco
```

You can also use the VSCode extension (>Dart: Add Dependency).

### Install manually

Alternatively, you can add Disco manually by updating your `pubspec.yaml` file as follows:

```yaml
name: # your app name

environment:
  sdk: ">=3.6.0 <4.0.0"
  flutter: ">=3.27.0"

dependencies:
  disco: ^1.0.0
  flutter:
    sdk: flutter
```

After updating the file, run `flutter pub get` in your terminal to fetch the dependencies.

# Copilot Instructions

## Project Overview

**Disco** is a Flutter library providing scoped dependency injection that is independent of any specific state management solution. It is organized as a Dart workspace (monorepo).

Key packages:
- `packages/disco` — the main library published to pub.dev.
- `packages/disco_lint` — a custom lint plugin for Disco-specific lint rules.
- `examples/` — runnable Flutter example apps.

## Repository Structure

```
disco/
├── packages/
│   ├── disco/          # Main library (lib/, test/, benchmark/, example/)
│   └── disco_lint/     # Custom lint plugin (lib/, example/)
├── examples/           # Example Flutter apps
├── pubspec.yaml        # Workspace root — links all packages together
└── analysis_options.yaml
```

## Build & Dependency Installation

Install dependencies from the workspace root:

```bash
flutter pub get
```

## Testing

Run the test suite for the main library:

```bash
cd packages/disco
flutter test
```

Run with coverage:

```bash
cd packages/disco
flutter test --coverage
```

## Linting & Static Analysis

Run Dart static analysis from the workspace root:

```bash
dart analyze
```

The project uses [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) (strict lint rules). All lint warnings must be resolved before merging.

## Code Style

- Follow the [Dart style guide](https://dart.dev/effective-dart/style).
- Comply with `very_good_analysis` rules — treat all lint warnings as errors.
- **Do NOT use `const` constructors on `Provider` subclasses.** Providers are used as identity keys; `const` would cause providers with the same signature to share the same hash code, making them indistinguishable. The `prefer_const_constructors_in_immutables` lint rule is intentionally disabled.
- Keep the public API minimal and well-documented with DartDoc comments.
- New features or breaking changes require a motivation/discussion before implementation.

## Adding / Changing Dependencies

- Add dependencies only to the relevant `pubspec.yaml` (e.g. `packages/disco/pubspec.yaml`), not the workspace root.
- Prefer Flutter/Dart SDK packages and packages already in use before introducing new ones.
- Run `flutter pub get` after any `pubspec.yaml` change.

## Pull Request Guidelines

- Include tests for any new behaviour in `packages/disco/test/`.
- Update `CHANGELOG.md` in `packages/disco/` for user-facing changes.
- Documentation lives at <https://disco.mariuti.com>; update the `docs/` folder if the public API changes.
- PRs that only touch `**.md` files skip CI automatically (see `flutter-test.yaml`).

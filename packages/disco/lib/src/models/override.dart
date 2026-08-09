part of '../disco_internal.dart';

/// A declarative configuration holding all the data needed to
/// construct and register an mock provider within a
/// [ProviderScope].
///
/// Concretely, it is either one of:
/// - [ProviderOverride]
/// - [ArgProviderOverride].
@immutable
sealed class Override {
  Override._();
}

/// Override that, if inserted into the widget tree, gives [_mockArgProvider]
/// precedence over [_originalArgProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._withArgProvider(
    this._originalArgProvider,
    this._mockArgProvider,
  ) : super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _originalArgProvider;

  /// The reference of the argument provider override.
  final ArgProvider<T, A> _mockArgProvider;
}

/// Override that, if inserted into the widget tree, gives [_mockProvider]
/// precedence over [_originalProvider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._withProvider(
    this._originalProvider,
    this._mockProvider,
  ) : super._();

  /// The reference of the provider to override.
  final Provider<T> _originalProvider;

  /// The reference of the provider override.
  final Provider<T> _mockProvider;
}

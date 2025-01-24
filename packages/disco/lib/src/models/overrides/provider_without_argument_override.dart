part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_provider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._(
    this._provider,
    T value,
    DisposeProviderValueFn<T>? disposeValue,
  )   : _value = value,
        _disposeValue = disposeValue,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final DisposeProviderValueFn<T>? _disposeValue;

  final T _value;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (_) => _value,
        dispose: _disposeValue,
        lazy: false,
      );
}

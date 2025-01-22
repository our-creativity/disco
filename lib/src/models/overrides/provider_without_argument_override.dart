part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_provider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._(
    this._provider, {
    CreateProviderValueFn<T>? createValue,
    DisposeProviderValueFn<T>? disposeValue,
    bool? lazy,
  })  : _createValue = createValue,
        _disposeValue = disposeValue,
        _lazy = lazy,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final CreateProviderValueFn<T>? _createValue;

  final DisposeProviderValueFn<T>? _disposeValue;

  final bool? _lazy;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (context) =>
            _createValue?.call(context) ?? _provider._createValue(context),
        disposeValue: _disposeValue ?? _provider._disposeValue,
        lazy: _lazy ?? _provider._lazy,
      );
}

part of '../../disco_internal.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_provider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._(
    this._provider,
    T value,
  )   : _value = value,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final T _value;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (_) => _value,
        lazy: false,
      );
}

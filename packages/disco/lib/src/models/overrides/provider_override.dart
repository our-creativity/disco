part of '../../disco_internal.dart';

sealed class _ProviderOverrideType<T extends Object> {}

// TODO (manuel-plavsic): I would get rid of this (and remove sealed class)
final class _ProviderOverrideWithValue<T extends Object>
    extends _ProviderOverrideType<T> {
  _ProviderOverrideWithValue._(this.value, this.debugName);
  final T value;

  /// {@macro Provider.debugName}
  final String? debugName;
}

final class _ProviderOverrideWithProvider<T extends Object>
    extends _ProviderOverrideType<T> {
  _ProviderOverrideWithProvider._(this.mockProvider);
  final Provider<T> mockProvider;
}

/// Override that, if inserted into the widget tree, takes precedence over
/// [_originalProvider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._withValue(
    this._originalProvider,
    T value,
    String? debugName,
  ) : _overrideType = _ProviderOverrideWithValue._(value, debugName),
      super._();

  ProviderOverride._withProvider(
    this._originalProvider,
    Provider<T> mockProvider,
  ) : _overrideType = _ProviderOverrideWithProvider._(mockProvider),
      super._();

  /// The reference of the provider to override.
  final Provider<T> _originalProvider;

  final _ProviderOverrideType<T> _overrideType;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => switch (_overrideType) {
    // TODO (manuel-plavsic): I would get rid of this
    _ProviderOverrideWithValue(:final T value) => Provider<T>(
      (_) => value,
      lazy: false,
    ),
    // TODO (manuel-plavsic): I would keep only this (and remove pattern matching)
    _ProviderOverrideWithProvider(:final Provider<T> mockProvider) =>
      mockProvider,
  };
}

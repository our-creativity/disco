part of '../../disco_internal.dart';

sealed class _ArgProviderOverrideType<T extends Object, A> {}

// TODO (manuel-plavsic): I would get rid of this (and remove sealed class)
final class _ArgProviderOverrideWithValue<T extends Object, A>
    extends _ArgProviderOverrideType<T, A> {
  _ArgProviderOverrideWithValue._(this.argument, this.value, this.debugName);

  final A argument;

  final T value;

  /// {@macro Provider.debugName}
  final String? debugName;
}

final class _ArgProviderOverrideWithProvider<T extends Object, A>
    extends _ArgProviderOverrideType<T, A> {
  _ArgProviderOverrideWithProvider._(this.mockProvider);
  final ArgProvider<T, A> mockProvider;
}

/// Override that, if inserted into the widget tree, takes precedence over
/// [_originalArgProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._withValue(
    this._originalArgProvider,
    A arg,
    T value,
    String? debugName,
  ) : _overrideType = _ArgProviderOverrideWithValue._(
        arg,
        value,
        debugName,
      ),
      super._();

  ArgProviderOverride._withArgProvider(
    this._originalArgProvider,
    ArgProvider<T, A> mockProvider,
  ) : _overrideType = _ArgProviderOverrideWithProvider._(mockProvider),
      super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _originalArgProvider;

  /// The overridden value.
  final _ArgProviderOverrideType<T, A> _overrideType;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => switch (_overrideType) {
    // TODO (manuel-plavsic): I would get rid of this
    _ArgProviderOverrideWithValue(:final T value) => Provider<T>(
      (_) => value,
      lazy: false,
    ),
    // TODO (manuel-plavsic): I would keep only this part below (and remove pattern matching)
    // TODO (manuel-plavsic): this requires a major change in ProviderScope: a new layer of intermediate providers should be added (this time of type ArgProvider, not just Provider)
    _ArgProviderOverrideWithProvider(:final ArgProvider<T, A> mockProvider) =>
      mockProvider,
  };
}

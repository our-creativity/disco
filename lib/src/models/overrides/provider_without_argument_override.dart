part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_provider].
@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._(
    this._provider, {
    CreateProviderFn<T>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  })  : _create = create,
        _dispose = dispose,
        _lazy = lazy,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final CreateProviderFn<T>? _create;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (context) => _create?.call(context) ?? _provider._create(context),
        dispose: _dispose ?? _provider._dispose,
        lazy: _lazy ?? _provider._lazy,
      );
}

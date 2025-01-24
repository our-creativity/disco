part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_argProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._(
    this._argProvider,
    T value,
    DisposeProviderValueFn<T>? disposeValue,
  )   : _value = value,
        _disposeValue = disposeValue,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// The overridden value.
  final T _value;

  final DisposeProviderValueFn<T>? _disposeValue;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (_) => _value,
        dispose: _disposeValue,
        lazy: false,
      );
}

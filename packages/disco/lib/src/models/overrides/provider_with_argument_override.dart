part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_argProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._(
    this._argProvider, {
    required A argument,
    CreateArgProviderValue<T, A>? createValue,
    DisposeProviderValueFn<T>? disposeValue,
    bool? lazy,
  })  : _argument = argument,
        _createValue = createValue,
        _disposeValue = disposeValue,
        _lazy = lazy,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// @macro Provider.create}
  final CreateArgProviderValue<T, A>? _createValue;

  final A? _argument;

  final DisposeProviderValueFn<T>? _disposeValue;

  final bool? _lazy;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider(A arg) => Provider<T>(
        (context) =>
            _createValue?.call(context, arg) ??
            _argProvider._createValue(context, arg),
        dispose: _disposeValue ?? _argProvider._disposeValue,
        lazy: _lazy ?? _argProvider._lazy,
      );
}

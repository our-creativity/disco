part of '../../../disco.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_argProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._(
    this._argProvider, {
    required A argument,
    CreateProviderFnWithArg<T, A>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  })  : _create = create,
        _argument = argument,
        _dispose = dispose,
        _lazy = lazy,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// @macro Provider.create}
  final CreateProviderFnWithArg<T, A>? _create;

  final A? _argument;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider(A arg) => Provider<T>(
        (context) =>
            _create?.call(context, arg) ?? _argProvider._create(context, arg),
        dispose: _dispose ?? _argProvider._dispose,
        lazy: _lazy ?? _argProvider._lazy,
      );
}

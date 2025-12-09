part of '../../disco_internal.dart';

/// Override that, if inserted into the widget tree, takes precedence over
/// [_argProvider].
@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._(this._argProvider, T value, {this.debugName})
      : _value = value,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// The overridden value.
  final T _value;

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider() => Provider<T>(
        (_) => _value,
        lazy: false,
      );

  /// {@macro Provider.debugName}
  final String? debugName;
}

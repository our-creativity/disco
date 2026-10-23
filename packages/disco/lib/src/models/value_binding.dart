part of '../disco_internal.dart';

/// A declarative configuration holding all the data needed to construct and
/// register an intermediate provider - and thus a lazy value - within a
/// [ProviderScope].
/// It specifies all needed information (e.g., the argument in case of an
/// [ArgProvider]).
///
/// This class acts as a lightweight blueprint. No actual value instantiation
/// or state evaluation occurs here; instead, value instantiation happens in
/// the [ProviderScope].
///
/// Concretely, it is either one of:
/// - [ProviderValueBinding]
/// - [ArgProviderValueBinding]
@immutable
sealed class ValueBinding {
  ValueBinding._({required bool? lazy}) : _lazy = lazy;

  /// {@template ValueBinding.lazy}
  /// Whether the value is created lazily in this [ProviderScope], i.e. the
  /// first time it is injected. If null, the laziness specified when the
  /// provider has been defined is used.
  /// {@endtemplate}
  ///
  /// {@macro lazy.precedence}
  final bool? _lazy;
}

/// {@template ArgProviderValueBinding}
/// Binds an [ArgProvider] along with its required initial argument [A]
/// for registration in a [ProviderScope].
/// {@endtemplate}
@immutable
class ArgProviderValueBinding<T extends Object, A> extends ValueBinding {
  /// {@macro ArgProviderValueBinding}
  ArgProviderValueBinding._(
    this._argProvider,
    this._arg, {
    required super.lazy,
  }) : super._();
  final ArgProvider<T, A> _argProvider;
  final A _arg;
}

/// {@template ProviderValueBinding}
/// Binds a standard [Provider] for registration in a [ProviderScope].
///
/// While a standard provider does not require arguments, wrapping it in a
/// [ProviderValueBinding] provides a uniform API for all entries in the
/// widget tree alongside [ArgProviderValueBinding].
/// {@endtemplate}
class ProviderValueBinding<T extends Object> extends ValueBinding {
  /// {@macro ProviderValueBinding}
  ProviderValueBinding._(this._provider, {required super.lazy}) : super._();
  final Provider<T> _provider;
}

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
  ValueBinding._();
}

/// {@template ArgProviderValueBinding}
/// Binds an [ArgProvider] along with its required initial argument [A]
/// for registration in a [ProviderScope].
/// {@endtemplate}
@immutable
class ArgProviderValueBinding<T extends Object, A> extends ValueBinding {
  /// {@macro ArgProviderValueBinding}
  ArgProviderValueBinding._(this._argProvider, this._arg) : super._();
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
  ProviderValueBinding._(this._provider) : super._();
  final Provider<T> _provider;
}

part of '../../disco_internal.dart';

/// Either one of:
/// - [InstantiableNoArgProvider]
/// - [InstantiableArgProvider]
@immutable
sealed class InstantiableProvider {
  InstantiableProvider._();
}

/// {@template InstantiableProvider}
/// An instance of this class is needed to insert a [Provider] into the
/// widget tree. This class is not strictly necessary; however, it guarantees
/// that the insertion into the widget tree is exactly the same as
/// what happens with [ArgProvider].
/// {@endtemplate}
class InstantiableNoArgProvider<T extends Object> extends InstantiableProvider {
  /// {@macro InstantiableProvider}
  InstantiableNoArgProvider._(this._provider) : super._();
  final Provider<T> _provider;
}

/// {@template InstantiableArgProvider}
/// An instance of this class is needed to insert an [ArgProvider] into the
/// widget tree. This ensures that an initial argument is always present and,
/// thus, the [ArgProvider] can be correctly created.
/// {@endtemplate}
@immutable
class InstantiableArgProvider<T extends Object, A>
    extends InstantiableProvider {
  /// {@macro InstantiableArgProvider}
  InstantiableArgProvider._(this._argProvider, this._arg) : super._();
  final ArgProvider<T, A> _argProvider;
  final A _arg;
}

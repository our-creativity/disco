// ignore_for_file: prefer_const_constructors_in_immutables

part of '../../../disco.dart';

/// A function that creates an object of type [T] with an argument of type [A].
typedef CreateProviderFnWithArg<T, A> = T Function(BuildContext context, A arg);

/// {@template ArgProvider}
/// A [Provider] that needs to be given an initial argument before
/// it can be used.
/// {@endtemplate}
@immutable
class ArgProvider<T extends Object, A> {
  /// {@macro ArgProvider}
  ArgProvider._(
    CreateProviderFnWithArg<T, A> create, {
    DisposeProviderFn<T>? dispose,
    bool lazy = true,
  })  : _create = create,
        _lazy = lazy,
        _dispose = dispose;

  /// {@macro Provider.lazy}
  final bool _lazy;

  /// {@macro Provider.create}
  final CreateProviderFnWithArg<T, A> _create;

  /// {@macro Provider.dispose}
  final DisposeProviderFn<T>? _dispose;

  // Overrides ----------------------------------------------------------------

  ArgProviderOverride<T, A> overrideWith({
    required A argument,
    CreateProviderFnWithArg<T, A>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  }) =>
      ArgProviderOverride._(
        this,
        argument: argument,
        create: create,
        dispose: dispose,
        lazy: lazy,
      );

  // DI methods ---------------------------------------------------------------

  /// Injects the value held by a provider. In case the provider is not found,
  /// it throws a [ProviderWithoutScopeError].
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) {
      throw ArgProviderWithoutScopeError(this);
    }
    return provider;
  }

  /// Injects the value held by a provider. In case the provider is not found,
  /// it returns null.
  T? maybeGet(BuildContext context) {
    return ProviderScope._getOrCreateArgProvider(context, id: this);
  }

  // Utils leveraged by ProviderScope -----------------------------------------

  /// It creates an [InstantiableArgProvider] with the passed argument.
  /// This ensures that an [ArgProvider] inserted into the widget tree always
  /// has an initial argument and, thus, can be created.
  InstantiableArgProvider<T, A> call(A arg) {
    return InstantiableArgProvider._(this, arg);
  }

  /// Returns the type of the value
  Type get _valueType => T;

  /// Returns the type of the arg
  Type get _argumentType => A;

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateIntermediateProvider(A arg) => Provider<T>(
        (context) => _create(context, arg),
        dispose: _dispose,
        lazy: _lazy,
      );
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

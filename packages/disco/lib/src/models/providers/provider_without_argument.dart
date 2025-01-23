part of '../../../disco.dart';

/// A function that creates an object of type [T].
typedef CreateProviderValueFn<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
typedef DisposeProviderValueFn<T> = void Function(T value);

/// {@template provider}
/// A Provider that manages the lifecycle of the value it provides by
/// delegating to a pair of [_createValue] and [_disposeValue].
///
/// It is usually used to avoid making a StatefulWidget for something trivial,
/// such as instantiating a BLoC.
///
/// Provider is the equivalent of a State.initState combined with State.dispose.
/// [_createValue] is called only once in State.initState.
/// The `create` callback is lazily called. It is called the first time the
/// value is read, instead of the first time Provider is inserted in the widget
/// tree.
/// This behavior can be disabled by passing [_lazy] false.
///
/// {@endtemplate}
@immutable
class Provider<T extends Object> extends InstantiableProvider {
  //! NB: do not make the constructor `const`, since that would give the same
  //! hash code to different instances of `Provider` with the same generic
  //! type.

  /// {@macro provider}
  Provider(
    /// @macro Provider.create}
    CreateProviderValueFn<T> create, {
    /// {@macro Provider.dispose}
    DisposeProviderValueFn<T>? dispose,

    /// {@macro Provider.lazy}
    bool lazy = true,
  })  : _createValue = create,
        _disposeValue = dispose,
        _lazy = lazy,
        super._();

  /// {@macro arg-provider}
  static ArgProvider<T, A> withArgument<T extends Object, A>(
    CreateArgProviderValue<T, A> create, {
    DisposeProviderValueFn<T>? dispose,
    bool lazy = true,
  }) =>
      ArgProvider._(create, disposeValue: dispose, lazy: lazy);

  /// {@template Provider.lazy}
  /// Makes the creation of the provided value lazy. Defaults to true.
  ///
  /// NB: the provider itself is not lazily created, only its contained value.
  ///
  /// If this value is true, the provider's value will be created only
  /// when retrieved from descendants for the first time.
  /// {@endtemplate}
  final bool _lazy;

  /// {@template Provider.create}
  /// The function called to create the element.
  /// {@endtemplate}
  final CreateProviderValueFn<T> _createValue;

  /// {@template Provider.dispose}
  /// An optional dispose function called when the [ProviderScope] that created
  /// this provider gets disposed. Its purpose is to dispose the provided
  /// value, not the provider itself.
  /// {@endtemplate}
  final DisposeProviderValueFn<T>? _disposeValue;

  // Overrides ----------------------------------------------------------------

  /// It creates an override of this provider to be passed to
  /// [ProviderScopeOverride].
  @visibleForTesting
  ProviderOverride<T> overrideWith({
    CreateProviderValueFn<T>? create,
    DisposeProviderValueFn<T>? dispose,
    bool? lazy,
  }) =>
      ProviderOverride._(
        this,
        createValue: create,
        disposeValue: dispose,
        lazy: lazy,
      );

  // DI methods ---------------------------------------------------------------

  /// Injects the value held by a provider. In case the provider is not found,
  /// it throws a [ProviderWithoutScopeError].
  ///
  /// NB: You should prefer [maybeGet] over [get] to retrieve a provider
  /// which you are aware it could be not present.
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) throw ProviderWithoutScopeError(this);
    return provider;
  }

  /// Injects the value held by a provider. In case the provider is not found,
  /// it returns null.
  T? maybeGet(BuildContext context) {
    return ProviderScope._getOrCreateProviderValue(context, id: this);
  }

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Function internally used by [_ProviderScopeState] that calls
  /// [_disposeValue].
  ///
  /// This method is necessary to ensure that `value` is correctly casted as
  /// `T` instead of `Object` (what the dispose method of
  /// [_ProviderScopeState] otherwise assumes).
  void _safeDisposeValue(Object value) {
    _disposeValue?.call(value as T);
  }

  /// Returns the type of the value.
  Type get _valueType => T;

  // NB: unlike ArgProvider and the Override classes, there is no
  // _generateIntermediateProvider, as the provider itself can
  // be used as its own intermediate provider.
}

part of '../../disco_internal.dart';

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
    bool? lazy,
    this.debugName,
  })  : _createValue = create,
        _disposeValue = dispose,
        _lazy = lazy ?? DiscoConfig.lazy,
        super._();

  /// {@macro arg-provider}
  static ArgProvider<T, A> withArgument<T extends Object, A>(
    CreateArgProviderValueFn<T, A> create, {
    DisposeProviderValueFn<T>? dispose,
    bool lazy = true,
    String? debugName,
  }) =>
      ArgProvider._(create, dispose: dispose, lazy: lazy, debugName: debugName);

  /// {@template Provider.lazy}
  /// Makes the creation of the provided value lazy. defaults to true.
  ///
  /// > The provider itself is not lazily created, only its contained value.
  ///
  /// if this value is true, the provider's value will be created only when
  /// retrieved from descendants for the first time.
  /// {@endtemplate}
  final bool _lazy;

  /// {@template Provider.create}
  /// The function called to create the element.
  /// {@endtemplate}
  final CreateProviderValueFn<T> _createValue;

  /// {@template Provider.dispose}
  /// An optional dispose function called when the [ProviderScope] that created
  /// this provider gets disposed. Its purpose is to dispose the provided
  /// value.
  /// {@endtemplate}
  final DisposeProviderValueFn<T>? _disposeValue;

  // Overrides ----------------------------------------------------------------

  /// {@template Provider.overrideWithValue}
  /// It creates an override of this provider to be passed to
  /// [ProviderScopeOverride].
  /// {@endtemplate}
  @visibleForTesting
  ProviderOverride<T> overrideWithValue(T value) =>
      ProviderOverride._(this, value);

  // DI methods ---------------------------------------------------------------

  /// {@template Provider.of}
  /// Injects the value held by a provider. In case the provider is not found,
  /// it throws a [ProviderWithoutScopeError].
  ///
  /// NB: You should prefer [maybeOf] over [of] to retrieve a provider
  /// which you are aware it could be not present.
  /// {@endtemplate}
  T of(BuildContext context) {
    final provider = maybeOf(context);
    if (provider == null) throw ProviderWithoutScopeError(this);
    return provider;
  }

  /// {@template Provider.maybeOf}
  /// Injects the value held by a provider. In case the provider is not found,
  /// it returns null.
  /// {@endtemplate}
  T? maybeOf(BuildContext context) {
    return ProviderScope._getOrCreateProviderValue(context, id: this);
  }

  // Utils leveraged by ProviderScope -----------------------------------------

  /// Function internally used by [ProviderScopeState] that calls
  /// [_disposeValue].
  ///
  /// This method is necessary to ensure that `value` is correctly casted as
  /// `T` instead of `Object` (what the dispose method of
  /// [ProviderScopeState] otherwise assumes).
  void _safeDisposeValue(Object value) {
    _disposeValue?.call(value as T);
  }

  /// Returns the type of the value.
  Type get _valueType => T;

  /// {@template Provider.debugName}
  /// An optional debug name for this provider.
  /// {@endtemplate}
  final String? debugName;
}

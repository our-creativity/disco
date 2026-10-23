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
/// The `create` callback is called lazily by default, i.e. the first time the
/// value is injected, and not when the provider is inserted into the widget
/// tree. Pass `lazy: false` to create the value as soon as the [ProviderScope]
/// providing it is mounted, either when defining the provider or when
/// inserting it into a [ProviderScope]:
///
/// ```dart
/// final myProvider = Provider((_) => MyValue(), lazy: false);
///
/// ProviderScope(
///   providers: [otherProvider(lazy: false)],
///   child: const MyChild(),
/// )
/// ```
///
/// {@endtemplate}
///
/// {@template lazy.precedence}
/// The laziness of a value is resolved when the [ProviderScope] providing it
/// is mounted, by taking the first non-null option among:
///
/// 1. the `lazy` given when inserting the provider into the [ProviderScope],
///    e.g. `myProvider(lazy: false)`;
/// 2. the `lazy` given when defining the provider, e.g.
///    `Provider((_) => MyValue(), lazy: false)`;
/// 3. [DiscoConfig.lazy], which defaults to true.
///
/// A non-lazy value is created as soon as its [ProviderScope] is mounted,
/// before the descendants of the scope are built.
///
/// NB: the mock of an overridden provider is created exactly when the value
/// of the original provider would have been created. Therefore, the laziness
/// of the original provider is used, and the `lazy` of the mock is ignored.
/// {@endtemplate}
@immutable
class Provider<T extends Object> {
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
  }) : _createValue = create,
       _disposeValue = dispose,
       _lazy = lazy;

  /// {@macro arg-provider}
  static ArgProvider<T, A> withArgument<T extends Object, A>(
    CreateArgProviderValueFn<T, A> create, {
    DisposeProviderValueFn<T>? dispose,
    bool? lazy,
    String? debugName,
  }) => ArgProvider._(
    create,
    dispose: dispose,
    lazy: lazy,
    debugName: debugName,
  );

  /// {@template Provider.lazy}
  /// Whether the value is created lazily, i.e. the first time it is injected.
  /// If null, [DiscoConfig.lazy] is used.
  /// {@endtemplate}
  ///
  /// {@macro lazy.precedence}
  final bool? _lazy;

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

  // Override -----------------------------------------------------------------

  /// {@template Provider.overrideWithProvider}
  /// It creates an override of this provider to be passed to
  /// [ProviderScopeOverride].
  /// {@endtemplate}
  @visibleForTesting
  ProviderOverride<T> overrideWith(
    Provider<T> override,
  ) => ProviderOverride._withProvider(this, override);

  /// Deprecated: Use [overrideWith] instead.
  ///
  /// This method is deprecated and will be removed in a future version.
  /// Use `provider.overrideWith(Provider((_) => value))` instead.
  @Deprecated('Use overrideWith(Provider((_) => value)) instead')
  @visibleForTesting
  ProviderOverride<T> overrideWithValue(T value) =>
      overrideWith(Provider<T>((_) => value));

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

  /// This method creates a [ProviderValueBinding]. You should interpret this
  /// as following: this method creates all necessary "instructions"/"data" for
  /// [ProviderScope] to actually generate an intermediate provider, and thus
  /// also an actual value (note that the value may be computed lazily).
  ///
  /// [lazy]: {@macro ValueBinding.lazy}
  ///
  /// {@macro lazy.precedence}
  ProviderValueBinding<T> call({bool? lazy}) {
    return ProviderValueBinding._(this, lazy: lazy);
  }

  /// Creates a new [Provider] behaving exactly like this one.
  ///
  /// This method is used internally by [ProviderScope] to generate the
  /// intermediate provider of an overridden provider. Generating a fresh
  /// instance guarantees that the same mock can override more than one
  /// provider without the resulting values being shared, since the values are
  /// keyed by their intermediate provider.
  Provider<T> _generateIntermediateProvider() => Provider<T>(
    _createValue,
    dispose: _disposeValue,
    debugName: debugName,
  );

  /// Returns the type of the value.
  Type get _valueType => T;

  /// {@template Provider.debugName}
  /// An optional debug name for this provider.
  /// {@endtemplate}
  final String? debugName;
}

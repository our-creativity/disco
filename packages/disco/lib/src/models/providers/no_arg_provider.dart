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
/// The `create` callback is always called lazily, i.e. the first time the value
/// is injected, and not when the provider is inserted into the widget tree.
///
/// > If you need a value to be created as soon as its [ProviderScope] is
/// > mounted, inject it in a widget placed right below the scope:
/// >
/// > ```dart
/// > ProviderScope(
/// >   providers: [myProvider()],
/// >   child: Builder(
/// >     builder: (context) {
/// >       myProvider.of(context);
/// >       return const MyChild();
/// >     },
/// >   ),
/// > )
/// > ```
///
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
    this.debugName,
  }) : _createValue = create,
       _disposeValue = dispose;

  /// {@macro arg-provider}
  static ArgProvider<T, A> withArgument<T extends Object, A>(
    CreateArgProviderValueFn<T, A> create, {
    DisposeProviderValueFn<T>? dispose,
    String? debugName,
  }) => ArgProvider._(create, dispose: dispose, debugName: debugName);

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

  /// It creates an [InstantiableNoArgProvider].
  InstantiableNoArgProvider<T> call() {
    return InstantiableNoArgProvider._(this);
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

part of '../../disco_internal.dart';

/// A function that creates an object of type [T] with an argument of type [A].
typedef CreateArgProviderValueFn<T, A> = T Function(
  BuildContext context,
  A arg,
);

/// {@template ArgProvider}
/// A [Provider] that needs to be given an initial argument before
/// it can be used.
/// {@endtemplate}
class ArgProvider<T extends Object, A> {
  /// {@macro ArgProvider}
  ArgProvider._(
    CreateArgProviderValueFn<T, A> create, {
    DisposeProviderValueFn<T>? dispose,
    bool? lazy,
  })  : _createValue = create,
        _disposeValue = dispose,
        _lazy = lazy ?? DiscoConfig.lazy;

  /// {@macro Provider.lazy}
  final bool _lazy;

  /// {@macro Provider.create}
  final CreateArgProviderValueFn<T, A> _createValue;

  /// {@macro Provider.dispose}
  final DisposeProviderValueFn<T>? _disposeValue;

  // cannot be late
  // ignore: use_late_for_private_fields_and_variables
  ProviderScopeState? _scopeState;

  // ---
  // Overrides
  // ---

  /// {@macro Provider.overrideWithValue}
  @visibleForTesting
  ArgProviderOverride<T, A> overrideWithValue(T value) =>
      ArgProviderOverride._(this, value);

  // ---
  // DI methods
  // ---

  /// {@macro Provider.of}
  T of(BuildContext context) {
    final provider = maybeOf(context);
    if (provider == null) {
      throw ArgProviderWithoutScopeError(this);
    }
    return provider;
  }

  /// {@macro Provider.maybeOf}
  T? maybeOf(BuildContext context) {
    return ProviderScope._getOrCreateArgProviderValue(context, id: this);
  }

  // ---
  // Utils leveraged by ProviderScope
  // ---

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
        (context) => _createValue(context, arg),
        dispose: _disposeValue,
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

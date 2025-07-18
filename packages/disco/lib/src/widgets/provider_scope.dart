// It is a bit simpler to follow the internal logic if the generic types are
// not displayed for all providers and argument providers.
// ignore_for_file: strict_raw_type

part of '../disco_internal.dart';

/// {@template ProviderScope}
/// Provides the passed [providers] to descendants (i.e. what is in [child]).
/// {@endtemplate}
@immutable
class ProviderScope extends StatefulWidget {
  /// {@macro ProviderScope}
  const ProviderScope({
    required this.child,
    required List<InstantiableProvider> this.providers,
    super.key,
  }) : overrides = null;

  const ProviderScope._overrides({
    required this.child,
    required List<Override> this.overrides,
    super.key,
  }) : providers = null;

  /// {@template ProviderScope.child}
  /// The widget child that gets access to the [providers].
  /// {@endtemplate}
  final Widget child;

  /// All the providers provided to all the descendants of [ProviderScope].
  final List<InstantiableProvider>? providers;

  /// All the overrides provided to all the descendants of
  /// [ProviderScopeOverride].
  final List<Override>? overrides;

  @override
  State<ProviderScope> createState() => ProviderScopeState();

  /// {@template _findState}
  /// Finds the first [ProviderScopeState] ancestor that satisfies the given
  /// [id].
  /// {@endtemplate}
  static ProviderScopeState? _findState<T extends Object>(
    BuildContext context, {
    required Provider id,
  }) {
    // try and find the override first
    final providerScopeOverride = ProviderScopeOverrideState.maybeOf(context);
    if (providerScopeOverride != null) {
      final state = providerScopeOverride.providerScopeState;
      if (state.isProviderInScope(id)) return state;
    }

    return _InheritedProvider.inheritFromNearest(context, id, null)?.state;
  }

  /// {@template _getOrCreateProvider}
  /// Tries to find the provided value associated to [id].
  ///
  /// If the [id] is not found in any [ProviderScope], this function
  /// returns null.
  ///
  /// In case the [id] is found in some [ProviderScope], but the find fails
  /// (no associated value in [ProviderScopeState.createdProviderValues]),
  /// the provider's value gets created.
  /// {@endtemplate}
  static T? _getOrCreateProviderValue<T extends Object>(
    BuildContext context, {
    required Provider<T> id,
  }) {
    // Try to find the provider in the current widget tree.
    var state = _findState<T>(context, id: id);
    // If the state has not been found yet, try to find it by using the
    // ProviderScopePortal context.
    if (state == null) {
      final providerScopePortalContext = ProviderScopePortal._maybeOf(context);
      if (providerScopePortalContext != null) {
        state = _findState<T>(providerScopePortalContext, id: id);
      }
    }
    if (state == null) return null;
    final createdProvider = state.createdProviderValues[id];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProviderValue(id) as T;
  }

  /// {@macro _findState}
  static ProviderScopeState? _findStateForArgProvider<T extends Object, A>(
    BuildContext context, {
    required ArgProvider<T, A> id,
  }) {
    // try finding the override first
    final providerScopeOverride = ProviderScopeOverrideState.maybeOf(context);
    if (providerScopeOverride != null) {
      final state = providerScopeOverride.providerScopeState;
      if (state.isArgProviderInScope(id)) return state;
    }

    return _InheritedProvider.inheritFromNearest(context, null, id)?.state;
  }

  /// {@macro _getOrCreateProvider}
  static T? _getOrCreateArgProviderValue<T extends Object, A>(
    BuildContext context, {
    required ArgProvider<T, A> id,
  }) {
    // Try to find the provider in the current widget tree.
    var state = _findStateForArgProvider<T, A>(context, id: id);
    // If the state has not been found yet, try to find it by using the
    // ProviderScopePortal context.
    if (state == null) {
      final providerScopePortalContext = ProviderScopePortal._maybeOf(context);
      if (providerScopePortalContext != null) {
        state =
            _findStateForArgProvider<T, A>(providerScopePortalContext, id: id);
      }
    }
    if (state == null) return null;
    final providerAsId = state.allArgProvidersInScope[id];
    final createdProvider = state.createdProviderValues[providerAsId];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProviderValueForArgProvider(id) as T;
  }
}

/// The state of the [ProviderScope] widget
@protected
class ProviderScopeState extends State<ProviderScope> {
  /// Stores all the argument providers in the current scope. The values are
  /// intermediate providers, which are used as internal IDs by
  /// [createdProviderValues].
  final allArgProvidersInScope = HashMap<ArgProvider, Provider>();

  /// Stores all the providers without argument in the current scope.
  /// The values are intermediate providers, which are used as internal IDs
  /// by [createdProviderValues].
  final allProvidersInScope = HashMap<Provider, Provider>();

  /// Stores all the created values (associated to the providers).
  /// The keys are the intermediate providers (which are not necessarily the
  /// globally defined providers), while the values are the provided values.
  final createdProviderValues = HashMap<Provider, Object>();

  @override
  void initState() {
    super.initState();

    if (widget.providers != null) {
      // Providers and ArgProviders logic --------------------------------------

      final providers = widget.providers!.whereType<Provider>().toList();

      assert(
        () {
          // check if there are multiple providers of the same type
          final ids = <Provider>[];
          for (final provider in providers) {
            final id = provider; // the instance of the provider
            if (ids.contains(id)) {
              throw MultipleProviderOfSameInstance();
            }
            ids.add(id);
          }
          return true;
        }(),
        '',
      );

      for (final provider in providers) {
        // NB: even though `id` and `provider` point to the same reference,
        // two different variables are used to simplify understanding how
        // providers are saved.
        final id = provider;

        // In this case, the provider put in scope can be the ID itself.
        allProvidersInScope[id] = provider;

        // create non lazy providers.
        if (!provider._lazy) {
          // create and store the provider
          createdProviderValues[id] = provider._createValue(context);
        }
      }

      final instantiableArgProviders =
          widget.providers!.whereType<InstantiableArgProvider>().toList();

      assert(
        () {
          // check if there are multiple providers of the same type
          final ids = <ArgProvider>[];
          for (final provider in instantiableArgProviders) {
            final id = provider._argProvider; // the instance of the provider
            if (ids.contains(id)) {
              throw MultipleProviderOfSameInstance();
            }
            ids.add(id);
          }
          return true;
        }(),
        '',
      );

      for (final instantiableArgProvider in instantiableArgProviders) {
        final id = instantiableArgProvider._argProvider;
        allArgProvidersInScope[id] = instantiableArgProvider._argProvider
            ._generateIntermediateProvider(instantiableArgProvider._arg);

        // create non lazy providers.
        if (!instantiableArgProvider._argProvider._lazy) {
          // the intermediate ID is a reference to the associated generated
          // intermediate provider
          final intermediateId = allArgProvidersInScope[id]!;
          // create and store the provider
          createdProviderValues[intermediateId] =
              allArgProvidersInScope[id]!._createValue(context);
        }
      }
    } else if (widget.overrides != null) {
      // ProviderOverride and ArgProvidersOverride logic ----------------------

      final providerOverrides =
          widget.overrides!.whereType<ProviderOverride<Object>>().toList();

      assert(
        () {
          // check if there are multiple providers of the same type
          final ids = <Provider>[];
          for (final override in providerOverrides) {
            final id = override._provider; // the instance of the provider
            if (ids.contains(id)) {
              throw MultipleProviderOverrideOfSameProviderInstance();
            }
            ids.add(id);
          }
          return true;
        }(),
        '',
      );

      for (final override in providerOverrides) {
        final id = override._provider;

        allProvidersInScope[id] = override._generateIntermediateProvider();

        // create providers (they are never lazy in the case of overrides)
        {
          // create and store the provider
          createdProviderValues[id] =
              allProvidersInScope[id]!._createValue(context);
        }
      }

      final argProviderOverrides = widget.overrides!
          .whereType<ArgProviderOverride<Object, dynamic>>()
          .toList();

      assert(
        () {
          // check if there are multiple providers of the same type
          final ids = <ArgProvider>[];
          for (final override in argProviderOverrides) {
            final id = override._argProvider; // the instance of the provider
            if (ids.contains(id)) {
              throw MultipleProviderOfSameInstance();
            }
            ids.add(id);
          }
          return true;
        }(),
        '',
      );

      for (final override in argProviderOverrides) {
        final id = override._argProvider;

        allArgProvidersInScope[id] = override._generateIntermediateProvider();

        // create providers (they are never lazy in the case of overrides)
        {
          // the intermediate ID is a reference to the associated generated
          // intermediate provider
          final intermediateId = allArgProvidersInScope[id]!;
          // create and store the provider
          createdProviderValues[intermediateId] =
              allArgProvidersInScope[id]!._createValue(context);
        }
      }
    }
  }

  @override
  void dispose() {
    // dispose all the created providers
    createdProviderValues.forEach((key, value) {
      allProvidersInScope[key]?._safeDisposeValue(value);
    });

    allArgProvidersInScope.clear();
    allProvidersInScope.clear();
    createdProviderValues.clear();
    super.dispose();
  }

  // Providers logic ----------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? getIntermediateProvider(Provider id) {
    return allProvidersInScope[id];
  }

  /// Creates a provider value and stores it to [createdProviderValues].
  dynamic createProviderValue(Provider id) {
    // find the intermediate provider in the list
    final provider = getIntermediateProvider(id)!;
    // create and return its value
    final value = provider._createValue(context);
    // store the created provider value
    createdProviderValues[id] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope.
  bool isProviderInScope(Provider id) {
    // Find the provider by type
    return getIntermediateProvider(id) != null;
  }

  // ArgProviders logic -------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? getIntermediateProviderForArgProvider(
    ArgProvider id,
  ) {
    return allArgProvidersInScope[id];
  }

  /// Creates a provider value and stores it to [createdProviderValues].
  dynamic createProviderValueForArgProvider(
    ArgProvider id,
  ) {
    // find the intermediate provider in the list
    final provider = getIntermediateProviderForArgProvider(id)!;
    // create and return its value
    final value = provider._createValue(context);
    // store the created provider value
    createdProviderValues[allArgProvidersInScope[id]!] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope.
  bool isArgProviderInScope(ArgProvider id) {
    return getIntermediateProviderForArgProvider(id) != null;
  }

  // Rest of _ProviderScopeState ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(
      state: this,
      child: widget.child,
    );
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty('createdProviderValues', createdProviderValues.values),
    );
  }
  // coverage:ignore-end
}

@immutable
class _InheritedProvider extends InheritedModel<Object> {
  const _InheritedProvider({required this.state, required super.child});

  final ProviderScopeState state;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant _InheritedProvider oldWidget) {
    return false;
  }
  // coverage:ignore-end

  bool isSupportedAspectWithType(
    Provider? providerId,
    ArgProvider? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );
    if (providerId != null) {
      return state.isProviderInScope(providerId);
    }
    return state.isArgProviderInScope(argProviderId!);
  }

  // coverage:ignore-start
  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedProvider oldWidget,
    Set<dynamic> dependencies,
  ) {
    return false;
  }
  // coverage:ignore-end

  /// The following two methods are taken from [InheritedModel] and modified
  /// in order to find the first [_InheritedProvider] ancestor that contains
  /// the searched provider (aspect).
  /// This is a small optimization that avoids traversing all of the
  /// [ProviderScope] ancestors.
  static InheritedElement? _findNearestModel(
    BuildContext context,
    Provider? providerId,
    ArgProvider? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );
    final model =
        context.getElementForInheritedWidgetOfExactType<_InheritedProvider>();
    // No ancestors of type _InheritedProvider found, exit.
    if (model == null) {
      return null;
    }

    assert(
      model.widget is _InheritedProvider,
      'The widget must be of type _InheritedProvider',
    );
    final modelWidget = model.widget as _InheritedProvider;

    // The model contains the aspect, the ancestor has been found, return it.
    if (modelWidget.isSupportedAspectWithType(providerId, argProviderId)) {
      return model;
    }

    // The aspect has not been found in the current ancestor, go up to other
    // ancestors and try to find it.
    Element? modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    // Return null if we've reached the root.
    if (modelParent == null) {
      return null;
    }

    return _findNearestModel(modelParent!, providerId, argProviderId);
  }

  /// Makes [context] dependent on the specified [providerId] of an
  /// [_InheritedProvider] (or [argProviderId], alternatively).
  ///
  /// The dependencies created by this method target the nearest
  /// [_InheritedProvider] ancestor whose [isSupportedAspect] returns true.
  ///
  /// If no ancestor of type _InheritedProvider exists, null is returned.
  static _InheritedProvider? inheritFromNearest(
    BuildContext context,
    Provider? providerId,
    ArgProvider? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );

    // Try and find a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel(context, providerId, argProviderId);
    if (model == null) {
      return null;
    }

    return model.widget as _InheritedProvider;
  }
}

/// {@template ProviderWithoutScopeError}
/// Error thrown when the [Provider] was never attached to a [ProviderScope].
/// {@endtemplate}
class ProviderWithoutScopeError extends Error {
  /// {@macro ProviderWithoutScopeError}
  ProviderWithoutScopeError(this.provider);

  /// The provider that is not found
  final Provider provider;

  @override
  String toString() {
    return 'Seems like that you forgot to provide the provider of type '
        '${provider._valueType} (without argument) to a ProviderScope.';
  }
}

/// {@template ArgProviderWithoutScopeError}
/// Error thrown when the [ArgProvider] was never attached to a [ProviderScope].
/// {@endtemplate}
class ArgProviderWithoutScopeError extends Error {
  /// {@macro ArgProviderWithoutScopeError}
  ArgProviderWithoutScopeError(this.argProvider);

  /// The provider that is not found
  final ArgProvider argProvider;

  @override
  String toString() {
    return 'Seems like that you forgot to provide the provider of type '
        '${argProvider._valueType} and argument type '
        '${argProvider._argumentType} to a ProviderScope.';
  }
}

/// {@template MultipleProviderOfSameInstance}
/// Error thrown when multiple providers of the same instance are created
/// together.
/// {@endtemplate}
class MultipleProviderOfSameInstance extends Error {
  /// {@macro MultipleProviderOfSameInstance}
  MultipleProviderOfSameInstance();

  @override
  String toString() =>
      'You cannot create or inject multiple providers of the same '
      'instance together.';
}

/// {@template MultipleProviderOverrideOfSameProviderInstance}
/// Error thrown when multiple provider overrides of the same provider instance
/// are created together.
/// {@endtemplate}
class MultipleProviderOverrideOfSameProviderInstance extends Error {
  /// {@macro MultipleProviderOverrideOfSameProviderInstance}
  MultipleProviderOverrideOfSameProviderInstance();

  @override
  String toString() =>
      'You cannot create or inject multiple provider overrides of the '
      'same provider instance together.';
}

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
  ///
  /// Providers can be either [Provider] or [ArgProvider].
  /// Providers that depends on other providers in the same [providers] list
  /// must be listed after the providers they depend on, otherwise a
  /// [ProviderForwardReferenceError] will be thrown.
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

  /// Helper method to handle common logic between Provider and ArgProvider
  /// access during initialization and lazy creation.
  static T? _getOrCreateValue<T extends Object, ID extends Object>({
    required BuildContext context,
    required ID id,
    required bool Function(ProviderScopeState, ID) isInScope,
    required int? Function(ProviderScopeState, ID) getIndex,
    required Provider? Function(ProviderScopeState, ID) getProviderId,
    required ProviderScopeState? Function(BuildContext, ID) findState,
    required T Function(ProviderScopeState, ID, BuildContext) createValue,
  }) {
    // STEP 1: Check if we're in the middle of initializing a scope
    final initializingScope = ProviderScopeState._currentlyInitializingScope;
    if (initializingScope != null) {
      // Check if the requested provider is in the CURRENT scope being
      // initialized
      if (isInScope(initializingScope, id)) {
        // Found in current scope! Now validate ordering.
        final requestedIndex = getIndex(initializingScope, id);
        final currentIndex = initializingScope._currentlyCreatingProviderIndex;

        // If we're currently creating a provider, validate it's not a
        // forward ref
        if (currentIndex != null && requestedIndex != null) {
          if (requestedIndex >= currentIndex) {
            // Forward reference detected!
            // Find the current provider being created - could be a Provider
            // or an ArgProvider
            final currentProvider = initializingScope.allProvidersInScope.keys
                    .cast<Provider?>()
                    .firstWhere(
                      (p) =>
                          p != null &&
                          initializingScope._providerIndices[p] == currentIndex,
                      orElse: () => null,
                    ) ??
                // If not found in regular providers, it must be an ArgProvider
                // accessing a regular Provider
                initializingScope.allArgProvidersInScope.keys.firstWhere((ap) =>
                    initializingScope._argProviderIndices[ap] == currentIndex);
            throw ProviderForwardReferenceError(
              requestedProvider: id,
              requestedIndex: requestedIndex,
              currentIndex: currentIndex,
              currentProvider: currentProvider,
            );
          }
        }

        // Valid same-scope access to an earlier provider
        // Check if already created
        final providerId = getProviderId(initializingScope, id);
        final createdProvider =
            initializingScope.createdProviderValues[providerId];
        if (createdProvider != null) return createdProvider as T;

        // Not created yet - create it now (for lazy providers)
        return createValue(initializingScope, id, context);
      }
    }

    // STEP 2: Not in current scope or not initializing - search ancestors
    // Try to find the provider in the current widget tree.
    var state = findState(context, id);
    // If the state has not been found yet, try to find it by using the
    // ProviderScopePortal context.
    if (state == null) {
      final providerScopePortalContext = ProviderScopePortal._maybeOf(context);
      if (providerScopePortalContext != null) {
        state = findState(providerScopePortalContext, id);
      }
    }
    if (state == null) return null;
    final providerId = getProviderId(state, id);
    final createdProvider = state.createdProviderValues[providerId];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return createValue(state, id, context);
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
    return _getOrCreateValue<T, Provider<T>>(
      context: context,
      id: id,
      isInScope: (scope, id) => scope.isProviderInScope(id),
      getIndex: (scope, id) => scope._providerIndices[id],
      getProviderId: (scope, id) => id,
      findState: (context, id) => _findState<T>(context, id: id),
      createValue: (scope, id, context) =>
          scope.createProviderValue(id, context) as T,
    );
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
    return _getOrCreateValue<T, ArgProvider<T, A>>(
      context: context,
      id: id,
      isInScope: (scope, id) => scope.isArgProviderInScope(id),
      getIndex: (scope, id) => scope._argProviderIndices[id],
      getProviderId: (scope, id) => scope.allArgProvidersInScope[id],
      findState: (context, id) =>
          _findStateForArgProvider<T, A>(context, id: id),
      createValue: (scope, id, context) =>
          scope.createProviderValueForArgProvider(id, context) as T,
    );
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

  /// Track the scope currently being initialized. This enables same-scope
  /// provider access during initialization.
  static ProviderScopeState? _currentlyInitializingScope;

  /// Map each provider to its index in the original providers list.
  /// Used to enforce ordering constraints during same-scope access.
  final _providerIndices = HashMap<Provider, int>();

  /// Map each ArgProvider to its index in the original providers list.
  /// Used to enforce ordering constraints during same-scope access.
  final _argProviderIndices = HashMap<ArgProvider, int>();

  /// The index of the provider currently being created during initialization.
  /// Null when not initializing. Used to detect forward/circular references.
  int? _currentlyCreatingProviderIndex;

  @override
  void initState() {
    super.initState();

    // Set this scope as currently initializing to enable same-scope access
    _currentlyInitializingScope = this;

    try {
      if (widget.providers != null) {
        final allProviders = widget.providers!;
        // Check for duplicate Providers
        assert(
          () {
            final providerIds = <Provider>[];
            for (final item in allProviders) {
              if (item is Provider) {
                if (providerIds.contains(item)) {
                  throw MultipleProviderOfSameInstance();
                }
                providerIds.add(item);
              }
            }
            return true;
          }(),
          '',
        );

        // Check for duplicate ArgProviders
        assert(
          () {
            final argProviderIds = <ArgProvider>[];
            for (final item in allProviders) {
              if (item is InstantiableArgProvider) {
                if (argProviderIds.contains(item._argProvider)) {
                  throw MultipleProviderOfSameInstance();
                }
                argProviderIds.add(item._argProvider);
              }
            }
            return true;
          }(),
          '',
        );

        // PHASE 1: Register all providers and track indices
        // This must be done before creating any providers so that
        // isProviderInScope() works correctly during creation
        for (var i = 0; i < allProviders.length; i++) {
          final item = allProviders[i];

          if (item is Provider) {
            final provider = item;
            final id = provider;

            // Track original index for ordering validation
            _providerIndices[id] = i;

            // In this case, the provider put in scope can be the ID itself.
            allProvidersInScope[id] = provider;
          } else if (item is InstantiableArgProvider) {
            final instantiableArgProvider = item;
            final id = instantiableArgProvider._argProvider;

            // Track original index for ordering validation
            _argProviderIndices[id] = i;

            final provider = instantiableArgProvider._argProvider
                ._generateIntermediateProvider(
              instantiableArgProvider._arg,
            );
            allArgProvidersInScope[id] = provider;
          }
        }

        // PHASE 2: Create non-lazy providers
        // Now that all providers are registered, we can create them
        for (var i = 0; i < allProviders.length; i++) {
          final item = allProviders[i];

          if (item is Provider) {
            final provider = item;
            final id = provider;

            // create non lazy providers.
            if (!provider._lazy) {
              _currentlyCreatingProviderIndex = i;
              createdProviderValues[id] = provider._createValue(context);
              _currentlyCreatingProviderIndex = null;
            }
          } else if (item is InstantiableArgProvider) {
            final instantiableArgProvider = item;
            final id = instantiableArgProvider._argProvider;

            // create non lazy providers.
            if (!instantiableArgProvider._argProvider._lazy) {
              _currentlyCreatingProviderIndex = i;
              createdProviderValues[allArgProvidersInScope[id]!] =
                  allArgProvidersInScope[id]!._createValue(context);
              _currentlyCreatingProviderIndex = null;
            }
          }
        }
      } else if (widget.overrides != null) {
        final providerOverrides =
            widget.overrides!.whereType<ProviderOverride<Object>>().toList();

        assert(
          () {
            // check if there are multiple providers of the same type
            final ids = <Provider>[];
            for (final override in providerOverrides) {
              final id = override._provider; // the instance of the provider
              if (ids.contains(id)) {
                throw MultipleProviderOverrideOfSameInstance();
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
    } finally {
      _currentlyInitializingScope = null;
      _currentlyCreatingProviderIndex = null;
    }
  }

  @override
  void dispose() {
    // dispose all the created providers
    createdProviderValues.forEach((key, value) {
      key._safeDisposeValue(value);
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
  dynamic createProviderValue(Provider id, BuildContext context) {
    // find the intermediate provider in the list
    final provider = getIntermediateProvider(id)!;

    // Support same-scope access for lazy providers
    final savedScope = _currentlyInitializingScope;
    final savedIndex = _currentlyCreatingProviderIndex;
    try {
      _currentlyInitializingScope = this;
      _currentlyCreatingProviderIndex = _providerIndices[id];

      // create and return its value
      final value = provider._createValue(context);
      // store the created provider value
      createdProviderValues[id] = value;
      return value;
    } finally {
      _currentlyInitializingScope = savedScope;
      _currentlyCreatingProviderIndex = savedIndex;
    }
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
    BuildContext context,
  ) {
    // find the intermediate provider in the list
    final provider = getIntermediateProviderForArgProvider(id)!;

    // Support same-scope access for lazy providers
    final savedScope = _currentlyInitializingScope;
    final savedIndex = _currentlyCreatingProviderIndex;
    try {
      _currentlyInitializingScope = this;
      _currentlyCreatingProviderIndex = _argProviderIndices[id];

      // create and return its value
      final value = provider._createValue(context);
      // store the created provider value
      createdProviderValues[allArgProvidersInScope[id]!] = value;
      return value;
    } finally {
      _currentlyInitializingScope = savedScope;
      _currentlyCreatingProviderIndex = savedIndex;
    }
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
  final Object provider;

  @override
  String toString() {
    final name = switch (provider) {
      final Provider p => p._debugName,
      final ArgProvider ap => ap._debugName,
      // coverage:ignore-start
      _ => throw Exception('Unknown provider type ${provider.runtimeType}'),
      // coverage:ignore-end
    };

    return 'Seems like that you forgot to provide the provider of type $name '
        'to a ProviderScope.';
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

/// {@template MultipleProviderOverrideOfSameInstance}
/// Error thrown when multiple provider overrides of the same provider instance
/// are created together.
/// {@endtemplate}
class MultipleProviderOverrideOfSameInstance extends Error {
  /// {@macro MultipleProviderOverrideOfSameInstance}
  MultipleProviderOverrideOfSameInstance();

  @override
  String toString() =>
      'You cannot create or inject multiple provider overrides of the '
      'same instance together.';
}

/// {@template ProviderForwardReferenceError}
/// Error thrown when a provider tries to access another provider that appears
/// later in the same ProviderScope's providers list.
///
/// This prevents circular dependencies by enforcing that providers can only
/// access providers defined earlier in the list.
/// {@endtemplate}
class ProviderForwardReferenceError extends Error {
  /// {@macro ProviderForwardReferenceError}
  ProviderForwardReferenceError({
    required this.currentIndex,
    required this.currentProvider,
    required this.requestedProvider,
    required this.requestedIndex,
  });

  /// The index of the provider currently being created
  final int currentIndex;

  /// The ArgProvider currently being created
  final Object currentProvider;

  /// The provider being requested
  final Object requestedProvider;

  /// The index of the requested provider in the providers list
  final int requestedIndex;

  @override
  String toString() {
    final currentName = switch (currentProvider) {
      final Provider p => p._debugName,
      final ArgProvider ap => ap._debugName,
      // coverage:ignore-start
      _ =>
        throw Exception('Unknown provider type ${currentProvider.runtimeType}'),
      // coverage:ignore-end
    };
    final requestedName = switch (requestedProvider) {
      final Provider p => p._debugName,
      final ArgProvider ap => ap._debugName,
      // coverage:ignore-start
      _ => throw Exception(
          'Unknown provider type ${requestedProvider.runtimeType}'),
      // coverage:ignore-end
    };

    return 'Forward reference detected!\n\n'
        '`$currentName` (at index $currentIndex) '
        'tried to access `$requestedName` (at index $requestedIndex).\n\n'
        'Providers in a ProviderScope can only access providers defined '
        'EARLIER in the providers list (with a lower index). This prevents '
        'circular dependencies.\n\n'
        'To fix: Move `$currentName` before '
        '`$requestedName` in your providers list.';
  }
}

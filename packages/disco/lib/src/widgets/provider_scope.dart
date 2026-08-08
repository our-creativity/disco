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
  /// [providers] and [overrides] cannot coexist.
  final List<InstantiableProvider>? providers;

  /// All the overrides provided to all the descendants of
  /// [ProviderScopeOverride].
  /// [providers] and [overrides] cannot coexist.
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
  /// [id] can be either a `Provider<T>` or an `ArgProvider<T, A>`.
  static T? _getOrCreateValue<T extends Object, ID extends Object>({
    required BuildContext context,
    required ID id,
    required T? Function(ProviderScopeState, ID) getCreatedValue,
    required ProviderScopeState? Function(BuildContext, ID) findState,
    required T Function(ProviderScopeState, ID, BuildContext) createValue,
  }) {
    // Try to find the provider in the current widget tree.
    //
    // NB: the scope providing [id] is always looked up through the widget tree
    // (or through the overrides), even while it is creating its own values.
    // This is what makes a provider injecting another provider of the same
    // scope get its override, if any.
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

    // The scope which has been found may be in the middle of creating one of
    // its own values: in that case, only the providers declared earlier in its
    // list can be injected.
    state._checkForwardReference(id);

    final createdValue = getCreatedValue(state, id);
    if (createdValue != null) return createdValue;
    // if the value has not been created yet, create it lazily
    return createValue(state, id, context);
  }

  /// {@template _getOrCreateProviderValue}
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
      getCreatedValue: (scope, id) => scope.getCreatedProviderValue(id) as T?,
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
    // NB: differently from [_findState], the override does not have to be
    // looked up here. An overridden argument provider is instantiated by the
    // ProviderScope inserting it into the widget tree (which is the only place
    // where its argument is known), i.e. the override is already taken into
    // account by the intermediate providers of that scope.
    return _InheritedProvider.inheritFromNearest(context, null, id)?.state;
  }

  /// {@macro _getOrCreateProviderValue}
  static T? _getOrCreateArgProviderValue<T extends Object, A>(
    BuildContext context, {
    required ArgProvider<T, A> id,
  }) {
    return _getOrCreateValue<T, ArgProvider<T, A>>(
      context: context,
      id: id,
      getCreatedValue: (scope, id) =>
          scope.getCreatedArgProviderValue(id) as T?,
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
  // There are three layers of providers:
  //
  // 1. the top-level providers, i.e. the ones defined by the user. They are
  //    never used to create any value: they only act as type-safe IDs.
  // 2. the intermediate providers, i.e. the providers actually used to create
  //    the values. An intermediate provider is generated (or regenerated, in
  //    case of an override) for every top-level provider inserted into this
  //    scope. For a [Provider], the intermediate provider is either the
  //    top-level provider itself or its mock; for an [ArgProvider], the
  //    intermediate provider is a [Provider] generated by combining the
  //    (possibly overridden) argument provider with the argument given in the
  //    widget tree.
  // 3. the values, which are created by the intermediate providers and are
  //    keyed by them.

  /// Stores all the argument providers in the current scope. The keys are the
  /// top-level argument providers, while the values are the intermediate
  /// providers, which are used as internal IDs by [createdArgProviderValues].
  final allArgProvidersInScope = HashMap<ArgProvider, Provider>();

  /// Stores all the providers without argument in the current scope.
  /// The keys are the top-level providers, while the values are the
  /// intermediate providers, which are used as internal IDs by
  /// [createdProviderValues].
  final allProvidersInScope = HashMap<Provider, Provider>();

  /// Stores the argument providers overridden by a [ProviderScopeOverride].
  ///
  /// This map is only filled for the internal [ProviderScope] of a
  /// [ProviderScopeOverride]. It maps a top-level argument provider to the
  /// argument provider that has to be used in its place.
  ///
  /// Differently from [ProviderOverride]s, an [ArgProviderOverride] cannot be
  /// instantiated here, since the argument is only known where the argument
  /// provider is inserted into the widget tree. Therefore, the overrides are
  /// only registered here and every [ProviderScope] looks them up while
  /// generating its intermediate providers.
  ///
  /// NB: as a consequence, the value of an overridden argument provider lives
  /// in the [ProviderScope] providing it (and not in the [ProviderScope] of
  /// the [ProviderScopeOverride]) and, thus, only the [ProviderScope]s that
  /// are descendants of the [ProviderScopeOverride] are affected.
  final overriddenArgProviders = HashMap<ArgProvider, ArgProvider>();

  /// Stores all the created values (associated to the providers).
  /// The keys are the intermediate providers (which are not necessarily the
  /// globally defined providers), while the values are the provided values.
  final createdProviderValues = HashMap<Provider, Object>();

  /// Stores all the created values (associated to the argument providers).
  /// The keys are the intermediate providers (which are generated by combining
  /// an argument provider with an argument), while the values are the provided
  /// values.
  final createdArgProviderValues = HashMap<Provider, Object>();

  /// Map each provider to its index in the original providers list.
  /// Used to enforce ordering constraints during same-scope access.
  final _providerIndices = HashMap<Provider, int>();

  /// Map each ArgProvider to its index in the original providers list.
  /// Used to enforce ordering constraints during same-scope access.
  final _argProviderIndices = HashMap<ArgProvider, int>();

  /// The index of the provider currently being created during initialization.
  /// Null when not initializing. Used to detect forward/circular references.
  int? _currentlyCreatingProviderIndex;

  /// The provider object currently being created during initialization.
  /// Null when not initializing. Used for error reporting.
  /// Can be either a Provider or ArgProvider instance.
  Object? _currentlyCreatingProvider;

  @override
  void initState() {
    super.initState();

    if (widget.providers != null) {
      _initializeProviders(widget.providers!);
    } else if (widget.overrides != null) {
      _initializeOverrides(widget.overrides!);
    }
  }

  /// Validates that there are no duplicate providers in the list.
  void _validateProvidersUniqueness(
    List<InstantiableProvider> allProviders,
  ) {
    assert(
      () {
        final providerIds = <Provider>{};
        final argProviderIds = <ArgProvider>{};

        for (final item in allProviders) {
          if (item is InstantiableNoArgProvider) {
            if (!providerIds.add(item._provider)) {
              throw MultipleProviderOfSameInstance();
            }
          } else if (item is InstantiableArgProvider) {
            if (!argProviderIds.add(item._argProvider)) {
              throw MultipleProviderOfSameInstance();
            }
          }
        }
        return true;
      }(),
      '',
    );
  }

  /// PHASE 1: Registers all providers (i.e. it generates their intermediate
  /// providers) and tracks their indices.
  /// This must be done before creating any value so that
  /// isProviderInScope() works correctly during creation.
  void _registerAllProviders(List<InstantiableProvider> allProviders) {
    // The overrides of a ProviderScopeOverride, if present. They are needed to
    // regenerate the intermediate providers of the overridden argument
    // providers.
    final overridesScope = ProviderScopeOverrideState.maybeOf(
      context,
    )?.providerScopeState;

    for (var i = 0; i < allProviders.length; i++) {
      final item = allProviders[i];

      if (item is InstantiableNoArgProvider) {
        final id = item._provider;

        // Track original index for ordering validation
        _providerIndices[id] = i;

        // In this case, the intermediate provider can be the ID itself.
        // NB: an eventual override of this provider is not handled here, since
        // the value of an overridden provider is created and stored by the
        // ProviderScope of the ProviderScopeOverride itself.
        allProvidersInScope[id] = id;
      } else if (item is InstantiableArgProvider) {
        final id = item._argProvider;

        // Track original index for ordering validation
        _argProviderIndices[id] = i;

        // The argument provider generating the intermediate provider is either
        // the top-level one or, if overridden, its mock.
        final argProvider = overridesScope?.getOverriddenArgProvider(id) ?? id;

        allArgProvidersInScope[id] = argProvider._generateIntermediateProvider(
          item._arg,
        );
      }
    }
  }

  /// Initializes providers by validating and registering them. Their values are
  /// always created lazily, i.e. the first time they are injected.
  void _initializeProviders(List<InstantiableProvider> allProviders) {
    _validateProvidersUniqueness(allProviders);
    _registerAllProviders(allProviders);
  }

  /// Throws a [ProviderForwardReferenceError] if this scope is currently
  /// creating one of its values and [id] is declared later than it in the
  /// providers list, i.e. if [id] is a forward reference.
  ///
  /// This prevents circular dependencies: a provider can only inject the
  /// providers declared before it in the same scope.
  void _checkForwardReference(Object id) {
    final currentIndex = _currentlyCreatingProviderIndex;
    // This scope is not creating any value, therefore there is nothing to
    // validate.
    if (currentIndex == null) return;

    final requestedIndex = switch (id) {
      final Provider provider => _providerIndices[provider],
      final ArgProvider argProvider => _argProviderIndices[argProvider],
      // coverage:ignore-start
      _ => null,
      // coverage:ignore-end
    };

    // The requested provider does not belong to this scope, or it is declared
    // earlier than the one being created.
    if (requestedIndex == null || requestedIndex < currentIndex) return;

    final currentProvider = _currentlyCreatingProvider;
    assert(
      currentProvider != null,
      'Current provider should be set during creation',
    );
    throw ProviderForwardReferenceError(
      requestedProvider: id,
      currentProvider: currentProvider!,
    );
  }

  /// Processes provider overrides by validating uniqueness and creating them.
  void _processProviderOverrides(
    List<ProviderOverride<Object>> providerOverrides,
  ) {
    assert(
      () {
        // check if there are multiple providers of the same type
        final ids = <Provider>[];
        for (final override in providerOverrides) {
          final id = override._originalProvider; // the instance of the provider
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
      final id = override._originalProvider;

      // The intermediate provider is regenerated: the mock takes the place of
      // the top-level provider. Its value is created lazily, like the value of
      // any other provider, so that a mock can inject other providers too.
      allProvidersInScope[id] = override._mockProvider;
    }
  }

  /// Processes arg provider overrides by validating uniqueness and registering
  /// them, so that the [ProviderScope]s below can generate their intermediate
  /// providers out of them.
  void _processArgProviderOverrides(
    List<ArgProviderOverride<Object, dynamic>> argProviderOverrides,
  ) {
    assert(
      () {
        // check if there are multiple providers of the same type
        final ids = <ArgProvider>[];
        for (final override in argProviderOverrides) {
          final id =
              override._originalArgProvider; // the instance of the provider
          if (ids.contains(id)) {
            throw MultipleProviderOverrideOfSameInstance();
          }
          ids.add(id);
        }
        return true;
      }(),
      '',
    );

    for (final override in argProviderOverrides) {
      final id = override._originalArgProvider;

      // The mock cannot be instantiated here, since no argument is available
      // in this scope. It is only registered, so that the ProviderScopes
      // inserting this argument provider into the widget tree can generate
      // their intermediate providers out of the mock.
      overriddenArgProviders[id] = override._mockArgProvider;
    }
  }

  /// Initializes overrides by processing both provider and arg provider
  /// overrides.
  void _initializeOverrides(List<Override> overrides) {
    final providerOverrides = overrides
        .whereType<ProviderOverride<Object>>()
        .toList();
    _processProviderOverrides(providerOverrides);

    final argProviderOverrides = overrides
        .whereType<ArgProviderOverride<Object, dynamic>>()
        .toList();
    _processArgProviderOverrides(argProviderOverrides);
  }

  @override
  void dispose() {
    // dispose all the created values, by leveraging the intermediate providers
    // that created them
    createdProviderValues.forEach((provider, value) {
      provider._safeDisposeValue(value);
    });
    createdArgProviderValues.forEach((provider, value) {
      provider._safeDisposeValue(value);
    });

    allArgProvidersInScope.clear();
    allProvidersInScope.clear();
    overriddenArgProviders.clear();
    createdProviderValues.clear();
    createdArgProviderValues.clear();
    super.dispose();
  }

  // Providers logic ----------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? getIntermediateProvider(Provider id) {
    return allProvidersInScope[id];
  }

  /// Tries to find the value already created for this [id].
  /// It returns null if the [id] is not in this scope or if its value has not
  /// been created yet.
  Object? getCreatedProviderValue(Provider id) {
    final provider = getIntermediateProvider(id);
    if (provider == null) return null;
    return createdProviderValues[provider];
  }

  /// Creates a provider value and stores it to [createdProviderValues].
  dynamic createProviderValue(Provider id, BuildContext context) {
    // find the intermediate provider in the list
    final provider = getIntermediateProvider(id)!;

    // Temporarily override the creation state of this scope
    final savedIndex = _currentlyCreatingProviderIndex;
    final savedProvider = _currentlyCreatingProvider;
    try {
      _currentlyCreatingProviderIndex = _providerIndices[id];
      _currentlyCreatingProvider = id;

      // Create the provider value (may throw or trigger nested creation)
      final value = provider._createValue(context);
      // Store the created provider value
      createdProviderValues[provider] = value;
      return value;
    } finally {
      // Restore the creation state on both success and failure
      _currentlyCreatingProviderIndex = savedIndex;
      _currentlyCreatingProvider = savedProvider;
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

  /// Tries to find the [ArgProvider] overriding this [id].
  ///
  /// It returns null if this [id] is not overridden. Only the internal
  /// [ProviderScope] of a [ProviderScopeOverride] can return a value here.
  ArgProvider? getOverriddenArgProvider(ArgProvider id) {
    return overriddenArgProviders[id];
  }

  /// Tries to find the value already created for this [id].
  /// It returns null if the [id] is not in this scope or if its value has not
  /// been created yet.
  Object? getCreatedArgProviderValue(ArgProvider id) {
    final provider = getIntermediateProviderForArgProvider(id);
    if (provider == null) return null;
    return createdArgProviderValues[provider];
  }

  /// Creates a provider value and stores it to [createdArgProviderValues].
  dynamic createProviderValueForArgProvider(
    ArgProvider id,
    BuildContext context,
  ) {
    // find the intermediate provider in the list
    final provider = getIntermediateProviderForArgProvider(id)!;

    // Temporarily override the creation state of this scope
    final savedIndex = _currentlyCreatingProviderIndex;
    final savedProvider = _currentlyCreatingProvider;
    try {
      _currentlyCreatingProviderIndex = _argProviderIndices[id];
      _currentlyCreatingProvider = id;

      // Create the provider value (may throw or trigger nested creation)
      final value = provider._createValue(
        context,
      );
      // Store the created provider value
      createdArgProviderValues[provider] = value;
      return value;
    } finally {
      // Restore the creation state on both success and failure
      _currentlyCreatingProviderIndex = savedIndex;
      _currentlyCreatingProvider = savedProvider;
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
    properties
      ..add(
        IterableProperty('createdProviderValues', createdProviderValues.values),
      )
      ..add(
        IterableProperty(
          'createdArgProviderValues',
          createdArgProviderValues.values,
        ),
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
    final model = context
        .getElementForInheritedWidgetOfExactType<_InheritedProvider>();
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
    required this.currentProvider,
    required this.requestedProvider,
  });

  /// The provider currently being created
  final Object currentProvider;

  /// The provider being requested
  final Object requestedProvider;

  @override
  String toString() {
    final currentName = switch (currentProvider) {
      final Provider p => p._debugName,
      final ArgProvider ap => ap._debugName,
      // coverage:ignore-start
      _ => throw Exception(
        'Unknown provider type ${currentProvider.runtimeType}',
      ),
      // coverage:ignore-end
    };
    final requestedName = switch (requestedProvider) {
      final Provider p => p._debugName,
      final ArgProvider ap => ap._debugName,
      // coverage:ignore-start
      _ => throw Exception(
        'Unknown provider type ${requestedProvider.runtimeType}',
      ),
      // coverage:ignore-end
    };

    return 'Forward reference detected!\n\n'
        '`$currentName` tried to access `$requestedName`.\n\n'
        'Providers in a ProviderScope can only access providers defined '
        'EARLIER in the providers list. This prevents circular dependencies.\n'
        '\nTo fix: Move `$requestedName` before `$currentName` in your '
        'providers list.';
  }
}

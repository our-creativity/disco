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

  /// Finds the first [ProviderScopeState] ancestor providing the given ID.
  ///
  /// Exactly one of [providerId] and [argProviderId] must be given.
  ///
  /// NB: the scope providing an ID is always looked up through the widget tree,
  /// even while that scope is creating its own values. Since the internal
  /// [ProviderScope] of a [ProviderScopeOverride] takes part in the widget tree
  /// as well, this is also what makes the overrides apply to the providers
  /// depending on an overridden provider.
  static ProviderScopeState? _findState(
    BuildContext context, {
    Provider? providerId,
    ArgProvider? argProviderId,
  }) {
    return _InheritedProvider.inheritFromNearest(
      context,
      providerId,
      argProviderId,
    )?.state;
  }

  /// Helper method to handle common logic between Provider and ArgProvider
  /// access during lazy creation.
  /// [id] can be either a `Provider<T>` or an `ArgProvider<T, A>`.
  static T? _getOrCreateValue<T extends Object, ID extends Object>({
    required BuildContext context,
    required ID id,
    required T? Function(ProviderScopeState, ID) getCreatedValue,
    required ProviderScopeState? Function(BuildContext, ID) findState,
    required T Function(ProviderScopeState, ID, BuildContext) createValue,
  }) {
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
  /// (no associated value in [ProviderScopeState.createdValues]),
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
      findState: (context, id) => _findState(context, providerId: id),
      createValue: (scope, id, context) =>
          scope.createProviderValue(id, context) as T,
    );
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
      findState: (context, id) => _findState(context, argProviderId: id),
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
  //    top-level provider itself or a copy of its mock; for an [ArgProvider],
  //    the intermediate provider is a [Provider] generated by combining the
  //    (possibly overridden) argument provider with the argument given in the
  //    widget tree.
  // 3. the values, which are created by the intermediate providers and are
  //    keyed by them.

  /// Stores all the argument providers in the current scope. The keys are the
  /// top-level argument providers, while the values are the intermediate
  /// providers, which are used as internal IDs by [createdValues].
  final allArgProvidersInScope = HashMap<ArgProvider, Provider>();

  /// Stores all the providers without argument in the current scope.
  /// The keys are the top-level providers, while the values are the
  /// intermediate providers, which are used as internal IDs by
  /// [createdValues].
  final allProvidersInScope = HashMap<Provider, Provider>();

  /// Stores the providers overridden by a [ProviderScopeOverride].
  ///
  /// This map is only filled for the internal [ProviderScope] of a
  /// [ProviderScopeOverride]. It maps a top-level provider to the provider
  /// that has to be used in its place.
  ///
  /// Every [ProviderScope] looks these overrides up while generating its own
  /// intermediate providers, so that the value of an overridden provider lives
  /// in the very same scope where the value of the original provider would have
  /// lived, and therefore shares its exact lifecycle.
  final overriddenProviders = HashMap<Provider, Provider>();

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
  /// NB: differently from [overriddenProviders], an overridden argument
  /// provider cannot be provided by this scope as a fallback, since no argument
  /// is available here. Therefore, only the [ProviderScope]s that are
  /// descendants of the [ProviderScopeOverride] are affected.
  final overriddenArgProviders = HashMap<ArgProvider, ArgProvider>();

  /// Stores all the values created by this scope, no matter whether they come
  /// from a [Provider] or from an [ArgProvider].
  ///
  /// The keys are the intermediate providers (which are not necessarily the
  /// top-level providers), while the values are the provided values.
  ///
  /// NB: this map preserves the insertion order, which is the order in which
  /// the values have been created. [dispose] relies on it.
  final createdValues = <Provider, Object>{};

  /// The top-level providers whose values are currently being created by this
  /// scope, in order of creation. Used to detect circular dependencies.
  ///
  /// Every element is either a [Provider] or an [ArgProvider].
  final _idsBeingCreated = <Object>[];

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

  /// Registers all providers, i.e. it generates their intermediate providers.
  ///
  /// This is done as soon as the scope is mounted, before any value exists, so
  /// that a provider can inject the other providers of its own scope no matter
  /// the order in which they are declared.
  void _registerAllProviders(List<InstantiableProvider> allProviders) {
    // The overrides of a ProviderScopeOverride, if present. They are needed to
    // regenerate the intermediate providers of the overridden providers.
    final overridesScope = ProviderScopeOverrideState.maybeOf(
      context,
    )?.providerScopeState;

    for (final item in allProviders) {
      if (item is InstantiableNoArgProvider) {
        final id = item._provider;

        // If this provider is overridden, its mock generates the intermediate
        // provider; otherwise the top-level provider can act as the
        // intermediate provider itself.
        final mock = overridesScope?.getOverriddenProvider(id);
        allProvidersInScope[id] = mock?._generateIntermediateProvider() ?? id;
      } else if (item is InstantiableArgProvider) {
        final id = item._argProvider;

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

  /// Processes provider overrides by validating uniqueness and registering
  /// them.
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
      final mock = override._mockProvider;

      // The mock is registered, so that every ProviderScope below can
      // regenerate its intermediate provider out of it. This is what makes the
      // value of an overridden provider live exactly where the value of the
      // original provider would have lived.
      overriddenProviders[id] = mock;

      // The mock is also provided by this scope, so that an override works even
      // if no ProviderScope below provides the original provider at all. In
      // that case only, the value lives here.
      allProvidersInScope[id] = mock._generateIntermediateProvider();
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
    _disposeCreatedValues();

    allArgProvidersInScope.clear();
    allProvidersInScope.clear();
    overriddenProviders.clear();
    overriddenArgProviders.clear();
    createdValues.clear();
    super.dispose();
  }

  /// Disposes all the values created by this scope, by leveraging the
  /// intermediate providers that created them.
  ///
  /// The values are disposed in the reverse order of creation. Since a provider
  /// can inject the other providers of its own scope, and since every value is
  /// created lazily, a value is always created *after* the values it depends on;
  /// therefore, reversing the creation order guarantees that a value is always
  /// disposed *before* the values it depends on.
  void _disposeCreatedValues() {
    for (final entry in createdValues.entries.toList().reversed) {
      try {
        entry.key._safeDisposeValue(entry.value);
      } on Object catch (error, stackTrace) {
        // A throwing dispose must not prevent the remaining values of this
        // scope from being disposed, otherwise a single faulty dispose would
        // leak everything else.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'disco',
            context: ErrorDescription(
              'while disposing the value of ${entry.key._debugName}',
            ),
          ),
        );
      }
    }
  }

  /// Creates the value of [intermediateProvider], the intermediate provider
  /// generated for the top-level provider [id], and stores it into
  /// [createdValues].
  dynamic _createAndStoreValue(
    Object id,
    Provider intermediateProvider,
    BuildContext context,
  ) {
    // A provider that is injected while its own value is being created can only
    // be waiting for itself.
    final cycleStart = _idsBeingCreated.indexOf(id);
    if (cycleStart >= 0) {
      throw ProviderCircularDependencyError([
        ..._idsBeingCreated.skip(cycleStart),
        id,
      ]);
    }

    _idsBeingCreated.add(id);
    try {
      // Create the value (it may throw or trigger nested creations)
      final value = intermediateProvider._createValue(context);
      // Store the created value
      createdValues[intermediateProvider] = value;
      return value;
    } finally {
      _idsBeingCreated.removeLast();
    }
  }

  // Providers logic ----------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? getIntermediateProvider(Provider id) {
    return allProvidersInScope[id];
  }

  /// Tries to find the [Provider] overriding this [id].
  ///
  /// It returns null if this [id] is not overridden. Only the internal
  /// [ProviderScope] of a [ProviderScopeOverride] can return a value here.
  Provider? getOverriddenProvider(Provider id) {
    return overriddenProviders[id];
  }

  /// Tries to find the value already created for this [id].
  /// It returns null if the [id] is not in this scope or if its value has not
  /// been created yet.
  Object? getCreatedProviderValue(Provider id) {
    final provider = getIntermediateProvider(id);
    if (provider == null) return null;
    return createdValues[provider];
  }

  /// Creates a provider value and stores it to [createdValues].
  dynamic createProviderValue(Provider id, BuildContext context) {
    return _createAndStoreValue(id, getIntermediateProvider(id)!, context);
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
    return createdValues[provider];
  }

  /// Creates a provider value and stores it to [createdValues].
  dynamic createProviderValueForArgProvider(
    ArgProvider id,
    BuildContext context,
  ) {
    return _createAndStoreValue(
      id,
      getIntermediateProviderForArgProvider(id)!,
      context,
    );
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
      IterableProperty('createdValues', createdValues.values),
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

/// Returns a debug name for a top-level provider, which is either a [Provider]
/// or an [ArgProvider].
String _debugNameOf(Object provider) => switch (provider) {
  final Provider p => p._debugName,
  final ArgProvider ap => ap._debugName,
  // coverage:ignore-start
  _ => throw Exception('Unknown provider type ${provider.runtimeType}'),
  // coverage:ignore-end
};

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
    return 'Seems like that you forgot to provide the provider of type '
        '${_debugNameOf(provider)} to a ProviderScope.';
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

/// {@template ProviderCircularDependencyError}
/// Error thrown when the value of a provider cannot be created because that
/// provider directly or indirectly injects itself.
/// {@endtemplate}
class ProviderCircularDependencyError extends Error {
  /// {@macro ProviderCircularDependencyError}
  ProviderCircularDependencyError(this.dependencyChain);

  /// The providers taking part in the cycle, in the order in which their values
  /// have been requested.
  ///
  /// The first and the last element are the same provider, i.e. the one closing
  /// the cycle. Every element is either a [Provider] or an [ArgProvider].
  final List<Object> dependencyChain;

  @override
  String toString() {
    final chain = dependencyChain.map(_debugNameOf).join('\n  -> ');

    return 'Circular dependency detected!\n\n'
        '  $chain\n\n'
        'A provider cannot inject itself, not even indirectly. Break the cycle '
        'by making one of these providers independent of the others, or by '
        'injecting the value where it is used instead of where it is created.';
  }
}

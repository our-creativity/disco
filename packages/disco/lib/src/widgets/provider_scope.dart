// It is a bit simpler to follow the internal logic if the generic types are
// not displayed for all providers and argument providers.
// ignore_for_file: strict_raw_type

part of '../disco_internal.dart';

/// {@template ProviderScope}
/// Provides the passed [_providers] to descendants (i.e. what is in [child]).
/// {@endtemplate}
@immutable
class ProviderScope extends StatefulWidget {
  /// {@macro ProviderScope}
  const ProviderScope({
    required this.child,
    required List<ValueBinding> providers,
    super.key,
  }) : _providers = providers,
       _overrides = null;

  const ProviderScope._overrides({
    required this.child,
    required List<Override> overrides,
    super.key,
  }) : _overrides = overrides,
       _providers = null;

  /// {@template ProviderScope.child}
  /// The widget child that gets access to the providers.
  /// {@endtemplate}
  final Widget child;

  /// All the providers provided to all the descendants of this [ProviderScope].
  ///
  /// Exactly one of [_providers] and [_overrides] is non-null.
  final List<ValueBinding>? _providers;

  /// All the overrides provided to all the descendants of a
  /// [ProviderScopeOverride].
  ///
  /// Exactly one of [_providers] and [_overrides] is non-null.
  final List<Override>? _overrides;

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
    return _InheritedProvider.findNearestProviding(
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
  /// (no associated value in [ProviderScopeState._createdValues]),
  /// the provider's value gets created.
  /// {@endtemplate}
  static T? _getOrCreateProviderValue<T extends Object>(
    BuildContext context, {
    required Provider<T> id,
  }) {
    return _getOrCreateValue<T, Provider<T>>(
      context: context,
      id: id,
      getCreatedValue: (scope, id) => scope._getCreatedProviderValue(id) as T?,
      findState: (context, id) => _findState(context, providerId: id),
      createValue: (scope, id, context) =>
          scope._createProviderValue(id, context) as T,
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
          scope._getCreatedArgProviderValue(id) as T?,
      findState: (context, id) => _findState(context, argProviderId: id),
      createValue: (scope, id, context) =>
          scope._createProviderValueForArgProvider(id, context) as T,
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
  /// providers, which are used as internal IDs by [_createdValues].
  final _allArgProvidersInScope = HashMap<ArgProvider, Provider>();

  /// Stores all the providers without argument in the current scope.
  /// The keys are the top-level providers, while the values are the
  /// intermediate providers, which are used as internal IDs by
  /// [_createdValues].
  final _allProvidersInScope = HashMap<Provider, Provider>();

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
  final _overriddenProviders = HashMap<Provider, Provider>();

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
  /// NB: differently from [_overriddenProviders], an overridden argument
  /// provider cannot be provided by this scope as a fallback, since no argument
  /// is available here. Therefore, only the [ProviderScope]s that are
  /// descendants of the [ProviderScopeOverride] are affected.
  final _overriddenArgProviders = HashMap<ArgProvider, ArgProvider>();

  /// Stores all the values created by this scope, no matter whether they come
  /// from a [Provider] or from an [ArgProvider].
  ///
  /// The keys are the intermediate providers (which are not necessarily the
  /// top-level providers), while the values are the provided values.
  ///
  /// NB: this map preserves the insertion order, which is the order in which
  /// the values have been created. [dispose] relies on it.
  final _createdValues = <Provider, Object>{};

  /// The top-level providers whose values are currently being created by this
  /// scope, in order of creation. Used to detect circular dependencies.
  ///
  /// Every element is either a [Provider] or an [ArgProvider].
  final _idsBeingCreated = <Object>[];

  @override
  void initState() {
    super.initState();

    final providers = widget._providers;
    if (providers != null) {
      _initializeProviders(providers);
    } else {
      _initializeOverrides(widget._overrides!);
    }
  }

  @override
  void didUpdateWidget(ProviderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_debugCheckScopeDidNotChange(oldWidget), '');
  }

  /// Checks that the set of providers of this scope has not changed.
  ///
  /// The providers (or the overrides) of a [ProviderScope] are read exactly
  /// once, when the scope is mounted. Inserting or removing one on a later
  /// rebuild would silently have no effect, therefore it is reported as an
  /// error in debug mode.
  ///
  /// NB: the error is *reported* and not thrown. Throwing here would abort the
  /// update of the element tree halfway through, which makes the framework fail
  /// again later on, in a much more confusing way. Reporting keeps this scope
  /// working with the providers it has been mounted with, which is exactly what
  /// the change amounts to.
  ///
  /// NB: only the *identity* of the providers is compared. Giving an argument
  /// provider a different argument on a rebuild is deliberately allowed, since
  /// the argument is often rebuilt along with the widget; the initial argument
  /// keeps winning, as documented in
  /// <https://disco.mariuti.com/core/immutability/>.
  bool _debugCheckScopeDidNotChange(ProviderScope oldWidget) {
    // The identity of every provider (or overridden provider) of a scope.
    Set<Object> describe(ProviderScope scope) {
      final ids = <Object>{};

      final providers = scope._providers;
      if (providers != null) {
        for (final item in providers) {
          if (item is ProviderValueBinding) {
            ids.add(item._provider);
          } else if (item is ArgProviderValueBinding) {
            ids.add(item._argProvider);
          }
        }
        return ids;
      }

      for (final item in scope._overrides!) {
        if (item is ProviderOverride) {
          ids.add(item._originalProvider);
        } else if (item is ArgProviderOverride) {
          ids.add(item._originalArgProvider);
        }
      }
      return ids;
    }

    final oldIds = describe(oldWidget);
    final newIds = describe(widget);

    if (oldIds.length != newIds.length || !newIds.containsAll(oldIds)) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError.fromParts([
            ErrorSummary(
              'The providers of a ProviderScope changed after it had been '
              'mounted.',
            ),
            ErrorDescription(
              'The providers (or the overrides) of a ProviderScope are read '
              'exactly once, when the scope is mounted. Inserting a provider '
              'into the list, or removing one from it, on a later rebuild '
              'therefore has no effect, and it usually surfaces much later as '
              'a ProviderWithoutScopeError.',
            ),
            ErrorHint(
              'Provide a fixed set of providers, and use a nested '
              'ProviderScope for the ones whose presence depends on the state '
              'of your widget. If you really need this scope to be rebuilt '
              'from scratch, give it a different key instead: that disposes '
              'its values and creates them again.',
            ),
          ]),
          library: 'disco',
          context: ErrorDescription('while updating a ProviderScope'),
        ),
      );
    }

    return true;
  }

  /// Validates that there are no duplicate providers in the list.
  void _validateProvidersUniqueness(
    List<ValueBinding> allProviders,
  ) {
    assert(
      () {
        final providerIds = <Provider>{};
        final argProviderIds = <ArgProvider>{};

        for (final item in allProviders) {
          if (item is ProviderValueBinding) {
            if (!providerIds.add(item._provider)) {
              throw MultipleProviderOfSameInstance();
            }
          } else if (item is ArgProviderValueBinding) {
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
  void _registerAllProviders(List<ValueBinding> allProviders) {
    // The overrides of a ProviderScopeOverride, if present. They are needed to
    // regenerate the intermediate providers of the overridden providers.
    final overridesScope = ProviderScopeOverrideState.maybeOf(
      context,
    )?._providerScopeState;

    for (final item in allProviders) {
      if (item is ProviderValueBinding) {
        final id = item._provider;

        // If this provider is overridden, its mock generates the intermediate
        // provider; otherwise the top-level provider can act as the
        // intermediate provider itself.
        final mock = overridesScope?._getOverriddenProvider(id);
        _allProvidersInScope[id] = mock?._generateIntermediateProvider() ?? id;
      } else if (item is ArgProviderValueBinding) {
        final id = item._argProvider;

        // The argument provider generating the intermediate provider is either
        // the top-level one or, if overridden, its mock.
        final argProvider = overridesScope?._getOverriddenArgProvider(id) ?? id;

        _allArgProvidersInScope[id] = argProvider._generateIntermediateProvider(
          item._arg,
        );
      }
    }
  }

  /// Initializes providers by validating and registering them. Their values are
  /// always created lazily, i.e. the first time they are injected.
  void _initializeProviders(List<ValueBinding> allProviders) {
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
      _overriddenProviders[id] = mock;

      // The mock is also provided by this scope, so that an override works even
      // if no ProviderScope below provides the original provider at all. In
      // that case only, the value lives here.
      _allProvidersInScope[id] = mock._generateIntermediateProvider();
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
      _overriddenArgProviders[id] = override._mockArgProvider;
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

    _allArgProvidersInScope.clear();
    _allProvidersInScope.clear();
    _overriddenProviders.clear();
    _overriddenArgProviders.clear();
    _createdValues.clear();
    super.dispose();
  }

  /// Disposes all the values created by this scope, by leveraging the
  /// intermediate providers that created them.
  ///
  /// The values are disposed in the reverse order of creation. Since a provider
  /// can inject the other providers of its own scope, and since every value is
  /// created lazily, a value is always created *after* the values it depends on
  /// ; therefore, reversing the creation order guarantees that a value is
  /// always disposed *before* the values it depends on.
  void _disposeCreatedValues() {
    for (final entry in _createdValues.entries.toList().reversed) {
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
  /// [_createdValues].
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
      _createdValues[intermediateProvider] = value;
      return value;
    } finally {
      _idsBeingCreated.removeLast();
    }
  }

  // Providers logic ----------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? _getIntermediateProvider(Provider id) {
    return _allProvidersInScope[id];
  }

  /// Tries to find the [Provider] overriding this [id].
  ///
  /// It returns null if this [id] is not overridden. Only the internal
  /// [ProviderScope] of a [ProviderScopeOverride] can return a value here.
  Provider? _getOverriddenProvider(Provider id) {
    return _overriddenProviders[id];
  }

  /// Tries to find the value already created for this [id].
  /// It returns null if the [id] is not in this scope or if its value has not
  /// been created yet.
  Object? _getCreatedProviderValue(Provider id) {
    final provider = _getIntermediateProvider(id);
    if (provider == null) return null;
    return _createdValues[provider];
  }

  /// Creates a provider value and stores it to [_createdValues].
  dynamic _createProviderValue(Provider id, BuildContext context) {
    return _createAndStoreValue(id, _getIntermediateProvider(id)!, context);
  }

  /// Used to determine if the requested provider is present in the current
  /// scope.
  bool _isProviderInScope(Provider id) {
    // Find the provider by type
    return _getIntermediateProvider(id) != null;
  }

  // ArgProviders logic -------------------------------------------------------

  /// Tries to find the intermediate [Provider] associated with this [id].
  Provider? _getIntermediateProviderForArgProvider(
    ArgProvider id,
  ) {
    return _allArgProvidersInScope[id];
  }

  /// Tries to find the [ArgProvider] overriding this [id].
  ///
  /// It returns null if this [id] is not overridden. Only the internal
  /// [ProviderScope] of a [ProviderScopeOverride] can return a value here.
  ArgProvider? _getOverriddenArgProvider(ArgProvider id) {
    return _overriddenArgProviders[id];
  }

  /// Tries to find the value already created for this [id].
  /// It returns null if the [id] is not in this scope or if its value has not
  /// been created yet.
  Object? _getCreatedArgProviderValue(ArgProvider id) {
    final provider = _getIntermediateProviderForArgProvider(id);
    if (provider == null) return null;
    return _createdValues[provider];
  }

  /// Creates a provider value and stores it to [_createdValues].
  dynamic _createProviderValueForArgProvider(
    ArgProvider id,
    BuildContext context,
  ) {
    return _createAndStoreValue(
      id,
      _getIntermediateProviderForArgProvider(id)!,
      context,
    );
  }

  /// Used to determine if the requested provider is present in the current
  /// scope.
  bool _isArgProviderInScope(ArgProvider id) {
    return _getIntermediateProviderForArgProvider(id) != null;
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
      IterableProperty('createdValues', _createdValues.values),
    );
  }

  // coverage:ignore-end
}

@immutable
class _InheritedProvider extends InheritedWidget {
  const _InheritedProvider({required this.state, required super.child});

  final ProviderScopeState state;

  /// The dependents of this widget are never notified: a [ProviderScope] hands
  /// out values, and the values themselves never change. Reacting to a mutation
  /// of a value is the job of the state management solution of choice.
  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant _InheritedProvider oldWidget) {
    return false;
  }
  // coverage:ignore-end

  /// Whether the scope of this widget provides the given ID.
  ///
  /// Exactly one of [providerId] and [argProviderId] must be given.
  bool _provides(Provider? providerId, ArgProvider? argProviderId) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );
    if (providerId != null) {
      return state._isProviderInScope(providerId);
    }
    return state._isArgProviderInScope(argProviderId!);
  }

  /// Returns the element of the nearest [_InheritedProvider] ancestor whose
  /// scope provides the given ID, or null if there is none.
  ///
  /// This logic is adapted from [InheritedModel]: instead of stopping at the
  /// nearest ancestor of this type, it keeps walking up until one of them
  /// actually provides the ID. This is a small optimization that avoids
  /// traversing every single element between two [ProviderScope]s.
  static InheritedElement? _findNearestElementProviding(
    BuildContext context,
    Provider? providerId,
    ArgProvider? argProviderId,
  ) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_InheritedProvider>();
    // No ancestors of type _InheritedProvider found, exit.
    if (element == null) {
      return null;
    }

    final widget = element.widget as _InheritedProvider;

    // The ancestor providing the ID has been found, return it.
    if (widget._provides(providerId, argProviderId)) {
      return element;
    }

    // This ancestor does not provide the ID: go further up and try again.
    Element? parent;
    element.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    // Return null if we've reached the root.
    if (parent == null) {
      return null;
    }

    return _findNearestElementProviding(parent!, providerId, argProviderId);
  }

  /// Returns the nearest [_InheritedProvider] ancestor whose scope provides the
  /// given ID, or null if there is none.
  ///
  /// Exactly one of [providerId] and [argProviderId] must be given.
  ///
  /// NB: no dependency is registered on the returned widget, since the values
  /// of a [ProviderScope] never change and, thus, there would be nothing to
  /// rebuild. The widget tree is merely walked.
  static _InheritedProvider? findNearestProviding(
    BuildContext context,
    Provider? providerId,
    ArgProvider? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );

    final element = _findNearestElementProviding(
      context,
      providerId,
      argProviderId,
    );
    if (element == null) {
      return null;
    }

    return element.widget as _InheritedProvider;
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

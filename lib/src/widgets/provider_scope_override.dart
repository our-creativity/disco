part of '../../disco.dart';

/// Error thrown when there are multiple ProviderScopeOverride widgets in the
/// widget tree.
class MultipleProviderScopeOverrideError extends Error {
  @override
  String toString() =>
      'You cannot have multiple ProviderScopeOverride widgets in the widget '
      'tree.';
}

/// {@template ProviderScopeOverride}
/// Allows to override specific providers for testing purposes. The same
/// providers that are also created in a [ProviderScope] widget are ignored.
///
/// This is useful for widget testing where mocking is needed.
/// {@endtemplate}
@visibleForTesting
class ProviderScopeOverride extends StatefulWidget {
  /// {@macro ProviderScopeOverride}
  ProviderScopeOverride({
    required this.overrides,
    required this.child,
    super.key,
  });

  /// The widget child that gets access to the [overrides].
  final Widget child;

  /// All the overridden providers provided to all the descendants of
  /// this [ProviderScopeOverride].
  final List<Override> overrides;

  /// Returns the [_ProviderScopeOverrideState] of the [ProviderScopeOverride]
  /// widget.
  /// Returns null if the [ProviderScopeOverride] widget is not found in the
  /// ancestor widget tree.
  static _ProviderScopeOverrideState? _maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<
            _InheritedProviderScopeOverride>()
        ?.widget;
    return (provider as _InheritedProviderScopeOverride?)?.state;
  }

  @override
  State<ProviderScopeOverride> createState() => _ProviderScopeOverrideState();
}

/// The state of the [ProviderScopeOverride] widget.
class _ProviderScopeOverrideState extends State<ProviderScopeOverride> {
  /// The key of the [_ProviderScopeState] of the [ProviderScopeOverride].
  final _providerScopeStateKey = GlobalKey<_ProviderScopeState>();

  /// The [_ProviderScopeState] of the [ProviderScopeOverride] widget.
  _ProviderScopeState get providerScopeState =>
      _providerScopeStateKey.currentState!;

  @override
  Widget build(BuildContext context) {
    if (ProviderScopeOverride._maybeOf(context) != null) {
      throw MultipleProviderScopeOverrideError();
    }
    return _InheritedProviderScopeOverride(
      state: this,
      child: ProviderScope._overrides(
        key: _providerScopeStateKey,
        overrides: widget.overrides,
        child: widget.child,
      ),
    );
  }
}

class _InheritedProviderScopeOverride extends InheritedWidget {
  const _InheritedProviderScopeOverride({
    required super.child,
    required this.state,
  });

  /// The data to be provided
  final _ProviderScopeOverrideState state;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant _InheritedProviderScopeOverride oldWidget) {
    return false;
  }
  // coverage:ignore-end
}

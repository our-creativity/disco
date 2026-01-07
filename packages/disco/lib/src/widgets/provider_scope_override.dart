part of '../disco_internal.dart';

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
class ProviderScopeOverride extends StatefulWidget {
  /// {@macro ProviderScopeOverride}
  @visibleForTesting
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

  @override
  State<ProviderScopeOverride> createState() => ProviderScopeOverrideState();
}

/// The state of the [ProviderScopeOverride] widget.
class ProviderScopeOverrideState extends State<ProviderScopeOverride> {
  /// Returns the [ProviderScopeOverrideState] of the [ProviderScopeOverride]
  /// widget.
  /// Returns null if the [ProviderScopeOverride] widget is not found in the
  /// ancestor widget tree.
  @visibleForTesting
  static ProviderScopeOverrideState? maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<
          _InheritedProviderScopeOverride
        >()
        ?.widget;
    return (provider as _InheritedProviderScopeOverride?)?.state;
  }

  /// The key of the [ProviderScopeState] of the [ProviderScopeOverride].
  final _providerScopeStateKey = GlobalKey<ProviderScopeState>();

  /// The [ProviderScopeState] of the [ProviderScopeOverride] widget.
  ProviderScopeState get providerScopeState =>
      _providerScopeStateKey.currentState!;

  @override
  Widget build(BuildContext context) {
    if (ProviderScopeOverrideState.maybeOf(context) != null) {
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
  final ProviderScopeOverrideState state;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant _InheritedProviderScopeOverride oldWidget) {
    return false;
  }

  // coverage:ignore-end
}

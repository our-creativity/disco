part of '../disco_internal.dart';

class _InheritedProviderScopePortal extends InheritedWidget {
  const _InheritedProviderScopePortal({
    required this.mainContext,
    required super.child,
  });

  final BuildContext mainContext;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  // coverage:ignore-end
}

/// {@template ProviderScopePortal}
/// Makes the providers of the [mainContext] (i.e. the context belonging
/// to the main tree) available in a new widget tree.
///
/// This is useful for accessing providers in modals, because are
/// spawned in a new widget tree.
/// {@endtemplate}
class ProviderScopePortal extends StatelessWidget {
  /// {@macro ProviderScopePortal}
  ProviderScopePortal({
    required this.mainContext,
    required this.child,
    super.key,
  });

  /// The context belonging to the main widget tree, which is used to retrieve
  /// the providers.
  ///
  /// It must be a descendant of the [ProviderScope] widget creating the
  /// provider that needs to be accessed.
  final BuildContext mainContext;

  /// {@macro ProviderScope.child}
  final Widget child;

  /// Retrieves the [ProviderScopePortal] from the closest ancestor.
  /// Returns the [BuildContext], if the widget is found.
  static BuildContext? _maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<
          _InheritedProviderScopePortal
        >()
        ?.widget;
    return (provider as _InheritedProviderScopePortal?)?.mainContext;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProviderScopePortal(
      mainContext: mainContext,
      child: child,
    );
  }
}

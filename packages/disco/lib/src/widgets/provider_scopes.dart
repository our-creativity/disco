part of '../disco_internal.dart';

class ProviderScopes extends StatefulWidget {
  ProviderScopes({
    required this.child,
    required this.providers,
    super.key,
  });

  /// {@template ProviderScope.child}
  /// The widget child that gets access to the [providers].
  /// {@endtemplate}
  final Widget child;

  /// All the providers provided to all the descendants of [ProviderScope].
  final List<List<InstantiableProvider>> providers;

  @override
  State<ProviderScopes> createState() => _ProviderScopesState();
}

class _ProviderScopesState extends State<ProviderScopes> {
  late final Widget nested;

  @override
  void initState() {
    super.initState();
    var widgetToDisplay = widget.child;

    for (final providersInCurrentScope in widget.providers.reversed) {
      widgetToDisplay = ProviderScope(
          providers: providersInCurrentScope, child: widgetToDisplay);
    }

    nested = widgetToDisplay;
  }

  @override
  Widget build(BuildContext context) => nested;
}

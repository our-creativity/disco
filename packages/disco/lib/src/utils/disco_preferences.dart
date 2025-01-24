part of '../../../disco.dart';

/// ## Disco preferences
abstract final class DiscoPreferences {
  DiscoPreferences._();

  /// Whether or not overrides inherit dispose, unless overridden.
  /// By default, this setting is set to false.
  static bool _overridesInheritDisposeByDefault = false;

  /// Whether or not providers compute their value lazily, unless overridden.
  /// By default, this setting is set to true.
  static bool _providersLazyByDefault = true;

  /// The default behavior of this package can be overridden.
  /// This static method should be called in main before starting the app.
  static void setPreferences({
    @visibleForTesting bool? overridesInheritDisposeByDefault,
    bool? providersLazyByDefault,
  }) {
    if (overridesInheritDisposeByDefault != null) {
      DiscoPreferences._overridesInheritDisposeByDefault =
          overridesInheritDisposeByDefault;
    }
    if (providersLazyByDefault != null) {
      DiscoPreferences._providersLazyByDefault = providersLazyByDefault;
    }
  }
}

part of '../disco_internal.dart';

/// ## Disco preferences
abstract final class DiscoPreferences {
  DiscoPreferences._();

  /// Whether or not providers compute their value lazily, unless overridden.
  /// By default, this setting is set to true.
  static bool _providersLazyByDefault = true;

  /// The default behavior of this package can be overridden.
  /// This static method should be called in main before starting the app.
  static void makeProvidersNonLazyByDefault() {
    DiscoPreferences._providersLazyByDefault = false;
  }
}

part of '../disco_internal.dart';

/// The global preferences for the Disco package.
abstract final class DiscoPreferences {
  /// {@template lazy}
  /// Whether or not providers compute their value lazily, unless overridden.
  ///
  /// Defaults to `true`.
  /// {@endtemplate}
  static bool lazy = true;
}

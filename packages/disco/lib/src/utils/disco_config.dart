part of '../disco_internal.dart';

/// The global preferences for the Disco package.
abstract final class DiscoConfig {
  /// Whether the values of the providers are created lazily.
  /// If so, they are created the first time they are injected (default).
  /// If not, they are created as soon as they are inserted in the widget tree.
  ///
  /// It is only used for the providers whose laziness is specified neither
  /// when they are inserted into a [ProviderScope] nor when they are defined.
  ///
  /// {@macro lazy.precedence}
  static bool lazy = true;
}

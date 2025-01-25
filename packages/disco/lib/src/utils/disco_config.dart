part of '../disco_internal.dart';

/// The global preferences for the Disco package.
abstract final class DiscoConfig {
  /// {@template Provider.lazy}
  /// Makes the creation of the provided value lazy. defaults to true.
  ///
  /// > The provider itself is not lazily created, only its contained value.
  ///
  /// if this value is true, the provider's value will be created only when
  /// retrieved from descendants for the first time.
  /// {@endtemplate}
  static bool lazy = true;
}

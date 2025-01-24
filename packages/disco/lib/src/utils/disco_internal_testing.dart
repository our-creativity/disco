part of '../../../disco.dart';

/// ## Disco internal testing
///
/// This class allows to tests internal, private components.
/// Do not use this class in the code of your application
/// (not even in tests).
/// 
/// By using this separate class, the testing methods are not
/// directly present as static methods on classes such as
/// [ProviderScopeOverride], [ProviderScope], etc, making the
/// library simple to be utilized by the users.
@protected
abstract final class DIT {
  DIT._();

  /// This function is used only internally to test
  /// [ProviderScopeOverride._maybeOf] and should not be used outside
  /// this library.
  ///
  /// It returns true if `ProviderScopeOverride._maybeOf(context)` returns
  /// null. Else, it returns false.
  @protected
  static bool providerScopeOverrideMaybeOf(BuildContext context) {
    final overrideState = ProviderScopeOverride._maybeOf(context);
    if (overrideState == null) {
      return true;
    }
    return false;
  }
}

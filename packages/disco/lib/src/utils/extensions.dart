part of '../disco_internal.dart';

extension _DebugNameProvider<T extends Object> on Provider<T> {
  // Returns a debug name for the provider.
  String? get _debugName {
    var s = 'Provider<$_valueType>';
    if (debugName != null) s += '(name: $debugName)';
    return s;
  }
}

extension _DebugNameArgProvider<T extends Object, A> on ArgProvider<T, A> {
  // Returns a debug name for the provider with arguments.
  String? get _debugName {
    var s = 'ArgProvider<$_valueType, $_argumentType>';
    if (debugName != null) s += '(name: $debugName)';
    return s;
  }
}

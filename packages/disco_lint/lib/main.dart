import 'dart:async';

import 'package:disco_lint/src/assists/wrap_with_provider_scope.dart';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

final plugin = _DiscoPlugin();

class _DiscoPlugin extends Plugin {
  @override
  String get name => 'disco_lint';

  @override
  FutureOr<void> register(PluginRegistry registry) {
    registry.registerAssist(WrapWithProviderScope.new);
  }
}

/// Disco is a Flutter library offering convenient, scoped providers for
/// dependency injection that are independent of any specific state
/// management solution.
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'src/models/overrides/override.dart';
part 'src/models/overrides/provider_with_argument_override.dart';
part 'src/models/overrides/provider_without_argument_override.dart';
part 'src/models/providers/instantiable_provider.dart';
part 'src/models/providers/provider_with_argument.dart';
part 'src/models/providers/provider_without_argument.dart';
part 'src/utils/disco_internal_testing.dart';
part 'src/widgets/provider_scope.dart';
part 'src/widgets/provider_scope_override.dart';
part 'src/widgets/provider_scope_portal.dart';

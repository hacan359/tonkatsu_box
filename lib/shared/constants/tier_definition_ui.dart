import 'dart:ui';

import 'package:core/models/tier_definition.dart';

/// Presentation extras for [TierDefinition].
extension TierDefinitionUi on TierDefinition {
  /// Tier label color.
  Color get color => Color(colorValue);
}

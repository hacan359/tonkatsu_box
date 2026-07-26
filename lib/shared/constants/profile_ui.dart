import 'dart:ui';

import '../models/profile.dart';
import '../utils/color_hex.dart';

/// Presentation extras for [Profile].
extension ProfileUi on Profile {
  /// Profile color parsed from the stored hex string.
  Color get displayColor => ColorHex.fromHex(color);
}

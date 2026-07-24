import 'dart:ui';

import '../models/data_source.dart';

/// Presentation extras for [DataSource].
extension DataSourceUi on DataSource {
  /// Brand color of the source.
  Color get color => Color(colorValue);
}

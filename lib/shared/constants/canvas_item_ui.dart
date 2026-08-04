import 'package:core/models/canvas_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import 'media_type_theme.dart';

/// Presentation extras for [CanvasItem].
extension CanvasItemUi on CanvasItem {
  /// Falls back to a note icon for non-media canvas items (text / image / link).
  IconData get mediaPlaceholderIcon {
    final MediaType? media = asMediaType;
    return media != null
        ? MediaTypeTheme.placeholderIconFor(media)
        : Icons.note;
  }
}

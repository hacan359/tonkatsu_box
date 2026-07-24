import 'package:flutter/material.dart';

import '../models/collection_item.dart';
import 'media_type_theme.dart';

/// Presentation extras for [CollectionItem].
extension CollectionItemUi on CollectionItem {
  /// Custom items masquerading as another type get that type's icon.
  IconData get placeholderIcon =>
      MediaTypeTheme.placeholderIconFor(displayMediaType);
}

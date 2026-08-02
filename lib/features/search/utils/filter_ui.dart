import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';

/// Sentinel for the "All" reset item: PopupMenuButton treats null as menu
/// dismissal (onSelected is not called), so the caller maps this back to null.
const String kFilterResetSentinel = '__filter_reset__';

/// Filter accent follows the source's media type, matching the type chevrons.
Color filterAccentForType(MediaType type) => MediaTypeTheme.colorFor(type);

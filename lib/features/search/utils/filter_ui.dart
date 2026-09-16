import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../models/search_source.dart';

/// Sentinel for the "All" reset item: PopupMenuButton treats null as menu
/// dismissal (onSelected is not called), so the caller maps this back to null.
const String kFilterResetSentinel = '__filter_reset__';

/// Filter accent follows the source's media type, matching the type chevrons.
Color filterAccentForType(MediaType type) => MediaTypeTheme.colorFor(type);

/// Why [filter] is off while [exclusive] holds a value; null when usable
/// (no exclusive filter set, or [filter] is the exclusive one itself).
String? exclusiveBlockReason(
  SearchFilter? exclusive,
  SearchFilter filter,
  S l,
) {
  if (exclusive == null || exclusive.key == filter.key) return null;
  return l.filterBlockedBy(exclusive.placeholder(l));
}

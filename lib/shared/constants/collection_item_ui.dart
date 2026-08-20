import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'media_type_theme.dart';

/// Presentation extras for [CollectionItem].
extension CollectionItemUi on CollectionItem {
  /// Custom items masquerading as another type get that type's icon.
  IconData get placeholderIcon =>
      MediaTypeTheme.placeholderIconFor(displayMediaType);

  /// Audio cards read as "Artist — Album" / "Author — Podcast"; a custom
  /// rename and every other type keep [displayName] as is.
  String cardTitle(String displayName) {
    if (mediaType != MediaType.audio || overrideName != null) {
      return displayName;
    }
    final String? artists = audioItem?.artistsString;
    return artists == null ? displayName : '$artists — $displayName';
  }

  /// Qualifier shown after the media type: platform for games, movie/TV for
  /// animation; `null` otherwise.
  String? cardSubcategoryLabel(S l) {
    switch (mediaType) {
      case MediaType.game:
        return platform == null ? null : platformName;
      case MediaType.animation:
        return platformId == AnimationSource.tvShow
            ? l.mediaTypeTvShow
            : l.mediaTypeMovie;
      default:
        return null;
    }
  }
}

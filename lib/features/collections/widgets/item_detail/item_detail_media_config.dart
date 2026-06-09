import 'package:flutter/material.dart';

import '../../../../core/services/image_cache_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/models/anime.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/custom_media.dart';
import '../../../../shared/models/manga.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/tv_show.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/media_detail_view.dart';
import '../../../../shared/widgets/source_badge.dart';

class ItemDetailMediaConfig {
  const ItemDetailMediaConfig({
    required this.coverUrl,
    required this.placeholderIcon,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.cacheImageType,
    required this.cacheImageId,
    required this.accentColor,
    required this.infoChips,
    required this.description,
    required this.hasEpisodeTracker,
    required this.hasMangaProgress,
    required this.hasAnimeProgress,
    required this.hasBookProgress,
    this.externalUrl,
    this.backdropUrl,
    this.tvShow,
    this.manga,
    this.anime,
    this.book,
  });

  factory ItemDetailMediaConfig.from(CollectionItem item, BuildContext context) {
    final String? externalUrl = switch (item.mediaType) {
      MediaType.game => item.game?.externalUrl,
      MediaType.movie || MediaType.animation =>
        item.movie?.externalUrl ?? item.tvShow?.externalUrl,
      MediaType.tvShow => item.tvShow?.externalUrl,
      MediaType.visualNovel => item.visualNovel?.externalUrl,
      MediaType.manga => item.manga?.externalUrl,
      MediaType.anime => item.anime?.externalUrl,
      MediaType.book => item.book?.externalUrl,
      MediaType.custom => item.customMedia?.externalUrl,
    };

    return ItemDetailMediaConfig(
      coverUrl: item.thumbnailUrl,
      placeholderIcon: item.placeholderIcon,
      source: item.dataSource,
      typeIcon: item.mediaType == MediaType.game
          ? Icons.sports_esports
          : item.placeholderIcon,
      typeLabel: _typeLabel(item, context),
      cacheImageType: item.imageType,
      cacheImageId: item.coverImageId,
      accentColor: MediaTypeTheme.colorFor(item.displayMediaType),
      infoChips: _buildChips(item, context),
      description: item.itemDescription,
      hasEpisodeTracker: item.mediaType == MediaType.tvShow ||
          (item.mediaType == MediaType.animation &&
              item.platformId == AnimationSource.tvShow),
      hasMangaProgress: item.mediaType == MediaType.manga,
      hasAnimeProgress: item.mediaType == MediaType.anime,
      hasBookProgress: item.mediaType == MediaType.book,
      externalUrl: externalUrl,
      backdropUrl: item.game?.artworkUrl ??
          item.movie?.backdropUrl ??
          item.tvShow?.backdropUrl ??
          item.manga?.bannerUrl ??
          item.anime?.bannerUrl,
      tvShow: item.tvShow,
      manga: item.manga,
      anime: item.anime,
      book: item.book,
    );
  }

  final String? coverUrl;
  final IconData placeholderIcon;
  final DataSource source;
  final IconData typeIcon;
  final String typeLabel;
  final ImageType cacheImageType;
  final String cacheImageId;
  final Color accentColor;
  final List<MediaDetailChip> infoChips;
  final String? description;
  final bool hasEpisodeTracker;
  final bool hasMangaProgress;
  final bool hasAnimeProgress;
  final bool hasBookProgress;
  final String? externalUrl;
  final String? backdropUrl;
  final TvShow? tvShow;
  final Manga? manga;
  final Anime? anime;
  final Book? book;
}

String _typeLabel(CollectionItem item, BuildContext context) {
  final S l = S.of(context);
  return switch (item.mediaType) {
    MediaType.game => item.platformName,
    MediaType.movie => l.mediaTypeMovie,
    MediaType.tvShow => l.mediaTypeTvShow,
    MediaType.animation => item.platformId == AnimationSource.tvShow
        ? l.animatedSeries
        : l.animatedMovie,
    MediaType.visualNovel => l.mediaTypeVisualNovel,
    MediaType.manga => l.mediaTypeManga,
    MediaType.anime => l.mediaTypeAnime,
    MediaType.book => l.mediaTypeBook,
    MediaType.custom => item.customMedia?.platformName ?? l.mediaTypeCustom,
  };
}

List<MediaDetailChip> _buildChips(CollectionItem item, BuildContext context) {
  final S l = S.of(context);
  final List<MediaDetailChip> chips = <MediaDetailChip>[];
  if (item.releaseYear != null) {
    chips.add(MediaDetailChip(
      icon: Icons.calendar_today_outlined,
      text: item.releaseYear.toString(),
    ));
  }
  if (item.runtime != null) {
    chips.add(MediaDetailChip(
      icon: Icons.schedule_outlined,
      text: _formatRuntime(item.runtime!, l),
    ));
  }
  if (item.totalSeasons != null) {
    chips.add(MediaDetailChip(
      icon: Icons.video_library_outlined,
      text: l.totalSeasons(item.totalSeasons!),
    ));
  }
  if (item.totalEpisodes != null) {
    chips.add(MediaDetailChip(
      icon: Icons.playlist_play,
      text: l.totalEpisodes(item.totalEpisodes!),
    ));
  }
  if (item.formattedRating != null) {
    chips.add(MediaDetailChip(
      icon: Icons.star,
      text: '${item.formattedRating}/10',
      iconColor: AppColors.ratingStar,
    ));
  }
  if (item.mediaType == MediaType.custom && item.customMedia != null) {
    final CustomMedia c = item.customMedia!;
    if (c.altTitle != null && c.altTitle!.isNotEmpty) {
      chips.add(MediaDetailChip(icon: Icons.translate, text: c.altTitle!));
    }
    if (c.platformName != null && c.platformName!.isNotEmpty) {
      chips.add(MediaDetailChip(
        icon: Icons.sports_esports,
        text: c.platformName!,
      ));
    }
  }
  if (item.mediaType == MediaType.manga && item.manga != null) {
    final Manga m = item.manga!;
    chips.add(MediaDetailChip(icon: Icons.menu_book, text: m.progressString));
    if (m.formatLabel != null) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: m.formatLabel!,
      ));
    }
    if (m.authorsString != null) {
      chips.add(MediaDetailChip(
        icon: Icons.person_outline,
        text: m.authorsString!,
      ));
    }
  }
  if (item.mediaType == MediaType.anime && item.anime != null) {
    final Anime a = item.anime!;
    if (a.formatLabel != null) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: a.formatLabel!,
      ));
    }
    chips.add(MediaDetailChip(
      icon: Icons.playlist_play,
      text: a.episodesString,
    ));
    if (a.durationString != null) {
      chips.add(MediaDetailChip(
        icon: Icons.schedule_outlined,
        text: a.durationString!,
      ));
    }
    if (a.studiosString != null) {
      chips.add(MediaDetailChip(icon: Icons.business, text: a.studiosString!));
    }
    if (a.seasonLabel != null) {
      chips.add(MediaDetailChip(icon: Icons.date_range, text: a.seasonLabel!));
    }
    if (a.sourceLabel != null) {
      chips.add(MediaDetailChip(icon: Icons.source, text: a.sourceLabel!));
    }
  }
  if (item.mediaStatus != null) {
    chips.add(MediaDetailChip(
      icon: Icons.info_outline,
      text: item.mediaStatus!,
    ));
  }
  if (item.genresString != null && item.mediaType != MediaType.manga) {
    chips.add(MediaDetailChip(
      icon: Icons.category_outlined,
      text: item.genresString!,
    ));
  }
  const int maxDisplayedTags = 8;
  final String? animeMangaTagsString = switch (item.mediaType) {
    MediaType.anime => item.anime?.tags?.take(maxDisplayedTags).join(', '),
    MediaType.manga => item.manga?.tags?.take(maxDisplayedTags).join(', '),
    _ => null,
  };
  if (animeMangaTagsString != null && animeMangaTagsString.isNotEmpty) {
    chips.add(MediaDetailChip(
      icon: Icons.local_offer_outlined,
      text: animeMangaTagsString,
    ));
  }
  return chips;
}

String _formatRuntime(int minutes, S l) {
  final int hours = minutes ~/ 60;
  final int mins = minutes % 60;
  if (hours > 0 && mins > 0) {
    return l.runtimeHoursMinutes(hours, mins);
  }
  if (hours > 0) {
    return l.runtimeHours(hours);
  }
  return l.runtimeMinutes(mins);
}

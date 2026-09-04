import 'package:core/models/audio_item.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/image_cache_service.dart';
import '../../../../features/search/helpers/studio_search.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/navigation/search_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/media_detail_view.dart';
import '../../../../shared/widgets/source_badge.dart';
import '../../../../shared/constants/collection_item_ui.dart';

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
    this.hasAudioTracker = false,
    required this.hasCustomProgress,
    this.externalUrl,
    this.backdropUrl,
    this.tvShow,
    this.manga,
    this.anime,
    this.book,
    this.audioItem,
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
      MediaType.audio => item.audioItem?.externalUrl,
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
      hasEpisodeTracker: item.usesEpisodeTracker,
      hasMangaProgress: item.mediaType == MediaType.manga,
      // Kitsu anime moved to the season grid; AniList anime stay on the flat
      // counter.
      hasAnimeProgress:
          item.mediaType == MediaType.anime && !item.usesEpisodeTracker,
      hasBookProgress: item.mediaType == MediaType.book,
      hasAudioTracker: item.mediaType == MediaType.audio,
      hasCustomProgress: item.mediaType == MediaType.custom &&
          (item.customUnitTotal != null || item.customUnitGroupTotal != null),
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
      audioItem: item.audioItem,
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
  final bool hasAudioTracker;
  final bool hasCustomProgress;
  final String? externalUrl;
  final String? backdropUrl;
  final TvShow? tvShow;
  final Manga? manga;
  final Anime? anime;
  final Book? book;
  final AudioItem? audioItem;
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
    // Like games showing their platform: the artist is the album's own
    // identity line, not a chip lost among the metadata.
    MediaType.audio => item.audioItem?.artistsString ?? l.mediaTypeAudio,
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
  if (item.mediaType == MediaType.audio && item.audioItem != null) {
    final AudioItem a = item.audioItem!;
    if (a.isPodcast) {
      if (a.trackCount != null) {
        chips.add(MediaDetailChip(
          icon: Icons.podcasts,
          text: l.podcastEpisodesCount(a.trackCount!),
        ));
      }
      if (a.language != null) {
        chips.add(MediaDetailChip(icon: Icons.language, text: a.language!));
      }
    } else {
      if (a.primaryType != null) {
        chips.add(MediaDetailChip(
          icon: Icons.category_outlined,
          text: <String>[a.primaryType!, ...a.secondaryTypes].join(' · '),
        ));
      }
      if (a.trackCount != null) {
        chips.add(MediaDetailChip(
          icon: Icons.queue_music,
          text: l.musicTracksCount(a.trackCount!),
        ));
      }
      if (a.label != null) {
        chips.add(MediaDetailChip(icon: Icons.business, text: a.label!));
      }
      if (a.format != null) {
        chips.add(
          MediaDetailChip(icon: Icons.album_outlined, text: a.format!),
        );
      }
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
    for (final String studio in a.studios ?? const <String>[]) {
      chips.add(MediaDetailChip(
        icon: Icons.business,
        text: studio,
        onTap: () => ProviderScope.containerOf(context, listen: false)
            .read(searchTabRequestProvider.notifier)
            .state = studioSearchRequest(studio),
      ));
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

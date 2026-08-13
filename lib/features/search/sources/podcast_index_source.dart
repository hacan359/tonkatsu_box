import 'package:core/models/audio_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/podcast_index_api.dart';
import '../../../l10n/app_localizations.dart';
import '../filters/podcast_index_category_filter.dart';
import '../filters/podcast_index_language_filter.dart';
import '../models/search_source.dart';

/// Podcast Index feeds. Text search is one relevance page (the API clamps at
/// 60 with no pagination); an empty query browses trending, where the
/// category and language filters actually apply.
class PodcastIndexSource extends SearchSource {
  @override
  String get id => 'podcastindex';

  @override
  MediaType get outputMediaType => MediaType.audio;

  @override
  DataSource get dataSource => DataSource.podcastIndex;

  @override
  String label(S l) => l.searchSourcePodcasts;

  @override
  IconData get icon => Icons.podcasts;

  @override
  bool get supportsBrowse => true;

  @override
  List<SearchFilter> get filters => <SearchFilter>[
        PodcastIndexCategoryFilter(),
        PodcastIndexLanguageFilter(),
      ];

  // Search is relevance-only; trending has no alternative order either.
  @override
  List<BrowseSortOption> get sortOptions => const <BrowseSortOption>[
        BrowseSortOption(id: 'relevance', apiValue: ''),
      ];

  @override
  String searchHint(S l) => l.searchHintPodcasts;

  @override
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  }) async {
    final String text = query?.trim() ?? '';
    final PodcastIndexApi api = ref.read(podcastIndexApiProvider);

    final List<AudioItem> podcasts = text.isEmpty
        ? await api.getTrending(
            lang: filterValues['language'] as String?,
            category: filterValues['category'] as String?,
          )
        : await api.search(text);

    return BrowseResult(
      items: podcasts,
      mediaType: MediaType.audio,
      currentPage: page,
    );
  }

  @override
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref) => null;
}

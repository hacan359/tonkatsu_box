import '../../../shared/navigation/search_providers.dart';
import '../filters/anilist_studio_filter.dart';
import '../sources/anilist_anime_source.dart';

/// Search tab on AniList anime with [studio] preset - the "liked their style,
/// what else did they make" path from a studio chip.
SearchTabRequest studioSearchRequest(String studio) => SearchTabRequest(
  sourceId: AniListAnimeSource.sourceId,
  filterValues: <String, Object?>{AniListStudioFilter.filterKey: studio},
);

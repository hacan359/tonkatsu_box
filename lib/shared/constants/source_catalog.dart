// Single source of truth for the data providers exposed on the Search screen.
// The Welcome "Sources" step and Settings → Credits both render from this, so
// `source_catalog_test` asserts it mirrors [groupedSearchSources].

import '../models/data_source.dart';
import '../models/media_type.dart';

/// Whether a data source needs the user to supply an API key.
enum SourceKeyRequirement { none, recommended, mandatory }

/// Presentation metadata for one data provider. Branding (label, color, logo)
/// lives on [DataSource]; this adds media types, URL and key requirement.
class SourceInfo {
  const SourceInfo({
    required this.source,
    required this.mediaTypes,
    required this.url,
    this.keyRequirement = SourceKeyRequirement.none,
  });

  final DataSource source;
  final List<MediaType> mediaTypes;
  final String url;
  final SourceKeyRequirement keyRequirement;
}

/// Data providers backing the Search screen, in search-tab order. SteamGridDB,
/// Fantlab and VGMaps are intentionally absent — they are not searchable.
const List<SourceInfo> kDataSourceCatalog = <SourceInfo>[
  SourceInfo(
    source: DataSource.tmdb,
    mediaTypes: <MediaType>[
      MediaType.movie,
      MediaType.tvShow,
      MediaType.animation,
    ],
    url: 'https://www.themoviedb.org/',
    keyRequirement: SourceKeyRequirement.recommended,
  ),
  SourceInfo(
    source: DataSource.igdb,
    mediaTypes: <MediaType>[MediaType.game],
    url: 'https://www.igdb.com/',
    keyRequirement: SourceKeyRequirement.recommended,
  ),
  SourceInfo(
    source: DataSource.anilist,
    mediaTypes: <MediaType>[MediaType.anime, MediaType.manga],
    url: 'https://anilist.co/',
  ),
  SourceInfo(
    source: DataSource.mangabaka,
    mediaTypes: <MediaType>[MediaType.manga],
    url: 'https://mangabaka.org/',
  ),
  SourceInfo(
    source: DataSource.vndb,
    mediaTypes: <MediaType>[MediaType.visualNovel],
    url: 'https://vndb.org/',
  ),
  SourceInfo(
    source: DataSource.openLibrary,
    mediaTypes: <MediaType>[MediaType.book],
    url: 'https://openlibrary.org/',
  ),
];

/// Maps a search-source `groupId` to its [DataSource] (used by the sync test).
const Map<String, DataSource> kSearchGroupToSource = <String, DataSource>{
  'tmdb': DataSource.tmdb,
  'igdb': DataSource.igdb,
  'anilist': DataSource.anilist,
  'mangabaka': DataSource.mangabaka,
  'vndb': DataSource.vndb,
  'books': DataSource.openLibrary,
};

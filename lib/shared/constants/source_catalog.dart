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

/// Data providers backing the Search screen — one entry per provider, in
/// search-tab order (the wizard "Sources" step and Settings → Credits render
/// from this). SteamGridDB and VGMaps are absent (not searchable). OpenLibrary
/// and Fantlab are separate book providers, each its own entry.
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
  SourceInfo(
    source: DataSource.fantlab,
    mediaTypes: <MediaType>[MediaType.book],
    url: 'https://fantlab.ru/',
  ),
  SourceInfo(
    source: DataSource.googleBooks,
    mediaTypes: <MediaType>[MediaType.book],
    // "Get a key" link target: the Cloud Console page to enable the Books API.
    url: 'https://console.cloud.google.com/apis/library/books.googleapis.com',
    keyRequirement: SourceKeyRequirement.recommended,
  ),
  SourceInfo(
    source: DataSource.hardcover,
    mediaTypes: <MediaType>[MediaType.book],
    // "Get a key" link target: the account page with the personal token.
    url: 'https://hardcover.app/account/api',
    keyRequirement: SourceKeyRequirement.mandatory,
  ),
  SourceInfo(
    source: DataSource.comicVine,
    mediaTypes: <MediaType>[MediaType.book],
    url: 'https://comicvine.gamespot.com/api/',
    keyRequirement: SourceKeyRequirement.recommended,
  ),
];

/// Maps a search-source `groupId` to the [DataSource]s in that group (used by
/// the sync test). Each provider is its own group (source-first).
const Map<String, List<DataSource>> kSearchGroupToSources =
    <String, List<DataSource>>{
  'tmdb': <DataSource>[DataSource.tmdb],
  'igdb': <DataSource>[DataSource.igdb],
  'anilist': <DataSource>[DataSource.anilist],
  'mangabaka': <DataSource>[DataSource.mangabaka],
  'vndb': <DataSource>[DataSource.vndb],
  'openlibrary': <DataSource>[DataSource.openLibrary],
  'fantlab': <DataSource>[DataSource.fantlab],
  'googlebooks': <DataSource>[DataSource.googleBooks],
  'hardcover': <DataSource>[DataSource.hardcover],
  'comicvine': <DataSource>[DataSource.comicVine],
};

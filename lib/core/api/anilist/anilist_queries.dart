// AniList caps perPage at 50.
const int aniListMaxPerPage = 50;

Iterable<List<int>> aniListBatches(List<int> ids) sync* {
  for (int i = 0; i < ids.length; i += aniListMaxPerPage) {
    yield ids.sublist(
      i,
      i + aniListMaxPerPage > ids.length ? ids.length : i + aniListMaxPerPage,
    );
  }
}

class AniListQueries {
  const AniListQueries._();

  static const String mangaSearch = r'''
query ($page: Int, $perPage: Int, $search: String, $genres: [String],
       $format: MediaFormat, $status: MediaStatus,
       $startDateGreater: FuzzyDateInt, $startDateLesser: FuzzyDateInt,
       $sort: [MediaSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      total
      currentPage
      lastPage
      hasNextPage
    }
    media(type: MANGA, search: $search, genre_in: $genres,
          format: $format, status: $status,
          startDate_greater: $startDateGreater,
          startDate_lesser: $startDateLesser,
          sort: $sort) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      chapters
      volumes
      format
      staff(sort: RELEVANCE, perPage: 5) {
        edges {
          node { name { full } }
          role
        }
      }
    }
  }
}
''';

  static const String mangaGetById = r'''
query ($id: Int) {
  Media(id: $id, type: MANGA) {
    id
    title { romaji english native }
    coverImage { extraLarge large medium }
    description(asHtml: false)
    genres
    averageScore
    status
    startDate { year month day }
    chapters
    volumes
    format
    staff(sort: RELEVANCE, perPage: 5) {
      edges {
        node { name { full } }
        role
      }
    }
  }
}
''';

  static const String mangaGetByIds = r'''
query ($page: Int, $perPage: Int, $ids: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: MANGA, id_in: $ids) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      chapters
      volumes
      format
      staff(sort: RELEVANCE, perPage: 5) {
        edges {
          node { name { full } }
          role
        }
      }
    }
  }
}
''';

  static const String animeSearch = r'''
query ($page: Int, $perPage: Int, $search: String, $genres: [String],
       $status: MediaStatus, $format: MediaFormat,
       $startDateGreater: FuzzyDateInt, $startDateLesser: FuzzyDateInt,
       $sort: [MediaSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      total
      currentPage
      lastPage
      hasNextPage
    }
    media(type: ANIME, search: $search, genre_in: $genres,
          status: $status, format: $format,
          startDate_greater: $startDateGreater,
          startDate_lesser: $startDateLesser,
          sort: $sort) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      episodes
      duration
      format
      source
      studios(isMain: true) { nodes { name } }
      nextAiringEpisode { episode }
    }
  }
}
''';

  static const String animeGetById = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english native }
    coverImage { extraLarge large medium }
    bannerImage
    description(asHtml: false)
    genres
    averageScore
    status
    startDate { year month day }
    episodes
    duration
    format
    source
    studios(isMain: true) { nodes { name } }
    nextAiringEpisode { episode }
  }
}
''';

  static const String animeGetByMalIds = r'''
query ($page: Int, $perPage: Int, $malIds: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, idMal_in: $malIds) {
      id
      idMal
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      episodes
      duration
      format
      source
      studios(isMain: true) { nodes { name } }
      nextAiringEpisode { episode }
    }
  }
}
''';

  static const String mangaGetByMalIds = r'''
query ($page: Int, $perPage: Int, $malIds: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: MANGA, idMal_in: $malIds) {
      id
      idMal
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      chapters
      volumes
      format
      staff(sort: RELEVANCE, perPage: 5) {
        edges {
          node { name { full } }
          role
        }
      }
    }
  }
}
''';

  static const String animeGetByIds = r'''
query ($page: Int, $perPage: Int, $ids: [Int]) {
  Page(page: $page, perPage: $perPage) {
    media(type: ANIME, id_in: $ids) {
      id
      title { romaji english native }
      coverImage { extraLarge large medium }
      bannerImage
      description(asHtml: false)
      genres
      averageScore
      status
      startDate { year month day }
      episodes
      duration
      format
      source
      studios(isMain: true) { nodes { name } }
      nextAiringEpisode { episode }
    }
  }
}
''';

  // MediaListCollection returns every list (Watching/Completed/…) for a user
  // in a single response — no pagination at this level.
  static const String userAnimeList = r'''
query ($userName: String) {
  MediaListCollection(userName: $userName, type: ANIME) {
    lists {
      isCustomList
      entries {
        status
        score(format: POINT_100)
        progress
        progressVolumes
        repeat
        notes
        startedAt { year month day }
        completedAt { year month day }
        updatedAt
        media {
          id
          isAdult
          title { romaji english native }
          coverImage { extraLarge large medium }
          bannerImage
          description(asHtml: false)
          genres
          averageScore
          status
          startDate { year month day }
          episodes
          duration
          format
          source
          studios(isMain: true) { nodes { name } }
          nextAiringEpisode { episode }
        }
      }
    }
  }
}
''';

  static const String userMangaList = r'''
query ($userName: String) {
  MediaListCollection(userName: $userName, type: MANGA) {
    lists {
      isCustomList
      entries {
        status
        score(format: POINT_100)
        progress
        progressVolumes
        repeat
        notes
        startedAt { year month day }
        completedAt { year month day }
        updatedAt
        media {
          id
          isAdult
          title { romaji english native }
          coverImage { extraLarge large medium }
          bannerImage
          description(asHtml: false)
          genres
          averageScore
          status
          startDate { year month day }
          chapters
          volumes
          format
          staff(sort: RELEVANCE, perPage: 5) {
            edges {
              node { name { full } }
              role
            }
          }
        }
      }
    }
  }
}
''';
}

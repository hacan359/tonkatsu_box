// Kitsu publication/airing status → the AniList-style vocabulary shared across
// the app. Identical for anime and manga, so both models reuse this.

/// Maps a Kitsu `status` onto RELEASING / FINISHED / NOT_YET_RELEASED.
String? kitsuStatusVocab(String? status) => switch (status) {
      'current' => 'RELEASING',
      'finished' => 'FINISHED',
      'tba' || 'unreleased' || 'upcoming' => 'NOT_YET_RELEASED',
      _ => null,
    };

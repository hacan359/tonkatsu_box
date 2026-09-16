/// AniList `MediaSeason`, in calendar order so `index` arithmetic walks them.
enum AnimeSeason {
  winter('WINTER'),
  spring('SPRING'),
  summer('SUMMER'),
  fall('FALL');

  const AnimeSeason(this.aniListValue);

  final String aniListValue;
}

typedef AnimeSeasonPoint = ({AnimeSeason season, int year});

/// Winter is Jan-Mar of the same calendar year, so `year` never shifts here.
AnimeSeasonPoint animeSeasonFor(DateTime date) {
  return (season: AnimeSeason.values[(date.month - 1) ~/ 3], year: date.year);
}

AnimeSeasonPoint nextAnimeSeason(AnimeSeasonPoint point) {
  final int next = point.season.index + 1;
  if (next == AnimeSeason.values.length) {
    return (season: AnimeSeason.winter, year: point.year + 1);
  }
  return (season: AnimeSeason.values[next], year: point.year);
}

import 'dart:convert';

import 'package:core/models/media_type.dart';
import 'package:core/utils/json_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/release_schedule.dart';

abstract final class ShowcaseSettingsKeys {
  /// JSON array of row keys the user turned off. Stored as the hidden set so
  /// a row added in a later release shows up for everyone by default.
  static String hiddenRows(String profileId) =>
      'showcase_hidden_rows_$profileId';

  static String hideOwned(String profileId) =>
      'showcase_hide_owned_$profileId';

  /// Discover stored both without a profile suffix; they seed every profile
  /// that has no showcase keys of its own yet.
  static const String legacyHideOwned = 'discover_hide_owned';
  static const String legacySections = 'discover_sections';
}

enum ShowcaseGroup { airing, popular }

enum ShowcaseRowId {
  animeThisSeason('anime_this_season', ShowcaseGroup.airing, MediaType.anime),
  animeNextSeason('anime_next_season', ShowcaseGroup.airing, MediaType.anime),
  nowPlaying('now_playing', ShowcaseGroup.airing, MediaType.movie),
  upcomingMovies('upcoming_movies', ShowcaseGroup.airing, MediaType.movie),
  // Was "TV shows on the air"; the key stays so a hidden row stays hidden.
  tvEpisodesThisWeek('tv_on_the_air', ShowcaseGroup.airing, MediaType.tvShow),
  upcomingGames('upcoming_games', ShowcaseGroup.airing, MediaType.game),
  freshAlbums('fresh_albums', ShowcaseGroup.airing, MediaType.audio),
  trendingMovies('trending_movies', ShowcaseGroup.popular, MediaType.movie),
  trendingTvShows('trending_tv_shows', ShowcaseGroup.popular, MediaType.tvShow),
  popularAnime('popular_anime', ShowcaseGroup.popular, MediaType.anime);

  const ShowcaseRowId(this.key, this.group, this.mediaType);

  /// Persistence key; never renamed once shipped.
  final String key;
  final ShowcaseGroup group;

  /// Library type whose count orders the row within its group.
  final MediaType mediaType;

  /// How a dated feed opens, and whether it offers the switch at all: a
  /// weekly rhythm reads best by weekday, a season of premieres by week.
  ReleaseGrouping get defaultGrouping => switch (this) {
        ShowcaseRowId.animeThisSeason ||
        ShowcaseRowId.tvEpisodesThisWeek =>
          ReleaseGrouping.weekday,
        ShowcaseRowId.animeNextSeason => ReleaseGrouping.week,
        _ => ReleaseGrouping.list,
      };

  IconData get icon => switch (this) {
        ShowcaseRowId.animeThisSeason => Icons.animation,
        ShowcaseRowId.animeNextSeason => Icons.upcoming,
        ShowcaseRowId.nowPlaying => Icons.theaters_outlined,
        ShowcaseRowId.upcomingMovies => Icons.upcoming,
        ShowcaseRowId.tvEpisodesThisWeek => Icons.live_tv_outlined,
        ShowcaseRowId.upcomingGames => Icons.sports_esports_outlined,
        ShowcaseRowId.freshAlbums => Icons.new_releases_outlined,
        ShowcaseRowId.trendingMovies => Icons.local_fire_department,
        ShowcaseRowId.trendingTvShows => Icons.local_fire_department,
        ShowcaseRowId.popularAnime => Icons.animation,
      };

  String localizedLabel(S l) => switch (this) {
        ShowcaseRowId.animeThisSeason => l.showcaseAnimeThisSeason,
        ShowcaseRowId.animeNextSeason => l.showcaseAnimeNextSeason,
        ShowcaseRowId.nowPlaying => l.showcaseNowPlaying,
        ShowcaseRowId.upcomingMovies => l.showcaseUpcomingMovies,
        ShowcaseRowId.tvEpisodesThisWeek => l.showcaseTvEpisodesThisWeek,
        ShowcaseRowId.upcomingGames => l.showcaseUpcomingGames,
        ShowcaseRowId.freshAlbums => l.musicDiscoverFreshReleases,
        ShowcaseRowId.trendingMovies => l.showcaseTrendingMovies,
        ShowcaseRowId.trendingTvShows => l.showcaseTrendingTvShows,
        ShowcaseRowId.popularAnime => l.showcasePopularAnime,
      };

  static ShowcaseRowId? fromKey(String key) {
    for (final ShowcaseRowId id in values) {
      if (id.key == key) return id;
    }
    return null;
  }

  static List<ShowcaseRowId> inGroup(ShowcaseGroup group) =>
      values.where((ShowcaseRowId id) => id.group == group).toList();
}

/// Discover's section keys and the rows they became; a section the user had
/// off hides all of its rows. Sections without a row today are dropped.
const Map<String, Set<ShowcaseRowId>> legacyDiscoverSections =
    <String, Set<ShowcaseRowId>>{
  'trending': <ShowcaseRowId>{
    ShowcaseRowId.trendingMovies,
    ShowcaseRowId.trendingTvShows,
  },
  'upcoming': <ShowcaseRowId>{ShowcaseRowId.upcomingMovies},
  'anime': <ShowcaseRowId>{ShowcaseRowId.popularAnime},
};

class ShowcaseSettings {
  const ShowcaseSettings({
    this.hiddenRows = const <ShowcaseRowId>{},
    this.hideOwned = false,
  });

  final Set<ShowcaseRowId> hiddenRows;

  /// Hide items already in a collection instead of badging them.
  final bool hideOwned;

  bool isEnabled(ShowcaseRowId row) => !hiddenRows.contains(row);

  ShowcaseSettings copyWith({Set<ShowcaseRowId>? hiddenRows, bool? hideOwned}) {
    return ShowcaseSettings(
      hiddenRows: hiddenRows ?? this.hiddenRows,
      hideOwned: hideOwned ?? this.hideOwned,
    );
  }
}

final NotifierProvider<ShowcaseSettingsNotifier, ShowcaseSettings>
    showcaseSettingsProvider =
    NotifierProvider<ShowcaseSettingsNotifier, ShowcaseSettings>(
  ShowcaseSettingsNotifier.new,
);

class ShowcaseSettingsNotifier extends Notifier<ShowcaseSettings> {
  late SharedPreferences _prefs;
  late String _profileId;

  @override
  ShowcaseSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _profileId = ref.watch(currentProfileProvider).id;
    return _load();
  }

  ShowcaseSettings _load() {
    final bool hideOwned =
        _prefs.getBool(ShowcaseSettingsKeys.hideOwned(_profileId)) ??
            _prefs.getBool(ShowcaseSettingsKeys.legacyHideOwned) ??
            false;
    final String? hiddenJson =
        _prefs.getString(ShowcaseSettingsKeys.hiddenRows(_profileId));
    if (hiddenJson != null) {
      return ShowcaseSettings(
        hiddenRows: _decodeRows(hiddenJson),
        hideOwned: hideOwned,
      );
    }
    final String? legacyJson =
        _prefs.getString(ShowcaseSettingsKeys.legacySections);
    if (legacyJson == null) return ShowcaseSettings(hideOwned: hideOwned);
    return ShowcaseSettings(
      hiddenRows: hiddenRowsFromLegacy(decodeJsonStringList(legacyJson).toSet()),
      hideOwned: hideOwned,
    );
  }

  /// Rows hidden by a Discover enabled-list: every row of a section that list
  /// left out. Sections Discover never had stay visible.
  static Set<ShowcaseRowId> hiddenRowsFromLegacy(Set<String> enabledSections) {
    return <ShowcaseRowId>{
      for (final MapEntry<String, Set<ShowcaseRowId>> entry
          in legacyDiscoverSections.entries)
        if (!enabledSections.contains(entry.key)) ...entry.value,
    };
  }

  static Set<ShowcaseRowId> _decodeRows(String json) =>
      decodeJsonStringList(json)
          .map(ShowcaseRowId.fromKey)
          .whereType<ShowcaseRowId>()
          .toSet();

  Future<void> toggleRow(ShowcaseRowId row) async {
    final Set<ShowcaseRowId> hidden = Set<ShowcaseRowId>.from(state.hiddenRows);
    if (!hidden.remove(row)) hidden.add(row);
    state = state.copyWith(hiddenRows: hidden);
    await _save();
  }

  Future<void> setHideOwned({required bool value}) async {
    state = state.copyWith(hideOwned: value);
    await _save();
  }

  Future<void> resetToDefault() async {
    state = const ShowcaseSettings();
    await _save();
  }

  Future<void> _save() async {
    final List<String> keys =
        state.hiddenRows.map((ShowcaseRowId r) => r.key).toList();
    await _prefs.setString(
      ShowcaseSettingsKeys.hiddenRows(_profileId),
      jsonEncode(keys),
    );
    await _prefs.setBool(
      ShowcaseSettingsKeys.hideOwned(_profileId),
      state.hideOwned,
    );
  }
}

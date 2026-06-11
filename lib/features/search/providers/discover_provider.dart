import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/genre_utils.dart';
import 'genre_provider.dart';

/// SharedPreferences keys for Discover settings.
abstract final class DiscoverSettingsKeys {
  /// Stored as a JSON array of enabled section keys.
  static const String sections = 'discover_sections';

  /// Whether to hide items already added to a collection.
  static const String hideOwned = 'discover_hide_owned';
}

enum DiscoverSectionId {
  trending('trending'),

  topRatedMovies('top_rated_movies'),

  popularTvShows('popular_tv_shows'),

  upcoming('upcoming'),

  anime('anime'),

  topRatedTvShows('top_rated_tv_shows');

  const DiscoverSectionId(this.key);

  /// String key used for SharedPreferences persistence.
  final String key;

  /// Returns `null` for an unknown key.
  static DiscoverSectionId? fromKey(String key) {
    for (final DiscoverSectionId id in values) {
      if (id.key == key) return id;
    }
    return null;
  }
}

/// Which Discover sections to show on each search tab, keyed by sourceId.
const Map<String, Set<DiscoverSectionId>> discoverSectionsPerSource =
    <String, Set<DiscoverSectionId>>{
  'movies': <DiscoverSectionId>{
    DiscoverSectionId.trending,
    DiscoverSectionId.topRatedMovies,
    DiscoverSectionId.upcoming,
  },
  'tv': <DiscoverSectionId>{
    DiscoverSectionId.trending,
    DiscoverSectionId.popularTvShows,
    DiscoverSectionId.topRatedTvShows,
  },
  'anime': <DiscoverSectionId>{
    DiscoverSectionId.trending,
    DiscoverSectionId.anime,
  },
};

class DiscoverSettings {
  const DiscoverSettings({
    this.enabledSections = const <DiscoverSectionId>{
      DiscoverSectionId.topRatedMovies,
      DiscoverSectionId.popularTvShows,
      DiscoverSectionId.upcoming,
      DiscoverSectionId.anime,
      DiscoverSectionId.topRatedTvShows,
    },
    this.hideOwned = false,
  });

  final Set<DiscoverSectionId> enabledSections;

  /// Hide items already added to a collection.
  final bool hideOwned;

  static const Set<DiscoverSectionId> defaultSections = <DiscoverSectionId>{
    DiscoverSectionId.topRatedMovies,
    DiscoverSectionId.popularTvShows,
    DiscoverSectionId.upcoming,
    DiscoverSectionId.anime,
    DiscoverSectionId.topRatedTvShows,
  };

  DiscoverSettings copyWith({
    Set<DiscoverSectionId>? enabledSections,
    bool? hideOwned,
  }) {
    return DiscoverSettings(
      enabledSections: enabledSections ?? this.enabledSections,
      hideOwned: hideOwned ?? this.hideOwned,
    );
  }
}

final NotifierProvider<DiscoverSettingsNotifier, DiscoverSettings>
    discoverSettingsProvider =
    NotifierProvider<DiscoverSettingsNotifier, DiscoverSettings>(
  DiscoverSettingsNotifier.new,
);

class DiscoverSettingsNotifier extends Notifier<DiscoverSettings> {
  late SharedPreferences _prefs;

  @override
  DiscoverSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs();
  }

  DiscoverSettings _loadFromPrefs() {
    final String? sectionsJson =
        _prefs.getString(DiscoverSettingsKeys.sections);
    final bool hideOwned =
        _prefs.getBool(DiscoverSettingsKeys.hideOwned) ?? false;

    Set<DiscoverSectionId> sections = DiscoverSettings.defaultSections;
    if (sectionsJson != null) {
      final List<dynamic> keys = jsonDecode(sectionsJson) as List<dynamic>;
      sections = keys
          .map((dynamic k) => DiscoverSectionId.fromKey(k as String))
          .whereType<DiscoverSectionId>()
          .toSet();
    }

    return DiscoverSettings(
      enabledSections: sections,
      hideOwned: hideOwned,
    );
  }

  Future<void> toggleSection(DiscoverSectionId section) async {
    final Set<DiscoverSectionId> updated =
        Set<DiscoverSectionId>.from(state.enabledSections);
    if (updated.contains(section)) {
      updated.remove(section);
    } else {
      updated.add(section);
    }
    state = state.copyWith(enabledSections: updated);
    await _save();
  }

  Future<void> setHideOwned({required bool value}) async {
    state = state.copyWith(hideOwned: value);
    await _save();
  }

  Future<void> resetToDefault() async {
    state = const DiscoverSettings();
    await _save();
  }

  Future<void> _save() async {
    final List<String> keys =
        state.enabledSections.map((DiscoverSectionId s) => s.key).toList();
    await _prefs.setString(DiscoverSettingsKeys.sections, jsonEncode(keys));
    await _prefs.setBool(DiscoverSettingsKeys.hideOwned, state.hideOwned);
  }
}

final FutureProvider<List<Movie>> discoverTrendingMoviesProvider =
    FutureProvider<List<Movie>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  final List<Movie> movies = await tmdb.getTrendingMovies();
  return resolveMovieGenres(movies, genreMap);
});

final FutureProvider<List<TvShow>> discoverTrendingTvShowsProvider =
    FutureProvider<List<TvShow>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  final List<TvShow> shows = await tmdb.getTrendingTvShows();
  return resolveTvGenres(shows, genreMap);
});

final FutureProvider<List<Movie>> discoverTopRatedMoviesProvider =
    FutureProvider<List<Movie>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  final List<Movie> movies = await tmdb.getTopRatedMovies();
  return resolveMovieGenres(movies, genreMap);
});

final FutureProvider<List<TvShow>> discoverPopularTvShowsProvider =
    FutureProvider<List<TvShow>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  final List<TvShow> shows = await tmdb.getPopularTvShows();
  return resolveTvGenres(shows, genreMap);
});

final FutureProvider<List<Movie>> discoverUpcomingMoviesProvider =
    FutureProvider<List<Movie>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  final List<Movie> movies = await tmdb.getUpcomingMovies();
  return resolveMovieGenres(movies, genreMap);
});

/// Anime: TV shows with the Animation genre (TMDB genre id 16).
final FutureProvider<List<TvShow>> discoverAnimeProvider =
    FutureProvider<List<TvShow>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  final List<TvShow> shows = await tmdb.discoverTvShows(genreId: 16);
  return resolveTvGenres(shows, genreMap);
});

final FutureProvider<List<TvShow>> discoverTopRatedTvShowsProvider =
    FutureProvider<List<TvShow>>((Ref ref) async {
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  final List<TvShow> shows = await tmdb.getTopRatedTvShows();
  return resolveTvGenres(shows, genreMap);
});

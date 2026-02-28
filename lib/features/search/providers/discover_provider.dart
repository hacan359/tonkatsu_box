// Провайдеры для Discover подборок.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/genre_utils.dart';
import 'genre_provider.dart';

/// Ключи настроек Discover.
abstract final class DiscoverSettingsKeys {
  /// JSON-массив включённых секций.
  static const String sections = 'discover_sections';

  /// Скрывать ли элементы, уже добавленные в коллекцию.
  static const String hideOwned = 'discover_hide_owned';
}

/// Идентификаторы секций Discover.
enum DiscoverSectionId {
  /// Тренды недели.
  trending('trending'),

  /// Лучшие фильмы.
  topRatedMovies('top_rated_movies'),

  /// Популярные сериалы.
  popularTvShows('popular_tv_shows'),

  /// Скоро в кино.
  upcoming('upcoming'),

  /// Аниме.
  anime('anime'),

  /// Лучшие сериалы.
  topRatedTvShows('top_rated_tv_shows');

  const DiscoverSectionId(this.key);

  /// Строковый ключ для сохранения в SharedPreferences.
  final String key;

  /// Создаёт из строки или null.
  static DiscoverSectionId? fromKey(String key) {
    for (final DiscoverSectionId id in values) {
      if (id.key == key) return id;
    }
    return null;
  }
}

/// Состояние настроек Discover.
class DiscoverSettings {
  /// Создаёт [DiscoverSettings].
  const DiscoverSettings({
    this.enabledSections = const <DiscoverSectionId>{
      DiscoverSectionId.trending,
      DiscoverSectionId.topRatedMovies,
      DiscoverSectionId.popularTvShows,
      DiscoverSectionId.upcoming,
      DiscoverSectionId.anime,
      DiscoverSectionId.topRatedTvShows,
    },
    this.hideOwned = false,
  });

  /// Включённые секции.
  final Set<DiscoverSectionId> enabledSections;

  /// Скрывать элементы, уже добавленные в коллекцию.
  final bool hideOwned;

  /// Все секции по умолчанию.
  static const Set<DiscoverSectionId> defaultSections = <DiscoverSectionId>{
    DiscoverSectionId.trending,
    DiscoverSectionId.topRatedMovies,
    DiscoverSectionId.popularTvShows,
    DiscoverSectionId.upcoming,
    DiscoverSectionId.anime,
    DiscoverSectionId.topRatedTvShows,
  };

  /// Копирование с изменениями.
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

/// Провайдер настроек Discover.
final NotifierProvider<DiscoverSettingsNotifier, DiscoverSettings>
    discoverSettingsProvider =
    NotifierProvider<DiscoverSettingsNotifier, DiscoverSettings>(
  DiscoverSettingsNotifier.new,
);

/// Notifier для настроек Discover.
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

  /// Переключает секцию.
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

  /// Устанавливает режим скрытия.
  Future<void> setHideOwned({required bool value}) async {
    state = state.copyWith(hideOwned: value);
    await _save();
  }

  /// Сбрасывает на настройки по умолчанию.
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

// ===== Провайдеры данных =====

/// Трендовые фильмы.
final FutureProvider<List<Movie>> discoverTrendingMoviesProvider =
    FutureProvider<List<Movie>>((Ref ref) async {
  // Пересчитать при смене языка TMDB
  ref.watch(settingsNotifierProvider
      .select((SettingsState s) => s.tmdbLanguage));
  final TmdbApi tmdb = ref.watch(tmdbApiProvider);
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  final List<Movie> movies = await tmdb.getTrendingMovies();
  return resolveMovieGenres(movies, genreMap);
});

/// Трендовые сериалы.
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

/// Лучшие фильмы.
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

/// Популярные сериалы.
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

/// Скоро в кино.
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

/// Аниме (TV с жанром Animation = 16).
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

/// Лучшие сериалы.
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

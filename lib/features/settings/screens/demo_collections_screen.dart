// Экран генерации демо-коллекций (.xcollx) для tonkatsu-collections.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/igdb_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../providers/settings_provider.dart';

/// IGDB platform IDs.
const int _kPlatformSnes = 19;
const int _kPlatformPs1 = 7;
const int _kPlatformNes = 18;
const int _kPlatformGenesis = 29;
const int _kPlatformN64 = 4;
const int _kPlatformGameBoy = 33;

/// TMDB animation genre ID.
const int _kTmdbAnimationGenreId = 16;

/// Описание одной коллекции для генерации.
class _CollectionSpec {
  const _CollectionSpec({
    required this.name,
    required this.description,
    required this.fileName,
    required this.type,
    this.platformId,
    this.genreId,
  });

  final String name;
  final String description;
  final String fileName;
  final _CollectionType type;
  final int? platformId;
  final int? genreId;
}

enum _CollectionType {
  igdbPlatform,
  tmdbTopMovies,
  tmdbTopTvShows,
  tmdbAnimeMovies,
  tmdbAnimeSeries,
}

/// Все 10 коллекций для генерации.
const List<_CollectionSpec> _collections = <_CollectionSpec>[
  // 6 игровых
  _CollectionSpec(
    name: 'Top SNES Games',
    description: 'Top 50 highest rated Super Nintendo games of all time',
    fileName: 'top_snes_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformSnes,
  ),
  _CollectionSpec(
    name: 'Top PS1 Games',
    description: 'Top 50 highest rated PlayStation 1 games of all time',
    fileName: 'top_ps1_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformPs1,
  ),
  _CollectionSpec(
    name: 'Top NES Games',
    description: 'Top 50 highest rated Nintendo Entertainment System games',
    fileName: 'top_nes_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformNes,
  ),
  _CollectionSpec(
    name: 'Top Sega Genesis Games',
    description: 'Top 50 highest rated Sega Genesis / Mega Drive games',
    fileName: 'top_genesis_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformGenesis,
  ),
  _CollectionSpec(
    name: 'Top N64 Games',
    description: 'Top 50 highest rated Nintendo 64 games of all time',
    fileName: 'top_n64_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformN64,
  ),
  _CollectionSpec(
    name: 'Top Game Boy Games',
    description: 'Top 50 highest rated Game Boy games of all time',
    fileName: 'top_gameboy_games',
    type: _CollectionType.igdbPlatform,
    platformId: _kPlatformGameBoy,
  ),
  // 4 медиа
  _CollectionSpec(
    name: 'Top Rated Movies',
    description: 'Top 50 highest rated movies of all time (TMDB)',
    fileName: 'top_rated_movies',
    type: _CollectionType.tmdbTopMovies,
  ),
  _CollectionSpec(
    name: 'Top Rated TV Shows',
    description: 'Top 50 highest rated TV shows of all time (TMDB)',
    fileName: 'top_rated_tv_shows',
    type: _CollectionType.tmdbTopTvShows,
  ),
  _CollectionSpec(
    name: 'Best Anime Series',
    description: 'Top 50 highest rated anime TV series (TMDB)',
    fileName: 'best_anime_series',
    type: _CollectionType.tmdbAnimeSeries,
    genreId: _kTmdbAnimationGenreId,
  ),
  _CollectionSpec(
    name: 'Best Anime Movies',
    description: 'Top 50 highest rated anime movies (TMDB)',
    fileName: 'best_anime_movies',
    type: _CollectionType.tmdbAnimeMovies,
    genreId: _kTmdbAnimationGenreId,
  ),
];

/// Экран генерации демо-коллекций.
class DemoCollectionsScreen extends ConsumerStatefulWidget {
  /// Создаёт [DemoCollectionsScreen].
  const DemoCollectionsScreen({super.key});

  @override
  ConsumerState<DemoCollectionsScreen> createState() =>
      _DemoCollectionsScreenState();
}

class _DemoCollectionsScreenState
    extends ConsumerState<DemoCollectionsScreen> {
  final List<String> _log = <String>[];
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = false;
  bool _isCancelled = false;
  String? _outputDir;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _log.add('[${_timestamp()}] $message');
    });
    // Scroll to bottom after frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _timestamp() {
    final DateTime now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDirectoryAndGenerate() async {
    final String? dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output folder for .xcollx files',
    );
    if (dir == null) return;

    setState(() {
      _outputDir = dir;
      _isRunning = true;
      _isCancelled = false;
      _log.clear();
    });

    _addLog('Output directory: $dir');
    _addLog('Starting generation of ${_collections.length} collections...');
    _addLog('');

    final IgdbApi igdbApi = ref.read(igdbApiProvider);
    final TmdbApi tmdbApi = ref.read(tmdbApiProvider);
    final SettingsState settings = ref.read(settingsNotifierProvider);

    // Ensure IGDB credentials are set.
    if (settings.accessToken != null && settings.clientId != null) {
      igdbApi.setCredentials(
        clientId: settings.clientId!,
        accessToken: settings.accessToken!,
      );
    }
    if (settings.tmdbApiKey != null) {
      tmdbApi.setApiKey(settings.tmdbApiKey!);
    }

    final Dio imageDio = Dio();
    int successCount = 0;

    try {
      for (int i = 0; i < _collections.length; i++) {
        if (_isCancelled) {
          _addLog('Cancelled by user.');
          break;
        }

        final _CollectionSpec spec = _collections[i];
        _addLog('--- [${i + 1}/${_collections.length}] ${spec.name} ---');

        try {
          final XcollFile xcoll = await _generateCollection(
            spec: spec,
            igdbApi: igdbApi,
            tmdbApi: tmdbApi,
            imageDio: imageDio,
          );

          if (_isCancelled) break;

          // Write file.
          final String filePath = '$dir/${spec.fileName}.xcollx';
          final String jsonString = xcoll.toJsonString();
          final File file = File(filePath);
          await file.writeAsString(jsonString);

          final int sizeKb = jsonString.length ~/ 1024;
          _addLog('Saved: ${spec.fileName}.xcollx ($sizeKb KB)');
          _addLog('');
          successCount++;
        } catch (e) {
          _addLog('ERROR generating ${spec.name}: $e');
          _addLog('');
        }
      }

      _addLog('===================================');
      _addLog('Done! $successCount/${_collections.length} files saved to $dir');
    } finally {
      imageDio.close();
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<XcollFile> _generateCollection({
    required _CollectionSpec spec,
    required IgdbApi igdbApi,
    required TmdbApi tmdbApi,
    required Dio imageDio,
  }) async {
    switch (spec.type) {
      case _CollectionType.igdbPlatform:
        return _generateGameCollection(
          spec: spec,
          igdbApi: igdbApi,
          imageDio: imageDio,
        );
      case _CollectionType.tmdbTopMovies:
        return _generateMovieCollection(
          spec: spec,
          tmdbApi: tmdbApi,
          imageDio: imageDio,
        );
      case _CollectionType.tmdbTopTvShows:
        return _generateTvShowCollection(
          spec: spec,
          tmdbApi: tmdbApi,
          imageDio: imageDio,
        );
      case _CollectionType.tmdbAnimeMovies:
        return _generateAnimeMovieCollection(
          spec: spec,
          tmdbApi: tmdbApi,
          imageDio: imageDio,
        );
      case _CollectionType.tmdbAnimeSeries:
        return _generateAnimeSeriesCollection(
          spec: spec,
          tmdbApi: tmdbApi,
          imageDio: imageDio,
        );
    }
  }

  // ===== Game collections (IGDB) =====

  Future<XcollFile> _generateGameCollection({
    required _CollectionSpec spec,
    required IgdbApi igdbApi,
    required Dio imageDio,
  }) async {
    _addLog('Fetching top games for platform ${spec.platformId}...');

    final List<Game> games = await igdbApi.getTopGamesByPlatform(
      platformId: spec.platformId!,
      limit: 50,
    );
    _addLog('Got ${games.length} games');

    // Rate limit delay for IGDB.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Build items and media.
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> mediaGames = <Map<String, dynamic>>[];

    for (final Game game in games) {
      items.add(<String, dynamic>{
        'media_type': 'game',
        'external_id': game.id,
        'platform_id': spec.platformId,
      });
      mediaGames.add(game.toDb());
    }

    // Download covers.
    final Map<String, String> images = await _downloadGameCovers(
      games: games,
      imageDio: imageDio,
    );

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: spec.name,
      author: 'Tonkatsu Box',
      created: DateTime.now().toUtc(),
      description: spec.description,
      items: items,
      images: images,
      media: <String, dynamic>{
        'games': mediaGames,
      },
    );
  }

  Future<Map<String, String>> _downloadGameCovers({
    required List<Game> games,
    required Dio imageDio,
  }) async {
    final Map<String, String> images = <String, String>{};
    final List<Game> gamesWithCovers =
        games.where((Game g) => g.coverUrl != null).toList();
    _addLog('Downloading ${gamesWithCovers.length} game covers...');

    // Download in chunks of 5.
    for (int i = 0; i < gamesWithCovers.length; i += 5) {
      if (_isCancelled) break;
      final int end = (i + 5).clamp(0, gamesWithCovers.length);
      final List<Game> chunk = gamesWithCovers.sublist(i, end);

      final List<String?> results = await Future.wait(
        chunk.map((Game g) => _downloadImageBase64(imageDio, g.coverUrl!)),
      );

      for (int j = 0; j < chunk.length; j++) {
        if (results[j] != null) {
          images['game_covers/${chunk[j].id}'] = results[j]!;
        }
      }

      if (i % 20 == 0 && i > 0) {
        _addLog('  ...${images.length} covers downloaded');
      }
    }

    _addLog('Downloaded ${images.length} covers');
    return images;
  }

  // ===== Movie collections (TMDB) =====

  Future<XcollFile> _generateMovieCollection({
    required _CollectionSpec spec,
    required TmdbApi tmdbApi,
    required Dio imageDio,
  }) async {
    _addLog('Fetching top rated movies...');

    final List<Movie> allMovies = <Movie>[];
    for (int page = 1; page <= 3 && allMovies.length < 50; page++) {
      final List<Movie> movies = await tmdbApi.getTopRatedMovies(page: page);
      allMovies.addAll(movies);
    }
    final List<Movie> movies = allMovies.take(50).toList();
    _addLog('Got ${movies.length} movies');

    return _buildMovieXcoll(
      spec: spec,
      movies: movies,
      imageDio: imageDio,
      mediaType: 'movie',
    );
  }

  Future<XcollFile> _generateAnimeMovieCollection({
    required _CollectionSpec spec,
    required TmdbApi tmdbApi,
    required Dio imageDio,
  }) async {
    _addLog('Fetching top anime movies...');

    final List<Movie> allMovies = <Movie>[];
    for (int page = 1; page <= 3 && allMovies.length < 50; page++) {
      final List<Movie> movies = await tmdbApi.discoverMovies(
        genreId: spec.genreId,
        voteCountGte: 100,
        sortBy: 'vote_average.desc',
        page: page,
      );
      allMovies.addAll(movies);
    }
    final List<Movie> movies = allMovies.take(50).toList();
    _addLog('Got ${movies.length} anime movies');

    return _buildMovieXcoll(
      spec: spec,
      movies: movies,
      imageDio: imageDio,
      mediaType: 'animation',
    );
  }

  Future<XcollFile> _buildMovieXcoll({
    required _CollectionSpec spec,
    required List<Movie> movies,
    required Dio imageDio,
    required String mediaType,
  }) async {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> mediaMovies = <Map<String, dynamic>>[];

    for (final Movie movie in movies) {
      items.add(<String, dynamic>{
        'media_type': mediaType,
        'external_id': movie.tmdbId,
      });
      mediaMovies.add(movie.toDb());
    }

    final Map<String, String> images = await _downloadMoviePosters(
      movies: movies,
      imageDio: imageDio,
    );

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: spec.name,
      author: 'Tonkatsu Box',
      created: DateTime.now().toUtc(),
      description: spec.description,
      items: items,
      images: images,
      media: <String, dynamic>{
        'movies': mediaMovies,
      },
    );
  }

  Future<Map<String, String>> _downloadMoviePosters({
    required List<Movie> movies,
    required Dio imageDio,
  }) async {
    final Map<String, String> images = <String, String>{};
    final List<Movie> moviesWithPosters =
        movies.where((Movie m) => m.posterUrl != null).toList();
    _addLog('Downloading ${moviesWithPosters.length} movie posters...');

    for (int i = 0; i < moviesWithPosters.length; i += 5) {
      if (_isCancelled) break;
      final int end = (i + 5).clamp(0, moviesWithPosters.length);
      final List<Movie> chunk = moviesWithPosters.sublist(i, end);

      final List<String?> results = await Future.wait(
        chunk.map((Movie m) => _downloadImageBase64(imageDio, m.posterUrl!)),
      );

      for (int j = 0; j < chunk.length; j++) {
        if (results[j] != null) {
          images['movie_posters/${chunk[j].tmdbId}'] = results[j]!;
        }
      }

      if (i % 20 == 0 && i > 0) {
        _addLog('  ...${images.length} posters downloaded');
      }
    }

    _addLog('Downloaded ${images.length} posters');
    return images;
  }

  // ===== TV Show collections (TMDB) =====

  Future<XcollFile> _generateTvShowCollection({
    required _CollectionSpec spec,
    required TmdbApi tmdbApi,
    required Dio imageDio,
  }) async {
    _addLog('Fetching top rated TV shows...');

    final List<TvShow> allShows = <TvShow>[];
    for (int page = 1; page <= 3 && allShows.length < 50; page++) {
      final List<TvShow> shows = await tmdbApi.getTopRatedTvShows(page: page);
      allShows.addAll(shows);
    }
    final List<TvShow> shows = allShows.take(50).toList();
    _addLog('Got ${shows.length} TV shows');

    return _buildTvShowXcoll(
      spec: spec,
      shows: shows,
      imageDio: imageDio,
      mediaType: 'tv_show',
    );
  }

  Future<XcollFile> _generateAnimeSeriesCollection({
    required _CollectionSpec spec,
    required TmdbApi tmdbApi,
    required Dio imageDio,
  }) async {
    _addLog('Fetching top anime series...');

    final List<TvShow> allShows = <TvShow>[];
    for (int page = 1; page <= 3 && allShows.length < 50; page++) {
      final List<TvShow> shows = await tmdbApi.discoverTvShows(
        genreId: spec.genreId,
        voteCountGte: 100,
        sortBy: 'vote_average.desc',
        page: page,
      );
      allShows.addAll(shows);
    }
    final List<TvShow> shows = allShows.take(50).toList();
    _addLog('Got ${shows.length} anime series');

    return _buildTvShowXcoll(
      spec: spec,
      shows: shows,
      imageDio: imageDio,
      mediaType: 'animation',
    );
  }

  Future<XcollFile> _buildTvShowXcoll({
    required _CollectionSpec spec,
    required List<TvShow> shows,
    required Dio imageDio,
    required String mediaType,
  }) async {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> mediaTvShows = <Map<String, dynamic>>[];

    for (final TvShow show in shows) {
      items.add(<String, dynamic>{
        'media_type': mediaType,
        'external_id': show.tmdbId,
      });
      mediaTvShows.add(show.toDb());
    }

    final Map<String, String> images = await _downloadTvShowPosters(
      shows: shows,
      imageDio: imageDio,
    );

    return XcollFile(
      version: xcollFormatVersion,
      format: ExportFormat.full,
      name: spec.name,
      author: 'Tonkatsu Box',
      created: DateTime.now().toUtc(),
      description: spec.description,
      items: items,
      images: images,
      media: <String, dynamic>{
        'tv_shows': mediaTvShows,
      },
    );
  }

  Future<Map<String, String>> _downloadTvShowPosters({
    required List<TvShow> shows,
    required Dio imageDio,
  }) async {
    final Map<String, String> images = <String, String>{};
    final List<TvShow> showsWithPosters =
        shows.where((TvShow s) => s.posterUrl != null).toList();
    _addLog('Downloading ${showsWithPosters.length} TV show posters...');

    for (int i = 0; i < showsWithPosters.length; i += 5) {
      if (_isCancelled) break;
      final int end = (i + 5).clamp(0, showsWithPosters.length);
      final List<TvShow> chunk = showsWithPosters.sublist(i, end);

      final List<String?> results = await Future.wait(
        chunk.map((TvShow s) => _downloadImageBase64(imageDio, s.posterUrl!)),
      );

      for (int j = 0; j < chunk.length; j++) {
        if (results[j] != null) {
          images['tv_show_posters/${chunk[j].tmdbId}'] = results[j]!;
        }
      }

      if (i % 20 == 0 && i > 0) {
        _addLog('  ...${images.length} posters downloaded');
      }
    }

    _addLog('Downloaded ${images.length} posters');
    return images;
  }

  // ===== Image download helper =====

  Future<String?> _downloadImageBase64(Dio dio, String url) async {
    try {
      final Response<List<int>> response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return base64Encode(response.data!);
      }
    } catch (_) {
      // Skip failed images silently.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: 'Demo Generator',
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header.
              Text(
                'Demo Collections Generator',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Generates 10 .xcollx files (6 game + 4 media) '
                'with embedded posters for tonkatsu-collections repo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Buttons.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _isRunning ? null : _pickDirectoryAndGenerate,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Generate All (10 collections)'),
                  ),
                  if (_isRunning) ...<Widget>[
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCancelled = true;
                        });
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Cancel'),
                    ),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              if (_outputDir != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Output: $_outputDir',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // Log area.
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: _log.isEmpty
                      ? Center(
                          child: Text(
                            'Press "Generate All" to start...',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          itemCount: _log.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String line = _log[index];
                            final bool isError =
                                line.contains('ERROR');
                            final bool isDone =
                                line.contains('Done!');
                            final bool isSaved =
                                line.contains('Saved:');
                            final bool isHeader =
                                line.contains('---');

                            Color textColor = AppColors.textSecondary;
                            if (isError) {
                              textColor = AppColors.error;
                            } else if (isDone) {
                              textColor = AppColors.success;
                            } else if (isSaved) {
                              textColor = AppColors.brand;
                            } else if (isHeader) {
                              textColor = AppColors.textPrimary;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                              ),
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

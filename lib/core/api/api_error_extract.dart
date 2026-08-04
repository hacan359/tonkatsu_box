import 'anilist_api.dart';
import 'comicvine_api.dart';
import 'fantlab_api.dart';
import 'google_books_api.dart';
import 'hardcover_api.dart';
import 'igdb_api.dart';
import 'kodi_api.dart';
import 'mangabaka_api.dart';
import 'openlibrary_api.dart';
import 'ra_api.dart';
import 'screenscraper_api.dart';
import 'simkl_api.dart';
import 'steam_api.dart';
import 'steamgriddb_api.dart';
import 'tmdb_api.dart';
import 'vndb_api.dart';

typedef ApiError = ({String message, String? detail});

/// Pulls a user-facing message and an optional debug `detail` out of any of
/// the project's typed API exceptions. Unknown exception types fall back to
/// `toString()`.
ApiError extractApiError(Exception e) {
  return switch (e) {
    TmdbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    IgdbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    AniListApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    MangaBakaApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    ComicVineApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    OpenLibraryApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    VndbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    SteamGridDbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    SteamApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    RaApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    GoogleBooksApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    HardcoverApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    FantlabApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    KodiApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    ScreenScraperApiException(:final String message) =>
      (message: message, detail: null),
    SimklApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    _ => (message: e.toString(), detail: null),
  };
}

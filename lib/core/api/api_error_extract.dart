import 'anilist_api.dart';
import 'igdb_api.dart';
import 'ra_api.dart';
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
    VndbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    SteamGridDbApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    SteamApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    RaApiException(:final String message, :final String? detail) =>
      (message: message, detail: detail),
    _ => (message: e.toString(), detail: null),
  };
}

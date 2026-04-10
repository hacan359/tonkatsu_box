// Хелпер для извлечения message и detail из типизированных API exceptions.

import 'anilist_api.dart';
import 'igdb_api.dart';
import 'ra_api.dart';
import 'steam_api.dart';
import 'steamgriddb_api.dart';
import 'tmdb_api.dart';
import 'vndb_api.dart';

/// Результат извлечения ошибки API: сообщение + опциональный detail.
typedef ApiError = ({String message, String? detail});

/// Извлекает user-friendly message и debug detail из [Exception].
///
/// Поддерживает все 7 типизированных API exception классов проекта.
/// Для неизвестных исключений возвращает `toString()` без detail.
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

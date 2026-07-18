import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/api/api_error_extract.dart';
import 'package:tonkatsu_box/core/api/comicvine_api.dart';
import 'package:tonkatsu_box/core/api/fantlab_api.dart';
import 'package:tonkatsu_box/core/api/google_books_api.dart';
import 'package:tonkatsu_box/core/api/hardcover_api.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/kodi_api.dart';
import 'package:tonkatsu_box/core/api/ra_api.dart';
import 'package:tonkatsu_box/core/api/screenscraper_api.dart';
import 'package:tonkatsu_box/core/api/steam_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/api/vndb_api.dart';

void main() {
  group('extractApiError', () {
    test('pulls message and detail from every typed API exception', () {
      final List<(Exception, String)> cases = <(Exception, String)>[
        (const TmdbApiException('tmdb', detail: 'd1'), 'tmdb'),
        (const IgdbApiException('igdb', detail: 'd2'), 'igdb'),
        (const AniListApiException('anilist', detail: 'd3'), 'anilist'),
        (const VndbApiException('vndb', detail: 'd4'), 'vndb'),
        (const SteamGridDbApiException('sgdb', detail: 'd5'), 'sgdb'),
        (const SteamApiException('steam', detail: 'd6'), 'steam'),
        (const RaApiException('ra', detail: 'd7'), 'ra'),
        (const ComicVineApiException('comicvine', detail: 'd8'), 'comicvine'),
        (const GoogleBooksApiException('gbooks', detail: 'd9'), 'gbooks'),
        (const HardcoverApiException('hardcover', detail: 'd10'), 'hardcover'),
        (const FantlabApiException('fantlab', detail: 'd11'), 'fantlab'),
        (const KodiApiException('kodi', detail: 'd12'), 'kodi'),
      ];

      for (final (Exception e, String msg) in cases) {
        final ApiError r = extractApiError(e);
        expect(r.message, msg);
        expect(r.detail, isNotNull);
      }
    });

    test('keeps a null detail when the exception carries none', () {
      final ApiError r = extractApiError(const TmdbApiException('boom'));
      expect(r.message, 'boom');
      expect(r.detail, isNull);
    });

    test('maps ScreenScraper message without a detail', () {
      final ApiError r = extractApiError(ScreenScraperApiException('ss'));
      expect(r.message, 'ss');
      expect(r.detail, isNull);
    });

    test('falls back to toString for unknown exception types', () {
      final ApiError r = extractApiError(const FormatException('bad input'));
      expect(r.detail, isNull);
      expect(r.message, contains('bad input'));
    });
  });
}

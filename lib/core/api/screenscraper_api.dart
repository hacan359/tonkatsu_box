import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/constants/api_defaults.dart';

class ScreenScraperApiException implements Exception {
  ScreenScraperApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ScreenScraperApiException($statusCode): $message';
}

class SsMedia {
  const SsMedia({
    required this.type,
    required this.url,
    this.format,
    this.region,
  });

  factory SsMedia.fromJson(Map<String, dynamic> json) => SsMedia(
        type: (json['type'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
        format: json['format'] as String?,
        region: json['region'] as String?,
      );

  final String type;
  final String url;
  final String? format;
  final String? region;
}

class SsGame {
  const SsGame({
    required this.id,
    required this.name,
    required this.medias,
  });

  factory SsGame.fromJson(Map<String, dynamic> json) {
    final List<dynamic> noms = (json['noms'] as List<dynamic>?) ?? <dynamic>[];
    String name = '';
    for (final dynamic n in noms) {
      if (n is Map<String, dynamic>) {
        final String? text = n['text'] as String?;
        if (text != null && text.isNotEmpty) {
          name = text;
          if (n['region'] == 'us' || n['region'] == 'wor') break;
        }
      }
    }
    final List<dynamic> medias =
        (json['medias'] as List<dynamic>?) ?? <dynamic>[];
    return SsGame(
      id: int.tryParse('${json['id']}') ?? 0,
      name: name,
      medias: medias
          .whereType<Map<String, dynamic>>()
          .map(SsMedia.fromJson)
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final List<SsMedia> medias;
}

class SsUserQuota {
  const SsUserQuota({
    required this.requestsToday,
    required this.maxPerDay,
    required this.maxPerMinute,
    required this.maxThreads,
    required this.level,
  });

  factory SsUserQuota.fromJson(Map<String, dynamic> json) {
    int parseInt(Object? v) => int.tryParse('${v ?? ''}') ?? 0;
    return SsUserQuota(
      requestsToday: parseInt(json['requeststoday']),
      maxPerDay: parseInt(json['maxrequestsperday']),
      maxPerMinute: parseInt(json['maxrequestspermin']),
      maxThreads: parseInt(json['maxthreads']),
      level: parseInt(json['niveau']),
    );
  }

  final int requestsToday;
  final int maxPerDay;
  final int maxPerMinute;
  final int maxThreads;
  final int level;
}

final Provider<ScreenScraperApi> screenScraperApiProvider =
    Provider<ScreenScraperApi>((Ref ref) => ScreenScraperApi());

class ScreenScraperApi {
  ScreenScraperApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.screenscraper.fr/api2/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
            ));

  final Dio _dio;

  String _ssid = '';
  String _sspassword = '';

  void setUserCredentials({required String ssid, required String sspassword}) {
    _ssid = ssid;
    _sspassword = sspassword;
  }

  bool get hasUserCredentials => _ssid.isNotEmpty && _sspassword.isNotEmpty;

  Map<String, String> _baseParams() {
    return <String, String>{
      'devid': ApiDefaults.screenScraperDevId,
      'devpassword': ApiDefaults.screenScraperDevPassword,
      'softname': ApiDefaults.screenScraperSoftname,
      'output': 'json',
      'ssid': _ssid,
      'sspassword': _sspassword,
    };
  }

  bool get _hasAllCredentials =>
      ApiDefaults.hasScreenScraperDevCreds && hasUserCredentials;

  Future<SsGame?> searchGame({
    required String name,
    required int systemeId,
  }) async {
    if (!_hasAllCredentials) {
      throw ScreenScraperApiException('Missing ScreenScraper credentials');
    }
    try {
      final Response<Map<String, dynamic>> resp =
          await _dio.get<Map<String, dynamic>>(
        'jeuRecherche.php',
        queryParameters: <String, dynamic>{
          ..._baseParams(),
          'recherche': name,
          'systemeid': systemeId.toString(),
        },
      );
      final Map<String, dynamic>? body = resp.data;
      final dynamic resObj = body?['response'];
      if (resObj is! Map<String, dynamic>) return null;
      final dynamic jeux = resObj['jeux'];
      if (jeux is! List<dynamic> || jeux.isEmpty) return null;
      final Map<String, dynamic> first = jeux.first as Map<String, dynamic>;
      return SsGame.fromJson(first);
    } on DioException catch (e) {
      throw ScreenScraperApiException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SsUserQuota> getUserInfo() async {
    if (!_hasAllCredentials) {
      throw ScreenScraperApiException('Missing ScreenScraper credentials');
    }
    try {
      final Response<Map<String, dynamic>> resp =
          await _dio.get<Map<String, dynamic>>(
        'ssuserInfos.php',
        queryParameters: _baseParams(),
      );
      final Map<String, dynamic>? body = resp.data;
      final dynamic resObj = body?['response'];
      if (resObj is! Map<String, dynamic>) {
        throw ScreenScraperApiException('Unexpected response shape');
      }
      final dynamic user = resObj['ssuser'];
      if (user is! Map<String, dynamic>) {
        throw ScreenScraperApiException('Unexpected response shape');
      }
      return SsUserQuota.fromJson(user);
    } on DioException catch (e) {
      throw ScreenScraperApiException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/screenscraper_api.dart';

final Provider<ScreenScraperCacheService> screenScraperCacheServiceProvider =
    Provider<ScreenScraperCacheService>(
        (Ref ref) => ScreenScraperCacheService());

class ScreenScraperCacheService {
  static const Duration _ttl = Duration(days: 30);
  static const String _folder = 'ss_cache';

  Future<File> _fileFor(String key) async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, _folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, '$key.json'));
  }

  /// Returns cached game if file is present and not older than TTL.
  Future<SsGame?> read(String key) async {
    try {
      final File f = await _fileFor(key);
      if (!await f.exists()) return null;
      final FileStat stat = await f.stat();
      if (DateTime.now().difference(stat.modified) > _ttl) {
        return null;
      }
      final String raw = await f.readAsString();
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      // negative marker: game not found in SS, don't refetch for TTL
      if (data['_notFound'] == true) {
        return null;
      }
      return SsGame.fromJson(data);
    } on Object {
      return null;
    }
  }

  /// Returns `true` if a "not found" marker exists and is still valid.
  Future<bool> isNegativelyCached(String key) async {
    try {
      final File f = await _fileFor(key);
      if (!await f.exists()) return false;
      final FileStat stat = await f.stat();
      if (DateTime.now().difference(stat.modified) > _ttl) return false;
      final String raw = await f.readAsString();
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      return data['_notFound'] == true;
    } on Object {
      return false;
    }
  }

  Future<void> writeGame(String key, SsGame game) async {
    final File f = await _fileFor(key);
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': game.id,
      'noms': <Map<String, String>>[
        <String, String>{'region': 'wor', 'text': game.name},
      ],
      'medias': game.medias
          .map((SsMedia m) => <String, String?>{
                'type': m.type,
                'url': m.url,
                'format': m.format,
                'region': m.region,
              })
          .toList(growable: false),
    };
    await f.writeAsString(jsonEncode(payload));
  }

  Future<void> writeNotFound(String key) async {
    final File f = await _fileFor(key);
    await f.writeAsString(jsonEncode(<String, bool>{'_notFound': true}));
  }

  static String cacheKey({required String gameName, required int systemeId}) {
    final String normalized = gameName.toLowerCase().replaceAll(
          RegExp('[^a-z0-9]+'),
          '_',
        );
    return '${systemeId}_$normalized';
  }
}

// Фильтр по платформе IGDB.

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/platform.dart' as app_platform;
import '../models/search_source.dart';

/// Фильтр по игровой платформе IGDB.
///
/// Загружает список платформ из БД-кэша.
class IgdbPlatformFilter extends SearchFilter {
  @override
  String get key => 'platform';

  @override
  String placeholder(S l) => l.browseFilterPlatform;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'All',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<app_platform.Platform> platforms =
        await db.getAllPlatforms();
    // Сортируем по имени для удобства
    platforms.sort(
      (app_platform.Platform a, app_platform.Platform b) =>
          a.name.compareTo(b.name),
    );
    return platforms
        .map(
          (app_platform.Platform p) => FilterOption(
            id: p.id.toString(),
            label: p.name,
            value: p.id,
          ),
        )
        .toList();
  }
}

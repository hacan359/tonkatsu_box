// Общие UI-утилиты для search-фильтров: sentinel сброса и accent по группе.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Sentinel-значение для пункта «All» в выпадающих меню фильтров.
///
/// PopupMenuButton трактует null как закрытие меню (не вызывает onSelected),
/// поэтому для явного сброса фильтра передаётся этот sentinel,
/// который вызывающая сторона интерпретирует как null.
const String kFilterResetSentinel = '__filter_reset__';

/// Accent цвет для группы источника поиска.
///
/// Используется в chevron-баре, bottom-sheet и searchable-диалоге.
Color filterAccentForGroup(String groupId) {
  return switch (groupId) {
    'tmdb' => AppColors.movieAccent,
    'igdb' => AppColors.gameAccent,
    'anilist' => AppColors.animeAccent,
    'vndb' => AppColors.visualNovelAccent,
    _ => AppColors.brand,
  };
}

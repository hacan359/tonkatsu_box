// Лёгкий провайдер для признака "rich collections".
//
// Отдельный Provider нужен, чтобы виджеты (CollectionCard и др.) могли читать
// настройку без обязательного инстанцирования всего `SettingsNotifier` —
// в unit-тестах этот Notifier требует целую пачку overrides.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';

/// Включён ли rich-вид коллекций (обложка + описание).
///
/// В unit-тестах, где `settingsNotifierProvider` не инициализирован,
/// значение безопасно фолбэчится в `false` — виджеты отображают обычную
/// мозаику.
final Provider<bool> richCollectionsEnabledProvider = Provider<bool>(
  (Ref ref) {
    try {
      return ref.watch(
        settingsNotifierProvider.select(
          (SettingsState s) => s.richCollectionsEnabled,
        ),
      );
    } on Object {
      return false;
    }
  },
);

// Прогресс игры из RetroAchievements.

import 'item_status.dart';

/// Прогресс игры пользователя из RetroAchievements.
///
/// Содержит данные о достижениях, платформе и наивысшей награде.
class RaGameProgress {
  /// Создаёт [RaGameProgress].
  const RaGameProgress({
    required this.gameId,
    required this.title,
    required this.consoleName,
    required this.consoleId,
    required this.numAwarded,
    required this.maxPossible,
    required this.hardcoreMode,
    this.highestAwardKind,
    this.lastPlayedAt,
  });

  /// Создаёт [RaGameProgress] из JSON ответа API_GetUserCompletionProgress.
  factory RaGameProgress.fromJson(Map<String, dynamic> json) {
    return RaGameProgress(
      gameId: json['GameID'] as int? ?? 0,
      title: json['Title'] as String? ?? '',
      consoleName: json['ConsoleName'] as String? ?? '',
      consoleId: json['ConsoleID'] as int? ?? 0,
      numAwarded: json['NumAwardedHardcore'] as int? ??
          json['NumAwarded'] as int? ??
          0,
      maxPossible: json['MaxPossible'] as int? ?? 0,
      hardcoreMode: (json['NumAwardedHardcore'] as int? ?? 0) > 0,
      highestAwardKind: json['HighestAwardKind'] as String?,
      lastPlayedAt: json['MostRecentAwardedDate'] != null
          ? DateTime.tryParse(json['MostRecentAwardedDate'] as String)
          : null,
    );
  }

  /// ID игры на RetroAchievements.
  final int gameId;

  /// Название игры.
  final String title;

  /// Название консоли (напр. "SNES", "Genesis").
  final String consoleName;

  /// ID консоли на RetroAchievements.
  final int consoleId;

  /// Количество полученных ачивок.
  final int numAwarded;

  /// Максимальное количество ачивок.
  final int maxPossible;

  /// Режим Hardcore.
  final bool hardcoreMode;

  /// Наивысшая награда: mastered, completed, beaten, или null.
  final String? highestAwardKind;

  /// Дата последней активности (получение ачивки).
  final DateTime? lastPlayedAt;

  /// Процент прохождения (0.0–1.0).
  double get completionRate =>
      maxPossible > 0 ? numAwarded / maxPossible : 0.0;

  /// Маппинг RA award → [ItemStatus].
  ///
  /// mastered*/completed*/beaten* → completed,
  /// >0 ачивок → inProgress,
  /// 0 ачивок → planned.
  ItemStatus get itemStatus {
    final String? award = highestAwardKind;
    if (award != null) {
      // Значения: "beaten-hardcore", "beaten-softcore", "mastered-hardcore",
      // "completed-hardcore" и т.д.
      if (award.startsWith('mastered') ||
          award.startsWith('completed') ||
          award.startsWith('beaten')) {
        return ItemStatus.completed;
      }
    }
    if (numAwarded > 0) return ItemStatus.inProgress;
    return ItemStatus.planned;
  }
}

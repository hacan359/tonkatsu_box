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
    required this.numAwardedHardcore,
    required this.maxPossible,
    required this.hardcoreMode,
    this.highestAwardKind,
    this.highestAwardDate,
    this.lastPlayedAt,
  });

  /// Создаёт [RaGameProgress] из JSON ответа API_GetUserCompletionProgress.
  factory RaGameProgress.fromJson(Map<String, dynamic> json) {
    return RaGameProgress(
      gameId: json['GameID'] as int? ?? 0,
      title: json['Title'] as String? ?? '',
      consoleName: json['ConsoleName'] as String? ?? '',
      consoleId: json['ConsoleID'] as int? ?? 0,
      numAwarded: json['NumAwarded'] as int? ?? 0,
      numAwardedHardcore: json['NumAwardedHardcore'] as int? ?? 0,
      maxPossible: json['MaxPossible'] as int? ?? 0,
      hardcoreMode: (json['NumAwardedHardcore'] as int? ?? 0) > 0,
      highestAwardKind: json['HighestAwardKind'] as String?,
      highestAwardDate: json['HighestAwardDate'] != null
          ? DateTime.tryParse(json['HighestAwardDate'] as String)
          : null,
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

  /// Количество полученных ачивок (softcore + hardcore).
  final int numAwarded;

  /// Количество hardcore ачивок.
  final int numAwardedHardcore;

  /// Максимальное количество ачивок.
  final int maxPossible;

  /// Режим Hardcore.
  final bool hardcoreMode;

  /// Наивысшая награда: mastered, completed, beaten, или null.
  final String? highestAwardKind;

  /// Дата получения наивысшей награды (beaten/mastered).
  final DateTime? highestAwardDate;

  /// Дата последней активности (получение ачивки).
  final DateTime? lastPlayedAt;

  /// Не-игровые ConsoleID (Hubs, Events, Standalone).
  static const Set<int> _nonGameConsoleIds = <int>{100, 101, 102};

  /// Это реальная игра (не ивент, хаб или standalone).
  bool get isRealGame => !_nonGameConsoleIds.contains(consoleId);

  /// Процент прохождения (0.0–1.0).
  double get completionRate =>
      maxPossible > 0 ? numAwarded / maxPossible : 0.0;

  /// Маппинг RA award → [ItemStatus].
  ///
  /// mastered*/completed*/beaten* → completed,
  /// >0 ачивок → inProgress,
  /// 0 ачивок → planned.
  ItemStatus? get itemStatus => statusFromAward(
        awardKind: highestAwardKind,
        numAwarded: numAwarded,
        lastPlayedAt: lastPlayedAt,
      );

  /// Маппинг RA данных → [ItemStatus] или null (не менять).
  ///
  /// mastered*/completed*/beaten* → completed,
  /// >0 ачивок + последняя активность >3 месяцев назад → dropped,
  /// >0 ачивок → inProgress,
  /// 0 ачивок → null (не трогаем — RA ничего не знает).
  static ItemStatus? statusFromAward({
    required String? awardKind,
    required int numAwarded,
    DateTime? lastPlayedAt,
  }) {
    if (awardKind != null) {
      if (awardKind.startsWith('mastered') ||
          awardKind.startsWith('completed') ||
          awardKind.startsWith('beaten')) {
        return ItemStatus.completed;
      }
    }
    if (numAwarded > 0) {
      if (lastPlayedAt != null) {
        final Duration inactivity = DateTime.now().difference(lastPlayedAt);
        if (inactivity.inDays > 90) return ItemStatus.dropped;
      }
      return ItemStatus.inProgress;
    }
    // 0 achievements — не трогаем статус (нет данных от RA).
    return null;
  }
}

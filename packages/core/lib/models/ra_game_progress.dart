
import 'item_status.dart';

class RaGameProgress {
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

  final int gameId;

  final String title;

  /// RA console name, e.g. `SNES`, `Genesis`.
  final String consoleName;

  final int consoleId;

  /// Softcore and hardcore combined.
  final int numAwarded;

  final int numAwardedHardcore;

  final int maxPossible;

  final bool hardcoreMode;

  /// `mastered`, `completed`, `beaten`, or null.
  final String? highestAwardKind;

  final DateTime? highestAwardDate;

  final DateTime? lastPlayedAt;

  /// Hubs, Events and Standalone entries — not real games.
  static const Set<int> _nonGameConsoleIds = <int>{100, 101, 102};

  bool get isRealGame => !_nonGameConsoleIds.contains(consoleId);

  /// Fraction in 0.0–1.0, not a percentage.
  double get completionRate =>
      maxPossible > 0 ? numAwarded / maxPossible : 0.0;

  /// Any award means completed; otherwise earned achievements decide between
  /// inProgress and planned.
  ItemStatus? get itemStatus => statusFromAward(
        awardKind: highestAwardKind,
        numAwarded: numAwarded,
        lastPlayedAt: lastPlayedAt,
      );

  /// Like [itemStatus] but also drops an item idle for over three months, and
  /// returns `null` on zero achievements — RA knows nothing then.
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
    // Zero achievements: RA has no signal, so the status stays put.
    return null;
  }
}

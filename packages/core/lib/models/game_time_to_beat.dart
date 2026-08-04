/// IGDB `game_time_to_beats`. Transient: fetched with search and carried
/// alongside [Game] in memory, never stored. IGDB reports seconds.
class GameTimeToBeat {
  const GameTimeToBeat({
    this.hastily,
    this.normally,
    this.completely,
    this.count = 0,
  });

  factory GameTimeToBeat.fromJson(Map<String, dynamic> json) {
    return GameTimeToBeat(
      hastily: json['hastily'] as int?,
      normally: json['normally'] as int?,
      completely: json['completely'] as int?,
      count: (json['count'] as int?) ?? 0,
    );
  }

  /// Rushed (≈ Main Story), seconds.
  final int? hastily;

  /// Normal (≈ Main + Extra), seconds.
  final int? normally;

  /// Completionist (100%), seconds.
  final int? completely;

  final int count;

  /// Most representative: normal, then rushed, then completionist.
  int? get primarySeconds => normally ?? hastily ?? completely;

  /// Whole hours, floored to 1h while non-zero; `null` when IGDB has no data.
  int? get primaryHours {
    final int? seconds = primarySeconds;
    if (seconds == null || seconds <= 0) return null;
    final int hours = (seconds / 3600).round();
    return hours < 1 ? 1 : hours;
  }
}

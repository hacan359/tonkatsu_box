/// Среднее время прохождения игры из IGDB (`game_time_to_beats`).
///
/// Транзиентная сущность: подтягивается при поиске и едет вместе с [Game] в
/// памяти, в базе не хранится. Значения IGDB отдаёт в секундах.
class GameTimeToBeat {
  const GameTimeToBeat({
    this.hastily,
    this.normally,
    this.completely,
    this.count = 0,
  });

  /// Создаёт [GameTimeToBeat] из записи `game_time_to_beats` IGDB API.
  factory GameTimeToBeat.fromJson(Map<String, dynamic> json) {
    return GameTimeToBeat(
      hastily: json['hastily'] as int?,
      normally: json['normally'] as int?,
      completely: json['completely'] as int?,
      count: (json['count'] as int?) ?? 0,
    );
  }

  /// «По-быстрому» (≈ Main Story), секунды.
  final int? hastily;

  /// «Нормально» (≈ Main + Extra), секунды.
  final int? normally;

  /// «На 100%» (≈ Completionist), секунды.
  final int? completely;

  /// Число пользовательских замеров — надёжность данных.
  final int count;

  /// Наиболее репрезентативное значение в секундах: нормальное прохождение, с
  /// откатом к быстрому, затем к полному.
  int? get primarySeconds => normally ?? hastily ?? completely;

  /// Основное значение в часах, округлённое (минимум 1ч, если время > 0).
  /// Возвращает `null`, когда у игры нет данных о времени прохождения.
  int? get primaryHours {
    final int? seconds = primarySeconds;
    if (seconds == null || seconds <= 0) return null;
    final int hours = (seconds / 3600).round();
    return hours < 1 ? 1 : hours;
  }
}

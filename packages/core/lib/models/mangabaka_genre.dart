// MangaBaka genre from the static `mangabaka_genres` lookup table.

/// One MangaBaka genre. [key] is the API filter value (`genre=`), [name] the
/// display label. The genre list is a fixed enum seeded into the DB.
class MangaBakaGenre {
  const MangaBakaGenre({
    required this.key,
    required this.name,
    this.isAdult = false,
  });

  factory MangaBakaGenre.fromDb(Map<String, dynamic> row) => MangaBakaGenre(
        key: row['key'] as String,
        name: row['name'] as String,
        isAdult: (row['is_adult'] as int? ?? 0) == 1,
      );

  final String key;
  final String name;
  final bool isAdult;
}

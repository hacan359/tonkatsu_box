/// [key] is the stored id; [needsFile] marks sources that read an export
/// file, so a rerun has to ask for one instead of running straight away.
enum ImportSourceKind {
  steam('steam', needsFile: false),
  retroAchievements('ra', needsFile: false),
  simkl('simkl', needsFile: false),
  aniList('anilist', needsFile: false),
  hardcover('hardcover', needsFile: false),
  kinorium('kinorium', needsFile: true),
  igdbList('igdb_list', needsFile: true),
  trakt('trakt', needsFile: true),
  mal('mal', needsFile: true),
  customCards('custom_cards', needsFile: true);

  const ImportSourceKind(this.key, {required this.needsFile});

  final String key;
  final bool needsFile;

  static ImportSourceKind? tryFromKey(String? key) {
    for (final ImportSourceKind kind in values) {
      if (kind.key == key) return kind;
    }
    return null;
  }
}

// Shared by the app (per-profile directory) and the selfhost server (volume),
// so the two never drift on which file they open.
const String kDatabaseFileName = 'tonkatsu_box.db';

/// Names for the secrets the server injects into proxied requests — env var
/// suffix, `keys.json` field and `/proxy/keys` flag all spell them this way.
abstract final class CredentialNames {
  static const String tmdb = 'tmdb';
  static const String tvdb = 'tvdb';
  static const String steamGridDb = 'steamgriddb';
  static const String igdbClientId = 'igdb_client_id';
  static const String igdbClientSecret = 'igdb_client_secret';
  static const String raUsername = 'ra_username';
  static const String ra = 'ra';
  static const String comicVine = 'comicvine';
  static const String googleBooks = 'googlebooks';
  static const String hardcover = 'hardcover';
  static const String simklClientId = 'simkl_client_id';

  static const List<String> all = <String>[
    tmdb,
    tvdb,
    steamGridDb,
    igdbClientId,
    igdbClientSecret,
    raUsername,
    ra,
    comicVine,
    googleBooks,
    hardcover,
    simklClientId,
  ];
}

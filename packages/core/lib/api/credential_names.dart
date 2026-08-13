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
  static const String podcastIndexKey = 'podcastindex_key';
  static const String podcastIndexSecret = 'podcastindex_secret';

  // ScreenScraper needs four: the dev pair comes from the operator's env or
  // keys.json, the user pair from the settings screen.
  static const String ssDevId = 'ss_dev_id';
  static const String ssDevPassword = 'ss_dev_password';
  static const String ssSsid = 'ss_ssid';
  static const String ssSspassword = 'ss_sspassword';

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
    podcastIndexKey,
    podcastIndexSecret,
    ssDevId,
    ssDevPassword,
    ssSsid,
    ssSspassword,
  ];
}

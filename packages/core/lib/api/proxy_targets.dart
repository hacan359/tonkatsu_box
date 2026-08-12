/// Allowlist of upstreams, shared so the browser's rewrite and the server's
/// refusal cannot drift. One host per constant; API hosts only.
enum ProxyTarget {
  anilist('graphql.anilist.co'),
  comicvine('comicvine.gamespot.com'),
  fantlab('api.fantlab.ru'),
  googlebooks('www.googleapis.com'),
  hardcover('api.hardcover.app'),
  igdb('api.igdb.com'),
  kitsu('kitsu.io'),
  listenbrainz('api.listenbrainz.org'),
  mangabaka('api.mangabaka.org'),
  mangadex('api.mangadex.org'),
  musicbrainz('musicbrainz.org'),
  openlibrary('openlibrary.org'),
  ra('retroachievements.org'),
  screenscraper('api.screenscraper.fr'),
  simkl('api.simkl.com'),
  steam('api.steampowered.com'),
  steamgriddb('www.steamgriddb.com'),
  tmdb('api.themoviedb.org'),
  tvdb('api4.thetvdb.com'),
  tvmaze('api.tvmaze.com'),
  vndb('api.vndb.org');

  const ProxyTarget(this.host);

  final String host;

  /// The path segment. Reusing [name] keeps the two from ever disagreeing.
  String get slug => name;
}

/// Where `/proxy` lives, so both ends spell the prefix once.
const String kProxyPathPrefix = '/proxy';

final Map<String, ProxyTarget> _byHost = <String, ProxyTarget>{
  for (final ProxyTarget t in ProxyTarget.values) t.host: t,
};

final Map<String, ProxyTarget> _bySlug = <String, ProxyTarget>{
  for (final ProxyTarget t in ProxyTarget.values) t.slug: t,
};

/// Null for anything off the allowlist — a Kodi box on the user's own LAN, say,
/// which the browser has no business reaching through our server.
ProxyTarget? proxyTargetForHost(String host) => _byHost[host.toLowerCase()];

ProxyTarget? proxyTargetForSlug(String slug) => _bySlug[slug];

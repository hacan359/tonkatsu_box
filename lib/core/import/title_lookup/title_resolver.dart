import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/title_match.dart';
import 'package:logging/logging.dart';

import '../rate_limited_retry.dart';
import 'lookup_candidate.dart';
import 'lookup_chains.dart';

sealed class ResolveOutcome {
  const ResolveOutcome();
}

class ResolvedMatch extends ResolveOutcome {
  const ResolvedMatch(this.candidate, {required this.platformId});

  final LookupCandidate candidate;

  /// The item's `platform_id`: proven for games, `AnimationSource.*` for
  /// animation, null otherwise.
  final int? platformId;
}

class ResolvedAmbiguous extends ResolveOutcome {
  const ResolvedAmbiguous(this.source, this.count);

  final DataSource source;
  final int count;
}

class ResolvedNotFound extends ResolveOutcome {
  const ResolvedNotFound();
}

/// Walks the type's chain until a source answers: a unique hit wins, an
/// ambiguous one stops the walk - a later source only adds candidates.
class TitleResolver {
  TitleResolver(
    this._chains, {
    RateLimitedRetry retry = const RateLimitedRetry(),
  }) : _retry = retry;

  static final Logger _log = Logger('TitleResolver');

  final LookupChains _chains;
  final RateLimitedRetry _retry;

  Future<ResolveOutcome> resolve(
    MediaType type,
    TitleQuery query, {
    bool platformUnknown = false,
    void Function(DataSource source)? onSource,
    void Function(Duration wait, int attempt)? onRateLimit,
  }) async {
    // A platform the catalog does not know cannot be checked against IGDB.
    if (type == MediaType.game && platformUnknown) {
      return const ResolvedNotFound();
    }
    for (final LookupSource source in _chains.chainFor(type, query.title)) {
      onSource?.call(source.source);
      final List<LookupCandidate> results;
      try {
        results = await _retry.run<List<LookupCandidate>>(
          () => source.search(query),
          isRateLimit: source.isRateLimit,
          onRetry: onRateLimit,
        );
      } on Object catch (e, stack) {
        _log.warning(
          'Lookup failed: ${source.source.name} "${query.title}"',
          e,
          stack,
        );
        continue;
      }
      final TitleMatch<LookupCandidate> match =
          classifyTitleMatches<LookupCandidate>(
        queryTitles: query.titles,
        results: results,
        titlesOf: (LookupCandidate c) => c.titles,
        year: query.year,
        yearOf: (LookupCandidate c) => c.year,
      );
      switch (match.kind) {
        case TitleMatchKind.none:
          continue;
        case TitleMatchKind.ambiguous:
          return ResolvedAmbiguous(source.source, match.count);
        case TitleMatchKind.unique:
          final LookupCandidate? hit = match.match;
          if (hit == null) continue;
          return type == MediaType.game
              ? _withGamePlatform(hit, query.platformId, source.source)
              : ResolvedMatch(hit, platformId: hit.platformId);
      }
    }
    return const ResolvedNotFound();
  }

  /// A search add asks the user for the platform; an import cannot, so it
  /// only takes one it can prove from the file or from a single-platform game.
  ResolveOutcome _withGamePlatform(
    LookupCandidate hit,
    int? wanted,
    DataSource source,
  ) {
    if (wanted != null) {
      return hit.platformIds.contains(wanted)
          ? ResolvedMatch(hit, platformId: wanted)
          : const ResolvedNotFound();
    }
    if (hit.platformIds.isEmpty) return ResolvedMatch(hit, platformId: null);
    if (hit.platformIds.length == 1) {
      return ResolvedMatch(hit, platformId: hit.platformIds.first);
    }
    return ResolvedAmbiguous(source, 1);
  }
}

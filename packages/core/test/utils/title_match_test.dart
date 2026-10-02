import 'package:core/utils/title_match.dart';
import 'package:test/test.dart';

class _R {
  const _R(this.titles, [this.year]);

  final List<String?> titles;
  final int? year;
}

TitleMatch<_R> _classify(
  List<String> query,
  List<_R> results, {
  int? year,
}) =>
    classifyTitleMatches<_R>(
      queryTitles: query,
      results: results,
      titlesOf: (_R r) => r.titles,
      year: year,
      yearOf: (_R r) => r.year,
    );

void main() {
  group('normalizeTitle', () {
    test('ignores case, punctuation and spacing', () {
      expect(
        normalizeTitle('Dune: Part Two'),
        normalizeTitle('dune part-two'),
      );
    });

    test('treats & as and', () {
      expect(
        normalizeTitle('Ratchet & Clank'),
        normalizeTitle('Ratchet and Clank'),
      );
    });

    test('keeps non-latin letters', () {
      expect(normalizeTitle('Дюна'), 'дюна');
      expect(normalizeTitle('Дюна'), isNot(normalizeTitle('Солярис')));
      expect(normalizeTitle('進撃の巨人'), isNotEmpty);
    });

    test('folds ё into е', () {
      expect(
        normalizeTitle('Ёжик в тумане'),
        normalizeTitle('Ежик в тумане'),
      );
    });

    test('blank input stays blank', () {
      expect(normalizeTitle('  !!  '), isEmpty);
    });
  });

  group('classifyTitleMatches', () {
    test('none on empty results', () {
      expect(_classify(<String>['Dune'], <_R>[]).kind, TitleMatchKind.none);
    });

    test('unique on one exact title among fuzzy hits', () {
      final TitleMatch<_R> m = _classify(<String>['Dune: Part Two'], <_R>[
        const _R(<String?>['Dune'], 2021),
        const _R(<String?>['Dune: Part Two'], 2024),
      ]);
      expect(m.kind, TitleMatchKind.unique);
      expect(m.match?.year, 2024);
      expect(m.count, 1);
    });

    test('ambiguous on two exact titles without a year', () {
      final TitleMatch<_R> m = _classify(<String>['Dune'], <_R>[
        const _R(<String?>['Dune'], 1984),
        const _R(<String?>['Dune'], 2021),
      ]);
      expect(m.kind, TitleMatchKind.ambiguous);
      expect(m.count, 2);
      expect(m.match, isNull);
    });

    test('year narrows ambiguity to unique', () {
      final TitleMatch<_R> m = _classify(
        <String>['Dune'],
        <_R>[
          const _R(<String?>['Dune'], 1984),
          const _R(<String?>['Dune'], 2021),
        ],
        year: 2021,
      );
      expect(m.kind, TitleMatchKind.unique);
      expect(m.match?.year, 2021);
    });

    test('year drops results with an unknown year', () {
      final TitleMatch<_R> m = _classify(
        <String>['Dune'],
        <_R>[const _R(<String?>['Dune'])],
        year: 2021,
      );
      expect(m.kind, TitleMatchKind.none);
    });

    test('matches an alternative title of the result', () {
      final TitleMatch<_R> m = _classify(<String>['Shingeki no Kyojin'], <_R>[
        const _R(<String?>['Attack on Titan', null, 'Shingeki no Kyojin']),
      ]);
      expect(m.kind, TitleMatchKind.unique);
    });

    test('matches by the alt title of the query', () {
      final TitleMatch<_R> m = _classify(
        <String>['Дюна', 'Dune'],
        <_R>[const _R(<String?>['Dune'], 2021)],
      );
      expect(m.kind, TitleMatchKind.unique);
    });

    test('prefix is not a match', () {
      final TitleMatch<_R> m = _classify(
        <String>['Dune'],
        <_R>[const _R(<String?>['Dune: Part Two'])],
      );
      expect(m.kind, TitleMatchKind.none);
    });

    test('blank query titles never match', () {
      final TitleMatch<_R> m = _classify(
        <String>['', '  '],
        <_R>[const _R(<String?>[''])],
      );
      expect(m.kind, TitleMatchKind.none);
    });
  });
}

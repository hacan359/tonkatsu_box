import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/sources/kinorium/kinorium_csv_parser.dart';
import 'package:tonkatsu_box/core/import/sources/kinorium/kinorium_entry.dart';

/// Builds one tab-separated, quoted row like Kinorium exports.
String _row(List<String> cells) =>
    cells.map((String c) => '"$c"').join('\t');

const List<String> _header = <String>[
  'ListTitle',
  'My rating',
  'Date',
  'Title',
  'Original Title',
  'Type',
  'Year',
  'Genres',
  'Actors',
  'Directors',
  'Note',
];

String _csv(List<List<String>> rows) =>
    <String>[_row(_header), ...rows.map(_row)].join('\n');

/// Encodes [text] as UTF-16 LE with a BOM, matching Kinorium's encoding.
Uint8List _utf16le(String text) {
  final List<int> bytes = <int>[0xFF, 0xFE];
  for (final int unit in text.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }
  return Uint8List.fromList(bytes);
}

void main() {
  const KinoriumCsvParser parser = KinoriumCsvParser();

  group('KinoriumCsvParser', () {
    group('parseString', () {
      test('parses a watched row into all fields', () {
        final String csv = _csv(<List<String>>[
          <String>[
            '', // ListTitle
            '8', // My rating
            '2023-06-15 21:30:00', // Date
            'Бегущий по лезвию', // Title
            'Blade Runner', // Original Title
            'Фильм', // Type
            '1982', // Year
            'фантастика, нуар', // Genres
            'Харрисон Форд', // Actors
            'Ридли Скотт', // Directors
            '', // Note
          ],
        ]);

        final List<KinoriumEntry> entries = parser.parseString(csv);

        expect(entries, hasLength(1));
        final KinoriumEntry e = entries.first;
        expect(e.title, 'Бегущий по лезвию');
        expect(e.originalTitle, 'Blade Runner');
        expect(e.searchQuery, 'Blade Runner');
        expect(e.type, KinoriumType.film);
        expect(e.year, 1982);
        expect(e.myRating, 8.0);
        expect(e.date, DateTime(2023, 6, 15, 21, 30));
        expect(e.genres, <String>['фантастика', 'нуар']);
        expect(e.actors, 'Харрисон Форд');
        expect(e.directors, 'Ридли Скотт');
        expect(e.note, isNull);
      });

      test('addresses columns by header name across export layouts', () {
        // The watched export (backup_..._votes.csv) starts with "My rating"
        // and has no "ListTitle"; the watchlist export (back.csv) starts with
        // "ListTitle". By-name addressing must parse both regardless of order.
        // This row uses the real watched-file column order.
        const String csv = '"My rating"\t"backup_id"\t"Date"\t"Title"\t'
            '"Original Title"\t"Type"\t"Year"\n'
            '"6"\t"171649219797559413"\t"2026-05-17 01:49:42"\t'
            '"Я иду искать 2"\t"Ready or Not: Here I Come"\t"Фильм"\t"2025"';

        final KinoriumEntry e = parser.parseString(csv).first;
        expect(e.title, 'Я иду искать 2');
        expect(e.searchQuery, 'Ready or Not: Here I Come');
        expect(e.type, KinoriumType.film);
        expect(e.year, 2025);
        expect(e.myRating, 6.0);
        expect(e.date, DateTime(2026, 5, 17, 1, 49, 42));
      });

      test('falls back to Title when Original Title is empty', () {
        final String csv = _csv(<List<String>>[
          <String>[
            '', '', '', 'Ух ты, говорящая рыба!', '', 'Мультфильм', '1983',
            '', '', '', '',
          ],
        ]);

        final KinoriumEntry e = parser.parseString(csv).first;
        expect(e.originalTitle, isNull);
        expect(e.searchQuery, 'Ух ты, говорящая рыба!');
        expect(e.type, KinoriumType.animatedFilm);
        expect(e.type.isAnimationHint, isTrue);
      });

      test('accepts comma decimal ratings and rejects out-of-range', () {
        final String csv = _csv(<List<String>>[
          <String>['', '6,8', '', 'A', '', 'Фильм', '0', '', '', '', ''],
          <String>['', '0', '', 'B', '', 'Фильм', '', '', '', '', ''],
          <String>['', '99', '', 'C', '', 'Фильм', '', '', '', '', ''],
        ]);

        final List<KinoriumEntry> entries = parser.parseString(csv);
        expect(entries[0].myRating, closeTo(6.8, 1e-9));
        expect(entries[0].year, isNull, reason: 'year 0 → null');
        expect(entries[1].myRating, isNull, reason: 'rating 0 → null');
        expect(entries[2].myRating, isNull, reason: 'rating 99 → null');
      });

      test('maps every known Type and falls back to unknown', () {
        final String csv = _csv(<List<String>>[
          <String>['', '', '', 'a', '', 'Фильм', '', '', '', '', ''],
          <String>['', '', '', 'b', '', 'Сериал', '', '', '', '', ''],
          <String>['', '', '', 'c', '', 'Мультсериал', '', '', '', '', ''],
          <String>['', '', '', 'd', '', 'Эпизод', '', '', '', '', ''],
          <String>['', '', '', 'e', '', 'Книга', '', '', '', '', ''],
        ]);

        final List<KinoriumEntry> e = parser.parseString(csv);
        expect(e[0].type, KinoriumType.film);
        expect(e[0].type.isMovieLike, isTrue);
        expect(e[1].type, KinoriumType.series);
        expect(e[1].type.isTvLike, isTrue);
        expect(e[2].type, KinoriumType.animatedSeries);
        expect(e[3].type, KinoriumType.episode);
        expect(e[4].type, KinoriumType.unknown);
      });

      test('preserves tabs and quotes inside quoted fields', () {
        const String csv = '"Title"\t"Type"\n'
            '"Tab\there"\t"Фильм"\n'
            '"Quote ""inside"""\t"Сериал"';

        final List<KinoriumEntry> entries = parser.parseString(csv);
        expect(entries[0].title, 'Tab\there');
        expect(entries[1].title, 'Quote "inside"');
      });

      test('skips rows without a title', () {
        final String csv = _csv(<List<String>>[
          <String>['', '', '', '', 'Orig', 'Фильм', '', '', '', '', ''],
          <String>['', '', '', 'Has title', '', 'Фильм', '', '', '', '', ''],
        ]);

        final List<KinoriumEntry> entries = parser.parseString(csv);
        expect(entries, hasLength(1));
        expect(entries.first.title, 'Has title');
      });

      test('throws when Title/Type columns are missing', () {
        expect(
          () => parser.parseString('"Foo"\t"Bar"\n"1"\t"2"'),
          throwsA(isA<KinoriumParseException>()),
        );
      });
    });

    group('parseBytes', () {
      test('decodes UTF-16 LE with BOM', () {
        final Uint8List bytes = _utf16le(_csv(<List<String>>[
          <String>['', '7', '', 'Матрица', 'The Matrix', 'Фильм', '1999',
              '', '', '', ''],
        ]));

        final KinoriumEntry e = parser.parseBytes(bytes).first;
        expect(e.title, 'Матрица');
        expect(e.searchQuery, 'The Matrix');
        expect(e.year, 1999);
        expect(e.myRating, 7.0);
      });
    });
  });
}

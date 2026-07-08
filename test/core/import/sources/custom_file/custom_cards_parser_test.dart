import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_card_entry.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_cards_parser.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  const CustomCardsParser sut = CustomCardsParser();

  bool hasIssue(CustomCardRow row, CustomCardIssueCode code, {String? field}) =>
      row.issues.any((CustomCardIssue issue) =>
          issue.code == code && (field == null || issue.field == field));

  group('CustomCardsParser', () {
    group('parseJson', () {
      test('parses an array of objects into valid entries', () {
        final List<CustomCardRow> rows = sut.parseJson('''
[
  {"title": "Chrono Trigger", "type": "game", "year": 1995,
   "genres": "RPG, Adventure", "link": "https://e.com/ct",
   "cover": "https://e.com/ct.jpg", "platform": "SNES",
   "status": "completed", "rating": 9.5, "comment": "Great",
   "rewatch_count": 2, "alt_title": "CT", "description": "JRPG"}
]
''');

        expect(rows, hasLength(1));
        final CustomCardEntry entry = rows.first.entry!;
        expect(entry.title, 'Chrono Trigger');
        expect(entry.type, MediaType.game);
        expect(entry.year, 1995);
        expect(entry.genres, 'RPG, Adventure');
        expect(entry.link, 'https://e.com/ct');
        expect(entry.coverUrl, 'https://e.com/ct.jpg');
        expect(entry.platform, 'SNES');
        expect(entry.status, ItemStatus.completed);
        expect(entry.rating, 9.5);
        expect(entry.comment, 'Great');
        expect(entry.rewatchCount, 2);
        expect(entry.altTitle, 'CT');
        expect(entry.description, 'JRPG');
      });

      test('accepts a single object as one card', () {
        final List<CustomCardRow> rows =
            sut.parseJson('{"title": "Solo", "type": "movie"}');

        expect(rows, hasLength(1));
        expect(rows.first.entry!.type, MediaType.movie);
      });

      test('throws invalidJson on broken JSON', () {
        expect(
          () => sut.parseJson('[{"title": '),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.invalidJson,
          )),
        );
      });

      test('throws invalidJson when the root is a scalar', () {
        expect(
          () => sut.parseJson('"just a string"'),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.invalidJson,
          )),
        );
      });

      test('throws emptyFile on an empty array', () {
        expect(
          () => sut.parseJson('[]'),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.emptyFile,
          )),
        );
      });

      test('flags a non-object array element', () {
        final List<CustomCardRow> rows =
            sut.parseJson('[{"title": "A", "type": "game"}, 42]');

        expect(rows, hasLength(2));
        expect(rows[0].isValid, isTrue);
        expect(rows[1].isValid, isFalse);
        expect(hasIssue(rows[1], CustomCardIssueCode.notAnObject), isTrue);
        expect(rows[1].index, 2);
      });

      test('ignores underscore-prefixed and unknown keys', () {
        final List<CustomCardRow> rows = sut.parseJson('''
[{"title": "A", "type": "game",
  "_type_values": "game, movie", "some_extra": "x"}]
''');

        expect(rows.single.isValid, isTrue);
      });

      test('accepts native JSON numbers and numeric strings', () {
        final List<CustomCardRow> rows = sut.parseJson('''
[{"title": "A", "type": "anime", "year": "2009",
  "unit_total": 64, "unit_group_total": "1", "rating": 10}]
''');

        final CustomCardEntry entry = rows.single.entry!;
        expect(entry.year, 2009);
        expect(entry.unitTotal, 64);
        expect(entry.unitGroupTotal, 1);
        expect(entry.rating, 10);
      });
    });

    group('validation', () {
      CustomCardRow one(Map<String, Object?> card) =>
          sut.parseJson(jsonEncode(<Object?>[card])).single;

      test('missing or blank title', () {
        expect(
          hasIssue(
            one(<String, Object?>{'type': 'game'}),
            CustomCardIssueCode.missingTitle,
          ),
          isTrue,
        );
        expect(
          hasIssue(
            one(<String, Object?>{'title': '  ', 'type': 'game'}),
            CustomCardIssueCode.missingTitle,
          ),
          isTrue,
        );
      });

      test('missing type', () {
        expect(
          hasIssue(
            one(<String, Object?>{'title': 'A'}),
            CustomCardIssueCode.missingType,
          ),
          isTrue,
        );
      });

      test('unknown type, including the reserved "custom"', () {
        expect(
          hasIssue(
            one(<String, Object?>{'title': 'A', 'type': 'podcast'}),
            CustomCardIssueCode.unknownType,
          ),
          isTrue,
        );
        expect(
          hasIssue(
            one(<String, Object?>{'title': 'A', 'type': 'custom'}),
            CustomCardIssueCode.unknownType,
          ),
          isTrue,
        );
      });

      test('type matching is case-insensitive', () {
        final CustomCardRow row =
            one(<String, Object?>{'title': 'A', 'type': 'Tv_Show'});
        expect(row.entry!.type, MediaType.tvShow);
      });

      test('all eight allowed types resolve', () {
        const Map<String, MediaType> expected = <String, MediaType>{
          'game': MediaType.game,
          'movie': MediaType.movie,
          'tv_show': MediaType.tvShow,
          'animation': MediaType.animation,
          'visual_novel': MediaType.visualNovel,
          'manga': MediaType.manga,
          'anime': MediaType.anime,
          'book': MediaType.book,
        };
        for (final MapEntry<String, MediaType> pair in expected.entries) {
          final CustomCardRow row =
              one(<String, Object?>{'title': 'A', 'type': pair.key});
          expect(row.entry!.type, pair.value, reason: pair.key);
        }
      });

      test('year out of range or non-numeric', () {
        for (final Object bad in <Object>[999, 10000, 'soon']) {
          expect(
            hasIssue(
              one(<String, Object?>{'title': 'A', 'type': 'game', 'year': bad}),
              CustomCardIssueCode.invalidNumber,
              field: 'year',
            ),
            isTrue,
            reason: '$bad',
          );
        }
      });

      test('unit totals must be positive integers', () {
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'anime',
              'unit_total': 0,
            }),
            CustomCardIssueCode.invalidNumber,
            field: 'unit_total',
          ),
          isTrue,
        );
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'anime',
              'unit_group_total': -1,
            }),
            CustomCardIssueCode.invalidNumber,
            field: 'unit_group_total',
          ),
          isTrue,
        );
      });

      test('rewatch_count allows zero but not negatives', () {
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'movie',
            'rewatch_count': 0,
          }).entry!.rewatchCount,
          0,
        );
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'movie',
              'rewatch_count': -1,
            }),
            CustomCardIssueCode.invalidNumber,
            field: 'rewatch_count',
          ),
          isTrue,
        );
      });

      test('rating bounds and decimal comma', () {
        expect(
          one(<String, Object?>{'title': 'A', 'type': 'game', 'rating': '7,5'})
              .entry!
              .rating,
          7.5,
        );
        for (final Object bad in <Object>[-1, 10.5, 'great']) {
          expect(
            hasIssue(
              one(<String, Object?>{
                'title': 'A',
                'type': 'game',
                'rating': bad,
              }),
              CustomCardIssueCode.invalidNumber,
              field: 'rating',
            ),
            isTrue,
            reason: '$bad',
          );
        }
      });

      test('status matching is case-insensitive; unknown flagged', () {
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'game',
            'status': 'REPLAYING',
          }).entry!.status,
          ItemStatus.replaying,
        );
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'game',
              'status': 'finished',
            }),
            CustomCardIssueCode.unknownStatus,
          ),
          isTrue,
        );
      });

      test('format normalizes case for manga and anime', () {
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'manga',
            'format': 'manhwa',
          }).entry!.format,
          'MANHWA',
        );
        expect(
          one(<String, Object?>{'title': 'A', 'type': 'anime', 'format': 'ova'})
              .entry!
              .format,
          'OVA',
        );
      });

      test('format from the other list is unknown for this type', () {
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'anime',
              'format': 'MANGA',
            }),
            CustomCardIssueCode.unknownFormat,
          ),
          isTrue,
        );
      });

      test('format on a non-manga/anime type is not applicable', () {
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'game',
              'format': 'TV',
            }),
            CustomCardIssueCode.formatNotApplicable,
          ),
          isTrue,
        );
      });

      test('cover must be an http(s) URL', () {
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'game',
            'cover': 'HTTPS://e.com/a.jpg',
          }).entry!.coverUrl,
          'HTTPS://e.com/a.jpg',
        );
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'game',
              'cover': 'file:///c/a.jpg',
            }),
            CustomCardIssueCode.invalidCoverUrl,
          ),
          isTrue,
        );
      });

      test('a row collects every issue it has', () {
        final CustomCardRow row = one(<String, Object?>{
          'year': 'abc',
          'rating': 99,
        });
        expect(row.isValid, isFalse);
        expect(hasIssue(row, CustomCardIssueCode.missingTitle), isTrue);
        expect(hasIssue(row, CustomCardIssueCode.missingType), isTrue);
        expect(hasIssue(row, CustomCardIssueCode.invalidNumber, field: 'year'),
            isTrue);
        expect(
            hasIssue(row, CustomCardIssueCode.invalidNumber, field: 'rating'),
            isTrue);
      });

      test('parses ISO dates and flags non-ISO ones', () {
        final CustomCardEntry ok = one(<String, Object?>{
          'title': 'A',
          'type': 'game',
          'started_at': '2024-01-05',
          'completed_at': '2024-02-10',
        }).entry!;
        expect(ok.startedAt, DateTime(2024, 1, 5));
        expect(ok.completedAt, DateTime(2024, 2, 10));

        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'game',
              'started_at': '31.12.2020',
            }),
            CustomCardIssueCode.invalidDate,
            field: 'started_at',
          ),
          isTrue,
        );
      });

      test('time_spent_minutes and progress positions allow zero, not negatives',
          () {
        final CustomCardEntry ok = one(<String, Object?>{
          'title': 'A',
          'type': 'anime',
          'time_spent_minutes': 0,
          'current_episode': 0,
          'current_season': 0,
        }).entry!;
        expect(ok.timeSpentMinutes, 0);
        expect(ok.currentEpisode, 0);
        expect(ok.currentSeason, 0);

        for (final String field in <String>[
          'time_spent_minutes',
          'current_episode',
          'current_season',
        ]) {
          expect(
            hasIssue(
              one(<String, Object?>{'title': 'A', 'type': 'anime', field: -1}),
              CustomCardIssueCode.invalidNumber,
              field: field,
            ),
            isTrue,
            reason: field,
          );
        }
      });

      test('favorite accepts booleans and common string spellings', () {
        expect(
          one(<String, Object?>{'title': 'A', 'type': 'game', 'favorite': true})
              .entry!
              .favorite,
          isTrue,
        );
        expect(
          one(<String, Object?>{'title': 'A', 'type': 'game', 'favorite': '0'})
              .entry!
              .favorite,
          isFalse,
        );
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'game',
            'favorite': 'YES',
          }).entry!.favorite,
          isTrue,
        );
        expect(
          hasIssue(
            one(<String, Object?>{
              'title': 'A',
              'type': 'game',
              'favorite': 'да',
            }),
            CustomCardIssueCode.invalidBool,
          ),
          isTrue,
        );
      });

      test('tags parse from a comma string or a JSON array, deduped', () {
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'game',
            'tags': ' jrpg, Classics ,JRPG,, ',
          }).entry!.tags,
          <String>['jrpg', 'Classics'],
        );
        expect(
          one(<String, Object?>{
            'title': 'A',
            'type': 'game',
            'tags': <Object?>['one', 'two', 'ONE'],
          }).entry!.tags,
          <String>['one', 'two'],
        );
        expect(
          one(<String, Object?>{'title': 'A', 'type': 'game'}).entry!.tags,
          isEmpty,
        );
      });

      test('keeps the raw title on invalid rows for preview labels', () {
        final CustomCardRow row =
            one(<String, Object?>{'title': 'Broken', 'type': 'nope'});
        expect(row.isValid, isFalse);
        expect(row.sourceTitle, 'Broken');
      });
    });

    group('parseCsv', () {
      test('parses rows addressed by header name', () {
        final List<CustomCardRow> rows = sut.parseCsv(
          'type,title,year\n'
          'game,"Mario, Lost Levels",1986\n'
          'book,Dune,1965\n',
        );

        expect(rows, hasLength(2));
        expect(rows[0].entry!.title, 'Mario, Lost Levels');
        expect(rows[0].entry!.year, 1986);
        expect(rows[1].entry!.type, MediaType.book);
      });

      test('handles CRLF, quoted quotes and short rows', () {
        final List<CustomCardRow> rows = sut.parseCsv(
          'title,type,description\r\n'
          '"He said ""hi""",game\r\n',
        );

        expect(rows.single.entry!.title, 'He said "hi"');
        expect(rows.single.entry!.description, isNull);
      });

      test('ignores unknown columns', () {
        final List<CustomCardRow> rows = sut.parseCsv(
          'title,type,shelf\nA,game,top\n',
        );

        expect(rows.single.isValid, isTrue);
      });

      test('empty field values collapse to null', () {
        final List<CustomCardRow> rows = sut.parseCsv(
          'title,type,year,status\nA,game,,\n',
        );

        final CustomCardEntry entry = rows.single.entry!;
        expect(entry.year, isNull);
        expect(entry.status, isNull);
      });

      test('throws when title or type column is missing', () {
        expect(
          () => sut.parseCsv('name,type\nA,game\n'),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.missingRequiredColumns,
          )),
        );
      });

      test('throws emptyFile when only the header is present', () {
        expect(
          () => sut.parseCsv('title,type\n'),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.emptyFile,
          )),
        );
      });

      test('row indexes are 1-based data rows', () {
        final List<CustomCardRow> rows = sut.parseCsv(
          'title,type\nA,game\nB,game\n',
        );
        expect(rows[0].index, 1);
        expect(rows[1].index, 2);
      });
    });

    group('parseBytes', () {
      Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

      test('throws emptyFile on a blank file', () {
        expect(
          () => sut.parseBytes(bytes('  \n')),
          throwsA(isA<CustomCardsParseException>().having(
            (CustomCardsParseException e) => e.code,
            'code',
            CustomCardsParseErrorCode.emptyFile,
          )),
        );
      });

      test('picks the parser from the file extension', () {
        final List<CustomCardRow> json = sut.parseBytes(
          bytes('[{"title": "A", "type": "game"}]'),
          fileName: 'cards.JSON',
        );
        final List<CustomCardRow> csv = sut.parseBytes(
          bytes('title,type\nA,game\n'),
          fileName: 'cards.csv',
        );
        expect(json.single.isValid, isTrue);
        expect(csv.single.isValid, isTrue);
      });

      test('sniffs JSON content without an extension hint', () {
        final List<CustomCardRow> rows = sut.parseBytes(
          bytes('  {"title": "A", "type": "game"}'),
          fileName: 'export.txt',
        );
        expect(rows.single.isValid, isTrue);
      });

      test('falls back to CSV for non-JSON content', () {
        final List<CustomCardRow> rows =
            sut.parseBytes(bytes('title,type\nA,game\n'));
        expect(rows.single.isValid, isTrue);
      });

      test('strips a UTF-8 BOM', () {
        final Uint8List withBom = Uint8List.fromList(<int>[
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('title,type\nA,game\n'),
        ]);
        final List<CustomCardRow> rows = sut.parseBytes(withBom);
        expect(rows.single.entry!.title, 'A');
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/fantlab/fantlab_editions.dart';

void main() {
  group('parseFantlabEditionBlocks', () {
    test('returns empty for a non-map payload', () {
      expect(parseFantlabEditionBlocks(null), isEmpty);
      expect(parseFantlabEditionBlocks(<dynamic>[]), isEmpty);
    });

    test('parses a block with its title and editions', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Издания',
          'list': <dynamic>[
            <String, dynamic>{
              'edition_id': 7337,
              'name': 'Солярис. Эдем',
              'year': 1973,
              'lang': 'русский',
              'lang_code': 'ru',
              'publisher': '[pub=162]Мир[/pub]',
              'pages': 504,
              'isbn': '978-5-699-12014-8',
              'pic_num': 1,
            },
          ],
        },
      });

      expect(blocks, hasLength(1));
      expect(blocks.first.title, 'Издания');
      expect(blocks.first.editions, hasLength(1));

      final FantlabEdition ed = blocks.first.editions.first;
      expect(ed.editionId, 7337);
      expect(ed.name, 'Солярис. Эдем');
      expect(ed.year, 1973);
      expect(ed.langCode, 'ru');
      expect(ed.langName, 'русский');
      expect(ed.publisher, 'Мир'); // BBCode stripped
      expect(ed.pages, 504);
      expect(ed.isbn, '9785699120148'); // dashes removed
      expect(ed.hasCover, isTrue);
    });

    test('marks an edition without a cover scan (pic_num == 0)', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Издания',
          'list': <dynamic>[
            <String, dynamic>{'edition_id': 1, 'pic_num': 0},
          ],
        },
      });

      expect(blocks.first.editions.first.hasCover, isFalse);
    });

    test('sorts editions with a cover first within a block', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Издания',
          'list': <dynamic>[
            <String, dynamic>{'edition_id': 1, 'pic_num': 0},
            <String, dynamic>{'edition_id': 2, 'pic_num': 3},
            <String, dynamic>{'edition_id': 3, 'pic_num': 0},
          ],
        },
      });

      final List<FantlabEdition> editions = blocks.first.editions;
      expect(editions.first.editionId, 2); // the only one with a cover
      expect(editions.first.hasCover, isTrue);
    });

    test('skips editions without a usable edition_id', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Издания',
          'list': <dynamic>[
            <String, dynamic>{'edition_id': 0},
            <String, dynamic>{'name': 'no id'},
            <String, dynamic>{'edition_id': 42},
          ],
        },
      });

      expect(blocks.first.editions, hasLength(1));
      expect(blocks.first.editions.first.editionId, 42);
    });

    test('drops a block whose editions are all invalid', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Empty',
          'list': <dynamic>[
            <String, dynamic>{'edition_id': 0},
          ],
        },
        '20': <String, dynamic>{
          'title': 'Good',
          'list': <dynamic>[
            <String, dynamic>{'edition_id': 5},
          ],
        },
      });

      expect(blocks, hasLength(1));
      expect(blocks.first.title, 'Good');
    });

    test('builds small / big cover URLs from the edition id', () {
      const FantlabEdition ed =
          FantlabEdition(editionId: 24724, name: 'x', hasCover: true);
      expect(ed.coverThumbUrl,
          'https://fantlab.ru/images/editions/small/24724');
      expect(ed.coverUrl, 'https://fantlab.ru/images/editions/big/24724');
    });

    test('coerces string-typed numbers (Perl backend)', () {
      final List<FantlabEditionBlock> blocks =
          parseFantlabEditionBlocks(<String, dynamic>{
        '10': <String, dynamic>{
          'title': 'Издания',
          'list': <dynamic>[
            <String, dynamic>{
              'edition_id': '99',
              'year': '1980',
              'pages': '320',
              'pic_num': '2',
            },
          ],
        },
      });

      final FantlabEdition ed = blocks.first.editions.first;
      expect(ed.editionId, 99);
      expect(ed.year, 1980);
      expect(ed.pages, 320);
      expect(ed.hasCover, isTrue);
    });
  });
}

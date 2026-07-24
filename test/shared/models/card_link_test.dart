import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/l10n/app_localizations_ru.dart';
import 'package:tonkatsu_box/shared/models/card_link.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/builders.dart';
import 'package:tonkatsu_box/shared/constants/collection_item_ui.dart';

void main() {
  group('CardLink', () {
    group('buildCardLinkToken', () {
      test('encodes game identity with platform and collection', () {
        final String token = buildCardLinkToken(createTestCollectionItem(
          mediaType: MediaType.game,
          externalId: 100,
          platformId: 5,
          collectionId: 1,
          overrideName: 'Chrono Trigger',
        ));

        expect(token, startsWith('[[card:'));
        expect(token, endsWith(']]'));
        expect(token, contains('mt=game'));
        expect(token, contains('id=100'));
        expect(token, contains('pf=5'));
        expect(token, contains('col=1'));
        expect(token, contains('Chrono Trigger'));
      });

      test('omits pf/col when absent', () {
        final String token = buildCardLinkToken(createTestCollectionItem(
          mediaType: MediaType.movie,
          externalId: 603,
          collectionId: null,
          overrideName: 'The Matrix',
        ));

        expect(token, contains('mt=movie'));
        expect(token, contains('id=603'));
        expect(token, isNot(contains('pf=')));
        expect(token, isNot(contains('col=')));
      });
    });

    group('parseCardLink', () {
      test('parses all fields', () {
        final CardLinkRef? ref =
            parseCardLink('mt=game;id=100;pf=5;col=1', 'Name');

        expect(ref, isNotNull);
        expect(ref!.mediaType, MediaType.game);
        expect(ref.externalId, 100);
        expect(ref.platformId, 5);
        expect(ref.collectionId, 1);
        expect(ref.display, 'Name');
      });

      test('parses manga source', () {
        final CardLinkRef? ref =
            parseCardLink('mt=manga;id=7;src=mangabaka', 'Berserk');

        expect(ref!.source, DataSource.mangabaka);
      });

      test('falls back to type label for empty display', () {
        final CardLinkRef? ref = parseCardLink('mt=movie;id=1', '');

        expect(ref!.display, MediaType.movie.displayLabel);
      });

      test('returns null for missing id, missing mt or bad id', () {
        expect(parseCardLink('mt=game', null), isNull);
        expect(parseCardLink('id=1', null), isNull);
        expect(parseCardLink('mt=game;id=abc', null), isNull);
      });

      test('returns null for unknown media type', () {
        expect(parseCardLink('mt=bogus;id=5', null), isNull);
        expect(parseCardLink('mt=;id=5', null), isNull);
      });
    });

    test('build then parse preserves identity', () {
      final CardLinkRef ref = extractCardLinks(buildCardLinkToken(
        createTestCollectionItem(
          mediaType: MediaType.tvShow,
          externalId: 42,
          collectionId: 3,
          overrideName: 'Firefly',
        ),
      )).single;

      expect(ref.mediaType, MediaType.tvShow);
      expect(ref.externalId, 42);
      expect(ref.collectionId, 3);
    });

    group('extractCardLinks', () {
      test('returns every valid token and skips invalid ones', () {
        const String text = 'see [[card:mt=game;id=1|A]] and '
            '[[card:mt=movie;id=2|B]] but not [[card:garbage]]';

        final List<CardLinkRef> refs = extractCardLinks(text);

        expect(refs, hasLength(2));
        expect(refs[0].externalId, 1);
        expect(refs[1].externalId, 2);
      });

      test('returns empty for plain text', () {
        expect(extractCardLinks('no links here'), isEmpty);
      });
    });

    test('sanitizeCardLinkDisplay strips grammar characters', () {
      expect(sanitizeCardLinkDisplay('a]b[c|d'), 'a b c d');
    });

    group('cardSubcategoryLabel', () {
      final S l = SRu();

      test('null for a game without a platform', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.game).cardSubcategoryLabel(l),
          isNull,
        );
      });

      test('movie/TV label for animation', () {
        expect(
          createTestCollectionItem(
              mediaType: MediaType.animation,
              platformId: AnimationSource.tvShow,
            ).cardSubcategoryLabel(l),
          l.mediaTypeTvShow,
        );
        expect(
          createTestCollectionItem(
              mediaType: MediaType.animation,
              platformId: AnimationSource.movie,
            ).cardSubcategoryLabel(l),
          l.mediaTypeMovie,
        );
      });

      test('null for other media types', () {
        expect(
          createTestCollectionItem(mediaType: MediaType.movie).cardSubcategoryLabel(l),
          isNull,
        );
      });
    });
  });
}

// Unit-тесты для TextExportService.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/text_export_service.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';

TextExportService _service() => TextExportService();

CollectionItem _gameItem({
  int id = 1,
  String name = 'Elden Ring',
  int? releaseYear = 2022,
  double? rating = 9.5,
  int? userRating = 10,
  ItemStatus status = ItemStatus.completed,
  String? genres = 'RPG, Action',
  String? userComment,
  int? platformId,
  Platform? platform,
}) {
  return CollectionItem(
    id: id,
    collectionId: 1,
    mediaType: MediaType.game,
    externalId: 100 + id,
    status: status,
    addedAt: DateTime(2024),
    userRating: userRating,
    userComment: userComment,
    platformId: platformId,
    platform: platform,
    game: Game(
      id: 100 + id,
      name: name,
      releaseDate: releaseYear != null
          ? DateTime(releaseYear)
          : null,
      rating: rating != null ? rating * 10 : null,
      genres: genres?.split(', '),
    ),
  );
}

CollectionItem _movieItem({
  int id = 10,
  String title = 'Inception',
  int? releaseYear = 2010,
  double? rating = 8.8,
  int? userRating,
}) {
  return CollectionItem(
    id: id,
    collectionId: 1,
    mediaType: MediaType.movie,
    externalId: 200 + id,
    status: ItemStatus.completed,
    addedAt: DateTime(2024),
    userRating: userRating,
    movie: Movie(
      tmdbId: 200 + id,
      title: title,
      releaseYear: releaseYear,
      rating: rating,
    ),
  );
}

void main() {
  group('TextExportService', () {
    group('formatItem', () {
      test('should replace {name} token', () {
        final String result = _service().formatItem(
          '{name}',
          _gameItem(name: 'Chrono Trigger'),
          1,
        );
        expect(result, equals('Chrono Trigger'));
      });

      test('should replace {year} token', () {
        final String result = _service().formatItem(
          '{name} ({year})',
          _gameItem(name: 'Elden Ring', releaseYear: 2022),
          1,
        );
        expect(result, equals('Elden Ring (2022)'));
      });

      test('should replace {rating} token with formatted value', () {
        final String result = _service().formatItem(
          '{name} — {rating}',
          _gameItem(name: 'Elden Ring', rating: 9.5),
          1,
        );
        expect(result, equals('Elden Ring — 9.5'));
      });

      test('should format whole number rating without decimal', () {
        final String result = _service().formatItem(
          '{rating}',
          _gameItem(rating: 9.0),
          1,
        );
        expect(result, equals('9'));
      });

      test('should replace {myRating} token', () {
        final String result = _service().formatItem(
          '{name} — {myRating}/10',
          _gameItem(name: 'BG3', userRating: 9),
          1,
        );
        expect(result, equals('BG3 — 9/10'));
      });

      test('should replace {platform} token', () {
        final String result = _service().formatItem(
          '{name} — {platform}',
          _gameItem(
            name: 'Zelda',
            platformId: 1,
            platform: const Platform(id: 1, name: 'Nintendo Switch', abbreviation: 'NSW'),
          ),
          1,
        );
        expect(result, equals('Zelda — NSW'));
      });

      test('should replace {status} token', () {
        final String result = _service().formatItem(
          '{name} [{status}]',
          _gameItem(status: ItemStatus.inProgress),
          1,
        );
        expect(result, equals('Elden Ring [In Progress]'));
      });

      test('should replace {genres} token', () {
        final String result = _service().formatItem(
          '{name} — {genres}',
          _gameItem(genres: 'RPG, Action'),
          1,
        );
        expect(result, equals('Elden Ring — RPG, Action'));
      });

      test('should replace {notes} token', () {
        final String result = _service().formatItem(
          '{name}: {notes}',
          _gameItem(userComment: 'Best game ever'),
          1,
        );
        expect(result, equals('Elden Ring: Best game ever'));
      });

      test('should replace {type} token', () {
        final String result = _service().formatItem(
          '{name} [{type}]',
          _gameItem(),
          1,
        );
        expect(result, equals('Elden Ring [Game]'));
      });

      test('should replace {#} with index', () {
        final String result = _service().formatItem(
          '{#}. {name}',
          _gameItem(),
          42,
        );
        expect(result, equals('42. Elden Ring'));
      });

      test('should replace {type} for movie', () {
        final String result = _service().formatItem(
          '{name} [{type}]',
          _movieItem(title: 'Inception'),
          1,
        );
        expect(result, equals('Inception [Movie]'));
      });
    });

    group('cleanup пустых токенов', () {
      test('should remove empty {year} with parentheses', () {
        final String result = _service().formatItem(
          '{name} ({year})',
          _gameItem(releaseYear: null),
          1,
        );
        expect(result, equals('Elden Ring'));
      });

      test('should remove empty {rating} with dash separator', () {
        final String result = _service().formatItem(
          '{name} — {rating}',
          _gameItem(rating: null),
          1,
        );
        expect(result, equals('Elden Ring'));
      });

      test('should remove empty {platform} with comma separator', () {
        final String result = _service().formatItem(
          '{name}, {platform}',
          _gameItem(),
          1,
        );
        expect(result, equals('Elden Ring'));
      });

      test('should remove empty {myRating} keeping filled tokens', () {
        final String result = _service().formatItem(
          '{name} ({year}) — {myRating}',
          _gameItem(userRating: null),
          1,
        );
        expect(result, equals('Elden Ring (2022)'));
      });

      test('should remove empty {notes} token', () {
        final String result = _service().formatItem(
          '{name} — {notes}',
          _gameItem(userComment: null),
          1,
        );
        expect(result, equals('Elden Ring'));
      });

      test('should handle multiple empty tokens', () {
        final String result = _service().formatItem(
          '{name} ({year}) — {rating} — {platform}',
          _gameItem(releaseYear: null, rating: null),
          1,
        );
        expect(result, equals('Elden Ring'));
      });
    });

    group('applyTemplate', () {
      test('should format multiple items', () {
        final List<CollectionItem> items = <CollectionItem>[
          _gameItem(id: 1, name: 'Game A', releaseYear: 2020),
          _gameItem(id: 2, name: 'Game B', releaseYear: 2021),
          _gameItem(id: 3, name: 'Game C', releaseYear: 2022),
        ];

        final String result =
            _service().applyTemplate('{name} ({year})', items);

        expect(
          result,
          equals('Game A (2020)\nGame B (2021)\nGame C (2022)'),
        );
      });

      test('should return empty string for empty list', () {
        final String result =
            _service().applyTemplate('{name}', <CollectionItem>[]);
        expect(result, isEmpty);
      });

      test('should handle single item without trailing newline', () {
        final String result = _service().applyTemplate(
          '{name}',
          <CollectionItem>[_gameItem(name: 'Solo')],
        );
        expect(result, equals('Solo'));
        expect(result.endsWith('\n'), isFalse);
      });

      test('should number items with {#}', () {
        final List<CollectionItem> items = <CollectionItem>[
          _gameItem(id: 1, name: 'First'),
          _gameItem(id: 2, name: 'Second'),
        ];

        final String result =
            _service().applyTemplate('{#}. {name}', items);

        expect(result, equals('1. First\n2. Second'));
      });
    });

    group('defaultTemplate', () {
      test('should be a valid template', () {
        expect(TextExportService.defaultTemplate, contains('{name}'));
      });

      test('should produce readable output', () {
        final String result = _service().applyTemplate(
          TextExportService.defaultTemplate,
          <CollectionItem>[_gameItem(name: 'Elden Ring', releaseYear: 2022)],
        );
        expect(result, equals('Elden Ring (2022)'));
      });
    });

    group('availableTokens', () {
      test('should contain all supported tokens', () {
        expect(
          TextExportService.availableTokens,
          containsAll(<String>[
            'name', 'year', 'rating', 'myRating', 'platform',
            'status', 'genres', 'notes', 'type', '#',
          ]),
        );
      });
    });
  });
}

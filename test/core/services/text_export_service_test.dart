import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/game.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/text_export_service.dart';

TextExportService _service() => TextExportService();

CollectionItem _gameItem({
  int id = 1,
  String name = 'Elden Ring',
  int? releaseYear = 2022,
  double? rating = 9.5,
  double? userRating = 10,
  ItemStatus status = ItemStatus.completed,
  String? genres = 'RPG, Action',
  String? userComment,
  int? platformId,
  Platform? platform,
  String? externalUrl,
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
      externalUrl: externalUrl,
    ),
  );
}

CollectionItem _customItem({
  int id = 20,
  String title = 'Homebrew Quest',
  MediaType? displayType,
  String? externalUrl,
}) {
  return CollectionItem(
    id: id,
    collectionId: 1,
    mediaType: MediaType.custom,
    externalId: 300 + id,
    status: ItemStatus.completed,
    addedAt: DateTime(2024),
    customMedia: CustomMedia(
      id: 300 + id,
      title: title,
      displayType: displayType,
      externalUrl: externalUrl,
    ),
  );
}

CollectionItem _movieItem({
  int id = 10,
  String title = 'Inception',
  int? releaseYear = 2010,
  double? rating = 8.8,
  double? userRating,
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
        expect(result, equals('BG3 — 9.0/10'));
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

      test('should replace {tags} with user tags for any media type', () {
        final CollectionItem item = _gameItem();
        final String result = _service().formatItem(
          '{name} — {tags}',
          item,
          1,
          tagsByItemId: <int, String>{item.id: 'Backlog, Favorites'},
        );
        expect(result, equals('Elden Ring — Backlog, Favorites'));
      });

      test('should ignore anime source tags — {tags} is user tags only', () {
        final CollectionItem item = CollectionItem(
          id: 7,
          collectionId: 1,
          mediaType: MediaType.anime,
          externalId: 1,
          status: ItemStatus.completed,
          addedAt: DateTime(2024),
          anime: const Anime(
            id: 1,
            title: 'Steins;Gate',
            tags: <String>['Time Loop', 'Conspiracy'],
          ),
        );
        final String result = _service().formatItem(
          '{name} — {tags}',
          item,
          1,
        );
        expect(result, equals('Steins;Gate'));
      });

      test('should remove {tags} token when the item has no user tags', () {
        final String result = _service().formatItem(
          '{name}{tags}',
          _gameItem(),
          1,
        );
        expect(result, equals('Elden Ring'));
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

      test('should use displayType for {type} of a masquerading custom', () {
        final String result = _service().formatItem(
          '{name} [{type}]',
          _customItem(displayType: MediaType.anime),
          1,
        );
        expect(result, equals('Homebrew Quest [Anime]'));
      });

      test('should keep Custom for {type} without displayType', () {
        final String result = _service().formatItem(
          '{name} [{type}]',
          _customItem(),
          1,
        );
        expect(result, equals('Homebrew Quest [Custom]'));
      });

      test('should replace {link} with the media external url', () {
        final String result = _service().formatItem(
          '{name} — {link}',
          _gameItem(externalUrl: 'https://www.igdb.com/games/elden-ring'),
          1,
        );
        expect(
          result,
          equals('Elden Ring — https://www.igdb.com/games/elden-ring'),
        );
      });

      test('should replace {link} with the custom item own url', () {
        final String result = _service().formatItem(
          '{name} — {link}',
          _customItem(externalUrl: 'https://example.com/quest'),
          1,
        );
        expect(result, equals('Homebrew Quest — https://example.com/quest'));
      });

      test('should remove empty {link} with its separator', () {
        final String result = _service().formatItem(
          '{name} — {link}',
          _gameItem(),
          1,
        );
        expect(result, equals('Elden Ring'));
      });
    });

    group('empty token cleanup', () {
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
            'status', 'genres', 'tags', 'notes', 'type', 'link', '#',
          ]),
        );
      });
    });
  });
}

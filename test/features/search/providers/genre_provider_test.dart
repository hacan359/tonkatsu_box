// Тесты для провайдеров жанров TMDB (genre_provider.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/search/providers/genre_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._initialState);

  final SettingsState _initialState;

  @override
  SettingsState build() {
    return _initialState;
  }
}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
  });

  /// Создаёт [ProviderContainer] с мок-зависимостями.
  ProviderContainer createContainer({
    String tmdbLanguage = 'ru-RU',
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
        settingsNotifierProvider.overrideWith(
          () => _FakeSettingsNotifier(
            SettingsState(tmdbLanguage: tmdbLanguage),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('movieGenreMapProvider', () {
    test('возвращает маппинг жанров фильмов из БД с языком ru', () async {
      final Map<String, String> expectedMap = <String, String>{
        '28': 'Боевик',
        '12': 'Приключения',
        '35': 'Комедия',
      };

      when(() => mockDb.getTmdbGenreMap('movie', lang: 'ru'))
          .thenAnswer((_) async => expectedMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'ru-RU',
      );

      final Map<String, String> result =
          await container.read(movieGenreMapProvider.future);

      expect(result, equals(expectedMap));
      verify(() => mockDb.getTmdbGenreMap('movie', lang: 'ru')).called(1);
    });

    test('возвращает маппинг жанров фильмов с языком en для en-US', () async {
      final Map<String, String> expectedMap = <String, String>{
        '28': 'Action',
        '12': 'Adventure',
      };

      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => expectedMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final Map<String, String> result =
          await container.read(movieGenreMapProvider.future);

      expect(result, equals(expectedMap));
      verify(() => mockDb.getTmdbGenreMap('movie', lang: 'en')).called(1);
    });

    test('возвращает пустой маппинг когда БД пуста', () async {
      when(() => mockDb.getTmdbGenreMap('movie', lang: 'ru'))
          .thenAnswer((_) async => <String, String>{});

      final ProviderContainer container = createContainer();

      final Map<String, String> result =
          await container.read(movieGenreMapProvider.future);

      expect(result, isEmpty);
    });

    test('маппинг языка: ru-RU преобразуется в ru', () async {
      when(() => mockDb.getTmdbGenreMap('movie', lang: 'ru'))
          .thenAnswer((_) async => <String, String>{'1': 'Тест'});

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'ru-RU',
      );

      await container.read(movieGenreMapProvider.future);

      verify(() => mockDb.getTmdbGenreMap('movie', lang: 'ru')).called(1);
      verifyNever(() => mockDb.getTmdbGenreMap('movie', lang: 'en'));
    });

    test('маппинг языка: en-US преобразуется в en', () async {
      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => <String, String>{'1': 'Test'});

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      await container.read(movieGenreMapProvider.future);

      verify(() => mockDb.getTmdbGenreMap('movie', lang: 'en')).called(1);
      verifyNever(() => mockDb.getTmdbGenreMap('movie', lang: 'ru'));
    });

    test('маппинг языка: произвольный язык преобразуется в en', () async {
      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => <String, String>{'1': 'Test'});

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'fr-FR',
      );

      await container.read(movieGenreMapProvider.future);

      verify(() => mockDb.getTmdbGenreMap('movie', lang: 'en')).called(1);
    });
  });

  group('tvGenreMapProvider', () {
    test('возвращает маппинг жанров сериалов из БД с языком ru', () async {
      final Map<String, String> expectedMap = <String, String>{
        '10759': 'Боевик и Приключения',
        '16': 'Мультфильм',
      };

      when(() => mockDb.getTmdbGenreMap('tv', lang: 'ru'))
          .thenAnswer((_) async => expectedMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'ru-RU',
      );

      final Map<String, String> result =
          await container.read(tvGenreMapProvider.future);

      expect(result, equals(expectedMap));
      verify(() => mockDb.getTmdbGenreMap('tv', lang: 'ru')).called(1);
    });

    test('возвращает маппинг жанров сериалов с языком en для en-US', () async {
      final Map<String, String> expectedMap = <String, String>{
        '10759': 'Action & Adventure',
        '16': 'Animation',
      };

      when(() => mockDb.getTmdbGenreMap('tv', lang: 'en'))
          .thenAnswer((_) async => expectedMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final Map<String, String> result =
          await container.read(tvGenreMapProvider.future);

      expect(result, equals(expectedMap));
      verify(() => mockDb.getTmdbGenreMap('tv', lang: 'en')).called(1);
    });

    test('возвращает пустой маппинг когда БД пуста', () async {
      when(() => mockDb.getTmdbGenreMap('tv', lang: 'ru'))
          .thenAnswer((_) async => <String, String>{});

      final ProviderContainer container = createContainer();

      final Map<String, String> result =
          await container.read(tvGenreMapProvider.future);

      expect(result, isEmpty);
    });
  });

  group('movieGenresProvider', () {
    test('конвертирует маппинг в список TmdbGenre', () async {
      final Map<String, String> genreMap = <String, String>{
        '28': 'Action',
        '12': 'Adventure',
        '35': 'Comedy',
      };

      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(movieGenresProvider.future);

      expect(result, hasLength(3));

      final TmdbGenre action =
          result.firstWhere((TmdbGenre g) => g.id == 28);
      expect(action.name, equals('Action'));

      final TmdbGenre adventure =
          result.firstWhere((TmdbGenre g) => g.id == 12);
      expect(adventure.name, equals('Adventure'));

      final TmdbGenre comedy =
          result.firstWhere((TmdbGenre g) => g.id == 35);
      expect(comedy.name, equals('Comedy'));
    });

    test('возвращает пустой список когда маппинг пуст', () async {
      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => <String, String>{});

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(movieGenresProvider.future);

      expect(result, isEmpty);
    });

    test('правильно парсит ID из строки в int', () async {
      final Map<String, String> genreMap = <String, String>{
        '99': 'Documentary',
      };

      when(() => mockDb.getTmdbGenreMap('movie', lang: 'en'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(movieGenresProvider.future);

      expect(result, hasLength(1));
      expect(result.first.id, equals(99));
      expect(result.first.name, equals('Documentary'));
    });

    test('возвращает жанры с русскими названиями для ru-RU', () async {
      final Map<String, String> genreMap = <String, String>{
        '28': 'Боевик',
        '35': 'Комедия',
      };

      when(() => mockDb.getTmdbGenreMap('movie', lang: 'ru'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'ru-RU',
      );

      final List<TmdbGenre> result =
          await container.read(movieGenresProvider.future);

      expect(result, hasLength(2));

      final TmdbGenre action =
          result.firstWhere((TmdbGenre g) => g.id == 28);
      expect(action.name, equals('Боевик'));
    });
  });

  group('tvGenresProvider', () {
    test('конвертирует маппинг в список TmdbGenre', () async {
      final Map<String, String> genreMap = <String, String>{
        '10759': 'Action & Adventure',
        '16': 'Animation',
      };

      when(() => mockDb.getTmdbGenreMap('tv', lang: 'en'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(tvGenresProvider.future);

      expect(result, hasLength(2));

      final TmdbGenre actionAdv =
          result.firstWhere((TmdbGenre g) => g.id == 10759);
      expect(actionAdv.name, equals('Action & Adventure'));

      final TmdbGenre animation =
          result.firstWhere((TmdbGenre g) => g.id == 16);
      expect(animation.name, equals('Animation'));
    });

    test('возвращает пустой список когда маппинг пуст', () async {
      when(() => mockDb.getTmdbGenreMap('tv', lang: 'en'))
          .thenAnswer((_) async => <String, String>{});

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(tvGenresProvider.future);

      expect(result, isEmpty);
    });

    test('возвращает жанры с русскими названиями для ru-RU', () async {
      final Map<String, String> genreMap = <String, String>{
        '10759': 'Боевик и Приключения',
        '16': 'Мультфильм',
      };

      when(() => mockDb.getTmdbGenreMap('tv', lang: 'ru'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'ru-RU',
      );

      final List<TmdbGenre> result =
          await container.read(tvGenresProvider.future);

      expect(result, hasLength(2));

      final TmdbGenre actionAdv =
          result.firstWhere((TmdbGenre g) => g.id == 10759);
      expect(actionAdv.name, equals('Боевик и Приключения'));
    });

    test('один жанр корректно конвертируется', () async {
      final Map<String, String> genreMap = <String, String>{
        '18': 'Drama',
      };

      when(() => mockDb.getTmdbGenreMap('tv', lang: 'en'))
          .thenAnswer((_) async => genreMap);

      final ProviderContainer container = createContainer(
        tmdbLanguage: 'en-US',
      );

      final List<TmdbGenre> result =
          await container.read(tvGenresProvider.future);

      expect(result, hasLength(1));
      expect(result.first.id, equals(18));
      expect(result.first.name, equals('Drama'));
    });
  });
}

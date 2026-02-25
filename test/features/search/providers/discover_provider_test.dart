// Тесты для Discover провайдера — настройки секций, сериализация, SharedPreferences.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/search/providers/discover_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

void main() {
  group('DiscoverSettingsKeys', () {
    test('sections содержит корректный ключ', () {
      expect(DiscoverSettingsKeys.sections, equals('discover_sections'));
    });

    test('hideOwned содержит корректный ключ', () {
      expect(DiscoverSettingsKeys.hideOwned, equals('discover_hide_owned'));
    });
  });

  group('DiscoverSectionId', () {
    group('key', () {
      test('trending имеет ключ "trending"', () {
        expect(DiscoverSectionId.trending.key, equals('trending'));
      });

      test('topRatedMovies имеет ключ "top_rated_movies"', () {
        expect(DiscoverSectionId.topRatedMovies.key, equals('top_rated_movies'));
      });

      test('popularTvShows имеет ключ "popular_tv_shows"', () {
        expect(
          DiscoverSectionId.popularTvShows.key,
          equals('popular_tv_shows'),
        );
      });

      test('upcoming имеет ключ "upcoming"', () {
        expect(DiscoverSectionId.upcoming.key, equals('upcoming'));
      });

      test('anime имеет ключ "anime"', () {
        expect(DiscoverSectionId.anime.key, equals('anime'));
      });

      test('topRatedTvShows имеет ключ "top_rated_tv_shows"', () {
        expect(
          DiscoverSectionId.topRatedTvShows.key,
          equals('top_rated_tv_shows'),
        );
      });
    });

    group('fromKey', () {
      test('возвращает trending для ключа "trending"', () {
        expect(
          DiscoverSectionId.fromKey('trending'),
          equals(DiscoverSectionId.trending),
        );
      });

      test('возвращает topRatedMovies для ключа "top_rated_movies"', () {
        expect(
          DiscoverSectionId.fromKey('top_rated_movies'),
          equals(DiscoverSectionId.topRatedMovies),
        );
      });

      test('возвращает popularTvShows для ключа "popular_tv_shows"', () {
        expect(
          DiscoverSectionId.fromKey('popular_tv_shows'),
          equals(DiscoverSectionId.popularTvShows),
        );
      });

      test('возвращает upcoming для ключа "upcoming"', () {
        expect(
          DiscoverSectionId.fromKey('upcoming'),
          equals(DiscoverSectionId.upcoming),
        );
      });

      test('возвращает anime для ключа "anime"', () {
        expect(
          DiscoverSectionId.fromKey('anime'),
          equals(DiscoverSectionId.anime),
        );
      });

      test('возвращает topRatedTvShows для ключа "top_rated_tv_shows"', () {
        expect(
          DiscoverSectionId.fromKey('top_rated_tv_shows'),
          equals(DiscoverSectionId.topRatedTvShows),
        );
      });

      test('возвращает null для невалидного ключа', () {
        expect(DiscoverSectionId.fromKey('nonexistent'), isNull);
      });

      test('возвращает null для пустой строки', () {
        expect(DiscoverSectionId.fromKey(''), isNull);
      });

      test('все значения enum доступны через fromKey', () {
        for (final DiscoverSectionId id in DiscoverSectionId.values) {
          final DiscoverSectionId? result = DiscoverSectionId.fromKey(id.key);
          expect(result, equals(id), reason: 'fromKey для ${id.key}');
        }
      });
    });

    group('values', () {
      test('содержит 6 значений', () {
        expect(DiscoverSectionId.values.length, equals(6));
      });
    });
  });

  group('DiscoverSettings', () {
    group('constructor', () {
      test('по умолчанию включает все 6 секций', () {
        const DiscoverSettings settings = DiscoverSettings();

        expect(settings.enabledSections.length, equals(6));
        expect(
          settings.enabledSections,
          containsAll(DiscoverSectionId.values),
        );
      });

      test('по умолчанию hideOwned == false', () {
        const DiscoverSettings settings = DiscoverSettings();

        expect(settings.hideOwned, isFalse);
      });

      test('принимает пользовательские enabledSections', () {
        const DiscoverSettings settings = DiscoverSettings(
          enabledSections: <DiscoverSectionId>{
            DiscoverSectionId.trending,
            DiscoverSectionId.anime,
          },
        );

        expect(settings.enabledSections.length, equals(2));
        expect(
          settings.enabledSections,
          contains(DiscoverSectionId.trending),
        );
        expect(settings.enabledSections, contains(DiscoverSectionId.anime));
      });

      test('принимает пользовательский hideOwned', () {
        const DiscoverSettings settings = DiscoverSettings(hideOwned: true);

        expect(settings.hideOwned, isTrue);
      });

      test('принимает пустой набор секций', () {
        const DiscoverSettings settings = DiscoverSettings(
          enabledSections: <DiscoverSectionId>{},
        );

        expect(settings.enabledSections, isEmpty);
      });
    });

    group('defaultSections', () {
      test('содержит все 6 секций', () {
        expect(DiscoverSettings.defaultSections.length, equals(6));
      });

      test('содержит trending', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.trending),
        );
      });

      test('содержит topRatedMovies', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.topRatedMovies),
        );
      });

      test('содержит popularTvShows', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.popularTvShows),
        );
      });

      test('содержит upcoming', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.upcoming),
        );
      });

      test('содержит anime', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.anime),
        );
      });

      test('содержит topRatedTvShows', () {
        expect(
          DiscoverSettings.defaultSections,
          contains(DiscoverSectionId.topRatedTvShows),
        );
      });

      test('совпадает с дефолтными enabledSections конструктора', () {
        const DiscoverSettings settings = DiscoverSettings();

        expect(
          settings.enabledSections,
          equals(DiscoverSettings.defaultSections),
        );
      });
    });

    group('copyWith', () {
      test('без изменений возвращает эквивалентный объект', () {
        const DiscoverSettings original = DiscoverSettings();
        final DiscoverSettings copy = original.copyWith();

        expect(copy.enabledSections, equals(original.enabledSections));
        expect(copy.hideOwned, equals(original.hideOwned));
      });

      test('изменяет enabledSections сохраняя hideOwned', () {
        const DiscoverSettings original = DiscoverSettings(hideOwned: true);
        final DiscoverSettings copy = original.copyWith(
          enabledSections: const <DiscoverSectionId>{
            DiscoverSectionId.anime,
          },
        );

        expect(copy.enabledSections.length, equals(1));
        expect(copy.enabledSections, contains(DiscoverSectionId.anime));
        expect(copy.hideOwned, isTrue);
      });

      test('изменяет hideOwned сохраняя enabledSections', () {
        const DiscoverSettings original = DiscoverSettings(
          enabledSections: <DiscoverSectionId>{
            DiscoverSectionId.trending,
          },
        );
        final DiscoverSettings copy = original.copyWith(hideOwned: true);

        expect(copy.enabledSections.length, equals(1));
        expect(copy.enabledSections, contains(DiscoverSectionId.trending));
        expect(copy.hideOwned, isTrue);
      });

      test('изменяет оба поля одновременно', () {
        const DiscoverSettings original = DiscoverSettings();
        final DiscoverSettings copy = original.copyWith(
          enabledSections: const <DiscoverSectionId>{
            DiscoverSectionId.upcoming,
          },
          hideOwned: true,
        );

        expect(copy.enabledSections.length, equals(1));
        expect(copy.enabledSections, contains(DiscoverSectionId.upcoming));
        expect(copy.hideOwned, isTrue);
      });

      test('может установить пустой набор секций', () {
        const DiscoverSettings original = DiscoverSettings();
        final DiscoverSettings copy = original.copyWith(
          enabledSections: const <DiscoverSectionId>{},
        );

        expect(copy.enabledSections, isEmpty);
      });

      test('не мутирует оригинал', () {
        const DiscoverSettings original = DiscoverSettings();
        original.copyWith(
          enabledSections: const <DiscoverSectionId>{
            DiscoverSectionId.anime,
          },
          hideOwned: true,
        );

        expect(original.enabledSections.length, equals(6));
        expect(original.hideOwned, isFalse);
      });
    });
  });

  group('DiscoverSettingsNotifier', () {
    late SharedPreferences prefs;

    Future<ProviderContainer> createContainer({
      Map<String, Object> initialPrefs = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(initialPrefs);
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    group('build', () {
      test('возвращает дефолтные настройки когда prefs пусты', () async {
        final ProviderContainer container = await createContainer();

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections, equals(DiscoverSettings.defaultSections));
        expect(state.hideOwned, isFalse);
      });

      test('загружает сохранённые секции из prefs', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(2));
        expect(
          state.enabledSections,
          contains(DiscoverSectionId.trending),
        );
        expect(state.enabledSections, contains(DiscoverSectionId.anime));
      });

      test('загружает hideOwned == true из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isTrue);
      });

      test('загружает hideOwned == false из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: false,
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isFalse);
      });

      test('загружает и секции и hideOwned из prefs одновременно', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.upcoming.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(1));
        expect(state.enabledSections, contains(DiscoverSectionId.upcoming));
        expect(state.hideOwned, isTrue);
      });

      test('игнорирует невалидные ключи секций в prefs', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
          'invalid_section_key',
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(2));
        expect(
          state.enabledSections,
          contains(DiscoverSectionId.trending),
        );
        expect(state.enabledSections, contains(DiscoverSectionId.anime));
      });

      test('возвращает пустой набор если все ключи в prefs невалидные',
          () async {
        final List<String> savedKeys = <String>[
          'bad_key_1',
          'bad_key_2',
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections, isEmpty);
      });

      test('загружает пустой массив секций из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(<String>[]),
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections, isEmpty);
      });

      test('загружает все 6 секций из prefs', () async {
        final List<String> allKeys = DiscoverSectionId.values
            .map((DiscoverSectionId id) => id.key)
            .toList();

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(allKeys),
          },
        );

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(6));
        expect(
          state.enabledSections,
          containsAll(DiscoverSectionId.values),
        );
      });
    });

    group('toggleSection', () {
      test('добавляет секцию, которой нет в наборе', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.anime);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(2));
        expect(
          state.enabledSections,
          contains(DiscoverSectionId.trending),
        );
        expect(state.enabledSections, contains(DiscoverSectionId.anime));
      });

      test('удаляет секцию, которая есть в наборе', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.trending);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(1));
        expect(state.enabledSections, contains(DiscoverSectionId.anime));
        expect(
          state.enabledSections.contains(DiscoverSectionId.trending),
          isFalse,
        );
      });

      test('сохраняет изменения в SharedPreferences при добавлении', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.anime);

        final String? storedJson =
            prefs.getString(DiscoverSettingsKeys.sections);
        expect(storedJson, isNotNull);
        final List<dynamic> storedKeys =
            jsonDecode(storedJson!) as List<dynamic>;
        expect(storedKeys, contains(DiscoverSectionId.trending.key));
        expect(storedKeys, contains(DiscoverSectionId.anime.key));
      });

      test('сохраняет изменения в SharedPreferences при удалении', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.trending);

        final String? storedJson =
            prefs.getString(DiscoverSettingsKeys.sections);
        expect(storedJson, isNotNull);
        final List<dynamic> storedKeys =
            jsonDecode(storedJson!) as List<dynamic>;
        expect(storedKeys, isNot(contains(DiscoverSectionId.trending.key)));
        expect(storedKeys, contains(DiscoverSectionId.anime.key));
      });

      test('может удалить последнюю секцию', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.anime);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections, isEmpty);
      });

      test('не изменяет hideOwned', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.toggleSection(DiscoverSectionId.trending);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isTrue);
      });

      test('двойной toggle возвращает секцию в исходное состояние', () async {
        final ProviderContainer container = await createContainer();

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        // Первый toggle — удаляем trending (он есть по умолчанию)
        await notifier.toggleSection(DiscoverSectionId.trending);
        DiscoverSettings state = container.read(discoverSettingsProvider);
        expect(
          state.enabledSections.contains(DiscoverSectionId.trending),
          isFalse,
        );

        // Второй toggle — возвращаем trending
        await notifier.toggleSection(DiscoverSectionId.trending);
        state = container.read(discoverSettingsProvider);
        expect(
          state.enabledSections.contains(DiscoverSectionId.trending),
          isTrue,
        );
      });
    });

    group('setHideOwned', () {
      test('устанавливает hideOwned в true', () async {
        final ProviderContainer container = await createContainer();

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.setHideOwned(value: true);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isTrue);
      });

      test('устанавливает hideOwned в false', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.setHideOwned(value: false);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isFalse);
      });

      test('сохраняет hideOwned в SharedPreferences', () async {
        final ProviderContainer container = await createContainer();

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.setHideOwned(value: true);

        final bool? storedValue =
            prefs.getBool(DiscoverSettingsKeys.hideOwned);
        expect(storedValue, isTrue);
      });

      test('не изменяет enabledSections', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.trending.key,
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.setHideOwned(value: true);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.enabledSections.length, equals(2));
        expect(
          state.enabledSections,
          contains(DiscoverSectionId.trending),
        );
        expect(state.enabledSections, contains(DiscoverSectionId.anime));
      });

      test('повторная установка того же значения не вызывает ошибку', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.setHideOwned(value: true);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isTrue);
      });
    });

    group('resetToDefault', () {
      test('восстанавливает все дефолтные секции', () async {
        final List<String> savedKeys = <String>[
          DiscoverSectionId.anime.key,
        ];

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections: jsonEncode(savedKeys),
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        // Проверяем что сначала настройки кастомные
        DiscoverSettings state = container.read(discoverSettingsProvider);
        expect(state.enabledSections.length, equals(1));
        expect(state.hideOwned, isTrue);

        await notifier.resetToDefault();

        state = container.read(discoverSettingsProvider);

        expect(
          state.enabledSections,
          equals(DiscoverSettings.defaultSections),
        );
        expect(state.enabledSections.length, equals(6));
      });

      test('восстанавливает hideOwned в false', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.resetToDefault();

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        expect(state.hideOwned, isFalse);
      });

      test('сохраняет дефолтные значения в SharedPreferences', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections:
                jsonEncode(<String>[DiscoverSectionId.anime.key]),
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.resetToDefault();

        // Проверяем prefs — секции сохранены
        final String? storedJson =
            prefs.getString(DiscoverSettingsKeys.sections);
        expect(storedJson, isNotNull);
        final List<dynamic> storedKeys =
            jsonDecode(storedJson!) as List<dynamic>;
        expect(storedKeys.length, equals(6));

        // Проверяем prefs — hideOwned сохранён как false
        final bool? storedHideOwned =
            prefs.getBool(DiscoverSettingsKeys.hideOwned);
        expect(storedHideOwned, isFalse);
      });

      test('состояние после reset идентично дефолтному конструктору',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections:
                jsonEncode(<String>[DiscoverSectionId.trending.key]),
            DiscoverSettingsKeys.hideOwned: true,
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.resetToDefault();

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);
        const DiscoverSettings defaultSettings = DiscoverSettings();

        expect(state.enabledSections, equals(defaultSettings.enabledSections));
        expect(state.hideOwned, equals(defaultSettings.hideOwned));
      });

      test('после reset можно снова изменять настройки', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            DiscoverSettingsKeys.sections:
                jsonEncode(<String>[DiscoverSectionId.anime.key]),
          },
        );

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        await notifier.resetToDefault();
        await notifier.toggleSection(DiscoverSectionId.trending);
        await notifier.setHideOwned(value: true);

        final DiscoverSettings state =
            container.read(discoverSettingsProvider);

        // trending удалён из дефолтных 6
        expect(state.enabledSections.length, equals(5));
        expect(
          state.enabledSections.contains(DiscoverSectionId.trending),
          isFalse,
        );
        expect(state.hideOwned, isTrue);
      });
    });

    group('_save (через интеграционные проверки)', () {
      test('toggleSection и setHideOwned сохраняют оба поля в prefs',
          () async {
        final ProviderContainer container = await createContainer();

        final DiscoverSettingsNotifier notifier =
            container.read(discoverSettingsProvider.notifier);

        // Удаляем trending
        await notifier.toggleSection(DiscoverSectionId.trending);
        // Включаем hideOwned
        await notifier.setHideOwned(value: true);

        // Проверяем, что оба поля сохранены
        final String? sectionsJson =
            prefs.getString(DiscoverSettingsKeys.sections);
        expect(sectionsJson, isNotNull);
        final List<dynamic> keys =
            jsonDecode(sectionsJson!) as List<dynamic>;
        expect(keys, isNot(contains(DiscoverSectionId.trending.key)));
        expect(keys.length, equals(5));

        final bool? hideOwned =
            prefs.getBool(DiscoverSettingsKeys.hideOwned);
        expect(hideOwned, isTrue);
      });

      test('сохранённые данные корректно загружаются в новом контейнере',
          () async {
        // Создаём первый контейнер и настраиваем
        final ProviderContainer container1 = await createContainer();

        final DiscoverSettingsNotifier notifier1 =
            container1.read(discoverSettingsProvider.notifier);

        await notifier1.toggleSection(DiscoverSectionId.trending);
        await notifier1.toggleSection(DiscoverSectionId.topRatedMovies);
        await notifier1.setHideOwned(value: true);

        // Читаем raw данные из SharedPreferences
        final String? sectionsJson =
            prefs.getString(DiscoverSettingsKeys.sections);
        final bool? hideOwned =
            prefs.getBool(DiscoverSettingsKeys.hideOwned);

        // Создаём второй контейнер с теми же данными в prefs
        final Map<String, Object> restoredPrefs = <String, Object>{};
        if (sectionsJson != null) {
          restoredPrefs[DiscoverSettingsKeys.sections] = sectionsJson;
        }
        if (hideOwned != null) {
          restoredPrefs[DiscoverSettingsKeys.hideOwned] = hideOwned;
        }
        final ProviderContainer container2 = await createContainer(
          initialPrefs: restoredPrefs,
        );

        final DiscoverSettings state2 =
            container2.read(discoverSettingsProvider);

        expect(state2.enabledSections.length, equals(4));
        expect(
          state2.enabledSections.contains(DiscoverSectionId.trending),
          isFalse,
        );
        expect(
          state2.enabledSections.contains(DiscoverSectionId.topRatedMovies),
          isFalse,
        );
        expect(state2.hideOwned, isTrue);
      });
    });
  });
}

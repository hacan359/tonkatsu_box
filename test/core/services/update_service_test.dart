// Тесты для UpdateService — проверка обновлений через GitHub Releases API.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/update_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UpdateService sut;
  late MockDio mockDio;

  const String latestVersion = '0.10.0';
  const String releaseUrl = 'https://github.com/hacan359/tonkatsu_box/releases/tag/v0.10.0';
  const String releaseNotes = 'New features and bug fixes';

  final Map<String, dynamic> successResponse = <String, dynamic>{
    'tag_name': 'v$latestVersion',
    'html_url': releaseUrl,
    'body': releaseNotes,
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    mockDio = MockDio();
    sut = UpdateService(
      prefs: prefs,
      dio: mockDio,
      currentVersionOverride: '0.9.0',
    );
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('UpdateInfo', () {
    test('должен создать объект с обязательными полями', () {
      const UpdateInfo info = UpdateInfo(
        currentVersion: '0.9.0',
        latestVersion: '0.10.0',
        releaseUrl: releaseUrl,
        hasUpdate: true,
      );

      expect(info.currentVersion, equals('0.9.0'));
      expect(info.latestVersion, equals('0.10.0'));
      expect(info.releaseUrl, equals(releaseUrl));
      expect(info.hasUpdate, isTrue);
      expect(info.releaseNotes, isNull);
    });

    test('должен создать объект с releaseNotes', () {
      const UpdateInfo info = UpdateInfo(
        currentVersion: '0.9.0',
        latestVersion: '0.10.0',
        releaseUrl: releaseUrl,
        hasUpdate: true,
        releaseNotes: 'Some notes',
      );

      expect(info.releaseNotes, equals('Some notes'));
    });
  });

  group('UpdateService', () {
    group('isNewer', () {
      test('major: 1.0.0 > 0.9.0', () {
        expect(sut.isNewer('1.0.0', '0.9.0'), isTrue);
      });

      test('minor: 0.10.0 > 0.9.0', () {
        expect(sut.isNewer('0.10.0', '0.9.0'), isTrue);
      });

      test('patch: 0.9.1 > 0.9.0', () {
        expect(sut.isNewer('0.9.1', '0.9.0'), isTrue);
      });

      test('equal: 0.9.0 == 0.9.0', () {
        expect(sut.isNewer('0.9.0', '0.9.0'), isFalse);
      });

      test('older: 0.8.0 < 0.9.0', () {
        expect(sut.isNewer('0.8.0', '0.9.0'), isFalse);
      });

      test('older patch: 0.9.0 < 0.9.1', () {
        expect(sut.isNewer('0.9.0', '0.9.1'), isFalse);
      });

      test('handles short version: 1.0 vs 0.9.0', () {
        expect(sut.isNewer('1.0', '0.9.0'), isTrue);
      });

      test('handles single number: 2 vs 1.0.0', () {
        expect(sut.isNewer('2', '1.0.0'), isTrue);
      });

      test('handles invalid parts gracefully', () {
        expect(sut.isNewer('abc', '0.9.0'), isFalse);
      });
    });

    group('checkForUpdate', () {
      test('должен вернуть UpdateInfo при наличии обновления', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNotNull);
        expect(result!.latestVersion, equals(latestVersion));
        expect(result.releaseUrl, equals(releaseUrl));
        expect(result.hasUpdate, isTrue);
        expect(result.releaseNotes, equals(releaseNotes));
      });

      test('должен вернуть hasUpdate=false если версия актуальна', () async {
        // Ответ где latest == current (currentVersionOverride = '0.9.0')
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: <String, dynamic>{
                'tag_name': 'v0.9.0',
                'html_url': releaseUrl,
                'body': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNotNull);
        expect(result!.hasUpdate, isFalse);
        expect(result.releaseNotes, isNull);
      });

      test('должен вернуть null при DioException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNull);
      });

      test('должен вернуть null при общей ошибке', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(Exception('Unknown error'));

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNull);
      });

      test('должен использовать правильный URL', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        await sut.checkForUpdate();

        verify(() => mockDio.get<Map<String, dynamic>>(
              'https://api.github.com/repos/hacan359/tonkatsu_box/releases/latest',
              options: any(named: 'options'),
            )).called(1);
      });
    });

    group('throttle', () {
      test('должен вернуть кеш при повторном вызове в течение 24ч', () async {
        // Первый вызов — реальный запрос
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        await sut.checkForUpdate();

        // Второй вызов — должен использовать кеш, без нового запроса
        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNotNull);
        expect(result!.latestVersion, equals(latestVersion));
        // Dio.get должен быть вызван только 1 раз
        verify(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).called(1);
      });

      test('должен вернуть null если кеш пуст и throttle активен', () async {
        // Записываем только timestamp без данных
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'update_last_check',
          DateTime.now().millisecondsSinceEpoch,
        );

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNull);
        verifyNever(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            ));
      });

      test('должен сделать запрос если прошло больше 24ч', () async {
        // Записываем старый timestamp (>24ч назад)
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'update_last_check',
          DateTime.now().millisecondsSinceEpoch - 86400001,
        );

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final UpdateInfo? result = await sut.checkForUpdate();

        expect(result, isNotNull);
        verify(() => mockDio.get<Map<String, dynamic>>(
              any(),
              options: any(named: 'options'),
            )).called(1);
      });
    });
  });
}

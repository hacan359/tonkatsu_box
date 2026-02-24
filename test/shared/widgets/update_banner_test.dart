import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для UpdateBanner — баннер уведомления об обновлении.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/update_service.dart';
import 'package:xerabora/shared/widgets/update_banner.dart';

void main() {
  const UpdateInfo updateAvailable = UpdateInfo(
    currentVersion: '0.9.0',
    latestVersion: '0.10.0',
    releaseUrl: 'https://github.com/hacan359/tonkatsu_box/releases/tag/v0.10.0',
    hasUpdate: true,
    releaseNotes: 'New features',
  );

  const UpdateInfo noUpdate = UpdateInfo(
    currentVersion: '0.10.0',
    latestVersion: '0.10.0',
    releaseUrl: 'https://github.com/hacan359/tonkatsu_box/releases/tag/v0.10.0',
    hasUpdate: false,
  );

  Widget buildWidget({required AsyncValue<UpdateInfo?> value}) {
    return ProviderScope(
      overrides: <Override>[
        updateCheckProvider.overrideWith(
          (Ref ref) => value.when(
            data: (UpdateInfo? data) => Future<UpdateInfo?>.value(data),
            loading: () => Completer<UpdateInfo?>().future,
            error: (Object e, StackTrace s) => Future<UpdateInfo?>.error(e, s),
          ),
        ),
      ],
      child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              Expanded(child: SizedBox.shrink()),
              UpdateBanner(),
            ],
          ),
        ),
      ),
    );
  }

  group('UpdateBanner', () {
    testWidgets('должен показать баннер при наличии обновления', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(updateAvailable)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update available: v0.10.0'), findsOneWidget);
      expect(find.text('Current: v0.9.0'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('должен скрыть баннер если обновления нет', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(noUpdate)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update available: v0.10.0'), findsNothing);
    });

    testWidgets('должен скрыть баннер если данных нет (null)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(null)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UpdateBanner), findsOneWidget);
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('должен скрыть баннер при ошибке', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          value: AsyncValue<UpdateInfo?>.error(
            Exception('Network error'),
            StackTrace.current,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('должен скрыть баннер при загрузке', (
      WidgetTester tester,
    ) async {
      // Completer никогда не завершится — провайдер останется в loading state
      // без pending timers (в отличие от Future.delayed).
      final Completer<UpdateInfo?> completer = Completer<UpdateInfo?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            updateCheckProvider.overrideWith(
              (Ref ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: SizedBox.shrink()),
                  UpdateBanner(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('должен скрыть баннер при нажатии крестика', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(updateAvailable)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update available: v0.10.0'), findsOneWidget);

      // Нажимаем крестик
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Update available: v0.10.0'), findsNothing);
    });

    testWidgets('должен содержать кнопку Update', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(updateAvailable)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Update'), findsOneWidget);
    });

    testWidgets('должен показывать иконку system_update', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(value: const AsyncValue<UpdateInfo?>.data(updateAvailable)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });
  });
}

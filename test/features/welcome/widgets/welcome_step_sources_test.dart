import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/settings/widgets/inline_text_field.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_sources.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/constants/source_catalog.dart';
import 'package:tonkatsu_box/shared/widgets/source_logo.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: WelcomeStepSources()),
      ),
    );
  }

  group('WelcomeStepSources', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeStepSources), findsOneWidget);
    });

    testWidgets('shows one logo per catalog source',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.byType(SourceLogo),
        findsNWidgets(kDataSourceCatalog.length),
      );
    });

    testWidgets('exposes key fields for IGDB and TMDB only',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // IGDB (Client ID + Secret) + TMDB (key) = 3 inline fields.
      expect(find.byType(InlineTextField), findsNWidgets(3));
    });
  });
}

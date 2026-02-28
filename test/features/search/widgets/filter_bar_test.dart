import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/search/widgets/filter_bar.dart';
import 'package:xerabora/features/search/widgets/filter_dropdown.dart';
import 'package:xerabora/features/search/widgets/source_dropdown.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: FilterBar(),
        ),
      ),
    );
  }

  group('FilterBar', () {
    testWidgets('renders SourceDropdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SourceDropdown), findsOneWidget);
    });

    testWidgets('renders FilterDropdowns for current source filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // TmdbMoviesSource (default) has 2 filters: genre + year
      expect(find.byType(FilterDropdown), findsNWidgets(2));
    });

    testWidgets('renders SortDropdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SortDropdown), findsOneWidget);
    });

    testWidgets('is wrapped in horizontal ListView',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final Finder listView = find.byType(ListView);
      expect(listView, findsOneWidget);
    });

    testWidgets('has fixed height of 36', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final SizedBox sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 36);
    });
  });
}

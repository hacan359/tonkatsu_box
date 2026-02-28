import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/search_sources.dart';
import 'package:xerabora/features/search/sources/tmdb_movies_source.dart';
import 'package:xerabora/features/search/sources/tmdb_tv_source.dart';
import 'package:xerabora/features/search/widgets/source_dropdown.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  Widget buildWidget({
    SearchSource? current,
    ValueChanged<SearchSource>? onChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SourceDropdown(
          current: current ?? TmdbMoviesSource(),
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('SourceDropdown', () {
    testWidgets('renders current source icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('renders dropdown arrow icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('opens popup menu on tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap the dropdown
      await tester.tap(find.byType(SourceDropdown));
      await tester.pumpAndSettle();

      // Should show all source options
      expect(find.byType(PopupMenuItem<String>), findsNWidgets(4));
    });

    testWidgets('shows all registered sources in popup',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SourceDropdown));
      await tester.pumpAndSettle();

      // Each source should have its icon
      for (final SearchSource source in searchSources) {
        expect(find.byIcon(source.icon), findsAtLeast(1));
      }
    });

    testWidgets('calls onChanged when different source selected',
        (WidgetTester tester) async {
      SearchSource? selectedSource;

      await tester.pumpWidget(
        buildWidget(
          current: TmdbMoviesSource(),
          onChanged: (SearchSource s) => selectedSource = s,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(SourceDropdown));
      await tester.pumpAndSettle();

      // Select TV source (tap on tv icon in popup)
      final Finder tvMenuItem = find.byWidgetPredicate(
        (Widget w) =>
            w is PopupMenuItem<String> && w.value == 'tv',
      );
      await tester.tap(tvMenuItem);
      await tester.pumpAndSettle();

      expect(selectedSource, isNotNull);
      expect(selectedSource, isA<TmdbTvSource>());
    });

    testWidgets('does not call onChanged when same source selected',
        (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        buildWidget(
          current: TmdbMoviesSource(),
          onChanged: (_) => callCount++,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(SourceDropdown));
      await tester.pumpAndSettle();

      // Select same source (movies)
      final Finder moviesMenuItem = find.byWidgetPredicate(
        (Widget w) =>
            w is PopupMenuItem<String> && w.value == 'movies',
      );
      await tester.tap(moviesMenuItem);
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });
}

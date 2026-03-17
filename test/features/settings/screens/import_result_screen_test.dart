import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/screens/import_result_screen.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/universal_import_result.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ImportResultScreen', () {
    group('success result', () {
      testWidgets('shows celebration icon and source name', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 10,
          },
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.byIcon(Icons.celebration), findsOneWidget);
        expect(find.textContaining('Steam'), findsWidgets);
      });

      testWidgets('shows imported card with breakdown', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Trakt',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.movie: 5,
            MediaType.tvShow: 3,
          },
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        // Total imported
        expect(find.text('8'), findsOneWidget);
        // Per-type breakdown
        expect(find.text('5'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows wishlist card when items wishlisted', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 10,
          },
          wishlistedByType: <MediaType, int>{
            MediaType.game: 3,
          },
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        // Wishlist hint text
        expect(
          find.textContaining('Wishlist'),
          findsWidgets,
        );
      });

      testWidgets('shows updated card when items updated', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 5,
          },
          updatedByType: <MediaType, int>{
            MediaType.game: 2,
          },
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.byIcon(Icons.sync), findsOneWidget);
      });

      testWidgets('shows skipped count', (WidgetTester tester) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Trakt',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.movie: 5,
          },
          skipped: 3,
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.textContaining('3'), findsWidgets);
      });

      testWidgets('shows Open Collection button when collection exists', (
        WidgetTester tester,
      ) async {
        final Collection collection = createTestCollection(id: 42);
        final UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          collection: collection,
          importedByType: const <MediaType, int>{
            MediaType.game: 10,
          },
        );

        await tester.pumpApp(
          ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.textContaining('Collection'), findsWidgets);
        expect(find.byIcon(Icons.collections_bookmark), findsOneWidget);
      });

      testWidgets('shows Done button', (WidgetTester tester) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Steam',
          success: true,
          collectionId: 1,
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.text('Done'), findsOneWidget);
      });
    });

    group('failure result', () {
      testWidgets('shows error icon and message', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult.failure(
          sourceName: 'Trakt',
          error: 'Connection timeout',
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Connection timeout'), findsOneWidget);
      });

      testWidgets('does not show Open Collection button on failure', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult.failure(
          sourceName: 'Steam',
          error: 'Failed',
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.byIcon(Icons.collections_bookmark), findsNothing);
      });
    });

    group('no collection id', () {
      testWidgets('hides Open Collection button when no collection', (
        WidgetTester tester,
      ) async {
        const UniversalImportResult result = UniversalImportResult(
          sourceName: 'Test',
          success: true,
          importedByType: <MediaType, int>{
            MediaType.game: 1,
          },
        );

        await tester.pumpApp(
          const ImportResultScreen(result: result),
          breadcrumbLabel: 'Settings',
        );

        expect(find.byIcon(Icons.collections_bookmark), findsNothing);
      });
    });
  });
}

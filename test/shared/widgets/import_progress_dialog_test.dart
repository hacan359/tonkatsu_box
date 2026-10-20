import 'dart:async';

import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/import_progress.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/widgets/import_progress_dialog.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late ValueNotifier<ImportProgress?> progress;
  late Completer<int> completer;

  setUp(() {
    progress = ValueNotifier<ImportProgress?>(null);
  });

  tearDown(() => progress.dispose());

  /// The loader and an indeterminate bar animate forever, so settle by
  /// time instead of pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pumpDialog(
    WidgetTester tester, {
    VoidCallback? onCancel,
    ImportTalliesBuilder? talliesBuilder,
    ImportResultBuilder<int>? resultBuilder,
  }) async {
    // Created inside the test body: a completer made in setUp lives outside
    // the FakeAsync zone and its completion never reaches the FutureBuilder.
    completer = Completer<int>();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => Center(
          child: ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => ImportProgressDialog<int>(
                title: 'Importing',
                progressNotifier: progress,
                importFuture: completer.future,
                onCancel: onCancel,
                talliesBuilder: talliesBuilder,
                resultBuilder: resultBuilder,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  group('ImportProgressDialog', () {
    testWidgets('renders without a progress snapshot', (WidgetTester tester) async {
      await pumpDialog(tester);

      expect(find.byType(ImportProgressDialog<int>), findsOneWidget);
      expect(tester.takeException(), isNull);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('cannot be popped while the import runs', (WidgetTester tester) async {
      await pumpDialog(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(ImportProgressDialog<int>), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('offers Done and pops once the import settles',
        (WidgetTester tester) async {
      await pumpDialog(tester);

      completer.complete(1);
      await settle(tester);

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await settle(tester);
      expect(find.byType(ImportProgressDialog<int>), findsNothing);
    });

    testWidgets('back closes the dialog after the import settles',
        (WidgetTester tester) async {
      await pumpDialog(tester);
      completer.complete(1);
      await settle(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(ImportProgressDialog<int>), findsNothing);
    });

    testWidgets('shows the current row and the source being asked',
        (WidgetTester tester) async {
      await pumpDialog(tester);

      progress.value = const ImportProgress(
        stage: ImportStage.resolvingTitles,
        current: 1,
        total: 4,
        currentItem: 'Dune',
        source: DataSource.tmdb,
      );
      await tester.pump();

      expect(find.textContaining('Dune'), findsOneWidget);
      expect(find.textContaining(DataSource.tmdb.label), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('shows tallies only once something was counted',
        (WidgetTester tester) async {
      await pumpDialog(tester);

      progress.value = const ImportProgress(
        stage: ImportStage.resolvingTitles,
        current: 0,
        total: 4,
      );
      await tester.pump();
      expect(find.textContaining('0'), findsOneWidget); // only "0 / 4"

      progress.value = const ImportProgress(
        stage: ImportStage.resolvingTitles,
        current: 2,
        total: 4,
        imported: 1,
        customCards: 1,
        ambiguous: 1,
      );
      await tester.pump();

      expect(find.textContaining('1'), findsWidgets);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('should show Stop only while running and fire it once',
        (WidgetTester tester) async {
      int cancels = 0;
      await pumpDialog(tester, onCancel: () => cancels++);
      progress.value = const ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: 2,
      );
      await tester.pump();

      final Finder stop = find.byType(TextButton);
      expect(stop, findsOneWidget);
      await tester.tap(stop);
      await tester.pump();
      expect(cancels, 1);
      expect(tester.widget<TextButton>(stop).onPressed, isNull);

      completer.complete(1);
      await settle(tester);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('should offer no Stop without a cancel handler',
        (WidgetTester tester) async {
      await pumpDialog(tester);

      expect(find.byType(TextButton), findsNothing);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('should render the custom tallies line',
        (WidgetTester tester) async {
      await pumpDialog(
        tester,
        talliesBuilder: (S l, ImportProgress p) => 'custom ${p.updated}',
      );
      progress.value = const ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 1,
        total: 2,
        updated: 7,
      );
      await tester.pump();

      expect(find.text('custom 7'), findsOneWidget);
      completer.complete(1);
      await tester.pump();
    });

    testWidgets('should render the result view only once settled',
        (WidgetTester tester) async {
      await pumpDialog(
        tester,
        resultBuilder: (BuildContext _, int r) => Text('result $r'),
      );
      progress.value = const ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: 1,
      );
      await tester.pump();
      expect(find.text('result 5'), findsNothing);

      completer.complete(5);
      await settle(tester);

      expect(find.text('result 5'), findsOneWidget);
    });
  });
}

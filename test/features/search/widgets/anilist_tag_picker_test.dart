import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/data/repositories/anilist_tags_repository.dart';
import 'package:xerabora/features/search/widgets/anilist_tag_picker.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/anilist_tag.dart';

import '../../../helpers/test_helpers.dart';

const List<AniListTag> _tags = <AniListTag>[
  AniListTag(id: 1, name: 'Time Loop', category: 'Theme-Plot'),
  AniListTag(id: 2, name: 'School', category: 'Setting'),
  AniListTag(id: 3, name: 'Ecchi', category: 'Theme', isAdult: true),
  AniListTag(id: 4, name: 'Plot Twist', category: 'Theme', isGeneralSpoiler: true),
];

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (BuildContext ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final Object? result = await showAniListTagPicker(
                ctx,
                ref,
                S.of(ctx),
                _lastResult,
              );
              _lastResult = result;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

Object? _lastResult;

void main() {
  setUp(() => _lastResult = null);

  Future<void> openPicker(WidgetTester tester, {Object? initial}) async {
    _lastResult = initial;
    await tester.pumpApp(
      const _Host(),
      overrides: <Override>[
        aniListTagsProvider.overrideWith((Ref _) async => _tags),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('AniListTagPicker', () {
    testWidgets('renders without exceptions and shows non-adult/non-spoiler tags',
        (WidgetTester tester) async {
      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Time Loop'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Ecchi'), findsNothing);
      expect(find.text('Plot Twist'), findsNothing);
    });

    testWidgets('Show 18+ toggle reveals adult tags',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      expect(find.text('Ecchi'), findsOneWidget);
    });

    testWidgets('Show spoiler toggle reveals spoiler tags',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.text('Plot Twist'), findsOneWidget);
    });

    testWidgets('search filter narrows the list',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.enterText(find.byType(TextField), 'school');
      await tester.pumpAndSettle();

      expect(find.text('School'), findsOneWidget);
      expect(find.text('Time Loop'), findsNothing);
    });

    testWidgets('Apply returns the picked tags',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Time Loop'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'School'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(_lastResult, isA<List<String>>());
      expect(
        (_lastResult! as List<String>).toSet(),
        <String>{'Time Loop', 'School'},
      );
    });

    testWidgets('Apply with no selection returns empty list',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(_lastResult, isA<List<String>>());
      expect(_lastResult! as List<String>, isEmpty);
    });

    testWidgets('Cancel returns null',
        (WidgetTester tester) async {
      await openPicker(tester, initial: const <String>['Time Loop']);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(_lastResult, isNull);
    });

    testWidgets('initial selection is preserved',
        (WidgetTester tester) async {
      await openPicker(tester, initial: const <String>['Time Loop']);

      final FilterChip chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Time Loop'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Clear all removes the selection',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Time Loop'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      final FilterChip chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Time Loop'),
      );
      expect(chip.selected, isFalse);
    });
  });
}

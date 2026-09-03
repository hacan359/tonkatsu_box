import 'package:core/models/anilist_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/utils/filter_ui.dart';
import 'package:tonkatsu_box/features/search/widgets/anilist_studio_picker.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

const List<AniListStudio> _studios = <AniListStudio>[
  AniListStudio(id: 2, name: 'Kyoto Animation'),
  AniListStudio(id: 6454, name: 'Kyotoma', isAnimationStudio: false),
];

Object? _lastResult;
bool _closed = false;

class _Host extends ConsumerWidget {
  const _Host({this.initial});

  final Object? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (BuildContext ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              _lastResult = await showAniListStudioPicker(
                ctx,
                ref,
                S.of(ctx),
                initial,
              );
              _closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

void main() {
  late MockAniListApi api;

  setUp(() {
    _lastResult = null;
    _closed = false;
    api = MockAniListApi();
    when(() => api.searchStudios(any(), perPage: any(named: 'perPage')))
        .thenAnswer((_) async => _studios);
  });

  Future<void> openPicker(WidgetTester tester, {Object? initial}) async {
    await tester.pumpApp(
      _Host(initial: initial),
      overrides: <Override>[aniListApiProvider.overrideWithValue(api)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> typeAndWait(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(SearchSource.defaultSearchDebounce);
    await tester.pumpAndSettle();
  }

  group('AniListStudioPicker', () {
    testWidgets('should not query until the debounce elapses',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.enterText(find.byType(TextField), 'kyo');
      await tester.pump(const Duration(milliseconds: 100));
      verifyNever(() => api.searchStudios(any(), perPage: any(named: 'perPage')));

      await tester.pump(SearchSource.defaultSearchDebounce);
      await tester.pumpAndSettle();
      verify(() => api.searchStudios('kyo', perPage: any(named: 'perPage')))
          .called(1);
    });

    testWidgets('should list only animation studios',
        (WidgetTester tester) async {
      await openPicker(tester);
      await typeAndWait(tester, 'kyo');

      expect(find.text('Kyoto Animation'), findsOneWidget);
      expect(find.text('Kyotoma'), findsNothing);
    });

    testWidgets('should return the tapped studio name and close',
        (WidgetTester tester) async {
      await openPicker(tester);
      await typeAndWait(tester, 'kyo');

      await tester.tap(find.text('Kyoto Animation'));
      await tester.pumpAndSettle();

      expect(_lastResult, 'Kyoto Animation');
      expect(_closed, isTrue);
    });

    testWidgets('should return the reset sentinel when the current pick is removed',
        (WidgetTester tester) async {
      await openPicker(tester, initial: 'MAPPA');

      expect(find.text('MAPPA'), findsOneWidget);
      tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
      await tester.pumpAndSettle();

      expect(_lastResult, kFilterResetSentinel);
    });

    testWidgets('should return null when dismissed',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(_lastResult, isNull);
      expect(_closed, isTrue);
    });

    testWidgets('should survive an API failure without leaving the spinner',
        (WidgetTester tester) async {
      when(() => api.searchStudios(any(), perPage: any(named: 'perPage')))
          .thenThrow(const AniListApiException('boom'));
      await openPicker(tester);
      await typeAndWait(tester, 'kyo');

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

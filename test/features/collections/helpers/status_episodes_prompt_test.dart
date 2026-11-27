import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tonkatsu_box/features/collections/helpers/status_episodes_prompt.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/shared/widgets/glass_dialog.dart';

import '../../../helpers/test_helpers.dart';

class _FakeTracker extends EpisodeTrackerNotifier {
  _FakeTracker(this.left, {this.marked = false});

  final int? left;
  final bool marked;

  @override
  EpisodeTrackerState build(EpisodeTrackerArg arg) =>
      const EpisodeTrackerState();

  @override
  Future<int?> unwatchedEpisodeCount() async => left;

  @override
  Future<bool> hasWatchedEpisodes() async => marked;
}

void main() {
  final CollectionItem show = createTestCollectionItem(
    mediaType: MediaType.tvShow,
    status: ItemStatus.inProgress,
  );

  group('askEpisodeSync', () {
    Future<bool?> ask(
      WidgetTester tester, {
      int? left,
      bool marked = false,
      CollectionItem? item,
      ItemStatus status = ItemStatus.completed,
      Future<void> Function()? answer,
    }) async {
      bool? result;
      bool done = false;
      await tester.pumpApp(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, _) => TextButton(
            onPressed: () async {
              result = await askEpisodeSync(
                context,
                ref.read,
                <CollectionItem?>[item ?? show],
                status,
              );
              done = true;
            },
            child: const Text('go'),
          ),
        ),
        wrapInScaffold: true,
        overrides: <Override>[
          episodeTrackerNotifierProvider.overrideWith(
            () => _FakeTracker(left, marked: marked),
          ),
        ],
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      if (answer != null) {
        await answer();
        await tester.pumpAndSettle();
      }
      expect(done, isTrue);
      return result;
    }

    testWidgets('should not ask when every episode is watched', (
      WidgetTester tester,
    ) async {
      expect(await ask(tester, left: 0), isTrue);
      expect(find.byType(GlassAlertDialog), findsNothing);
    });

    testWidgets('should not ask for a status other than completed', (
      WidgetTester tester,
    ) async {
      expect(await ask(tester, left: 4, status: ItemStatus.dropped), isTrue);
    });

    testWidgets('should not ask for a title without an episode tracker', (
      WidgetTester tester,
    ) async {
      final CollectionItem movie = createTestCollectionItem(
        mediaType: MediaType.movie,
      );
      expect(await ask(tester, left: 4, item: movie), isTrue);
    });

    testWidgets('should mark the rest when the user asks for it', (
      WidgetTester tester,
    ) async {
      final bool? result = await ask(
        tester,
        left: 4,
        answer: () => tester.tap(find.byType(TextButton).last),
      );
      expect(result, isTrue);
    });

    testWidgets('should complete without marking on the middle choice', (
      WidgetTester tester,
    ) async {
      final bool? result = await ask(
        tester,
        left: null,
        answer: () => tester.tap(
          find
              .descendant(
                of: find.byType(GlassAlertDialog),
                matching: find.byType(TextButton),
              )
              .at(1),
        ),
      );
      expect(result, isFalse);
    });

    testWidgets('should return null when the user cancels', (
      WidgetTester tester,
    ) async {
      final bool? result = await ask(
        tester,
        left: 4,
        answer: () => tester.tap(
          find
              .descendant(
                of: find.byType(GlassAlertDialog),
                matching: find.byType(TextButton),
              )
              .first,
        ),
      );
      expect(result, isNull);
    });

    group('back to not started', () {
      final CollectionItem watched = createTestCollectionItem(
        mediaType: MediaType.tvShow,
        status: ItemStatus.completed,
      );

      testWidgets('should erase the marks when the user asks for it', (
        WidgetTester tester,
      ) async {
        final bool? result = await ask(
          tester,
          marked: true,
          item: watched,
          status: ItemStatus.notStarted,
          answer: () => tester.tap(find.byType(TextButton).last),
        );
        expect(result, isTrue);
      });

      testWidgets('should keep the marks on the middle choice', (
        WidgetTester tester,
      ) async {
        final bool? result = await ask(
          tester,
          marked: true,
          item: watched,
          status: ItemStatus.notStarted,
          answer: () => tester.tap(
            find
                .descendant(
                  of: find.byType(GlassAlertDialog),
                  matching: find.byType(TextButton),
                )
                .at(1),
          ),
        );
        expect(result, isFalse);
      });

      testWidgets('should not ask when nothing is marked', (
        WidgetTester tester,
      ) async {
        expect(
          await ask(tester, item: watched, status: ItemStatus.notStarted),
          isTrue,
        );
        expect(find.byType(GlassAlertDialog), findsNothing);
      });

      testWidgets('should not ask for a title that was not completed', (
        WidgetTester tester,
      ) async {
        expect(
          await ask(tester, marked: true, status: ItemStatus.notStarted),
          isTrue,
        );
        expect(find.byType(GlassAlertDialog), findsNothing);
      });
    });

    testWidgets('should fit a phone-sized screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await ask(
        tester,
        left: 4,
        answer: () => tester.tap(find.byType(TextButton).last),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

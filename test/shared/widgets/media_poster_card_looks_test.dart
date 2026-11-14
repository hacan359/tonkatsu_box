import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tag.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';
import 'package:tonkatsu_box/shared/utils/item_card_progress.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';
import 'package:tonkatsu_box/shared/widgets/poster_look.dart';

import '../../helpers/test_helpers.dart';

void main() {
  const String title = 'Cowboy Bebop';
  final List<Tag> tags = <Tag>[
    createTestTag(id: 1, name: 'aa'),
    createTestTag(id: 2, name: 'bb'),
  ];

  Widget card(
    PosterLook look, {
    CardVariant variant = CardVariant.grid,
    Size size = const Size(170, 309),
    bool bare = false,
    VoidCallback? onTap,
    void Function(Offset)? onTagTap,
  }) {
    return PosterLookScope(
      look: look,
      child: Center(
        child: SizedBox.fromSize(
          size: size,
          child: MediaPosterCard(
            variant: variant,
            title: title,
            imageUrl: '',
            cacheImageType: ImageType.gameCover,
            cacheImageId: '1',
            mediaType: bare ? null : MediaType.anime,
            status: bare ? null : ItemStatus.inProgress,
            progress: bare
                ? null
                : const ItemCardProgress(label: '12/24', fraction: 0.5),
            userRating: bare ? null : 8,
            splitRatings: !bare,
            year: 1998,
            tags: bare ? const <Tag>[] : tags,
            onTap: onTap,
            onTagTap: onTagTap,
          ),
        ),
      ),
    );
  }

  Future<void> hover(WidgetTester tester) async {
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MediaPosterCard)));
    await tester.pumpAndSettle();
  }

  setUp(() => AppSurface.skin = AppSkin.glass);

  group('MediaPosterCard', () {
    group('looks', () {
      for (final PosterLook look in PosterLook.values) {
        testWidgets('should render ${look.id} with every stat set', (
          WidgetTester tester,
        ) async {
          await tester.pumpApp(card(look), wrapInScaffold: true);

          expect(tester.takeException(), isNull);
        });

        testWidgets('should render ${look.id} with nothing but a title', (
          WidgetTester tester,
        ) async {
          await tester.pumpApp(card(look, bare: true), wrapInScaffold: true);

          expect(tester.takeException(), isNull);
        });

        testWidgets('should render ${look.id} as a compact phone card', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = const Size(640, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpApp(
            card(look, variant: CardVariant.compact, size: const Size(90, 164)),
            wrapInScaffold: true,
          );

          expect(tester.takeException(), isNull);
        });

        testWidgets('should survive hover on ${look.id}', (
          WidgetTester tester,
        ) async {
          await tester.pumpApp(card(look), wrapInScaffold: true);

          await hover(tester);

          expect(tester.takeException(), isNull);
          // Minimal composes the title with inline marks in one rich text.
          expect(
            find.textContaining(title, findRichText: true),
            findsOneWidget,
          );
        });

        testWidgets('should fire onTap on ${look.id}', (
          WidgetTester tester,
        ) async {
          int taps = 0;
          await tester.pumpApp(
            card(look, onTap: () => taps++),
            wrapInScaffold: true,
          );

          await tester.tapAt(tester.getCenter(find.byType(MediaPosterCard)));
          await tester.pump();

          expect(taps, 1);
        });
      }

      testWidgets('should keep the kino title hidden until hover', (
        WidgetTester tester,
      ) async {
        await tester.pumpApp(card(PosterLook.kino), wrapInScaffold: true);

        expect(find.text(title), findsNothing);

        await hover(tester);

        expect(find.text(title), findsOneWidget);
      });

      for (final PosterLook look in <PosterLook>[
        PosterLook.cinema,
        PosterLook.shelf,
        PosterLook.kino,
      ]) {
        testWidgets('should reveal the tags of ${look.id} on hover', (
          WidgetTester tester,
        ) async {
          await tester.pumpApp(card(look), wrapInScaffold: true);

          expect(find.text(tags.first.name), findsNothing);

          await hover(tester);

          expect(find.text(tags.first.name), findsOneWidget);
        });
      }

      testWidgets('should report a tag tap from a revealed tag', (
        WidgetTester tester,
      ) async {
        int tagTaps = 0;
        await tester.pumpApp(
          card(PosterLook.cinema, onTagTap: (_) => tagTaps++),
          wrapInScaffold: true,
        );
        await hover(tester);

        await tester.tap(find.text(tags.first.name));
        await tester.pump();

        expect(tagTaps, 1);
      });

      testWidgets('should fall back to the classic card off the glass skin', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.classic;
        addTearDown(() => AppSurface.skin = AppSkin.glass);

        await tester.pumpApp(card(PosterLook.kino), wrapInScaffold: true);

        expect(find.text(title), findsOneWidget);
      });
    });
  });
}

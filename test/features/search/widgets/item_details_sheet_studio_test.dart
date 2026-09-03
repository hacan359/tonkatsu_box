import 'package:core/models/anime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/widgets/item_details_sheet.dart';

import '../../../helpers/test_helpers.dart';

class _Host extends StatelessWidget {
  const _Host({required this.anime, this.onStudioTap});

  final Anime anime;
  final ValueChanged<String>? onStudioTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => ItemDetailsSheet.anime(
              anime,
              onAddToCollection: () {},
              animeMangaTitleLanguage: 'romaji',
              onStudioTap: onStudioTap,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  final Anime anime = createTestAnime(
    id: 1,
    title: 'Violet Evergarden',
    studios: <String>['Kyoto Animation', 'Animation Do'],
  );

  Future<void> open(WidgetTester tester, {ValueChanged<String>? onStudioTap}) async {
    await tester.pumpApp(_Host(anime: anime, onStudioTap: onStudioTap));
    await tester.tap(find.text('open'));
    // CachedImage keeps a spinner alive, so pumpAndSettle would time out.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('ItemDetailsSheet.anime studios', () {
    testWidgets('should render one tappable chip per studio and close on tap',
        (WidgetTester tester) async {
      String? tapped;
      await open(tester, onStudioTap: (String s) => tapped = s);

      expect(find.text('Kyoto Animation'), findsOneWidget);
      expect(find.text('Animation Do'), findsOneWidget);

      await tester.tap(find.text('Animation Do'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapped, 'Animation Do');
      expect(find.text('Animation Do'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should keep a single joined chip without a callback',
        (WidgetTester tester) async {
      await open(tester);

      expect(find.text('Kyoto Animation, Animation Do'), findsOneWidget);
      expect(find.text('Kyoto Animation'), findsNothing);
    });
  });
}

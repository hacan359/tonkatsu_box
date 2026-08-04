import 'package:core/models/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/screens/card_banner_debug_screen.dart';

import '../../../helpers/test_helpers.dart';

class _EmptyCollectionsNotifier extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => <Collection>[];
}

void main() {
  setUpAll(registerAllFallbacks);

  Future<void> pumpLab(WidgetTester tester) async {
    await tester.pumpApp(
      const Scaffold(body: CardBannerDebugScreen()),
      overrides: <Override>[
        collectionsProvider.overrideWith(_EmptyCollectionsNotifier.new),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('CardBannerDebugScreen', () {
    testWidgets('should render every variant without layout errors',
        (WidgetTester tester) async {
      await pumpLab(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should render without layout errors on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLab(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should keep the episode count right of the tag',
        (WidgetTester tester) async {
      await pumpLab(tester);

      // Variant D's demo card carries both a tag and an episode count.
      final Rect tag = tester.getRect(find.text('weekend').first);
      final Rect count = tester.getRect(find.text('S2 · 12/24').first);

      expect(tag.right, lessThanOrEqualTo(count.left));
    });
  });
}

import 'package:core/models/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/content/custom_cards_import_content.dart';

import '../../../helpers/test_helpers.dart';

class _TestCollectionsNotifier extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => const <Collection>[];
}

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      const Scaffold(
        body: SingleChildScrollView(child: CustomCardsImportContent()),
      ),
      overrides: <Override>[
        collectionsProvider.overrideWith(_TestCollectionsNotifier.new),
      ],
    );
    await tester.pump();
  }

  group('CustomCardsImportContent', () {
    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      await pump(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the source lookup switch starts off and toggles',
        (WidgetTester tester) async {
      await pump(tester);

      final Finder lookup = find.byType(SwitchListTile).last;
      expect(tester.widget<SwitchListTile>(lookup).value, isFalse);

      await tester.ensureVisible(lookup);
      await tester.tap(lookup);
      await tester.pump();

      expect(tester.widget<SwitchListTile>(lookup).value, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/widgets/collection_picker_field.dart';

import '../../helpers/test_helpers.dart';

class _StubCollectionsNotifier extends CollectionsNotifier {
  _StubCollectionsNotifier(this._data);

  final List<Collection> _data;

  @override
  Future<List<Collection>> build() async => _data;
}

void main() {
  final List<Collection> sampleCollections = <Collection>[
    createTestCollection(id: 10, name: 'My Games', author: 'Alice'),
    createTestCollection(id: 20, name: 'Watch List', author: 'Bob'),
  ];

  Future<void> pumpField(
    WidgetTester tester, {
    required int? value,
    String? hint,
    String? nullLabel,
    ValueChanged<int?>? onChanged,
    bool enabled = true,
  }) {
    return tester.pumpApp(
      CollectionPickerField(
        value: value,
        hint: hint,
        nullLabel: nullLabel,
        enabled: enabled,
        onChanged: onChanged ?? (_) {},
      ),
      wrapInScaffold: true,
      overrides: <Override>[
        collectionsProvider.overrideWith(
          () => _StubCollectionsNotifier(sampleCollections),
        ),
      ],
    );
  }

  group('CollectionPickerField', () {
    testWidgets(
        'should show the hint when value is null and nullLabel is not set',
        (WidgetTester tester) async {
      await pumpField(tester, value: null, hint: 'Pick something');
      expect(find.text('Pick something'), findsOneWidget);
    });

    testWidgets(
        'should show the picked collection name and author when value matches',
        (WidgetTester tester) async {
      await pumpField(tester, value: 10, hint: 'Pick something');
      expect(find.text('My Games'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets(
        'should show nullLabel when value is null and nullLabel is set',
        (WidgetTester tester) async {
      await pumpField(
        tester,
        value: null,
        hint: 'Pick something',
        nullLabel: 'All collections',
      );
      expect(find.text('All collections'), findsOneWidget);
      expect(find.text('Pick something'), findsNothing);
    });

    testWidgets(
        'should ignore taps when disabled',
        (WidgetTester tester) async {
      int callCount = 0;
      await pumpField(
        tester,
        value: null,
        hint: 'Pick something',
        enabled: false,
        onChanged: (_) => callCount++,
      );
      await tester.tap(find.text('Pick something'));
      await tester.pumpAndSettle();
      expect(callCount, 0);
      // No dialog opened.
      expect(find.byType(Dialog), findsNothing);
    });
  });
}

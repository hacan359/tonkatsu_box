import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/create_custom_item_dialog.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

CustomMedia _media({MediaType? displayType}) => CustomMedia(
      id: 1,
      title: 'My Item',
      displayType: displayType,
      cachedAt: 1700000000,
    );

CustomItemData? _returned;

Future<void> _openEdit(
  WidgetTester tester, {
  required CustomMedia existing,
}) async {
  _returned = null;
  await tester.pumpApp(
    Builder(
      builder: (BuildContext ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              _returned = await CreateCustomItemDialog.edit(ctx, existing);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

// Chip order is custom first, then MediaType.values order, so movie is at
// index 2 (custom, game, movie, ...).
const int _movieChipIndex = 2;

void main() {
  group('CreateCustomItemDialog edit mode', () {
    testWidgets('renders the media-type chip row when editing',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('offers a chip for every MediaType so a new type is not forgotten',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(MediaType.values.length),
      );
    });

    testWidgets('preselects exactly one chip — the one matching displayType',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.movie));

      final Iterable<ChoiceChip> selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((ChoiceChip c) => c.selected);
      expect(selected, hasLength(1));
    });

    testWidgets('defaults to a single selected chip when displayType is null',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media());

      final Iterable<ChoiceChip> selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((ChoiceChip c) => c.selected);
      expect(selected, hasLength(1));
    });

    testWidgets('Save returns CustomItemData carrying the new mediaType',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));

      await tester.tap(find.byType(ChoiceChip).at(_movieChipIndex));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_returned, isNotNull);
      expect(_returned!.mediaType, MediaType.movie);
    });
  });
}

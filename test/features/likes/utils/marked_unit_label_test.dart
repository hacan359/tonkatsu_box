import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/likes/utils/marked_unit_label.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

MarkedUnit _unit(
  String unitType,
  int parent,
  int unit, {
  String? title,
}) {
  return MarkedUnit(
    mark: ItemMark(
      id: 0,
      itemId: 1,
      unitType: unitType,
      parentNumber: parent,
      unitNumber: unit,
      isFavorite: true,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    unitTitle: title,
  );
}

void main() {
  final S l = lookupS(const Locale('en'));

  group('markedUnitLabel', () {
    test('should use the short season-episode form for a seasoned episode',
        () {
      expect(
        markedUnitLabel(l, _unit(kUnitEpisode, 2, 5)),
        l.itemMarkEpisodeShort(2, 5),
      );
    });

    test('should fall back to the plain form for an episode without a season',
        () {
      final String label = markedUnitLabel(l, _unit(kUnitEpisode, 0, 5));
      expect(label, isNot(l.itemMarkEpisodeShort(0, 5)));
      expect(label, contains('5'));
    });

    test('should name the disc only for a multi-disc track', () {
      expect(
        markedUnitLabel(l, _unit(kUnitTrack, 2, 3)),
        l.likesTrackWithDisc(3, 2),
      );
      expect(
        markedUnitLabel(l, _unit(kUnitTrack, 1, 3)),
        isNot(contains(l.likesTrackWithDisc(3, 1))),
      );
    });

    test('should show the season number for a season-level mark', () {
      expect(markedUnitLabel(l, _unit(kUnitSeason, 4, 0)), contains('4'));
    });

    test('should render an unknown unit type verbatim with its number', () {
      expect(markedUnitLabel(l, _unit('arc', 0, 7)), contains('arc 7'));
    });

    test('should append the cached title when present', () {
      final String label =
          markedUnitLabel(l, _unit(kUnitEpisode, 2, 5, title: 'Rains'));
      expect(label, endsWith(' · Rains'));
      expect(label, startsWith(l.itemMarkEpisodeShort(2, 5)));
    });
  });
}

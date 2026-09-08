import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';

import '../../../l10n/app_localizations.dart';
import '../../collections/widgets/item_mark_controls.dart';

/// "S2·E5 · The Rains of Castamere", "Track 3 · Disc 2", "Chapter 12" — the
/// number the way the tracker shows it, plus the cached name when there is one.
String markedUnitLabel(S l, MarkedUnit unit) {
  final ItemMark m = unit.mark;
  final String number;
  if (m.unitType == kUnitEpisode && m.parentNumber > 0) {
    number = l.itemMarkEpisodeShort(m.parentNumber, m.unitNumber);
  } else if (m.unitType == kUnitTrack && m.parentNumber > 1) {
    number = l.likesTrackWithDisc(m.unitNumber, m.parentNumber);
  } else {
    number = l.itemMarkUnitLabel(
      unitTypeLabel(l, m.unitType),
      m.displayNumber,
    );
  }
  final String? title = unit.unitTitle;
  return title == null ? number : '$number · $title';
}

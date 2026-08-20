import 'package:core/models/tag_sort_mode.dart';

import '../../l10n/app_localizations.dart';

extension TagSortModeUi on TagSortMode {
  String localizedLabel(S l) {
    switch (this) {
      case TagSortMode.manual:
        return l.tagSortManual;
      case TagSortMode.alphaAsc:
        return l.tagSortAlphaAsc;
      case TagSortMode.alphaDesc:
        return l.tagSortAlphaDesc;
    }
  }
}

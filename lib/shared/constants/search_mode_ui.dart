import 'package:core/utils/meta_search.dart';

import '../../l10n/app_localizations.dart';

extension SearchModeUi on SearchMode {
  String localizedLabel(S l) => switch (this) {
        SearchMode.title => l.searchModeTitle,
        SearchMode.meta => l.searchModeMeta,
      };
}

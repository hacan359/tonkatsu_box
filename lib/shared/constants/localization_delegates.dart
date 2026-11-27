import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

// gen-l10n still emits the delegates of the frozen in-SDK Material, which
// material_ui widgets do not read; these are the ones they look up.
const List<LocalizationsDelegate<dynamic>> kAppLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      S.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

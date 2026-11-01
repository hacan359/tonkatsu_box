import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_assets.dart';

extension ImportSourceKindUi on ImportSourceKind {
  String localizedLabel(S l) => switch (this) {
    ImportSourceKind.steam => l.settingsSteamImport,
    ImportSourceKind.retroAchievements => l.settingsRaImport,
    ImportSourceKind.simkl => l.simklImportTitle,
    ImportSourceKind.aniList => l.settingsAniListImport,
    ImportSourceKind.hardcover => l.hardcoverImportTitle,
    ImportSourceKind.kinorium => l.settingsKinoriumImport,
    ImportSourceKind.igdbList => l.settingsIgdbImport,
    ImportSourceKind.trakt => l.traktTitle,
    ImportSourceKind.mal => l.settingsMalImport,
    ImportSourceKind.customCards => l.settingsCustomCardsImport,
  };

  /// Brand icon; custom cards have none and fall back to [fallbackIcon].
  String? get assetPath => switch (this) {
    ImportSourceKind.steam => AppAssets.iconSteamColor,
    ImportSourceKind.retroAchievements => AppAssets.iconRaColor,
    ImportSourceKind.simkl => AppAssets.iconSimklColor,
    ImportSourceKind.aniList => AppAssets.iconAnilistColor,
    ImportSourceKind.hardcover => AppAssets.iconHardcoverColor,
    ImportSourceKind.kinorium => AppAssets.iconKinoriumColor,
    ImportSourceKind.igdbList => AppAssets.iconIgdbColor,
    ImportSourceKind.trakt => AppAssets.iconTraktColor,
    ImportSourceKind.mal => AppAssets.iconMalColor,
    ImportSourceKind.customCards => null,
  };

  IconData get fallbackIcon => Icons.upload_file;
}

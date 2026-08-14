import '../../l10n/app_localizations.dart';
import 'rich_hero_style.dart';

extension RichHeroStyleUi on RichHeroStyle {
  String localizedLabel(S l) => switch (this) {
        RichHeroStyle.classic => l.settingsRichHeroStyleClassic,
        RichHeroStyle.comic => l.settingsRichHeroStyleComic,
        RichHeroStyle.stickers => l.settingsRichHeroStyleStickers,
        RichHeroStyle.brutalist => l.settingsRichHeroStyleBrutalist,
        RichHeroStyle.slats => l.settingsRichHeroStyleSlats,
      };
}

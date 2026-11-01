import 'app_palette.dart';

/// Selectable app themes. [id] is the SharedPreferences value — stable,
/// never rename.
enum AppThemeId {
  dark('dark'),
  sakura('sakura'),
  ps1('ps1'),
  eva('eva');

  const AppThemeId(this.id);

  final String id;

  AppPalette get palette => switch (this) {
        AppThemeId.dark => AppPalette.dark,
        AppThemeId.sakura => AppPalette.sakura,
        AppThemeId.ps1 => AppPalette.ps1,
        AppThemeId.eva => AppPalette.eva,
      };

  static AppThemeId fromId(String? id) => AppThemeId.values.firstWhere(
        (AppThemeId theme) => theme.id == id,
        orElse: () => AppThemeId.dark,
      );
}

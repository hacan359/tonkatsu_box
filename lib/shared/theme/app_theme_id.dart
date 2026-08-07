import 'app_palette.dart';

/// Selectable app themes. [id] is the SharedPreferences value — stable,
/// never rename.
enum AppThemeId {
  dark('dark'),
  sakura('sakura');

  const AppThemeId(this.id);

  final String id;

  AppPalette get palette => switch (this) {
        AppThemeId.dark => AppPalette.dark,
        AppThemeId.sakura => AppPalette.sakura,
      };

  static AppThemeId fromId(String? id) => AppThemeId.values.firstWhere(
        (AppThemeId theme) => theme.id == id,
        orElse: () => AppThemeId.dark,
      );
}

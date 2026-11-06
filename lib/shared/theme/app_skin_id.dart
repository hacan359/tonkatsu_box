import 'app_skin.dart';

/// Selectable surface styles. [id] is the SharedPreferences value — stable,
/// never rename.
enum AppSkinId {
  glass('glass'),
  classic('classic');

  const AppSkinId(this.id);

  final String id;

  AppSkin get skin => switch (this) {
    AppSkinId.glass => AppSkin.glass,
    AppSkinId.classic => AppSkin.classic,
  };

  static AppSkinId fromId(String? id) => AppSkinId.values.firstWhere(
    (AppSkinId skin) => skin.id == id,
    orElse: () => AppSkinId.glass,
  );
}

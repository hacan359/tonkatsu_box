import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/navigation/app_wallpaper.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';

import '../../helpers/test_helpers.dart';

class _MissingWallpaperSettings extends SettingsNotifier {
  @override
  SettingsState build() =>
      const SettingsState(wallpaperPath: 'no-such-dir/no-such-wallpaper.png');
}

void main() {
  group('AppWallpaper', () {
    tearDown(() => AppSurface.skin = AppSkin.glass);

    testWidgets('should lay the palette tile on glass with no picture', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.glass;

      await tester.pumpApp(const AppWallpaper());

      expect(find.byKey(AppWallpaper.tileKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should fall back to the tile when the picture is unreadable', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.glass;

      await tester.pumpApp(
        const AppWallpaper(),
        overrides: <Override>[
          settingsNotifierProvider.overrideWith(_MissingWallpaperSettings.new),
        ],
        settle: false,
      );
      expect(find.byKey(AppWallpaper.tileKey), findsNothing);
      // The file read fails on a real isolate turn, outside the fake clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(AppWallpaper.tileKey), findsOneWidget);
    });

    testWidgets('should lay the palette tile on classic', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;

      await tester.pumpApp(const AppWallpaper());

      expect(find.byKey(AppWallpaper.tileKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

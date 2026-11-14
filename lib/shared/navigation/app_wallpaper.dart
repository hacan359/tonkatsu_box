import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_surface.dart';

/// The bottom layer of the frame, what every panel sits on. The picture is
/// shown as loaded: legibility is the panels' job, not a wash over it.
class AppWallpaper extends ConsumerWidget {
  const AppWallpaper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? custom = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.wallpaperPath),
    );
    // Without a user picture glass sits on the palette tile, like classic.
    if (custom == null || kIsWebBuild) return _tile();
    return switch (AppSurface.wallpaper) {
      SkinWallpaper.picture => _picture(custom),
      SkinWallpaper.tile => _tile(),
    };
  }

  Widget _tile() => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.background,
      image: AppColors.palette.tileImage,
    ),
    child: const SizedBox.expand(),
  );

  /// Only reached off web: File() throws there before any IO.
  Widget _picture(String custom) {
    final double sigma = AppSurface.wallpaperBlurSigma;
    final Widget picture = _image(FileImage(File(custom)));
    // Blurred here once instead of by every panel; the boundary caches a
    // still picture, an animated GIF re-blurs only on its own frames.
    return ColoredBox(
      color: AppColors.background,
      child: sigma > 0
          ? RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: picture,
              ),
            )
          : picture,
    );
  }

  /// A missing or unreadable file falls back to the palette tile.
  Widget _image(ImageProvider<Object> provider) => Image(
    image: provider,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (BuildContext _, Object _, StackTrace? _) => _tile(),
  );
}

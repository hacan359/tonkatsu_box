import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_surface.dart';

/// The bottom layer of the frame, what every panel sits on. A picture gets
/// the skin's wash, since pages may lie on it with no panel of their own.
class AppWallpaper extends ConsumerWidget {
  const AppWallpaper({super.key});

  static const Key tileKey = ValueKey<String>('wallpaper-tile');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? custom = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.wallpaperPath),
    );
    final bool picture =
        AppSurface.wallpaper == SkinWallpaper.picture &&
        custom != null &&
        !kIsWebBuild;
    return picture
        ? _WallpaperPicture(path: custom)
        : const _PaletteTile(key: tileKey);
  }
}

/// The palette's own background: what classic always shows and what glass
/// shows until the user sets a picture.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.background,
      image: AppColors.palette.tileImage,
    ),
    child: const SizedBox.expand(),
  );
}

/// Only built off web: File() throws there before any IO.
class _WallpaperPicture extends StatefulWidget {
  const _WallpaperPicture({required this.path});

  final String path;

  @override
  State<_WallpaperPicture> createState() => _WallpaperPictureState();
}

class _WallpaperPictureState extends State<_WallpaperPicture> {
  bool _failed = false;

  @override
  void didUpdateWidget(_WallpaperPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _failed = false;
  }

  Widget _onError(BuildContext _, Object _, StackTrace? _) {
    // The tile must replace the whole stack, not sit under its blur and wash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
    return const SizedBox.expand();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _PaletteTile(key: AppWallpaper.tileKey);
    final double sigma = AppSurface.wallpaperBlurSigma;
    final Widget picture = Image(
      image: FileImage(File(widget.path)),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: _onError,
    );
    // Blurred here once instead of by every panel; the boundary caches a
    // still picture, an animated GIF re-blurs only on its own frames.
    return ColoredBox(
      color: AppColors.background,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (sigma > 0)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: picture,
              )
            else
              picture,
            ColoredBox(color: AppSurface.wallpaperWash()),
          ],
        ),
      ),
    );
  }
}

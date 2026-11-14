import 'package:material_ui/material_ui.dart';

import 'skins/classic_skin.dart';
import 'skins/glass_skin.dart';

export 'skins/classic_skin.dart';
export 'skins/glass_skin.dart';

/// What a translucent panel is made of: neutral frost (white on a light
/// palette, black on a dark one) or the palette's own surface colour.
enum SkinFill { frost, surface }

/// What sits under the panels: a picture or the palette's tile.
enum SkinWallpaper { picture, tile }

/// One alpha per palette brightness: frost needs more on dark than on light.
@immutable
class SkinAlpha {
  const SkinAlpha({required this.dark, required this.light});

  const SkinAlpha.same(int alpha) : dark = alpha, light = alpha;

  final int dark;
  final int light;

  int of(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;
}

/// The surface half of a theme: blur, translucency, shape, gaps, wallpaper.
/// Colours stay in [AppPalette]; any skin pairs with any palette.
@immutable
class AppSkin {
  const AppSkin({
    required this.wallpaperBlurSigma,
    required this.modalBlurSigma,
    required this.panelFill,
    required this.panelFrost,
    required this.panelEdge,
    required this.panelHighlight,
    required this.panelRadius,
    required this.frameGap,
    required this.wallpaper,
    required this.contentOnWallpaper,
    required this.tileAlpha,
    required this.tileEdge,
    required this.tileShadow,
    required this.cardElevation,
    required this.chipAlpha,
    required this.cardAlpha,
    required this.sheenAlpha,
    required this.inputFillAlpha,
    required this.modalAlpha,
    required this.popupAlpha,
    required this.detailBackdrop,
    required this.barrierAlpha,
  });

  static const AppSkin glass = glassSkin;

  static const AppSkin classic = classicSkin;

  /// Blur of the wallpaper under the frame's panels; 0 turns it off.
  final double wallpaperBlurSigma;

  /// Blur behind dialogs, sheets and popups; 0 turns it off.
  final double modalBlurSigma;

  final SkinFill panelFill;
  final SkinAlpha panelFrost;
  final SkinAlpha panelEdge;
  final SkinAlpha panelHighlight;

  /// Corner radius of the frame's panels; 0 for square ones.
  final double panelRadius;

  /// Gap between the window edge and the panels, and between the panels.
  final double frameGap;

  final SkinWallpaper wallpaper;

  /// The content panel paints no fill, so pages sit straight on the
  /// wallpaper the way they did before the frame.
  final bool contentOnWallpaper;

  final SkinAlpha tileAlpha;
  final SkinAlpha tileEdge;
  final bool tileShadow;

  /// Material elevation of a Card; 0 on glass, where a shadow would halo.
  final double cardElevation;

  /// Small controls with text sit on a near-solid surface, or they do not read.
  final int chipAlpha;

  final SkinAlpha cardAlpha;

  /// The highlight sweeping across a loading placeholder.
  final SkinAlpha sheenAlpha;

  final int inputFillAlpha;
  final int modalAlpha;
  final int popupAlpha;

  /// Whether a title card lays its artwork behind the text column.
  final bool detailBackdrop;

  /// Scrim behind every dialog, sheet and blocking overlay.
  final SkinAlpha barrierAlpha;
}

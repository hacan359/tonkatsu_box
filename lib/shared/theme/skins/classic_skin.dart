import '../app_skin.dart';

/// The 0.46 look: opaque square panels on the palette's tile, no blur, no
/// gaps, content straight on the tile with shadowed cards.
const AppSkin classicSkin = AppSkin(
  wallpaperBlurSigma: 0,
  modalBlurSigma: 0,
  panelFill: SkinFill.surface,
  panelFrost: SkinAlpha.same(255),
  panelEdge: SkinAlpha.same(255),
  panelHighlight: SkinAlpha.same(0),
  panelRadius: 0,
  frameGap: 0,
  wallpaper: SkinWallpaper.tile,
  contentOnWallpaper: true,
  tileAlpha: SkinAlpha.same(255),
  tileEdge: SkinAlpha.same(255),
  tileShadow: false,
  cardElevation: 2,
  chipAlpha: 255,
  cardAlpha: SkinAlpha.same(255),
  sheenAlpha: SkinAlpha(dark: 60, light: 120),
  inputFillAlpha: 255,
  modalAlpha: 255,
  popupAlpha: 255,
  detailBackdrop: true,
  barrierAlpha: SkinAlpha(dark: 138, light: 115),
);

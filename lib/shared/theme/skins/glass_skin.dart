import '../app_skin.dart';

/// Frosted panels over a blurred picture; the values the redesign was tuned on.
const AppSkin glassSkin = AppSkin(
  wallpaperBlurSigma: 4.2,
  modalBlurSigma: 5.6,
  panelFill: SkinFill.frost,
  panelFrost: SkinAlpha(dark: 70, light: 60),
  panelEdge: SkinAlpha(dark: 30, light: 70),
  panelHighlight: SkinAlpha(dark: 10, light: 28),
  panelRadius: 22,
  frameGap: 10,
  wallpaper: SkinWallpaper.picture,
  contentOnWallpaper: false,
  tileAlpha: SkinAlpha(dark: 110, light: 120),
  tileEdge: SkinAlpha(dark: 34, light: 180),
  tileShadow: true,
  cardElevation: 0,
  chipAlpha: 225,
  cardAlpha: SkinAlpha(dark: 16, light: 70),
  sheenAlpha: SkinAlpha(dark: 50, light: 150),
  inputFillAlpha: 150,
  modalAlpha: 225,
  popupAlpha: 215,
  detailBackdrop: false,
  barrierAlpha: SkinAlpha(dark: 80, light: 60),
);

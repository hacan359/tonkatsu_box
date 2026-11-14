[← Back to README](../README.md)

# Themes: palettes and skins

A theme in Tonkatsu Box has two independent axes. The user picks each one in
Settings → Appearance.

| Axis | Settings tile | Type | Registry | Default |
|------|---------------|------|----------|---------|
| Palette: every colour | Theme | `AppPalette` | `AppThemeId` | `dark` |
| Skin: how surfaces look (blur, translucency, corners, gaps, wallpaper) | Style | `AppSkin` | `AppSkinId` | `glass` |

Any skin pairs with any palette. The code never special-cases a combination;
if one looks wrong, fix the palette's colours or the skin's alphas, not a widget.

Built-in palettes: `dark`, `sakura`, `ps1`, `eva`
(`lib/shared/theme/palettes/`). Built-in skins: `glass` (frosted panels over a
blurred picture) and `classic` (the pre-0.47 look: opaque square panels on the
palette's tile, no gaps) (`lib/shared/theme/skins/`).

## How a theme reaches the widgets

`TonkatsuBoxApp` (`lib/app.dart`) reads both settings, assigns
`AppColors.palette` and `AppSurface.skin`, builds `ThemeData` from the palette
and keys the `MaterialApp` with `'<theme id>-<skin id>'`. Changing either
setting remounts the whole tree, so static reads stay correct without
listeners.

Widgets read colours through one of three doors and never through a palette
or skin object directly:

| Need | Read from | Examples |
|------|-----------|----------|
| A plain colour | `AppColors` | `AppColors.textSecondary`, `AppColors.brand` |
| A text style | `AppTypography` | `AppTypography.body` |
| A surface that depends on the skin | `AppSurface` or the glass helpers in `lib/shared/widgets/glass_panel.dart` | `glassTileDecoration()`, `glassChipColor()`, `AppSurface.barrier()` |

`AppSurface` takes an optional palette argument. `AppTheme.build(palette)` uses
it because it runs before the static palette is swapped; everything else omits
it.

## Adding a palette

1. Create `lib/shared/theme/palettes/<name>_palette.dart` with a
   `const AppPalette <name>Palette = AppPalette(...)`. Every field is required;
   copy the closest built-in and change the values.
2. Add `static const AppPalette <name> = <name>Palette;` and the import/export
   pair in `lib/shared/theme/app_palette.dart`.
3. Add the value to `AppThemeId` (`lib/shared/theme/app_theme_id.dart`): the
   string id goes to SharedPreferences, so it never changes once shipped.
   Extend the `palette` switch.
4. Add the background tile: `assets/images/background_tile_<name>.png`, a
   constant in `AppAssets`, and `tileAsset` / `tileOpacity` in the palette.
   The classic skin uses it as the wallpaper; the splash screen and route
   backgrounds paint it through `AppColors.tileImage`.
5. Add the label: `settingsTheme<Name>` in all six ARB files under
   `lib/l10n/`, run `flutter gen-l10n`, extend `_themeLabel` in
   `lib/features/settings/screens/settings_screen.dart`.
6. Run `flutter test test/shared/theme`. `theme_palette_guard_test.dart`
   iterates over every `AppThemeId`, so a new palette is checked without new
   test code.

Rules the guard test enforces on every palette:

- Contrast: `textPrimary` on `background`, `surface` and `surfaceLight` at
  4.5 or better; `textSecondary` on `background` at 3.0; `textTertiary` at 2.5;
  `onBrand` on `brand` and `onBadge` on `badge` at 3.0; `onOverlay` on `scrim`
  and `onBrandContainer` on `brandContainer` at 4.5.
- `brandContainer` differs from `brand`. Material paints hovered switch thumbs
  with it, and an equal colour merges the thumb into the track.
- The tile asset exists on disk.

Rules the test cannot check:

- `scrim` and `onOverlay` stay theme-independent (black and white). They sit on
  poster art, not on the palette.
- `barrier` carries the hue only. The skin decides its depth, so the alpha in
  the palette is ignored.
- A light palette needs darkened media-type accents and darker text than you
  would pick for a white sheet of paper. The glass skin puts text on a white
  frost over a photo, which eats pale colours. Sakura's text went three steps
  deeper for that reason; check a new light palette in both skins before
  calling it done.

## Adding a skin

1. Create `lib/shared/theme/skins/<name>_skin.dart` with a
   `const AppSkin <name>Skin = AppSkin(...)`. Every field is required.
2. Add `static const AppSkin <name> = <name>Skin;` and the import/export pair
   in `lib/shared/theme/app_skin.dart`.
3. Add the value to `AppSkinId` (`lib/shared/theme/app_skin_id.dart`) and
   extend its `skin` switch. The id is stored, so it never changes.
4. Add the label: `settingsSkin<Name>` in the six ARB files, `flutter gen-l10n`,
   extend `_skinLabel` in the settings screen.
5. Add the skin to `test/shared/theme/app_skin_test.dart` and run
   `flutter test test/shared/theme`.

Nothing else changes. Every surface in the app already reads the skin
through `AppSurface`, so a new skin is one data file.

### What each field controls

Alphas are 0 to 255. A `SkinAlpha` carries one value for dark palettes and one
for light ones, because frost needs more body on a dark background.

| Field | Controls | glass | classic |
|-------|----------|-------|---------|
| `wallpaperBlurSigma` | Blur of the wallpaper under the frame, applied once | 4.2 | 0 |
| `modalBlurSigma` | Blur behind dialogs, sheets and popups | 5.6 | 0 |
| `panelFill` | Panel material: neutral `frost` (white on light, black on dark) or the palette `surface` | frost | surface |
| `panelFrost` | Panel fill alpha | 70 / 60 | 255 |
| `panelEdge` | Panel border alpha | 30 / 70 | 255 |
| `panelHighlight` | White highlight along a panel's top edge | 10 / 28 | 0 |
| `panelRadius` | Corner radius of the three frame panels | 22 | 0 |
| `frameGap` | Gap between the window edge and the panels, and between panels | 10 | 0 |
| `wallpaper` | What sits under everything: a `picture` (the user's, set in Settings → Appearance → Wallpaper; the palette tile until one is set) or the palette `tile` | picture | tile |
| `contentOnWallpaper` | Content panel paints no fill; pages sit straight on the wallpaper | no | yes |
| `tileAlpha` | Fill of a big block (`GlassTile`, `glassTileDecoration`) | 110 / 120 | 255 |
| `tileEdge` | Border of that block | 34 / 180 | 255 |
| `tileShadow` | Drop shadow under a `GlassTile` | yes | no |
| `cardElevation` | Material elevation of a `Card` | 0 | 2 |
| `chipAlpha` | Fill of small controls with text (chips, tags, filter tiles); keep near-solid | 225 | 255 |
| `cardAlpha` | Fill of a Material `Card` | 16 / 70 | 255 |
| `sheenAlpha` | Highlight sweeping across a loading placeholder | 50 / 150 | 60 / 120 |
| `inputFillAlpha` | Text field fill | 150 | 255 |
| `modalAlpha` | Dialog and bottom sheet fill | 225 | 255 |
| `popupAlpha` | Popup menu fill | 215 | 255 |
| `detailBackdrop` | Artwork band inside the text block of a title card | no | yes |
| `barrierAlpha` | Scrim behind dialogs, sheets, the blocking loader and the FAB menu | 80 / 60 | 138 / 115 |

Values marked `a / b` are dark / light.

The corner radius is a skin property on purpose. The user turned down a
separate "rounded corners" setting: a skin is one coherent look, not a bag of
toggles.

### Where the values land

| `AppSurface` member | Used by |
|---------------------|---------|
| `panelFill`, `panelEdge`, `panelHighlight`, `panelRadius`, `frameGap` | `AppFrame`, `GlassPanel`, `GlassDialog`, `GlassSheet` |
| `tileFill`, `tileEdge`, `tileShadow` | `GlassTile`, `glassTileDecoration()`, `ImagePlaceholder` |
| `pictureTileFill` | `pictureTileDecoration()`: a block over a poster, alpha capped at 120 so the picture shows in every skin |
| `chipFill` | `glassChipColor()`, `ChipTheme` |
| `cardFill`, `cardElevation` | `CardTheme` |
| `inputFill` | `InputDecorationTheme` |
| `modalFill`, `modalBlurSigma` | `DialogTheme`, `BottomSheetTheme`, `GlassPanel` inside modals |
| `popupFill` | `PopupMenuTheme`; `GlassPopupMenuButton` draws a `GlassPanel` instead |
| `barrier` | `DialogTheme.barrierColor`, `BottomSheetTheme.modalBarrierColor`, `withBlockingSpinner`, `DraggableFab` |
| `wallpaper`, `wallpaperBlurSigma`, `wallpaperWash`, `contentOnWallpaper` | `AppWallpaper`, `AppFrame` |
| `sheen` | `ShimmerLoading` |
| `detailBackdrop` | `MediaDetailView` |

## Rules for widget code

- Read colours from `AppColors`, surfaces from `AppSurface` or the glass
  helpers. A widget that checks `brightness` or compares `AppSurface.skin` is
  doing the skin's job.
- Small text sits on `glassChipColor()`. Translucent chips were unreadable on
  the glass skin.
- A block laid over a picture (a poster, a backdrop) uses
  `pictureTileDecoration()`, never `glassTileDecoration()`. On the classic
  skin the latter is opaque and hides the picture.
- Modals get their blur from `GlassPanel`; pages never add a `BackdropFilter`
  of their own. The wallpaper is blurred once, in `AppWallpaper`.
- Scrims over images (`AppColors.scrim.withAlpha(...)`) are fine; they do not
  belong to the skin. Scrims behind routes go through `AppSurface.barrier()`.
- `BoxDecoration` with a `gradient` drops its `color`. Keep a tint and a
  gradient in separate layers.
- Tests assert behaviour, not colours. The theme tests check that a resolver
  reads the active skin and palette, not what shade comes out.

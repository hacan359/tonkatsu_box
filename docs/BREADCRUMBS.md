[← Back to README](../README.md)

# 🍞 Breadcrumb Navigation

## Overview

All screens use `BreadcrumbAppBar` — a unified navigation bar with breadcrumb trail. It replaces the standard `AppBar` and provides consistent navigation across the app.

## Widget: `BreadcrumbAppBar`

**File:** `lib/shared/widgets/breadcrumb_app_bar.dart`

```dart
BreadcrumbAppBar(
  crumbs: <BreadcrumbItem>[
    BreadcrumbItem(label: 'Settings', onTap: () => Navigator.of(context).pop()),
    BreadcrumbItem(label: 'Credentials'), // last — no onTap
  ],
  actions: <Widget>[...],   // optional action buttons on the right
  bottom: tabBar,           // optional TabBar below breadcrumbs
)
```

---

## Adaptive Root Element

The root element (leftmost) adapts to screen size:

| Screen Width | Root Element | Behavior |
|---|---|---|
| >= 800px (desktop) | `/` text | Static, no interaction (logo is visible above NavigationRail) |
| < 800px (mobile) | App logo 20x20 | Tappable — navigates to home (pops to root route) |

---

## Styling

| Element | Font Size | Font Weight | Color | Hover Color |
|---|---|---|---|---|
| Active crumb (last) | 12px (body) | w500 | textSecondary (#B0B0B0) | — |
| Clickable crumbs | 12px (body) | w400 | textTertiary (#707070) | textPrimary (#FFFFFF) |
| Separator `›` | 12px (body) | w300 | textTertiary (#707070) | — |
| Root `/` (desktop) | 12px (body) | w300 | textTertiary (#707070) | — |

- Clickable crumbs have a **hover effect**: color changes to white (`textPrimary`) on mouse enter
- Clickable crumbs show `SystemMouseCursors.click` cursor
- The last crumb is always non-interactive (even if `onTap` is provided)

---

## Navigation Patterns

### Tab Screens (root level)

Single crumb, no `onTap`:

```dart
// AllItemsScreen, HomeScreen, SearchScreen, SettingsScreen
BreadcrumbAppBar(
  crumbs: <BreadcrumbItem>[
    BreadcrumbItem(label: 'Settings'),
  ],
)
```

### One Level Deep

Two crumbs, first is clickable:

```dart
// CredentialsScreen, CacheScreen, DatabaseScreen, DebugHubScreen
BreadcrumbAppBar(
  crumbs: <BreadcrumbItem>[
    BreadcrumbItem(label: 'Settings', onTap: () => Navigator.of(context).pop()),
    BreadcrumbItem(label: 'Credentials'),
  ],
)
```

### Two Levels Deep

Three crumbs. Use `popUntil(isFirst)` for the root crumb:

```dart
// CollectionScreen -> Detail Screen
BreadcrumbAppBar(
  crumbs: <BreadcrumbItem>[
    BreadcrumbItem(
      label: 'Collections',
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
    ),
    BreadcrumbItem(
      label: collectionName,
      onTap: () => Navigator.of(context).pop(),
    ),
    BreadcrumbItem(label: itemName),
  ],
  bottom: tabBar, // detail screens have TabBar
)
```

### Three Levels Deep (Debug Screens)

```dart
// Settings > Debug > SteamGridDB
BreadcrumbAppBar(
  crumbs: <BreadcrumbItem>[
    BreadcrumbItem(
      label: 'Settings',
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
    ),
    BreadcrumbItem(
      label: 'Debug',
      onTap: () => Navigator.of(context).pop(),
    ),
    BreadcrumbItem(label: 'SteamGridDB'),
  ],
  bottom: tabBar, // SteamGridDB has 5 tabs
)
```

---

## With TabBar

Pass a `TabBar` as `bottom`. The `preferredSize` automatically includes the TabBar height:

```dart
BreadcrumbAppBar(
  crumbs: crumbs,
  bottom: const TabBar(
    tabs: <Tab>[Tab(text: 'Tab 1'), Tab(text: 'Tab 2')],
  ),
)
```

## With Action Buttons

Pass widgets to `actions` for buttons on the right side of the bar:

```dart
BreadcrumbAppBar(
  crumbs: crumbs,
  actions: <Widget>[
    IconButton(icon: Icon(Icons.add), onPressed: _addItem),
    IconButton(icon: Icon(Icons.lock), onPressed: _toggleLock),
  ],
)
```

---

## Technical Details

> [!NOTE]
> - **Height:** `kBreadcrumbToolbarHeight = 40` (+ TabBar if present)
> - **Horizontal scroll:** long breadcrumb trails wrap in `SingleChildScrollView`
> - **No back button:** `automaticallyImplyLeading: false` — navigation is via crumbs only
> - **Background:** `AppColors.background` (#0A0A0A)
> - **Breakpoint:** uses `navigationBreakpoint` (800px) from `navigation_shell.dart`

> [!TIP]
> When adding a new screen, always use `BreadcrumbAppBar` instead of the standard `AppBar`. The last crumb in the list represents the current screen and should **not** have an `onTap` handler.

---

## All Screens Using BreadcrumbAppBar

| Screen | Crumbs |
|---|---|
| AllItemsScreen | `Main` |
| HomeScreen | `Collections` |
| CollectionScreen | `Collections › {name}` |
| GameDetailScreen | `Collections › {collection} › {game}` |
| MovieDetailScreen | `Collections › {collection} › {movie}` |
| TvShowDetailScreen | `Collections › {collection} › {show}` |
| AnimeDetailScreen | `Collections › {collection} › {anime}` |
| SearchScreen | `Search` |
| SettingsScreen | `Settings` |
| CredentialsScreen | `Settings › Credentials` |
| CacheScreen | `Settings › Cache` |
| DatabaseScreen | `Settings › Database` |
| DebugHubScreen | `Settings › Debug` |
| ImageDebugScreen | `Settings › Debug › IGDB Media` |
| SteamGridDbDebugScreen | `Settings › Debug › SteamGridDB` |
| GamepadDebugScreen | `Settings › Debug › Gamepad` |

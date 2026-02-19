[← Back to README](../README.md)

# Breadcrumb Navigation

## Overview

All screens use `AutoBreadcrumbAppBar` — an automatic navigation bar that reads breadcrumb labels from the widget tree via `BreadcrumbScope` InheritedWidget. This eliminates manual crumb assembly and removes data coupling (e.g., passing `collectionName` just for breadcrumbs).

## Architecture: BreadcrumbScope

**File:** `lib/shared/widgets/breadcrumb_scope.dart`

`BreadcrumbScope` is an `InheritedWidget` that holds a single `label` string. Each screen wraps its content in a scope, and `AutoBreadcrumbAppBar` collects all scope labels from the widget tree automatically.

### Three levels of scope:

1. **Tab root scope** — set in `NavigationShell._buildTabNavigator()`, **above** the Navigator. Visible to all routes via ancestor traversal.

2. **Screen's own scope** — each screen wraps its Scaffold in `BreadcrumbScope(label: ownLabel)`.

3. **Push scope** — when pushing a child route, the parent wraps it in a scope with its own label:

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => BreadcrumbScope(
    label: 'Debug',              // parent screen's label
    child: SteamGridDbDebugScreen(),
  ),
));
```

`visitAncestorElements` from the child finds: `'Settings'` (NavigationShell) → `'Debug'` (push builder) → `'SteamGridDB'` (screen's own scope).

## Widget: `AutoBreadcrumbAppBar`

**File:** `lib/shared/widgets/auto_breadcrumb_app_bar.dart`

```dart
BreadcrumbScope(
  label: 'Credentials',
  child: Scaffold(
    appBar: const AutoBreadcrumbAppBar(),
    body: ...,
  ),
)
```

Navigation is automatic:
- **First crumb** → `popUntil(isFirst)` (returns to tab root)
- **Intermediate crumbs** → `pop()` N times
- **Last crumb** (current) → no interaction

Parameters: `actions`, `bottom` (TabBar), `accentColor` (accent border-bottom).

## Widget: `BreadcrumbAppBar`

**File:** `lib/shared/widgets/breadcrumb_app_bar.dart`

Low-level widget used by `AutoBreadcrumbAppBar`. Accepts explicit `crumbs` list. Normally not used directly.

---

## Adaptive Root Element

| Screen Width | Root Element | Behavior |
|---|---|---|
| >= 800px (desktop) | `/` text | Static |
| < 800px (mobile) | `←` back button | Pops to previous route (if `canPop`) |

---

## Styling

| Element | Font Size | Font Weight | Color |
|---|---|---|---|
| Current crumb (last) | 13px | w600 | textPrimary (#FFFFFF) |
| Clickable crumbs | 13px | w400 | textTertiary (#707070) |
| Separator `>` | Icon 14px | — | textTertiary @ 50% alpha |
| Root `/` (desktop) | 13px | w300 | textTertiary (#707070) |

- **Hover effect:** pill background (`surfaceLight`, borderRadius 6) + text color → textPrimary
- **Overflow:** maxWidth 300px (current crumb), 180px (others), `TextOverflow.ellipsis`
- **Mobile collapse:** >2 crumbs → `[first] > … > [last]`
- **Gamepad:** `Actions > Focus > MouseRegion > GestureDetector` with `FocusNode` (disposed)

---

## Migration Patterns

### Tab Root Screen (Level 0)

Tab root scope comes from `NavigationShell`. Screen only needs `AutoBreadcrumbAppBar`:

```dart
// SettingsScreen, HomeScreen, AllItemsScreen, SearchScreen, WishlistScreen
Scaffold(
  appBar: const AutoBreadcrumbAppBar(),
  body: ...,
)
```

### One Level Deep (Level 1)

Screen wraps in its own scope:

```dart
// CredentialsScreen, CacheScreen, DatabaseScreen, DebugHubScreen, CollectionScreen
BreadcrumbScope(
  label: 'Credentials',
  child: Scaffold(
    appBar: const AutoBreadcrumbAppBar(),
    body: ...,
  ),
)
```

### Two Levels Deep (Level 2)

Parent wraps push builder in its scope label. Screen adds its own scope:

```dart
// In DebugHubScreen:
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => const BreadcrumbScope(
    label: 'Debug',
    child: SteamGridDbDebugScreen(),
  ),
));

// In SteamGridDbDebugScreen:
BreadcrumbScope(
  label: 'SteamGridDB',
  child: Scaffold(
    appBar: const AutoBreadcrumbAppBar(bottom: TabBar(...)),
    body: ...,
  ),
)
```

### Detail Screens (Dynamic Label)

Loading state uses `'...'`, loaded state uses item name:

```dart
// In GameDetailScreen:
return BreadcrumbScope(
  label: collectionItem.itemName,  // dynamic label
  child: Scaffold(
    appBar: AutoBreadcrumbAppBar(actions: [...]),
    body: ...,
  ),
);
```

---

## Technical Details

> [!NOTE]
> - **Height:** `kBreadcrumbToolbarHeight = 44` (+ TabBar if present)
> - **Horizontal scroll:** long breadcrumb trails wrap in `SingleChildScrollView`
> - **No back button on desktop:** `automaticallyImplyLeading: false` — navigation is via crumbs only
> - **Background:** `AppColors.background` (#0A0A0A)
> - **Breakpoint:** uses `navigationBreakpoint` (800px) from `navigation_shell.dart`
> - **Rebuild:** `dependOnInheritedWidgetOfExactType` triggers rebuild when nearest scope label changes (loading → loaded)

> [!TIP]
> When adding a new screen, wrap it in `BreadcrumbScope(label: 'ScreenName')` and use `AutoBreadcrumbAppBar`. If the screen is pushed from another screen, the parent should wrap the push builder in `BreadcrumbScope(label: parentLabel)`.

---

## All Screens Using AutoBreadcrumbAppBar

| Screen | Crumbs | Scope Source |
|---|---|---|
| AllItemsScreen | `Main` | NavigationShell |
| HomeScreen | `Collections` | NavigationShell |
| CollectionScreen | `Collections > {name}` | NavigationShell + own |
| GameDetailScreen | `Collections > {collection} > {game}` | NavigationShell + push + own |
| MovieDetailScreen | `Collections > {collection} > {movie}` | NavigationShell + push + own |
| TvShowDetailScreen | `Collections > {collection} > {show}` | NavigationShell + push + own |
| AnimeDetailScreen | `Collections > {collection} > {anime}` | NavigationShell + push + own |
| SearchScreen | `Search` | NavigationShell |
| WishlistScreen | `Wishlist` | NavigationShell |
| SettingsScreen | `Settings` | NavigationShell |
| CredentialsScreen | `Settings > Credentials` | NavigationShell + own |
| CacheScreen | `Settings > Cache` | NavigationShell + own |
| DatabaseScreen | `Settings > Database` | NavigationShell + own |
| DebugHubScreen | `Settings > Debug` | NavigationShell + own |
| ImageDebugScreen | `Settings > Debug > IGDB Media` | NavigationShell + push + own |
| SteamGridDbDebugScreen | `Settings > Debug > SteamGridDB` | NavigationShell + push + own |
| GamepadDebugScreen | `Settings > Debug > Gamepad` | NavigationShell + push + own |

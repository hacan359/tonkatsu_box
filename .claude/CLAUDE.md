# Tonkatsu Box — project rules

## Language

Always reply to the user in Russian. Code, comments, commit messages and docs
are English (see "Comments" below).

## Stack

- Flutter 3.38+ / Dart SDK `^3.10.8`
- Platforms: Windows desktop (full) + Android (no VGMaps/WebView)
- State: **Riverpod 2.x** (`NotifierProvider`, `AsyncNotifierProvider`)
- DB: SQLite (`sqflite_common_ffi` on desktop, `sqflite` on Android)
- HTTP: Dio
- Tests: `flutter_test` + `mocktail`
- Localization: ARB files in `lib/l10n/` — `en`, `ru`, `es`, `fr`, `pt`, `zh`

## Toolchain

**The Flutter SDK lives on Windows, not inside WSL.** Run every Flutter command
through PowerShell. `$(wslpath -w "$PWD")` resolves the current WSL directory to
its Windows path — never hardcode it.

```bash
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter analyze --fatal-infos --fatal-warnings"
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter test"
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter run -d windows"
```

`flutter.bat` goes through cmd, which eats an unquoted `|`. For arguments
containing one (e.g. `--coverage-package="tonkatsu_box|core"`) write a `.ps1`
and use PowerShell's `--%` stop-parsing token.

### Workspace layout

The repo is a Flutter app plus two path packages:

| Path | What |
|------|------|
| `lib/` | The Flutter app |
| `packages/core/` | Pure-Dart shared layer (models, DB, utils), no Flutter |
| `packages/gamepads_windows_stub/` | Stub overriding the crashing `gamepads_windows` plugin |

`packages/core` resolves its own dependencies. A root `flutter pub get` does
**not** create `packages/core/.dart_tool/package_config.json`, so its `test/`
files fail to analyze (`package:test` is only in *its* dev_dependencies). CI and
fresh clones need:

```bash
dart pub get --directory packages/core
```

Coverage has the same trap: `flutter test --coverage` defaults
`--coverage-package` to the current package only, silently dropping every
`packages/core` line. Always pass `--coverage-package='tonkatsu_box|core'`.

## Architecture

```
lib/
├── main.dart              # Entry point, SQLite init, ProviderScope
├── app.dart               # TonkatsuBoxApp — MaterialApp, dark theme, SplashScreen
├── l10n/                  # ARB sources + generated AppLocalizations
├── core/
│   ├── api/               # One client per provider (igdb, tmdb, anilist, kitsu, …)
│   ├── database/          # database_service.dart — init, profiles, DAO providers
│   ├── import/            # Import pipeline + per-source adapters
│   ├── logging/
│   └── services/          # export/import, backup, sync, image cache, config, …
├── data/repositories/     # canvas, collection, game
├── features/              # collections, search, settings, splash, statistics,
│                          # tier_lists, mood_grids, wishlist, releases,
│                          # recommendations, genre_cloud, personalization,
│                          # home, welcome
└── shared/
    ├── constants/         # media_type_theme, platform_features, *_ui extensions
    ├── extensions/  gamepad/  keyboard/  navigation/  services/  utils/
    ├── theme/             # AppColors, AppTypography, AppSpacing, AppTheme (dark)
    └── widgets/           # CachedImage, PosterCard, RatingBadge, ShimmerLoading…

packages/core/lib/         # Pure Dart — shared with the future selfhost server
├── models/                # Game, Movie, TvShow, Collection, CanvasItem, XcollFile…
├── database/              # schema.dart, database_opener.dart, migrations/, dao/
└── utils/                 # bbcode, html_text, stable_id, cover_image_id…
```

Principles: feature-based layout, single responsibility, DI through Riverpod,
immutability (`copyWith`), composition over inheritance.

## Patterns

### Models (`packages/core/lib/models/`)

Models live in the pure-Dart `core` package — import via `package:core/models/…`.
Flutter is physically barred: `core` does not depend on Flutter, and
`dart analyze` inside the package fails on any `package:flutter` / `dart:ui`
import. Anything presentational (colors, icons, localized labels) belongs in
extensions under `lib/shared/constants/*_ui.dart` on the app side.

Every model shares the same shape:

```dart
class Game {
  factory Game.fromJson(Map<String, dynamic> json);  // from an API
  factory Game.fromDb(Map<String, dynamic> row);     // from SQLite
  Map<String, dynamic> toDb();                       // to SQLite
  Game copyWith({String? name, ...});                // immutable update
}
```

Exportable models mix in `Exportable` (`toExport()`).

### Riverpod providers

```dart
// Synchronous state
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

// Asynchronous state
final collectionItemsProvider = AsyncNotifierProvider
    .family<CollectionItemsNotifier, List<CollectionItem>, int>(
  CollectionItemsNotifier.new,
);

// Plain dependency
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
```

### API clients (`lib/core/api/`)

One class per provider, Dio + a Riverpod provider. `IgdbApi` uses Twitch OAuth
(client credentials); `TmdbApi` and `SteamGridDbApi` use bearer tokens. Keys live
in SharedPreferences and are read through `SettingsNotifier`.

### Database

Schema, migrations and DAOs live in `packages/core/lib/database/` (pure Dart).
The app keeps only `lib/core/database/database_service.dart`: initialization,
paths/profiles (`dart:io`) and the Riverpod DAO providers — the seam where DAOs
get swapped for remote stubs on web. Provider: `databaseServiceProvider`.

#### Migrations are the single source of truth

A fresh install and an upgrade build the schema the same way — by replaying the
migration chain. `openAppDatabase` (`packages/core/lib/database/database_opener.dart`)
owns both paths:

- `onCreate` (fresh DB) replays the **whole** chain `MigrationRegistry.all` from 0.
- `onUpgrade` replays `MigrationRegistry.pending(oldVersion)`.

**The target version is `MigrationRegistry.latestVersion`** — derived from the
registry, so adding a migration cannot drift from a hand-maintained number. There
is no `createAll` / "full schema in one block" anywhere; that used to be a second,
hand-synced source and was deleted. Replaying from an empty DB must produce
exactly the schema a really-upgraded DB has —
`test/core/database/migrations/migration_chain_test.dart` asserts it (no gaps in
the registry, replay from zero creates every table, a second replay is a no-op).
There is no golden schema snapshot yet.

`schema.dart` (`DatabaseSchema`) survives only as a set of `create*Table` DDL
helpers called by individual migrations (and by test setup). Those helpers are
**as immutable as the migrations themselves**: you cannot add a column to an
existing `create*Table` — it reflects the table's shape at its creating
migration, and editing it breaks replay.

```
lib/core/database/
└── database_service.dart          # CRUD, init, paths/profiles, DAO providers

packages/core/lib/database/
├── database_opener.dart           # openAppDatabase — onCreate/onUpgrade/onConfigure
├── schema.dart                    # Immutable create*Table DDL helpers
└── migrations/
    ├── migration.dart             # Abstract Migration + addColumnIfAbsent
    ├── migration_registry.dart    # .all (v1..N), .pending(from), .latestVersion
    ├── migration_runner.dart      # Replay + MigrationFailure reporting
    ├── migration_v1.dart          # Base schema — start of the chain
    └── migration_vN.dart          # One file per version (currently up to v60)
```

#### ⚠️ CARDINAL RULE: existing migrations are IMMUTABLE

**Never edit an existing migration — only append a new one.** Each migration is
a historical fact; editing it changes the replay result and diverges from DBs
already installed in the wild. This covers the SQL inside `migrate()` and any
DDL it inlines. Changing the schema means a **new** migration.

To add a schema change:

- Create `packages/core/lib/database/migrations/migration_vN.dart` with
  `class MigrationVN extends Migration`; **write DDL inline in `migrate()`**.
  Do not touch existing `create*Table` helpers (see above).
- Register it at the end of `MigrationRegistry.all` (`migration_registry.dart`).
  The version bump is automatic — `latestVersion` reads the registry.
- **New column** → `Migration.addColumnIfAbsent(db, table, column, def)`
  (idempotent), never a bare `ALTER … ADD COLUMN`.
- **Index** → `CREATE [UNIQUE] INDEX IF NOT EXISTS`.
- Run `migration_chain_test` — replay from zero and a repeat replay must pass.
- `database_service.dart` stays CRUD + init only, no CREATE/ALTER.

### Tests

`test/` mirrors `lib/`, with model tests under `test/shared/models/`. Shared
helpers in `test/helpers/`:

- `mocks.dart` — every mock/fake class (single source of truth)
- `builders.dart` — test data factories (`createTestCollection`, `createTestGame`…)
- `fallbacks.dart` — `registerAllFallbacks()` for mocktail
- `pump_app.dart` — `tester.pumpApp(widget, overrides: [...])` for widget tests
- `test_helpers.dart` — barrel export of the above

Conventions:

- Mocks via mocktail, declared only in `mocks.dart`
- Grouping: `group('ClassName', () { group('methodName', () { ... }); });`
- Widget tests use `tester.pumpApp()`, not a hand-rolled `ProviderScope`
- **Test behavior, not visuals** — never assert colors, labels, icons, spacing.
  A test should break when logic breaks, not when design changes.

DAO tests: prefer a real in-memory SQLite over mocks — mocks cannot cover
transactions, UNIQUE conflicts or FK cascades. Build the production schema by
replaying the chain, and mirror `openAppDatabase`'s `onConfigure`, otherwise FK
cascades silently no-op:

```dart
db = await databaseFactory.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    version: MigrationRegistry.all.last.version,
    onCreate: (Database d, int _) async {
      for (final Migration m in MigrationRegistry.all) {
        await m.migrate(d);
      }
    },
    onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
  ),
);
```

`packages/core` also has its own `test/` run by `dart test` from inside the
package (CI runs it as a separate step).

### Navigation

```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (BuildContext context) => const TargetScreen(),
));
```

## Strict Dart typing

Required:

- **Never** `dynamic` — always explicit types
- **Never** `var` in public APIs — explicit types only
- **Always** annotate return types and parameter types
- **Always** `final` for values that never change; `const` wherever possible
- **Never** `!` (null assertion) unless there is no alternative
- **Always** handle nullables through `?.`, `??` or a check

```dart
// GOOD
final String userName = 'John';
const int maxRetries = 3;

Future<List<User>> fetchUsers({required int limit}) async {
  final List<User> users = await _api.getUsers(limit: limit);
  return users;
}

// BAD
var userName = 'John';  // no explicit type
dynamic data;           // dynamic
fetchUsers(limit) {}    // no types
```

## Code style

### Naming

- `UpperCamelCase` — classes, enums, typedefs, extensions
- `lowerCamelCase` — variables, functions, parameters
- `_privateMember` — private members start with `_`
- `SCREAMING_CAPS` — deprecated constants only

### Comments (whole repo)

- **English only.** No Cyrillic in `///`, `//`, `/* */`. The one exception is
  literal values from an external API needed to grep a response (`роман` /
  `повесть` from Fantlab); the prose around them stays English. UI strings live
  in `.arb` — this rule is about comments in code.
- **WHY only, never WHAT.** The name and type already say *what*. A comment
  exists to explain a hidden constraint, a non-obvious invariant, a workaround
  or an algorithm choice.
- **Hard limit: 2 lines** per block, including dartdoc on public API. If it does
  not fit, cut it. Needing more usually means two separate facts: a summary above
  the declaration plus an inline `//` at the point it matters.
- **No file headers.** A file never opens with a "what is this file" block — the
  path and the first declaration already said it. Dartdoc on the first
  declaration (in a file with no imports) is not a header.
- **No banner separators** (`// ==== Foo ====`, `// --- bar ---`).
- **No comment beats a bad comment.** `/// The collection name.` above
  `final String name` — delete it.
- `public_member_api_docs` is off on purpose: a docstring is optional, and
  absence beats duplication.
- Do **not** start a file with `///` without a `library` directive (triggers
  `dangling_library_doc_comments`) — use `//`.

### Error handling

- Custom exception classes
- Always handle errors in try/catch
- Log errors with context

## Definition of done

### 1. Tests

After writing any code:

- Unit tests for each function/method
- Cover every branch (if/else/switch)
- Cover edge cases (empty lists, null, boundaries)
- Cover error handling
- Run `flutter test --coverage --coverage-package='tonkatsu_box|core'`

### 2. Double review

**Round 1 — correctness:** Is the logic right? Are edge cases handled? Any
vulnerabilities? Is the typing strict?

**Round 2 — quality:** Is it readable? Any duplication? Is the performance
sane? Does it match the surrounding style?

### 3. Gates

```bash
flutter analyze --fatal-infos --fatal-warnings  # must match CI
flutter test
dart test  # from packages/core
```

## Forbidden

- `print()` in production code — use the logger
- Hardcoded UI strings — use localization
- Magic numbers — extract constants
- Ignoring lint warnings
- Committing commented-out code
- `setState` in complex widgets — use Riverpod

## Flutter practices

### Widgets

- Split large widgets into small ones
- Use `const` constructors
- Keep styling in `AppColors` / `AppSpacing` / `AppTypography`
- Give list children a `Key`

### Performance

- Avoid rebuilding the whole tree
- Prefer `const` widgets
- Lazy-load long lists (`ListView.builder`)
- Cache expensive computations

### TextField inside a custom container

The global theme sets `filled: true` and a branded `focusedBorder` on every
`TextField`. Nested inside a container that draws its own border, that renders a
double border — turn the decorations off:

```dart
decoration: InputDecoration(
  border: InputBorder.none,
  focusedBorder: InputBorder.none,
  enabledBorder: InputBorder.none,
  filled: false,
),
```

Reference: `InlineTextField` (`lib/features/settings/widgets/inline_text_field.dart`).

### Layout traps (recurring crashes)

1. **A button inside a `Row`.** The theme gives buttons
   `minimumSize: Size(double.infinity, 48)`. As a non-flex child of a `Row` that
   raises "BoxConstraints forces an infinite width" — **only in debug** (an
   assert); release runs silently, so it is easy to miss. Any Material button in
   a `Row` needs either `styleFrom(minimumSize: Size(0, 40))` or an
   `Expanded`/`Flexible` wrapper. Precedents: the welcome tour, the Copy button
   on the error screen.

2. **`AlertDialog` with fixed content.** On a phone, the on-screen keyboard
   squeezes the dialog to ~150px and it overflows vertically. **Always** wrap
   dialog `content` in a `SingleChildScrollView`. Precedent: the mood-grid
   caption template dialog.

3. **A computed width in an offscreen/export view.** If a container's width comes
   from a formula, the formula must mirror the real layout — every padding of
   every child. Better: one source of truth, a "cell + its paddings" constant used
   by both the formula and the layout. Precedent: `MoodGridExportView` (the
   formula assumed `md` gaps, the layout used `xs` paddings).

4. **Tests only catch these with the real theme.** `tester.pumpApp()` wires up
   the actual `AppTheme.darkTheme` (do not remove it) — a plain "renders without
   exception" test (`expect(tester.takeException(), isNull)`) catches classes 1
   and 3. For dialogs and mobile layouts also run at phone size:
   `tester.view.physicalSize = const Size(360, 640)` plus
   `addTearDown(tester.view.reset)`.

### Platform-dependent code

Check the platform through `lib/shared/constants/platform_features.dart`
(`kCanvasEnabled`, `kVgMapsEnabled`, `kScreenshotEnabled`, `kIsMobile`,
`kGamepadSupported`, `kDiscordRpcAvailable`). VGMaps / WebView2 are Windows-only.
Long-press context menus are Android; right-click is Windows.

### Gamepad support (D-pad navigation)

D-pad and the A button are handled globally in `NavigationShell` via
`DirectionalFocusIntent` / `ActivateIntent`. New widgets support the gamepad
automatically **if they are focusable**.

1. **InkWell / Material buttons** — nothing to do (focusable, `ActivateIntent`
   out of the box).
2. **GestureDetector** — not focusable. Wrap it in `Actions` > `Focus`:

   ```dart
   Actions(
     actions: <Type, Action<Intent>>{
       ActivateIntent: CallbackAction<ActivateIntent>(
         onInvoke: (_) { onTap?.call(); return null; },
       ),
     },
     child: Focus(
       focusNode: _focusNode, // dispose it in dispose()!
       child: GestureDetector(onTap: onTap, child: ...),
     ),
   )
   ```

   `Actions` must sit **above** `Focus` — `Actions.invoke` walks up the tree.
3. **A new screen with scrolling/tabs** — add a `GamepadListener` with the
   callbacks it needs (`onScroll`, `onSubTabSwitch`).

Full docs: `docs/GAMEPAD.md`.

## Orientation map

| File | What |
|------|------|
| `lib/core/database/database_service.dart` | CRUD, init, profiles, DAO providers |
| `packages/core/lib/database/database_opener.dart` | `openAppDatabase` — replay, pragmas |
| `packages/core/lib/database/migrations/` | Migrations v1..N + registry + runner |
| `packages/core/lib/database/schema.dart` | Immutable `create*Table` DDL helpers |
| `packages/core/lib/database/dao/` | DAOs — the future RPC boundary for web |
| `packages/core/lib/models/` | All models (`package:core/models/…`) |
| `packages/core/lib/models/collection_item.dart` | The universal collection entry |
| `packages/core/lib/models/canvas_item.dart` | Canvas element (7 types) |
| `lib/features/collections/widgets/canvas_view.dart` | The Board/Canvas widget |
| `lib/features/collections/providers/canvas_provider.dart` | Canvas state |
| `lib/features/collections/providers/collections_provider.dart` | Collections state |
| `lib/shared/theme/app_theme.dart` | Centralized theme (dark Material 3) |
| `test/helpers/test_helpers.dart` | Shared mocks, builders, `pumpApp` |
| `analysis_options.yaml` | Strict lint rules |
| `docs/` | ARCHITECTURE, CODESTYLE, COMMITS, GAMEPAD, RCOLL_FORMAT… |

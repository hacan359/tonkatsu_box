# Tonkatsu Box Coding Standards

Mandatory rules for all code in the Tonkatsu Box project. This document is the single source of truth.

---

## Analyzer

Maximum strictness. Code must produce zero warnings/infos:

- strict-casts: true
- strict-inference: true
- strict-raw-types: true
- always_specify_types: true
- avoid_print: true (print is forbidden, use _log)
- require_trailing_commas: true
- prefer_single_quotes: true

---

## Project Structure

    lib/
      main.dart                  # Entry point
      app.dart                   # Root widget
      core/                      # Core layer (does not depend on features)
        api/                     #   API clients (Dio)
        database/                #   DatabaseService, schema, migrations
          dao/                   #     Domain-specific DAO classes
          migrations/            #     Individual migration files
        logging/                 #   AppLogger
        services/                #   Export, Import, ImageCache, Config
      data/                      # Repositories (bridge core <-> features)
        repositories/
      features/                  # Features (screens, providers, widgets)
      l10n/                      # Localization (ARB, gen_l10n)
      shared/                    # Shared models, widgets, theme

Dependency direction: features -> data -> core -> shared. Features do not import each other (except for navigation).

---

## Naming

- Files: snake_case.dart
- Classes: PascalCase
- Enums: PascalCase, values camelCase
- Providers: camelCaseProvider (suffix Provider)
- Private fields: _camelCase
- Constants: camelCase (Dart style, not UPPER_SNAKE)

---

## File Size Limits

- Hard limit: no file exceeds 800 lines. If it does, split it.
- Soft target: aim for under 400 lines.
- Screens: past 500 lines, extract widgets into separate files in the same widgets/ directory.
- Providers: past 400 lines, decompose into sub-providers or extract helper classes.

When splitting, extract into the same feature directory rather than creating new directories.

---

## State Management (Riverpod)

Provider types must be explicit in declarations. Use ref.watch() in build(), ref.read() in action methods.

---

## Data Models

Immutable classes with factory constructors. Order within model class:
1. const constructor
2. Factory constructors (fromJson, fromDb)
3. Fields (final)
4. Getters / computed properties
5. Methods (toDb, toJson, copyWith)

---

## Database Layer

### DAO Pattern

Database operations are organized into domain-specific DAO classes. Each DAO receives a database accessor function.

DAOs live in lib/core/database/dao/. DatabaseService exposes DAO instances via late final fields and delegates all public methods to them, preserving the existing API for consumers.

Available DAOs:
- GameDao: games, platforms, IGDB genres
- MovieDao: movies, TMDB genres
- TvShowDao: TV shows, seasons, episodes, watched episodes
- CollectionDao: collections, collection items
- CanvasDao: canvas items, connections, viewports
- WishlistDao: wishlist items
- VisualNovelDao: visual novels, VNDB tags

When adding new database methods: add to the appropriate DAO, then add a one-line delegate in DatabaseService.

### Migrations

Each migration is a separate file in lib/core/database/migrations/.

Procedure (where N is the next version number):
1. Create migration_vN.dart
2. Add MigrationVN() to MigrationRegistry.all
3. Update version: N in _initDatabase()
4. New table needed? Add method to DatabaseSchema, call from createAll()

---

## Logging

print() and debugPrint() are forbidden. Use package:logging.
Initialize: AppLogger.init() in main() before runApp().
Logs output via dart:developer log() (visible in Flutter DevTools).

Levels:
- _log.fine()    Debug details, noisy
- _log.info()    Important lifecycle events
- _log.warning() Non-breaking errors
- _log.severe()  Critical errors

Logger placement: static _log field goes first in the class body. Logger name = class name.

Required in: all classes in lib/core/, all repositories, all Notifier/AsyncNotifier.
Not needed in: models, static utilities, widgets (except debug screens).

---

## Error Handling

### Typed Exceptions

API clients throw domain-specific exceptions: TmdbApiException, IgdbApiException, VndbApiException, SteamGridDbApiException.

### Layer Responsibilities

- API clients: throw typed exceptions
- Repositories: catch API exceptions, return null/empty or rethrow
- Providers: handle errors through Riverpod AsyncValue.error state
- UI: display errors via AsyncValue.when(error: ...) never crash on error

### Catch Block Rules

Forbidden to write catch (_) without logging. Every catch must either:
- Log the error: _log.warning(description, e)
- Rethrow: rethrow
- Have a comment explaining why the error is intentionally ignored

---

## Documentation

- Doc comments (///) in Russian
- Required on all public classes and methods
- Required on private methods if logic is non-obvious
- DO NOT place /// at file top without library directive (triggers dangling_library_doc_comments), use // instead

---

## Imports

Group order (separated by blank lines):
1. dart: standard library
2. package: external packages
3. Relative project imports

---

## Testing

### Shared Test Helpers

All tests use shared helpers from test/helpers/. One import covers everything:

    import xx/helpers/test_helpers.dart

Contents:
- mocks.dart: all mock/fake classes (single source of truth)
- builders.dart: test data factories (createTestCollection, createTestCollections, createTestStats, createTestCollectionItem, createTestGame, createTestMovie, createTestTvShow, createTestVisualNovel, createTestWishlistItem, createTestCanvasItem, createTestCanvasConnection)
- fallbacks.dart: registerAllFallbacks() for mocktail
- pump_app.dart: tester.pumpApp(widget, overrides: [...]) for widget tests
- test_helpers.dart: barrel export of all above

### Mock Rules

- DO NOT declare mock classes in test files if they exist in test/helpers/mocks.dart
- DO NOT write registerFallbackValue() inline, use registerAllFallbacks() in setUpAll()
- DO NOT construct test data manually, use builders from builders.dart
- DO NOT write ProviderScope + MaterialApp + localizationsDelegates manually, use tester.pumpApp()
- New mock needed in 2+ files? Add to mocks.dart
- New builder needed in 2+ files? Add to builders.dart
- Mock/builder unique to one file? OK to declare locally

### Test Behavior, Not Visuals

Tests should break only when behavior breaks, not when design changes.

DO TEST:
- Method returns correct value for given input
- State changes after actions (status updated, item added/removed)
- Error handling (exception thrown, error state set)
- Async flows (loading -> data, loading -> error)
- Navigation triggers (screen pushes on tap)
- Conditional rendering (widget shown/hidden based on state)
- Callbacks fire correctly (onTap called, onChanged called with value)
- Data transformations (model parsing, JSON mapping, filtering, sorting)
- Lists render correct number of items

DO NOT TEST:
- Button labels and text content (cosmetic)
- Colors (design decision)
- Font sizes, weights, styles (typography)
- Icon types (cosmetic)
- Padding, margins, spacing (layout)
- Border radius, shadows, decorations (visual styling)
- Localized string values (test that text IS displayed, not WHAT exact string)

Data-driven text IS behavior (testing that collection.name renders is OK; testing that screen title says Collections is NOT OK).

### Test Naming

    should [expected result] when [condition]

### Coverage

- Target: 100% line and branch coverage
- In-memory SQLite (sqflite_common_ffi, inMemoryDatabasePath) for database tests
- Mirror lib/ structure in test/

---

## Widget Guidelines

### Theme Constants

Always use theme constants, never hardcode (AppColors, AppTypography, AppSpacing).

### Construction

- Use const constructors wherever possible
- Use Key for list items: ValueKey<int>(item.id)
- Prefer ListView.builder / GridView.builder for long lists
- Split widgets exceeding ~200 lines into sub-widgets or separate files

### TextField in Custom Containers

Global theme sets filled: true + focusedBorder: brand. If TextField is inside a container with its own border, disable decorations to avoid double borders.

### Platform-Specific Code

- Check platform via platform_features.dart (kCanvasEnabled, kVgMapsEnabled)
- VGMaps / WebView2: Windows only
- Long press context menu: Android, right-click: Windows
- Gamepad: new interactive widgets must be focusable (see docs/GAMEPAD.md)

---

## Forbidden

- print() in production code, use logger
- Hardcoded UI strings, use localization
- Magic numbers, extract to constants
- Ignoring lint warnings
- Committing commented-out code
- setState in complex widgets, use Riverpod
- dynamic type, always explicit types
- var for public API, only explicit types
- ! (null assertion) without extreme necessity
- Silent catch blocks without logging or comment
- Declaring mock classes in test files when they exist in test/helpers/mocks.dart
- Testing visual details (colors, labels, icons, spacing) in unit/widget tests
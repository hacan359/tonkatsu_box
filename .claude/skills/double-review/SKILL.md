---
name: double-review
description: Two-stage code review with improvements and optimizations. Use before finishing any task.
---

# Double Code Review

## Round 1: Functionality and Correctness

### Checklist:

#### Logic
- [ ] Does the code do what is required?
- [ ] Are all edge cases handled?
- [ ] No logical errors?
- [ ] Is the algorithm correct?

#### Typing
- [ ] No `dynamic`?
- [ ] No implicit types in public API?
- [ ] Nullable types handled correctly?
- [ ] `final`/`const` used where possible?

#### Error Handling
- [ ] All exceptions caught?
- [ ] Errors logged with context?
- [ ] User receives clear messages?
- [ ] No silent failures?

#### Security
- [ ] No SQL/XSS injections?
- [ ] Input data is validated?
- [ ] Sensitive data is not logged?
- [ ] No hardcoded secrets?

#### Cross-Platform Compatibility
- [ ] No hardcoded Windows paths (`C:\`, `AppData`, backslashes)?
- [ ] File paths use `package:path` (`p.join()`) instead of string concatenation?
- [ ] `Platform.isWindows` / `Platform.isAndroid` checks have correct fallthrough for all supported platforms (Windows, Linux, Android)?
- [ ] Windows-only plugins (`webview_windows`) are guarded by `kVgMapsEnabled` or `Platform.isWindows` — never instantiated on other platforms?
- [ ] Non-federated plugin imports don't cause compilation failures on other platforms?
- [ ] SQLite initialization covers all desktop platforms (`Platform.isWindows || Platform.isLinux || Platform.isMacOS`)?
- [ ] File picker logic correctly distinguishes mobile (`Platform.isAndroid || Platform.isIOS`) from desktop (Windows + Linux + macOS)?
- [ ] Native runner files (window title, binary name, application ID) are consistent across platforms?
- [ ] CI workflows include `--dart-define` secrets for ALL platform build jobs (Windows, Android, Linux)?
- [ ] Generated scaffolding (`flutter create`) values match project identity (not default package name)?

#### New Media Type / Enum Value Propagation
When adding a new `MediaType`, `CanvasItemType`, or similar enum value, check ALL of these:
- [ ] `CanvasItemType` enum — new value added, `fromMediaType()` maps correctly, `isMediaItem` includes it?
- [ ] `CanvasItem` model — new joined field (e.g. `final VisualNovel? visualNovel`), `copyWith`, and ALL unified accessors (`mediaTitle`, `mediaThumbnailUrl`, `mediaImageType`, `mediaCacheId`, `mediaPlaceholderIcon`, `asMediaType`)?
- [ ] `canvas_repository.dart` `_enrichItemsWithMediaData()` — new IDs collected, DB query added to `Future.wait`, new map built, switch case added?
- [ ] `canvas_repository.dart` `initializeCanvas()` — new field passed in `copyWith` when creating items?
- [ ] `canvas_view.dart` — ALL `switch (item.itemType)` statements updated (edit, build, width, height, fallback label)?
- [ ] `all_items_screen.dart` `_buildChipsRow()` — filter chip added for new type with localization key (`allItems*`)?
- [ ] `collection_screen.dart` — filter dropdown entry added with count from `CollectionStats`?
- [ ] `CollectionStats` — new count field added, computed in `database_service.dart`?
- [ ] `collections_provider.dart` — `collectedXxxIdsProvider` added for search in-collection markers?
- [ ] `browse_grid.dart` — new IDs wired into `_collectedIdsProvider`?
- [ ] Localization keys added: `unknown*`, `allItems*`, `collectionFilter*`, `mediaType*`, `searchSource*`?
- [ ] `export_service.dart` / `import_service.dart` — new media section handled in both directions?

**Tip:** Run `flutter analyze` immediately after adding a new enum value — exhaustive switch errors will reveal most missing locations.

### Actions After Round 1:
1. Fix all found issues
2. Ensure tests pass
3. Proceed to Round 2

---

## Round 2: Quality and Performance

### Checklist:

#### Readability
- [ ] Variable names are clear and descriptive?
- [ ] Functions are not too long (< 30 lines)?
- [ ] Classes have a single responsibility?
- [ ] Code is self-documenting?
- [ ] Complex logic is commented?

#### Duplication
- [ ] No copy-paste code?
- [ ] Shared logic extracted into utilities?
- [ ] No repeated magic values?

#### Performance
- [ ] No O(n²) where O(n) is possible?
- [ ] No unnecessary object recreation?
- [ ] Heavy computations are cached?
- [ ] No memory leaks (subscriptions, controllers)?

#### Flutter Specifics
- [ ] Widgets use `const` constructors?
- [ ] No unnecessary rebuilds?
- [ ] Lists use `ListView.builder`?
- [ ] `dispose()` called for controllers?

#### Code Style
- [ ] Follows Dart style guide?
- [ ] `flutter analyze` has no warnings?
- [ ] Imports organized (dart, package, relative)?

### Actions After Round 2:
1. Apply all optimizations
2. Ensure tests still pass
3. Run `flutter analyze`
4. Proceed to Round 3

---

## Round 3: Localization Completeness

### Checklist:

#### No Hardcoded UI Strings
- [ ] No user-visible string literals in `lib/` (buttons, labels, titles, tooltips, hints, error messages, empty states, dialog text)?
- [ ] Every UI string uses `S.of(context).key` or `l.key` (where `final S l = S.of(context);`)?
- [ ] Enum display labels use localized extension methods (`localizedLabel(S l, ...)`) instead of hardcoded `displayLabel`?
- [ ] SnackBar messages use localized strings?
- [ ] AlertDialog titles, content, and action labels are localized?

#### ARB File Consistency
- [ ] Every key used in code exists in both `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb`?
- [ ] No orphan keys in ARB files (keys that exist in ARB but are never used in code)?
- [ ] Placeholder parameters (`{name}`, `{count}`, `{error}`) match between EN and RU?
- [ ] Russian plurals use correct ICU forms (`=0`, `=1`, `few`, `other`) where applicable?

#### Context-Aware Labels
- [ ] Status labels adapt to media type (e.g., "Playing" for games vs "Watching" for movies/TV)?
- [ ] Media type labels are localized via `MediaType.localizedLabel(S l)`?
- [ ] Sort mode labels use `localizedDisplayLabel(S l)` / `localizedShortLabel(S l)`?

#### Exceptions (Allowed Without Localization)
- [ ] Debug screens (`*_debug_screen.dart`) — technical labels (API field names, JSON keys) may stay in English
- [ ] Log messages and `debugPrint` — not user-facing, English is OK
- [ ] Model field names, enum `.name`, serialization values — internal, not displayed
- [ ] Test assertions — string matchers may use English (they match against EN locale)

### How to Check:

```bash
# Search for suspicious string literals in UI code (excluding imports, comments, keys):
grep -rn "Text(\s*'" lib/features/ lib/shared/widgets/ --include="*.dart" | grep -v "import\|//\|test\|\.arb"

# Search for displayLabel calls that should be localizedLabel:
grep -rn "\.displayLabel" lib/ --include="*.dart"

# Verify ARB key count matches:
grep -c '"@' lib/l10n/app_en.arb lib/l10n/app_ru.arb
```

### Actions After Round 3:
1. Add missing keys to both ARB files (EN and RU)
2. Replace hardcoded strings with `S.of(context).key`
3. Run `flutter gen-l10n` if ARB files changed
4. Run `flutter analyze` and `flutter test`
5. Task is ready to commit

---

## Report Format

After each round, provide a report:

```
## Review Round [1/2/3]

### Issues Found:
1. [Critical] Issue description
   - File: path/to/file.dart:123
   - Fix: ...

2. [Important] Issue description
   - File: path/to/file.dart:45
   - Fix: ...

3. [Suggestion] Improvement description
   - File: path/to/file.dart:78
   - Suggestion: ...

### Fixed in This Round:
- Fix 1
- Fix 2

### Status: [Proceeding to Round 2 / Proceeding to Round 3 / Ready to commit]
```

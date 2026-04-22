---
name: finish
description: End-of-task pipeline — simplify review, double review, tests, single analyze+test gate, changelog/docs. Use when you've finished implementing a task and want to harden it before committing. Does NOT commit or push; the user must ask explicitly.
---

# Finish Pipeline

Run this **once** at the end of a task. The pipeline merges the old simplify / double-review / full-coverage-tests / changelog-docs skills into a single flow with a **single** analyze+test gate at the end.

## Ground rules

- Collect the diff once at Phase 0; reuse it across phases.
- Do NOT run `flutter analyze` or `flutter test` between phases — only Phase 5 runs them.
- Do NOT commit or push unless the user explicitly asks.
- Do NOT create new `.md` files unless the user explicitly asks.
- Fix findings inline within the phase that surfaced them; don't park lists of "TODO later".

## Phases

### Phase 0 — Snapshot

```bash
git status --short
git diff HEAD
```

Enumerate changed files once. If the diff is empty, stop with "nothing to finalise".

### Phase 1 — Simplify

Review new/changed code from three independent angles. **This phase is self-contained — do not delegate to a built-in `/simplify` skill, which may not exist in every Claude Code version.** Run the review yourself using these three lenses:

1. **Reuse**
   - Search the codebase for existing utilities, DAO methods, helpers, or constants that could replace newly written code. Common locations: `lib/shared/`, sibling files of the changed file, existing DAOs.
   - Flag new functions that duplicate existing functionality.
   - Flag inline logic that could use an existing helper (string manipulation, path handling, type guards, platform checks).

2. **Quality**
   - Redundant state, cached values that could be derived.
   - Parameter sprawl (adding N-th param instead of restructuring).
   - Copy-paste with slight variation → unify with shared abstraction.
   - Leaky abstractions, stringly-typed code where enums/consts exist.
   - Unnecessary wrapper widgets/Boxes that add no layout value.
   - Nested conditionals 3+ levels (flatten with early returns, lookup tables, if/else-if cascade).
   - Unnecessary comments explaining WHAT (delete; keep only WHY for hidden constraints, subtle invariants, workarounds).

3. **Efficiency**
   - Redundant computations, duplicate network/DB calls, N+1 patterns.
   - Missed concurrency: independent `await`s in sequence → `Future.wait`.
   - Hot-path bloat (startup, per-render, per-request).
   - No-op store updates in polling loops / event handlers (add change-detection guard).
   - TOCTOU anti-pattern (pre-checking existence then operating) → operate directly and handle the error.
   - Unbounded data structures, missing cleanup, event listener leaks.
   - Reading whole files when a slice is enough.

**For large diffs** (≥5 changed files or ≥300 lines), dispatch the three angles as parallel `Agent` sub-tasks (`subagent_type: Explore`) in a single message — each agent gets the full diff and reports its findings in ≤300 words. Then aggregate and fix. On small diffs, review all three angles yourself inline.

Fix actionable issues. Skip false positives — don't argue, just move on. Out-of-scope issues (pre-existing cruft in untouched files) get noted in the final report, not fixed here.

### Phase 2 — Double review

**R1 — correctness**
- Logic, edge cases, strict typing (no `dynamic`, no `var` in public API, `final` / `const` where possible, nullable handled via `?.` / `??` / checks).
- Error handling (no silent failures).
- **SharedPreferences per-profile rule**: user-specific keys MUST be suffixed with `'${profileId}'` read via a getter (not cached in a field — profile can change). Global keys (API creds, theme, language) are the exception.
- **Cross-platform**: no hardcoded Windows paths, `package:path` for joins, `Platform.isX` branches fall through for all supported OS (Windows + Linux + Android), Windows-only plugins (`webview_windows`) gated by `kVgMapsEnabled`.
- **New enum value propagation** (only if the change adds a `MediaType` / `CanvasItemType` value): run `flutter analyze` to surface exhaustive-switch errors across `canvas_view.dart`, `all_items_screen.dart`, `collection_screen.dart`, `export_service.dart`, `import_service.dart`, plus filter chips, `CollectionStats` counts, `collectedXxxIdsProvider`, and all localisation keys (`unknown*`, `allItems*`, `collectionFilter*`, `mediaType*`, `searchSource*`).

**R2 — quality and performance**
- Readability (function size, single responsibility, self-documenting names).
- Duplication (shared logic extracted).
- Memory / leaks (subscriptions cancelled, controllers disposed).
- Flutter specifics (`const` widgets, `ListView.builder` for long lists, no object creation in `build()`).

**R3 — localisation**
- Every UI string uses `S.of(context).key` or `final S l = S.of(context);`.
- ARB: every key exists in both `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb`; placeholder names match; Russian plurals use ICU `=0` / `=1` / `few` / `other`.
- Enum labels via `localizedLabel(S l)` extensions, not raw `.displayLabel`.
- Status labels adapt to media type (Playing for games, Watching for movies/TV).
- Allowed English: debug screens, `debugPrint`, model field names, enum `.name`, test assertions.

### Phase 3 — Tests for new code

**Goal: useful tests, not coverage theatre.** 100% line/branch coverage is *not* the target. Aim for tests that break only when real behaviour breaks — and that would catch a future regression you'd actually care about.

Every test must pull its weight in one of three buckets:

**1. UI doesn't silently break**
   - Widget renders without exceptions (`expect(tester.takeException(), isNull)`).
   - Critical flows work: tap handlers fire the right callback, navigation happens, conditional widgets show/hide on state change, lists render the right item count.
   - **Do NOT test** colours, text labels, icons, font sizes, padding, border radius, widget types used purely for styling (e.g. `find.byType(Container)`). Design changes must not break tests. Localised string values — same rule: assert that *some* text appears, not that it equals a specific string.
   - Data-driven text that flows from model → UI is fair game (`expect(find.text(collection.name), findsOneWidget)` is OK; `expect(find.text('Collections'), findsOneWidget)` for a static title is not).

**2. Logic is verified reliably**
   - For every public method / function: happy path + each meaningful branch (if/else, switch cases, early returns, error paths).
   - Edge cases the change actually cares about: empty input, null, boundaries, concurrent-state races where relevant. Skip defensive null-guards that can't trigger in practice.
   - Model serialisation round-trips (`fromJson`/`toJson`, `fromDb`/`toDb`) when the change touches models.
   - `copyWith` semantics when a new field is added.

**3. Method calls at the boundary are verified**
   - When the change orchestrates multiple collaborators (DAO, repository, API client, provider), use `verify(() => mock.method(args)).called(N)` to pin down that the right method was called with the right args, the right number of times.
   - Use `verifyNever` to assert negative-space guarantees (e.g. "no tag remap when sourceTagId is null").
   - Use `captureAny()` to inspect complex payloads (e.g. "the cloned row has `tag_id: null`").

**Infrastructure rules (non-negotiable):**
- `import '../../helpers/test_helpers.dart'` — reuse mocks from `test/helpers/mocks.dart`, builders from `builders.dart`, fallbacks via `registerAllFallbacks()` in `setUpAll`.
- Mock/builder will be used in ≥2 files → add it to helpers. Unique to one test → declare locally.
- Widget tests use `tester.pumpApp()`, not a hand-rolled `ProviderScope` + `MaterialApp`.
- Naming: `should [expected result] when [condition]`.

**Self-check before finishing a test:** *"If someone changed the design tomorrow (colours, labels, layout) — would this test fail?"* If yes, and the change wasn't a logic change, the test is overfitted. Remove or relax it.

### Phase 4 — Changelog + docs

**CHANGELOG.md** (`[Unreleased]` section, Keep a Changelog format):
- English entries, past-tense verbs (Added / Changed / Fixed / Removed).
- Mention specific files/classes/methods changed.
- **Unreleased consolidation**: when enhancing or fixing something already in `[Unreleased]` that was never released, update the existing entry in place — don't add a separate Fixed/Changed bullet. Users should see the final state, not the development history.

**docs/** — update only if the change actually affects them:

| File | When to touch |
|------|---------------|
| `ARCHITECTURE.md` | New layer, major module, or shift in patterns. Keep it a high-level map — do NOT add per-file tables or SQL schema dumps |
| `ROADMAP.md` | Tick off completed items, add new plans |
| `CONTRIBUTING.md` | Changes to development process |
| `CODESTYLE.md` | New lint rules, typing conventions |
| `COMMITS.md` | Changes to commit conventions |
| `RCOLL_FORMAT.md` | Changes to `.xcoll` / `.xcollx` export format |
| `GAMEPAD.md` | New focusable widgets, navigation rules |
| `SNACKBAR.md` | Changes to `context.showSnack()` API or types |

Language per file: most are Russian; ROADMAP.md is English. Keep each in its current language. Preserve formatting — make targeted edits, don't rewrite.

### Phase 5 — Gate (single run)

```bash
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter analyze --fatal-infos --fatal-warnings"
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter test"
```

Follow the failure-recovery rules below. When green, STOP — report what changed and wait for an explicit commit/push instruction.

## Failure recovery

| Failure | Response |
|---------|----------|
| **Analyzer fails** | Fix inline. Re-run analyzer only. Do not re-do earlier phases. |
| **Test fails — a test I just wrote** | Fix the test (wrong mock stub, missing fallback, wrong assertion). Re-run tests only. |
| **Test fails — existing test** | **Default: the test is right, the production code is wrong.** Do not edit the test yet. First, re-read the test and the code paths it covers. Ask: *"Was this specific behaviour something I deliberately changed as part of the task?"* Answer this honestly before touching anything. **→ If NO** (surprise failure, behaviour change you didn't plan): back to **Phase 1** — the code is wrong, fix the code, then Phase 3 for the affected area, then re-gate. **→ If YES** (the old assertion contradicts the intended new behaviour, and the new behaviour is in the spec/user request): update the test, rerun tests. Document the behaviour change in the final report so the user sees what shifted. **If unsure, default to NO.** |
| **Review (Phase 1-2) needs a code change** | Fix inline. If the fix touches production code (not just comments/docstrings), add/update tests in Phase 3 before re-gating. |
| **R3 reveals missing ARB keys** | Add keys to both `app_en.arb` and `app_ru.arb`, run `powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter gen-l10n"`, re-run analyzer. |
| **Flaky test** | Retry the affected test file once via `flutter test path/to/test.dart`. If it still fails, treat it as real. |

**Anti-loop rule** — if the same error has been attempted twice with different fixes and still fails, STOP and report to the user. Do not keep hacking.

**Scope creep** — unrelated issues discovered during review (pre-existing bugs, cruft in untouched files) are NOT fixed here. Note them in the final report; user decides.

## Report format

One line per phase as it completes, e.g.:

```
Phase 1 simplify: 2 fixes (removed redundant setItemTag write, inlined unused helper).
Phase 2 R1 critical fix: SQLite LOWER() doesn't handle Cyrillic → switched to Dart toLowerCase. R2/R3 clean.
Phase 3 tests: 20 new tests across 3 files, all green.
Phase 4 changelog: 1 Changed entry; no docs/ touched.
Phase 5 gate: analyze clean, 4776 tests passed.
Status: ready for commit. Awaiting explicit /commit.
```

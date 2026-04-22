---
name: changelog-docs
description: Documents changes in CHANGELOG.md and updates docs/. Run last, after completing work, tests, and review.
---

# Documenting Changes and Updating Documentation

Run **last**, after all work, tests, and review are complete.

## Execution Order

### 1. Collect Changes

Identify all changes in the current session:
```bash
git diff --name-status HEAD
git diff --stat HEAD
```

If changes are already committed (branch differs from main):
```bash
git log main..HEAD --oneline
git diff --name-status main..HEAD
```

### 2. Update CHANGELOG.md

File `CHANGELOG.md` in the project root. Format: [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

## [Unreleased]

### Added
- New features and files

### Changed
- Changes to existing code

### Fixed
- Bug fixes

### Removed
- Deleted files and functions
```

**Rules:**
- Entries in English
- Each entry starts with a past-tense verb: "Added", "Changed", "Fixed", "Removed"
- Mention specific files/classes/methods
- Group related changes together
- Do not include intermediate fixes (lint fix, test fix) — only the final result
- If CHANGELOG.md doesn't exist — create it with a header and [Unreleased] section

**Unreleased consolidation rule:**
- `[Unreleased]` describes the **cumulative difference** between the last release and the current state
- When enhancing, fixing, or changing something that is already in `[Unreleased]` and was **never released** — update the existing entry in place, do NOT create a separate Fixed/Changed entry
- Separate "Fixed" and "Changed" entries are only for things that were broken/different in a **released** version (i.e., users actually experienced the old behavior)
- Example: if `[Unreleased]` says "Added Steam import" and you later add collection selector to it — rewrite the Added entry to include the selector, don't add a new entry
- Think of it as: when a user reads the release notes, they should see the final state of each feature, not the development history

### 3. Update docs/

Check each file in `docs/` against the current state of the code:

| File | What to check |
|------|--------------|
| `ARCHITECTURE.md` | New architectural layers, patterns, or major modules. Do NOT list individual files/methods — keep it a high-level map |
| `ROADMAP.md` | Mark completed items, add new plans |
| `CONTRIBUTING.md` | Changes to development process |
| `CODESTYLE.md` | New lint rules, typing conventions |
| `COMMITS.md` | Changes to commit conventions |
| `RCOLL_FORMAT.md` | Changes to export/import format (`.xcoll` / `.xcollx`) |
| `GAMEPAD.md` | New focusable widgets, navigation rules |
| `SNACKBAR.md` | Changes to `context.showSnack()` API or types |

**Update rules:**
- Only add what actually changed
- Preserve existing style and formatting of the document
- Don't rewrite the entire file — make targeted edits
- Documentation language: match the existing doc (most are Russian; `ROADMAP.md` is English — keep each file in its current language)
- If a file is not affected by changes — don't touch it
- Do NOT create new `.md` files unless the user explicitly asks (keep docs/ lean)

### 4. Verification

```bash
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter analyze --fatal-infos --fatal-warnings"
powershell.exe -Command "cd '$(wslpath -w "$PWD")'; flutter test"
```

## Checklist Before Finishing

- [ ] CHANGELOG.md is up to date
- [ ] docs/ touched only if the change actually affects them (ARCHITECTURE, ROADMAP, RCOLL_FORMAT, GAMEPAD, SNACKBAR, CODESTYLE, CONTRIBUTING, COMMITS)
- [ ] `flutter analyze --fatal-infos --fatal-warnings` passes
- [ ] `flutter test` — all tests pass

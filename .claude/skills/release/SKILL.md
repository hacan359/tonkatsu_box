---
name: release
description: Automates the full release process — analyzes changes, suggests version, updates CHANGELOG and pubspec.yaml, commits, tags, and pushes.
---

# Release Process

Automates everything from changelog update to git tag push.

**Prerequisites:**
- Working tree must be clean (`git status` shows no changes)
- You should be on the branch you want to release from (usually `main`)
- All changes should already be pushed and CI should be green

---

## Step 1: Preflight Checks

Verify the working tree is clean and we're on the right branch:

```bash
git status --porcelain
git branch --show-current
```

If working tree is not clean, **STOP** and tell the user to commit or stash changes first.

---

## Step 2: Analyze Changes Since Last Release

Find the last release tag and show what changed:

```bash
# Last release tag (empty if first release)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
  echo "Last release: $LAST_TAG"
  echo ""
  echo "=== Commits since $LAST_TAG ==="
  git log "${LAST_TAG}..HEAD" --oneline
  echo ""
  echo "=== Stats ==="
  git diff --stat "${LAST_TAG}..HEAD"
else
  echo "No previous releases found. This will be the first release."
  echo ""
  echo "=== All commits ==="
  git log --oneline -20
fi
```

---

## Step 3: Read CHANGELOG [Unreleased]

Read `CHANGELOG.md` and extract the `[Unreleased]` section to understand what's being released.

Show the content to the user as a summary of what will be in the release notes.

If the `[Unreleased]` section is empty, **STOP** and tell the user there's nothing to release — they should update the CHANGELOG first (use `/changelog-docs` skill).

---

## Step 4: Determine Version

Read current version from `pubspec.yaml`:

```bash
grep '^version:' pubspec.yaml
```

Calculate next build number:

```bash
TAG_COUNT=$(git tag --list 'v*' | wc -l)
NEXT_BUILD=$((TAG_COUNT + 1))
echo "Next build number: +${NEXT_BUILD}"
```

**SemVer rules (pre-1.0):**
- `patch` (0.9.0 → 0.9.1): bug fixes, small improvements, minor tweaks
- `minor` (0.9.0 → 0.10.0): new features, significant additions
- `major` (0.9.0 → 1.0.0): stable release, breaking public API changes

Analyze the [Unreleased] content and suggest a version bump type with reasoning.

**Ask the user** using AskUserQuestion with options:
- Option 1: Suggested version (with reasoning)
- Option 2: Alternative version
- Option 3: Other (user types custom version)

Wait for user confirmation before proceeding.

---

## Step 5: Update CHANGELOG.md

After user confirms version `X.Y.Z`:

1. Get today's date (format: YYYY-MM-DD)
2. In `CHANGELOG.md`, find the line `## [Unreleased]`
3. Insert a blank line after it, then add `## [X.Y.Z] - YYYY-MM-DD`
4. All existing content between `## [Unreleased]` and the new version header stays under the version header
5. The `## [Unreleased]` section should be left empty (no subsection headers)

Result should look like:

```markdown
## [Unreleased]

## [0.9.0] - 2026-02-19

### Added
- ...

### Changed
- ...
```

Use the Edit tool to make the changes precisely.

---

## Step 6: Bump Version in pubspec.yaml

Update the `version:` line in `pubspec.yaml`:

```
version: X.Y.Z+N
```

Where `N` is the build number calculated in Step 4.

Use the Edit tool to make the change.

---

## Step 6.5: Update Version on Landing Page

Update the version in `docs/index.html` in two places:

1. **Hero badge** — find `<span>vOLD</span>` and replace with `<span>vX.Y.Z</span>`
2. **JSON-LD structured data** — find `"softwareVersion": "OLD"` and replace with `"softwareVersion": "X.Y.Z"`

Use the Edit tool to make both changes.

---

## Step 7: Generate Release Notes

Create **user-facing release notes** in English from the CHANGELOG `[X.Y.Z]` section. These notes will be used as the annotated tag message and will appear on the GitHub Release page.

**Rules:**
- Language: English only
- Strip all file names, class names, and technical details (no `steam_import_service.dart`, no `collectionStatsProvider`)
- Rewrite each entry as a short, clear sentence a user would understand
- Group into: `## What's New`, `## Improvements`, `## Bug Fixes` (skip empty groups)
- Use bullet points, no bold prefixes
- Keep it concise: 1 line per feature, max 2 sentences for complex features
- Add a footer: `**Full Changelog**: https://github.com/hacan359/tonkatsu_box/compare/vPREV...vX.Y.Z`

**Example transformation:**

CHANGELOG (technical):
```
### Added
- **Steam Library import** — new `SteamApi` client (`steam_api.dart`) fetches user's owned games via Steam Web API. `SteamImportService` orchestrates the full import pipeline: fetch library → filter DLC/soundtracks → match each game to IGDB → add to collection. Target collection selector...
```

Release notes (user-facing):
```
## What's New
- Import your Steam game library — games are automatically matched to IGDB with playtime tracking. Choose to create a new collection or add to an existing one.
```

**Show the generated release notes to the user** and ask for confirmation before proceeding.

Save the release notes text for use in Step 8.

---

## Step 8: Commit, Tag, Push

```bash
# Stage the changed files
git add pubspec.yaml CHANGELOG.md docs/index.html

# Create commit
git commit -m "release: vX.Y.Z"

# Create annotated tag with release notes (use HEREDOC for multiline)
git tag -a "vX.Y.Z" -m "$(cat <<'EOF'
Release vX.Y.Z

<paste release notes here>
EOF
)"

# Push commit and tag
git push origin HEAD
git push origin "vX.Y.Z"
```

---

## Step 9: Report

Tell the user:
- Commit created with hash
- Tag `vX.Y.Z` pushed
- GitHub Actions release workflow is now running
- It will: run quality gate → build Windows + Android → create GitHub Release with artifacts
- They can monitor progress at the repository's Actions tab

---

## Important Notes

- **Never skip** the user confirmation step (Step 4)
- **Never run** this skill if the working tree is dirty
- If the quality-gate fails in CI after push, the release artifacts won't be built — the user should fix issues and create a new patch release
- The skill does NOT run `flutter analyze` or `flutter test` locally — CI handles that
- Build number is sequential: count of existing `v*` tags + 1

[← Back to Contributing](CONTRIBUTING.md)

# Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

## Format

```
type(scope): description
```

## Types

| Type | When to use |
|------|-------------|
| `feat` | New feature for the user |
| `fix` | Bug fix |
| `refactor` | Code change without behavior change |
| `chore` | Build, dependencies, CI, configs |
| `docs` | Documentation only |
| `test` | Tests only |
| `style` | Formatting, whitespace (not CSS) |

## Scope

Optional but encouraged. Use the feature or module name:

```
feat(search): show platform name on game cards
fix(canvas): prevent double-scaling on drag
refactor(database): extract DAO classes from DatabaseService
chore: update Flutter to 3.38
test(tier-list): add tests for drag-and-drop reorder
```

## Rules

- One commit = one logical change
- Use imperative mood: "add", "fix", "remove" (not "added", "fixes")
- Keep the first line under 72 characters
- If a feature includes model + UI + tests — that's one `feat(...)` commit
- If tests are large and standalone — separate `test(...)` commit is fine

## Branch Naming

Format: `type/short-description`

```
feat/search-platform-display
fix/canvas-zoom-reset
chore/update-dependencies
```

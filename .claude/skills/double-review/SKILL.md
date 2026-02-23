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
4. Task is ready to commit

---

## Report Format

After each round, provide a report:

```
## Review Round [1/2]

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

### Status: [Proceeding to Round 2 / Ready to commit]
```

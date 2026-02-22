[← Back to README](../README.md)

# Unified SnackBar Notification System

All user-facing notifications in the app use a single extension method `context.showSnack()` defined in `lib/shared/extensions/snackbar_extension.dart`. To change the look or behavior of any notification, edit only this file.

---

## API

### SnackType

```dart
enum SnackType { success, error, info }
```

| Type | Icon | Icon Color | Border Color |
|------|------|------------|--------------|
| `success` | `check_circle_outline` | `AppColors.success` (green) | `AppColors.success` at 50% alpha |
| `error` | `error_outline` | `AppColors.error` (red) | `AppColors.error` at 50% alpha |
| `info` | `info_outline` | `AppColors.brand` (orange) | `AppColors.surfaceBorder` |

### showSnack()

```dart
context.showSnack(
  'Message text',
  type: SnackType.info,                        // default: info
  duration: const Duration(seconds: 2),         // default: 2s
  action: SnackBarAction(label: 'UNDO', ...),   // optional
  loading: false,                                // default: false
);
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `message` | `String` | required | Text displayed in the notification |
| `type` | `SnackType` | `info` | Controls icon and border color |
| `duration` | `Duration` | 2 seconds | How long the notification stays visible |
| `action` | `SnackBarAction?` | `null` | Optional button (e.g. "UNDO", "OK") |
| `loading` | `bool` | `false` | Replaces the icon with a `CircularProgressIndicator` |

### hideSnack()

```dart
context.hideSnack();
```

Manually hides the current notification. Useful when a loading notification should be dismissed after an async operation completes.

---

## Behavior

- **Auto-hide previous**: Calling `showSnack()` automatically hides any currently visible notification before showing the new one.
- **Swipe to dismiss**: Users can swipe horizontally to dismiss.
- **Platform-aware width**:
  - **Desktop** (Windows): fixed 360px width, centered.
  - **Mobile** (Android): full-width with 16px horizontal margin.
- **Visual style**: Dark surface background (`AppColors.surfaceLight`), colored left border per type, floating with elevation 4.

---

## Usage Examples

### Basic notifications

```dart
// Success after an operation
context.showSnack('Collection renamed', type: SnackType.success);

// Error with details
context.showSnack('Failed to delete: $e', type: SnackType.error);

// Informational (default type)
context.showSnack('URL copied to clipboard');
```

### Loading indicator

```dart
// Show loading state
context.showSnack(
  'Preparing export...',
  loading: true,
  duration: const Duration(seconds: 30),
);

// After operation completes — auto-hidden by next showSnack()
context.showSnack('Exported to $path', type: SnackType.success);
```

### With action button

```dart
context.showSnack(
  'Exported to $path',
  type: SnackType.success,
  action: SnackBarAction(
    label: 'OK',
    onPressed: () {},
  ),
);
```

### Manual hide (e.g. on cancel)

```dart
if (result.isCancelled) {
  context.hideSnack();
}
```

---

## File Location

```
lib/shared/extensions/snackbar_extension.dart   # Extension + SnackType enum
test/shared/extensions/snackbar_extension_test.dart  # 17 tests
```

## Import

```dart
import '../../../shared/extensions/snackbar_extension.dart';
```

The import makes both `SnackType` and the `showSnack()`/`hideSnack()` extension methods available.

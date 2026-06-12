import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/profile_service.dart';
import '../../core/services/storage_volumes.dart';
import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../extensions/snackbar_extension.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/folder_picker_dialog.dart';

/// Offers an app restart after a storage-level change; declining shows
/// [laterMessage] instead.
Future<void> offerAppRestart(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
  required String laterMessage,
}) async {
  final S l10n = S.of(context);
  final bool restart = await ConfirmDialog.show(
    context,
    title: title,
    message: message,
    confirmLabel: l10n.storageLocationRestartNow,
    destructive: false,
  );
  if (!context.mounted) return;

  if (restart) {
    await ProfileService.restartApp(context, ref);
  } else {
    context.showSnack(laterMessage);
  }
}

/// Lets the user pick a directory usable as a raw filesystem path.
///
/// Desktop uses the native dialog (it returns real paths); on Android the
/// SAF picker's URI-to-path conversion is firmware-dependent guesswork, so
/// an in-app browser over the real filesystem is shown instead, listing
/// all mounted volumes.
Future<String?> pickRawFolder(
  BuildContext context, {
  required String dialogTitle,
}) async {
  if (!kIsMobile) {
    return FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);
  }

  final S l10n = S.of(context);
  final List<StorageVolume> volumes = StorageVolumes.detect();
  final List<FolderPickerRoot> roots = volumes.isEmpty
      ? <FolderPickerRoot>[
          FolderPickerRoot(
            path: StorageVolumes.primaryPath,
            label: l10n.folderPickerInternalStorage,
          ),
        ]
      : volumes
          .map(
            (StorageVolume volume) => FolderPickerRoot(
              path: volume.path,
              label: volume.isPrimary
                  ? l10n.folderPickerInternalStorage
                  : p.basename(volume.path),
              removable: !volume.isPrimary,
            ),
          )
          .toList();
  return FolderPickerDialog.show(context, roots: roots, title: dialogTitle);
}

/// Ensures the storage permission required for raw-path file access.
///
/// Desktop needs none. Android 11+ uses "All files access"
/// (MANAGE_EXTERNAL_STORAGE); Android 10 and below use the classic storage
/// permission plus requestLegacyExternalStorage. On denial the user is
/// offered the relevant system settings screen; returns false either way —
/// the caller simply retries after the permission is granted.
Future<bool> ensureStorageAccess(BuildContext context) async {
  if (!kIsMobile) return true;

  final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
  if (!context.mounted) return false;
  if (info.version.sdkInt >= 30) {
    return _ensureAllFilesAccess(context);
  }
  return _ensureLegacyStorage(context);
}

Future<bool> _ensureAllFilesAccess(BuildContext context) async {
  if (await Permission.manageExternalStorage.isGranted) return true;

  final PermissionStatus status =
      await Permission.manageExternalStorage.request();
  if (status.isGranted) return true;

  // Some OEM builds cannot resolve the per-app "All files access" screen,
  // so the request fails instantly — route the user through the
  // system-wide list instead.
  if (!context.mounted) return false;
  final S l10n = S.of(context);
  final bool open = await ConfirmDialog.show(
    context,
    title: l10n.storageLocationPermissionTitle,
    message: l10n.storageLocationPermissionMessage,
    confirmLabel: l10n.storageLocationOpenSettings,
    destructive: false,
  );
  if (open) {
    await _openAllFilesAccessScreen();
  }
  return false;
}

/// Android 10 and below: a regular permission dialog is enough; the app
/// settings page is the fallback after "don't ask again".
Future<bool> _ensureLegacyStorage(BuildContext context) async {
  if (await Permission.storage.isGranted) return true;

  final PermissionStatus status = await Permission.storage.request();
  if (status.isGranted) return true;

  if (!context.mounted) return false;
  final S l10n = S.of(context);
  final bool open = await ConfirmDialog.show(
    context,
    title: l10n.storageLocationPermissionTitle,
    message: l10n.storageLocationLegacyPermissionMessage,
    confirmLabel: l10n.storageLocationOpenSettings,
    destructive: false,
  );
  if (open) {
    await openAppSettings();
  }
  return false;
}

/// The system-wide "All files access" list resolves on OEM builds that
/// hide the per-app screen; the app settings page is the last resort.
Future<void> _openAllFilesAccessScreen() async {
  const AndroidIntent intent = AndroidIntent(
    action: 'android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION',
  );
  try {
    await intent.launch();
  } on Exception {
    await openAppSettings();
  }
}

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

/// Desktop uses the native dialog; on Android SAF's URI-to-path conversion is
/// firmware-dependent guesswork, so an in-app filesystem browser is shown.
Future<String?> pickRawFolder(
  BuildContext context, {
  required String dialogTitle,
}) async {
  if (!kIsMobile) {
    return FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);
  }

  final S l10n = S.of(context);
  final List<StorageVolume> volumes = await StorageVolumes.detect();
  if (!context.mounted) return null;
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

/// Android 11+ needs "All files access", older releases the classic storage
/// permission. Returns false on denial — the caller retries after the grant.
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

  // Some OEM builds cannot resolve the per-app "All files access" screen and
  // fail instantly, so the user is routed through the system-wide list.
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

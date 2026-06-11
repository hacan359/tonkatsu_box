import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/storage_root.dart';
import '../../../core/services/storage_volumes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/folder_picker_dialog.dart';
import 'settings_group.dart';
import 'settings_tile.dart';

/// Settings group for choosing where the database and profiles live.
///
/// The default location stays untouched unless the user explicitly picks
/// a custom folder; switching always requires an app restart because the
/// open database connection cannot be re-pointed in place.
class StorageLocationSection extends ConsumerStatefulWidget {
  /// Creates a [StorageLocationSection].
  const StorageLocationSection({super.key});

  @override
  ConsumerState<StorageLocationSection> createState() =>
      _StorageLocationSectionState();
}

class _StorageLocationSectionState
    extends ConsumerState<StorageLocationSection> {
  static final Logger _log = Logger('StorageLocationSection');

  late Future<StorageRootResolution> _rootFuture;

  @override
  void initState() {
    super.initState();
    _rootFuture = StorageRoot.resolve();
  }

  void _refresh() {
    setState(() {
      _rootFuture = StorageRoot.resolve();
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);

    return SettingsGroup(
      title: l10n.storageLocationTitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.storageLocationSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.storageLocationDangerWarning,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
        FutureBuilder<StorageRootResolution>(
          future: _rootFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<StorageRootResolution> snapshot,
          ) {
            final StorageRootResolution? root = snapshot.data;
            final bool fellBack = root?.fellBack ?? false;
            return SettingsTile(
              title: l10n.storageLocationFolder,
              value: root?.path ?? '...',
              valueColor: fellBack ? AppColors.error : null,
              subtitle: fellBack ? l10n.storageLocationFallbackWarning : null,
              showChevron: false,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: FutureBuilder<StorageRootResolution>(
            future: _rootFuture,
            builder: (
              BuildContext context,
              AsyncSnapshot<StorageRootResolution> snapshot,
            ) {
              final StorageRootResolution? root = snapshot.data;
              final bool hasCustom =
                  (root?.isCustom ?? false) || (root?.fellBack ?? false);
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget changeButton = OutlinedButton.icon(
                    onPressed: () => _changeFolder(context),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(l10n.storageLocationChange),
                  );
                  final Widget resetButton = OutlinedButton.icon(
                    onPressed:
                        hasCustom ? () => _resetFolder(context) : null,
                    icon: const Icon(Icons.restore, size: 18),
                    label: Text(l10n.storageLocationReset),
                  );
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        changeButton,
                        const SizedBox(height: AppSpacing.sm),
                        resetButton,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: changeButton),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: resetButton),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changeFolder(BuildContext context) async {
    final S l10n = S.of(context);

    if (!await _ensureStoragePermission(context)) return;
    if (!context.mounted) return;

    final String? dir = await _pickFolder(context, l10n);
    if (dir == null) return;

    final StorageRootResolution current = await StorageRoot.resolve();
    if (p.equals(dir, current.path)) return;

    if (!await StorageRoot.isWritable(dir)) {
      if (!context.mounted) return;
      context.showSnack(
        l10n.storageLocationNotWritable(dir),
        type: SnackType.error,
      );
      return;
    }

    final bool targetHasData = StorageRoot.hasData(dir);

    if (!context.mounted) return;
    if (targetHasData) {
      final bool useExisting = await ConfirmDialog.show(
        context,
        title: l10n.storageLocationUseExistingTitle,
        message: l10n.storageLocationUseExistingMessage,
        confirmLabel: l10n.storageLocationUseExistingConfirm,
        destructive: false,
      );
      if (!useExisting) return;
    } else {
      final bool copy = await ConfirmDialog.show(
        context,
        title: l10n.storageLocationCopyTitle,
        message: l10n.storageLocationCopyMessage,
        confirmLabel: l10n.storageLocationCopyConfirm,
        destructive: false,
      );
      if (!copy) return;
      if (!context.mounted) return;

      try {
        // Flush the WAL so the plain file copy of the live DB is complete.
        await ref.read(databaseServiceProvider).checkpointWal();
        await StorageRoot.copyDataTo(current.path, dir);
      } on Exception catch (e) {
        _log.warning('Data copy to $dir failed', e);
        if (!context.mounted) return;
        context.showSnack(
          l10n.storageLocationCopyError,
          type: SnackType.error,
        );
        return;
      }
    }

    await StorageRoot.setCustomDir(dir);
    if (!context.mounted) return;
    _refresh();
    await _offerRestart(context);
  }

  Future<void> _resetFolder(BuildContext context) async {
    final S l10n = S.of(context);
    final bool confirm = await ConfirmDialog.show(
      context,
      title: l10n.storageLocationResetTitle,
      message: l10n.storageLocationResetMessage,
      confirmLabel: l10n.storageLocationReset,
      destructive: false,
    );
    if (!confirm) return;

    await StorageRoot.clearCustomDir();
    if (!context.mounted) return;
    _refresh();
    await _offerRestart(context);
  }

  Future<void> _offerRestart(BuildContext context) async {
    final S l10n = S.of(context);
    final bool restart = await ConfirmDialog.show(
      context,
      title: l10n.storageLocationRestartTitle,
      message: l10n.storageLocationRestartMessage,
      confirmLabel: l10n.storageLocationRestartNow,
      destructive: false,
    );
    if (!context.mounted) return;

    if (restart) {
      await ProfileService.restartApp(context, ref);
    } else {
      context.showSnack(l10n.storageLocationRestartLater);
    }
  }

  /// Desktop uses the native dialog (it returns real paths); on Android
  /// the SAF picker's URI-to-path conversion is firmware-dependent
  /// guesswork, so an in-app browser over the real filesystem is used
  /// instead.
  Future<String?> _pickFolder(BuildContext context, S l10n) async {
    if (kIsMobile) {
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
      return FolderPickerDialog.show(
        context,
        roots: roots,
        title: l10n.storageLocationSelectDialog,
      );
    }
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.storageLocationSelectDialog,
    );
  }

  /// Android blocks raw-path writes outside app-specific folders without
  /// a storage permission; desktop needs none. Android 11+ uses "All
  /// files access" (MANAGE_EXTERNAL_STORAGE), Android 10 and below use
  /// the classic storage permission plus requestLegacyExternalStorage.
  Future<bool> _ensureStoragePermission(BuildContext context) async {
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

    // Some OEM builds cannot resolve the per-app "All files access"
    // screen, so the request fails instantly — route the user through
    // the system-wide list instead.
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

  /// Android 10 and below: a regular permission dialog is enough; the
  /// app settings page is the fallback after "don't ask again".
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
}

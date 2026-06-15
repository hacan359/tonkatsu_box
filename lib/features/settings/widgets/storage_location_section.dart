import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database_service.dart';
import '../../../core/services/storage_root.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/storage_access.dart';
import '../../../shared/widgets/confirm_dialog.dart';
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

    if (!await ensureStorageAccess(context)) return;
    if (!context.mounted) return;

    final String? dir = await pickRawFolder(
      context,
      dialogTitle: l10n.storageLocationSelectDialog,
    );
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
      final DataDirVerdict verdict = await StorageRoot.validateDataDir(dir);
      if (verdict != DataDirVerdict.ok) {
        if (!context.mounted) return;
        context.showSnack(
          verdict == DataDirVerdict.tooNew
              ? l10n.storageLocationDbTooNew
              : l10n.storageLocationDbCorrupted,
          type: SnackType.error,
        );
        return;
      }
      if (!context.mounted) return;
      final bool useExisting = await ConfirmDialog.show(
        context,
        title: l10n.storageLocationUseExistingTitle,
        message: l10n.storageLocationUseExistingMessage,
        confirmLabel: l10n.storageLocationUseExistingConfirm,
        destructive: false,
      );
      if (!useExisting) return;
    } else {
      final ({bool includeImages})? choice =
          await _askCopyOptions(context, l10n);
      if (choice == null) return;
      if (!context.mounted) return;

      try {
        await StorageRoot.copyDataTo(
          current.path,
          dir,
          flushDatabase: ref.read(databaseServiceProvider).checkpointWal,
          includeImages: choice.includeImages,
        );
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

  /// Copy confirmation with an opt-in "bring the images too" checkbox
  /// (off by default — the re-downloadable cover cache re-fetches, so most
  /// moves skip it; on copies hero banners and the whole image cache for an
  /// offline mirror). Returns null on cancel.
  Future<({bool includeImages})?> _askCopyOptions(
    BuildContext context,
    S l10n,
  ) {
    bool includeImages = false;
    return showDialog<({bool includeImages})>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(l10n.storageLocationCopyTitle),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.storageLocationCopyMessage),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: includeImages,
                    onChanged: (bool? value) =>
                        setState(() => includeImages = value ?? false),
                    title: Text(l10n.storageLocationCopyImages),
                    subtitle: Text(l10n.storageLocationCopyImagesHint),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context)
                      .pop((includeImages: includeImages)),
                  child: Text(l10n.storageLocationCopyConfirm),
                ),
              ],
            );
          },
        );
      },
    );
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
    await offerAppRestart(
      context,
      ref,
      title: l10n.storageLocationRestartTitle,
      message: l10n.storageLocationRestartMessage,
      laterMessage: l10n.storageLocationRestartLater,
    );
  }
}

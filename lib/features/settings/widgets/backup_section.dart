import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/services/db_sync_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/utils/storage_access.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'settings_group.dart';
import 'settings_tile.dart';

/// Settings group for rolling back to the `.bak` database left by the
/// last data replacement (network sync receive).
///
/// The swap is symmetric — the replaced database becomes the new backup,
/// so restoring twice undoes itself. This is the only recovery path on
/// Android's default data folder, which file managers cannot reach.
class BackupSection extends ConsumerStatefulWidget {
  /// Creates a [BackupSection].
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  static final Logger _log = Logger('BackupSection');

  late Future<DateTime?> _backupFuture;

  @override
  void initState() {
    super.initState();
    _backupFuture = ref.read(dbSyncServiceProvider).backupTimestamp();
  }

  void _refresh() {
    setState(() {
      _backupFuture = ref.read(dbSyncServiceProvider).backupTimestamp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);

    return SettingsGroup(
      title: l10n.backupTitle,
      children: <Widget>[
        FutureBuilder<DateTime?>(
          future: _backupFuture,
          builder: (BuildContext context, AsyncSnapshot<DateTime?> snapshot) {
            final DateTime? backupAt = snapshot.data;
            return SettingsTile(
              title: l10n.backupRestoreTile,
              value: backupAt != null
                  ? _formatDate(backupAt)
                  : l10n.backupNone,
              showChevron: false,
              leadingIcon: Icons.settings_backup_restore,
              onTap: backupAt != null
                  ? () => _restore(context, backupAt)
                  : null,
            );
          },
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, DateTime backupAt) async {
    final S l10n = S.of(context);

    final bool confirm = await ConfirmDialog.show(
      context,
      title: l10n.backupRestoreConfirmTitle,
      message: l10n.backupRestoreConfirmMessage(_formatDate(backupAt)),
      confirmLabel: l10n.backupRestoreConfirm,
    );
    if (!confirm || !context.mounted) return;

    try {
      await ref.read(dbSyncServiceProvider).restoreBackup();
    } on Exception catch (e) {
      _log.warning('Backup restore failed', e);
      if (!context.mounted) return;
      context.showSnack(l10n.backupRestoreError, type: SnackType.error);
      return;
    }

    if (!context.mounted) return;
    _refresh();
    context.showSnack(l10n.backupRestored, type: SnackType.success);
    await offerAppRestart(
      context,
      ref,
      title: l10n.storageLocationRestartTitle,
      message: l10n.backupRestartMessage,
      laterMessage: l10n.storageLocationRestartLater,
    );
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    return '${material.formatCompactDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }
}

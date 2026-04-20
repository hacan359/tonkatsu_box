// Единый экран Kodi: настройки подключения + sync + debug + логи.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/kodi_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/kodi_sync_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/kodi_application_info.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/kodi_settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';

/// Breakpoint для переключения ширины контента.
const double _desktopBreakpoint = 800;

/// Единый экран Kodi: подключение, sync-настройки, debug-инструменты.
class KodiScreen extends ConsumerStatefulWidget {
  /// Создаёт [KodiScreen].
  const KodiScreen({super.key});

  @override
  ConsumerState<KodiScreen> createState() => _KodiScreenState();
}

class _KodiScreenState extends ConsumerState<KodiScreen> {
  // — Connection test —
  bool _isTesting = false;
  String? _connectionResult;
  bool _connectionOk = false;

  // — Raw JSON-RPC —
  final TextEditingController _methodController = TextEditingController(
    text: 'JSONRPC.Ping',
  );
  final TextEditingController _paramsController = TextEditingController();
  String? _rawResponse;
  bool _isSendingRaw = false;

  @override
  void dispose() {
    _methodController.dispose();
    _paramsController.dispose();
    super.dispose();
  }

  // ==================== Actions ====================

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionResult = null;
    });

    try {
      final KodiApi api = ref.read(kodiApiProvider);
      final bool pong = await api.ping();
      if (!pong) {
        if (mounted) {
          setState(() {
            _isTesting = false;
            _connectionOk = false;
            _connectionResult = S.of(context).kodiPingFailed;
          });
        }
        return;
      }

      final KodiApplicationInfo info = await api.getApplicationProperties();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _connectionOk = true;
          _connectionResult = S.of(context).kodiConnectedTo(
            info.versionString,
            info.name ?? '',
          );
        });
      }
    } on KodiApiException catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _connectionOk = false;
          _connectionResult = e.message;
        });
      }
    }
  }

  Future<void> _sendRawRequest() async {
    final String method = _methodController.text.trim();
    if (method.isEmpty) return;

    Map<String, dynamic>? params;
    final String paramsText = _paramsController.text.trim();
    if (paramsText.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(paramsText);
        if (decoded is Map<String, dynamic>) {
          params = decoded;
        } else {
          setState(() {
            _rawResponse = S.of(context).kodiParamsNotObject;
          });
          return;
        }
      } on FormatException catch (e) {
        setState(() {
          _rawResponse = S.of(context).kodiJsonParseError(e.message);
        });
        return;
      }
    }

    setState(() {
      _isSendingRaw = true;
      _rawResponse = null;
    });

    try {
      final KodiApi api = ref.read(kodiApiProvider);
      final Map<String, dynamic> result = await api.rawCall(method, params);
      if (mounted) {
        setState(() {
          _isSendingRaw = false;
          _rawResponse =
              const JsonEncoder.withIndent('  ').convert(result);
        });
      }
    } on KodiApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSendingRaw = false;
          _rawResponse = S.of(context).kodiRawError(e.message) +
              (e.detail != null ? '\n${e.detail}' : '');
        });
      }
    }
  }

  void _startSync(KodiSettingsState settings) {
    if (settings.targetCollectionId == null) return;

    ref.read(kodiSyncServiceProvider).start(
          intervalSeconds: settings.syncIntervalSeconds,
          targetCollectionId: settings.targetCollectionId!,
          importRatings: settings.importRatings,
          createSubCollections: settings.createSubCollections,
          onSyncTimestamp: (String timestamp) {
            ref
                .read(kodiSettingsProvider.notifier)
                .setLastSyncTimestamp(timestamp);
          },
          onResult: (KodiSyncResult result) {
            if (result.hasChanges && mounted) {
              ref.invalidate(collectionsProvider);
              ref.invalidate(allItemsNotifierProvider);
              for (final int collId in result.affectedCollectionIds) {
                ref.invalidate(collectionStatsProvider(collId));
                ref.invalidate(collectionCoversProvider(collId));
                ref.invalidate(collectionItemsNotifierProvider(collId));
                ref.invalidate(canvasNotifierProvider(collId));
              }
            }
          },
          onTargetNotFound: () {
            ref.read(kodiSettingsProvider.notifier).setEnabled(enabled: false);
            ref.read(kodiSettingsProvider.notifier).setTargetCollectionId(null);
            if (mounted) {
              context.showSnack(
                S.of(context).kodiTargetDeletedSnack,
                type: SnackType.error,
              );
            }
          },
        );
  }

  void _showIntervalPicker(KodiSettingsState settings) {
    const List<int> intervals = <int>[30, 60, 300, 900];
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(S.of(context).kodiSyncInterval),
        children: <Widget>[
          for (final int seconds in intervals)
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(kodiSettingsProvider.notifier)
                    .setSyncIntervalSeconds(seconds);
                Navigator.pop(dialogContext);
              },
              child: Row(
                children: <Widget>[
                  if (settings.syncIntervalSeconds == seconds)
                    const Icon(Icons.check, size: 18, color: AppColors.brand)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_formatInterval(seconds)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatInterval(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    return '${seconds ~/ 3600}h';
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final KodiSettingsState settings = ref.watch(kodiSettingsProvider);
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= _desktopBreakpoint;

    return Column(
      children: <Widget>[
        const SubScreenTitleBar(title: 'Kodi'), // proper noun
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                children: <Widget>[
                  _buildConnectionSection(settings),
                  const SizedBox(height: AppSpacing.md),
                  _buildSyncSection(settings),
                  if (settings.hasConnection) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    _buildDebugSection(settings),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Connection ====================

  Widget _buildConnectionSection(KodiSettingsState settings) {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.kodiConnectionTitle,
      subtitle: l.kodiConnectionSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InlineTextField(
            label: l.kodiHost,
            value: settings.host,
            placeholder: '192.168.1.100',
            compact: true,
            onChanged: (String value) {
              ref.read(kodiSettingsProvider.notifier).setHost(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InlineTextField(
            label: l.kodiPort,
            value: settings.port.toString(),
            placeholder: kodiDefaultPort.toString(),
            compact: true,
            onChanged: (String value) {
              final int? port = int.tryParse(value);
              if (port != null && port > 0 && port <= 65535) {
                ref.read(kodiSettingsProvider.notifier).setPort(port);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InlineTextField(
            label: l.kodiUsername,
            value: settings.username,
            placeholder: 'kodi',
            compact: true,
            onChanged: (String value) {
              ref.read(kodiSettingsProvider.notifier).setUsername(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InlineTextField(
            label: l.kodiPassword,
            value: settings.password,
            placeholder: l.kodiPasswordHint,
            obscureText: true,
            compact: true,
            onChanged: (String value) {
              ref.read(kodiSettingsProvider.notifier).setPassword(value);
            },
          ),
        ),
        SettingsTile(
          title: l.kodiTestConnection,
          showChevron: false,
          value: _isTesting
              ? l.kodiConnecting
              : _connectionResult,
          titleColor:
              _connectionResult != null && _connectionOk
                  ? AppColors.statusCompleted
                  : _connectionResult != null
                      ? AppColors.error
                      : null,
          onTap: settings.hasConnection && !_isTesting
              ? _testConnection
              : null,
        ),
      ],
    );
  }

  // ==================== Sync ====================

  Widget _buildSyncSection(KodiSettingsState settings) {
    final S l = S.of(context);
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    // Название выбранной коллекции.
    final String targetLabel = collectionsAsync.when(
      data: (List<Collection> cols) {
        if (settings.targetCollectionId == null) return l.kodiTargetNotSelected;
        final Collection? target = cols
            .where((Collection c) => c.id == settings.targetCollectionId)
            .firstOrNull;
        return target?.name ??
            l.kodiTargetDeletedLabel(settings.targetCollectionId!);
      },
      loading: () => '...',
      error: (_, _) => l.kodiTargetError,
    );

    final bool canEnable =
        settings.hasConnection && settings.targetCollectionId != null;

    return SettingsGroup(
      title: l.kodiSyncTitle,
      children: <Widget>[
        // Выбор целевой коллекции (обязательно).
        SettingsTile(
          title: l.kodiTargetCollection,
          subtitle: l.kodiTargetCollectionSubtitle,
          value: targetLabel,
          onTap: () => _showCollectionPicker(settings, collectionsAsync),
        ),
        SettingsTile(
          title: l.kodiEnableSync,
          subtitle: settings.enabled
              ? l.kodiEnableSyncActiveSubtitle
              : !canEnable
                  ? l.kodiEnableSyncDisabledSubtitle
                  : null,
          showChevron: false,
          trailing: Switch(
            value: settings.enabled,
            onChanged: canEnable
                ? (bool value) {
                    ref
                        .read(kodiSettingsProvider.notifier)
                        .setEnabled(enabled: value);
                    if (value) {
                      _startSync(settings);
                    } else {
                      ref.read(kodiSyncServiceProvider).stop();
                    }
                  }
                : null,
          ),
        ),
        SettingsTile(
          title: l.kodiSyncInterval,
          value: _formatInterval(settings.syncIntervalSeconds),
          onTap: () => _showIntervalPicker(settings),
        ),
        SettingsTile(
          title: l.kodiCreateSubCollections,
          subtitle: l.kodiCreateSubCollectionsSubtitle,
          showChevron: false,
          trailing: Switch(
            value: settings.createSubCollections,
            onChanged: (bool value) {
              ref
                  .read(kodiSettingsProvider.notifier)
                  .setCreateSubCollections(enabled: value);
            },
          ),
        ),
        SettingsTile(
          title: l.kodiImportRatings,
          subtitle: l.kodiImportRatingsSubtitle,
          showChevron: false,
          trailing: Switch(
            value: settings.importRatings,
            onChanged: (bool value) {
              ref
                  .read(kodiSettingsProvider.notifier)
                  .setImportRatings(enabled: value);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCollectionPicker(
    KodiSettingsState settings,
    AsyncValue<List<Collection>> collectionsAsync,
  ) async {
    final List<Collection> collections =
        collectionsAsync.valueOrNull ?? <Collection>[];

    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(S.of(context).kodiTargetCollection),
        children: <Widget>[
          // Create new.
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'create_new'),
            child: Row(
              children: <Widget>[
                const Icon(Icons.add, size: 18, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Text(S.of(context).kodiCollectionPickerCreateNew),
              ],
            ),
          ),
          if (collections.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          // Existing collections.
          for (final Collection c in collections)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, c.id),
              child: Row(
                children: <Widget>[
                  if (c.id == settings.targetCollectionId)
                    const Icon(Icons.check, size: 18, color: AppColors.brand)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'create_new') {
      final S l = S.of(context);
      final DatabaseService db = ref.read(databaseServiceProvider);
      final Collection created = await db.createCollection(
        name: l.kodiCollectionLibraryName,
        author: 'Kodi',
      );
      ref.invalidate(collectionsProvider);
      await ref
          .read(kodiSettingsProvider.notifier)
          .setTargetCollectionId(created.id);
      if (mounted) {
        context.showSnack(
          l.kodiCollectionCreated(l.kodiCollectionLibraryName),
          type: SnackType.success,
        );
      }
    } else if (result is int) {
      await ref
          .read(kodiSettingsProvider.notifier)
          .setTargetCollectionId(result);
    }
  }

  Widget _buildRequestLog() {
    final S l = S.of(context);
    final List<KodiLogEntry> log = ref.read(kodiApiProvider).requestLog;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                l.kodiRequestLog(log.length),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (log.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l.kodiCopyLog,
                  onPressed: () {
                    final String text =
                        log.map((KodiLogEntry e) => e.formatted).join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    context.showSnack(l.kodiLogCopied);
                  },
                ),
              if (log.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l.kodiClearLog,
                  onPressed: () {
                    ref.read(kodiApiProvider).requestLog.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: log.isEmpty
                ? Text(
                    l.kodiNoRequests,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  )
                : SingleChildScrollView(
                    reverse: true,
                    child: SelectableText(
                      log.map((KodiLogEntry e) => e.formatted).join('\n'),
                      style: AppTypography.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== Debug ====================

  Widget _buildDebugSection(KodiSettingsState settings) {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.kodiDebugTitle,
      children: <Widget>[
        // — Connection status —
        if (_connectionResult != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Icon(
                  _connectionOk
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color:
                      _connectionOk ? AppColors.statusCompleted : AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _connectionResult!,
                    style: AppTypography.bodySmall.copyWith(
                      color: _connectionOk
                          ? AppColors.statusCompleted
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // — Sync status —
        SettingsTile(
          title: l.kodiSyncStatus,
          value: ref.read(kodiSyncServiceProvider).isRunning
              ? l.kodiSyncRunning
              : l.kodiSyncStopped,
          showChevron: false,
        ),
        SettingsTile(
          title: l.kodiLastSync,
          value: settings.lastSyncTimestamp ?? l.kodiLastSyncNever,
          showChevron: false,
        ),
        SettingsTile(
          title: l.kodiClearLastSync,
          subtitle: l.kodiClearLastSyncSubtitle,
          titleColor: AppColors.error,
          onTap: () async {
            await ref
                .read(kodiSettingsProvider.notifier)
                .clearLastSyncTimestamp();
            if (mounted) {
              context.showSnack(
                l.kodiLastSyncCleared,
                type: SnackType.success,
              );
            }
          },
        ),

        // — Request Log —
        _buildRequestLog(),

        // — Raw JSON-RPC —
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.kodiRawJsonRpc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _methodController,
                decoration: InputDecoration(
                  labelText: l.kodiMethod,
                  hintText: 'VideoLibrary.GetMovies',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _paramsController,
                decoration: InputDecoration(
                  labelText: l.kodiParams,
                  hintText: '{"limits": {"start": 0, "end": 5}}',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: AppTypography.bodySmall,
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSendingRaw ? null : _sendRawRequest,
                  icon: _isSendingRaw
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: Text(l.kodiSend),
                ),
              ),
              if (_rawResponse != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Stack(
                    children: <Widget>[
                      SingleChildScrollView(
                        child: SelectableText(
                          _rawResponse!,
                          style: AppTypography.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 14),
                          color: AppColors.textTertiary,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: l.kodiCopyToClipboard,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _rawResponse!),
                            );
                            context.showSnack(l.kodiCopiedToClipboard);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

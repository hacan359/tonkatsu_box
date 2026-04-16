// Единый экран Kodi: настройки подключения + sync + debug + логи.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/kodi_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/kodi_import_service.dart';
import '../../../core/services/kodi_sync_service.dart';
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
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';
import 'import_result_screen.dart';

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

  // — Import —
  bool _isImporting = false;
  KodiImportProgress? _importProgress;

  // — Collection selector —
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  // — Raw JSON-RPC —
  final TextEditingController _methodController = TextEditingController(
    text: 'JSONRPC.Ping',
  );
  final TextEditingController _paramsController = TextEditingController();
  String? _rawResponse;
  bool _isSendingRaw = false;

  @override
  void initState() {
    super.initState();
    // Auto-start sync if enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final KodiSettingsState settings = ref.read(kodiSettingsProvider);
      if (settings.enabled && settings.targetCollectionId != null) {
        _startSync(settings);
      }
    });
  }

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
            _connectionResult = 'Ping failed — unexpected response';
          });
        }
        return;
      }

      final KodiApplicationInfo info = await api.getApplicationProperties();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _connectionOk = true;
          _connectionResult =
              'Kodi ${info.versionString} "${info.name}"';
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
            _rawResponse = 'Error: params must be a JSON object';
          });
          return;
        }
      } on FormatException catch (e) {
        setState(() {
          _rawResponse = 'JSON parse error: ${e.message}';
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
          _rawResponse = 'Error: ${e.message}'
              '${e.detail != null ? '\n${e.detail}' : ''}';
        });
      }
    }
  }

  Future<void> _startImport() async {
    final KodiSettingsState settings = ref.read(kodiSettingsProvider);
    final String authorName =
        ref.read(settingsNotifierProvider).authorName;

    setState(() {
      _isImporting = true;
      _importProgress = null;
    });

    try {
      final KodiImportService service =
          ref.read(kodiImportServiceProvider);

      // Сохраняем target для existing collection тоже.
      if (!_useNewCollection && _selectedCollectionId != null) {
        await ref
            .read(kodiSettingsProvider.notifier)
            .setTargetCollectionId(_selectedCollectionId);
      }

      final KodiImportResult result = await service.importLibrary(
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        createCollection: _useNewCollection
            ? () async {
                final DatabaseService db = ref.read(databaseServiceProvider);
                final Collection collection = await db.createCollection(
                  name: 'Kodi Library',
                  author: authorName,
                );
                // Сохраняем как target для будущих sync.
                await ref
                    .read(kodiSettingsProvider.notifier)
                    .setTargetCollectionId(collection.id);
                return collection.id;
              }
            : null,
        createSubCollections: settings.createSubCollections,
        importRatings: settings.importRatings,
        onProgress: (KodiImportProgress progress) {
          if (mounted) {
            setState(() => _importProgress = progress);
          }
        },
      );

      if (!mounted) return;

      // Invalidate providers.
      final int collectionId = result.collectionId;
      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider(collectionId));
      ref.invalidate(collectionCoversProvider(collectionId));
      ref.invalidate(collectionItemsNotifierProvider(collectionId));
      ref.invalidate(canvasNotifierProvider(collectionId));
      ref.invalidate(allItemsNotifierProvider);

      // Save last sync timestamp.
      await ref
          .read(kodiSettingsProvider.notifier)
          .setLastSyncTimestamp(DateTime.now().toIso8601String());

      setState(() => _isImporting = false);

      // Fetch collection for result screen.
      final Collection? resultCollection = await ref
          .read(databaseServiceProvider)
          .getCollectionById(collectionId);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImportResultScreen(
            result: result.toUniversal(collection: resultCollection),
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(e.toString(), type: SnackType.error);
    }
  }

  void _startSync(KodiSettingsState settings) {
    if (settings.targetCollectionId == null) return;

    ref.read(kodiSyncServiceProvider).start(
          intervalSeconds: settings.syncIntervalSeconds,
          targetCollectionId: settings.targetCollectionId!,
          importRatings: settings.importRatings,
          onSyncTimestamp: (String timestamp) {
            ref
                .read(kodiSettingsProvider.notifier)
                .setLastSyncTimestamp(timestamp);
          },
          onResult: (KodiSyncResult result) {
            if (result.hasChanges && mounted) {
              // Invalidate UI providers when sync finds changes.
              ref.invalidate(collectionsProvider);
              ref.invalidate(allItemsNotifierProvider);
            }
          },
        );
  }

  void _showIntervalPicker(KodiSettingsState settings) {
    const List<int> intervals = <int>[30, 60, 300, 900];
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: const Text('Sync interval'),
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
        const SubScreenTitleBar(title: 'Kodi'),
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
                  if (settings.hasConnection) ...<Widget>[
                    _buildImportSection(settings),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
    return SettingsGroup(
      title: 'Connection',
      subtitle: 'Kodi HTTP JSON-RPC (Settings → Services → Control)',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InlineTextField(
            label: 'Host',
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
            label: 'Port',
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
            label: 'Username',
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
            label: 'Password',
            value: settings.password,
            placeholder: 'Enter password',
            obscureText: true,
            compact: true,
            onChanged: (String value) {
              ref.read(kodiSettingsProvider.notifier).setPassword(value);
            },
          ),
        ),
        SettingsTile(
          title: 'Test connection',
          showChevron: false,
          value: _isTesting
              ? 'Connecting...'
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

  // ==================== Import ====================

  Widget _buildImportSection(KodiSettingsState settings) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return SettingsGroup(
      title: 'Import',
      subtitle: 'Import Kodi movie library',
      children: <Widget>[
        // Collection selector.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Target collection',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              RadioGroup<bool>(
                groupValue: _useNewCollection,
                onChanged: (bool? value) {
                  if (value == null || _isImporting) return;
                  setState(() {
                    _useNewCollection = value;
                    if (value) _selectedCollectionId = null;
                  });
                },
                child: const Row(
                  children: <Widget>[
                    Radio<bool>(value: true),
                    Text('Create new'),
                    SizedBox(width: AppSpacing.md),
                    Radio<bool>(value: false),
                    Text('Existing'),
                  ],
                ),
              ),
              if (!_useNewCollection)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: collectionsAsync.when(
                    data: (List<Collection> collections) {
                      if (collections.isEmpty) {
                        return Text(
                          'No collections yet',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        );
                      }
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedCollectionId,
                        hint: const Text('Select collection'),
                        isExpanded: true,
                        items: collections.map((Collection c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _isImporting
                            ? null
                            : (int? v) =>
                                setState(() => _selectedCollectionId = v),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (Object e, StackTrace s) => Text(
                      'Error loading collections',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Toggles.
        SettingsTile(
          title: 'Create sub-collections from Kodi sets',
          subtitle: 'E.g. "Harry Potter Collection (kodi)"',
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
          title: 'Import ratings from Kodi',
          subtitle: 'Copy Kodi userrating (1–10) when empty',
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

        // Import button + progress.
        if (_isImporting && _importProgress != null)
          _buildImportProgress()
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _canImport ? _startImport : null,
              icon: const Icon(Icons.download),
              label: const Text('Import from Kodi'),
            ),
          ),
      ],
    );
  }

  bool get _canImport =>
      ref.read(kodiSettingsProvider).hasConnection &&
      (_useNewCollection || _selectedCollectionId != null) &&
      !_isImporting;

  Widget _buildImportProgress() {
    final KodiImportProgress progress = _importProgress!;

    final String stageText = switch (progress.stage) {
      KodiImportStage.fetchingLibrary => 'Fetching Kodi library...',
      KodiImportStage.matchingMovies => 'Matching movies...',
      KodiImportStage.completed => 'Import complete',
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(stageText, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress.total > 0 ? progress.progress : null,
          ),
          if (progress.total > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${progress.current} / ${progress.total}',
              style: AppTypography.bodySmall,
            ),
          ],
          if (progress.currentName != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              progress.currentName!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow(
            Icons.check_circle,
            AppColors.statusCompleted,
            'Imported: ${progress.importedCount}',
          ),
          _buildStatRow(
            Icons.sync,
            AppColors.statusInProgress,
            'Updated: ${progress.updatedCount}',
          ),
          _buildStatRow(
            Icons.help_outline,
            AppColors.textTertiary,
            'Unmatched: ${progress.unmatchedCount}',
          ),
          if (progress.collectionsCreated > 0)
            _buildStatRow(
              Icons.folder,
              AppColors.brand,
              'Collections: ${progress.collectionsCreated}',
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }

  // ==================== Sync ====================

  Widget _buildSyncSection(KodiSettingsState settings) {
    return SettingsGroup(
      title: 'Sync',
      children: <Widget>[
        SettingsTile(
          title: 'Enable Kodi sync',
          subtitle: settings.enabled
              ? 'Active while Tonkatsu is running'
              : null,
          showChevron: false,
          trailing: Switch(
            value: settings.enabled,
            onChanged: settings.hasConnection &&
                    settings.targetCollectionId != null
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
          title: 'Sync interval',
          value: _formatInterval(settings.syncIntervalSeconds),
          onTap: () => _showIntervalPicker(settings),
        ),
      ],
    );
  }

  Widget _buildRequestLog() {
    final List<KodiLogEntry> log = ref.read(kodiApiProvider).requestLog;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Request Log (${log.length})',
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
                  tooltip: 'Copy log',
                  onPressed: () {
                    final String text =
                        log.map((KodiLogEntry e) => e.formatted).join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    context.showSnack('Log copied');
                  },
                ),
              if (log.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Clear log',
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
                    'No requests yet',
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
    return SettingsGroup(
      title: 'Debug',
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
          title: 'Sync status',
          value: ref.read(kodiSyncServiceProvider).isRunning
              ? 'Running'
              : 'Stopped',
          showChevron: false,
        ),
        SettingsTile(
          title: 'Last sync',
          value: settings.lastSyncTimestamp ?? 'Never',
          showChevron: false,
        ),
        SettingsTile(
          title: 'Clear last sync timestamp',
          subtitle: 'Next sync will fetch all watched items',
          titleColor: AppColors.error,
          onTap: () async {
            await ref
                .read(kodiSettingsProvider.notifier)
                .clearLastSyncTimestamp();
            if (mounted) {
              context.showSnack(
                'Last sync timestamp cleared',
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
                'Raw JSON-RPC',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _methodController,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  hintText: 'VideoLibrary.GetMovies',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _paramsController,
                decoration: const InputDecoration(
                  labelText: 'Params (JSON)',
                  hintText: '{"limits": {"start": 0, "end": 5}}',
                  border: OutlineInputBorder(),
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
                  label: const Text('Send'),
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
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _rawResponse!),
                            );
                            context.showSnack('Copied to clipboard');
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

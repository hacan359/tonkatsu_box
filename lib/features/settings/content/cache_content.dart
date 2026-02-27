// Контент экрана настроек кэширования изображений (без Scaffold/AppBar).

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Контент экрана настроек кэширования.
///
/// Позволяет включить/выключить offline mode, выбрать папку кэша,
/// просмотреть статистику и очистить кэш.
/// Используется как standalone в десктопном sidebar и внутри [CacheScreen].
class CacheContent extends ConsumerStatefulWidget {
  /// Создаёт [CacheContent].
  const CacheContent({super.key});

  @override
  ConsumerState<CacheContent> createState() => _CacheContentState();
}

class _CacheContentState extends ConsumerState<CacheContent> {
  late Future<bool> _enabledFuture;
  late Future<String> _pathFuture;
  late Future<(int, int)> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFutures();
  }

  void _refreshFutures() {
    final ImageCacheService cacheService =
        ref.read(imageCacheServiceProvider);
    _enabledFuture = cacheService.isCacheEnabled();
    _pathFuture = cacheService.getBaseCachePath();
    _statsFuture = _getCacheStats(cacheService);
  }

  @override
  Widget build(BuildContext context) {
    final ImageCacheService cacheService =
        ref.read(imageCacheServiceProvider);
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return SettingsSection(
      title: S.of(context).cacheImageCache,
      icon: Icons.folder,
      compact: compact,
      children: <Widget>[
        // Галка включения кэширования
        FutureBuilder<bool>(
          future: _enabledFuture,
          builder:
              (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool enabled = snapshot.data ?? false;
            return SettingsRow(
              title: S.of(context).cacheOfflineMode,
              subtitle: S.of(context).cacheOfflineModeSubtitle,
              compact: compact,
              trailing: Switch(
                value: enabled,
                onChanged: (bool value) async {
                  await cacheService.setCacheEnabled(value);
                  if (!mounted) return;
                  _refreshFutures();
                  setState(() {});
                },
              ),
            );
          },
        ),

        // Путь к кэшу (только десктоп)
        if (!kIsMobile)
          FutureBuilder<String>(
            future: _pathFuture,
            builder:
                (BuildContext context, AsyncSnapshot<String> snapshot) {
              final String path = snapshot.data ?? 'Loading...';
              return SettingsRow(
                title: S.of(context).cacheCacheFolder,
                subtitle: path,
                showDivider: true,
                compact: compact,
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () =>
                      _selectCacheFolder(cacheService),
                  tooltip: S.of(context).cacheSelectFolder,
                ),
              );
            },
          ),

        // Статистика кэша
        FutureBuilder<(int, int)>(
          future: _statsFuture,
          builder: (BuildContext context,
              AsyncSnapshot<(int, int)> snapshot) {
            final int count = snapshot.data?.$1 ?? 0;
            final int size = snapshot.data?.$2 ?? 0;
            return SettingsRow(
              title: S.of(context).cacheCacheSize,
              subtitle:
                  S.of(context).cacheCacheStats(count, cacheService.formatSize(size)),
              showDivider: true,
              compact: compact,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: S.of(context).cacheClearCache,
                onPressed: count > 0
                    ? () => _clearCache(cacheService)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<(int, int)> _getCacheStats(ImageCacheService cacheService) async {
    final int count = await cacheService.getCachedCount();
    final int size = await cacheService.getCacheSize();
    return (count, size);
  }

  Future<void> _selectCacheFolder(ImageCacheService cacheService) async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(
      dialogTitle: S.of(context).cacheSelectFolderDialog,
    );

    if (selectedDirectory != null) {
      await cacheService.setCachePath(selectedDirectory);
      if (!mounted) return;
      _refreshFutures();
      setState(() {});
      context.showSnack(S.of(context).cacheFolderUpdated, type: SnackType.success);
    }
  }

  Future<void> _clearCache(ImageCacheService cacheService) async {
    final S l10n = S.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.cacheClearCacheTitle),
        content: Text(l10n.cacheClearCacheMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cacheService.clearCache();
      if (!mounted) return;
      _refreshFutures();
      setState(() {});
      context.showSnack(S.of(context).cacheCleared, type: SnackType.success);
    }
  }
}

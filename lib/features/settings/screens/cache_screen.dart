// Экран настроек кэширования изображений.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Экран настроек кэширования изображений.
///
/// Позволяет включить/выключить offline mode, выбрать папку кэша,
/// просмотреть статистику и очистить кэш.
class CacheScreen extends ConsumerStatefulWidget {
  /// Создаёт [CacheScreen].
  const CacheScreen({super.key});

  @override
  ConsumerState<CacheScreen> createState() => _CacheScreenState();
}

class _CacheScreenState extends ConsumerState<CacheScreen> {
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

    return BreadcrumbScope(
      label: 'Cache',
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          child: SettingsSection(
            title: 'Image Cache',
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
                    title: 'Offline mode',
                    subtitle: 'Save images locally for offline use',
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

              // Путь к кэшу (только десктоп — на Android Scoped Storage
              // не позволяет dart:io писать в выбранную SAF-папку)
              if (!kIsMobile)
                FutureBuilder<String>(
                  future: _pathFuture,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    final String path = snapshot.data ?? 'Loading...';
                    return SettingsRow(
                      title: 'Cache folder',
                      subtitle: path,
                      showDivider: true,
                      compact: compact,
                      trailing: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () =>
                            _selectCacheFolder(cacheService),
                        tooltip: 'Select folder',
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
                    title: 'Cache size',
                    subtitle:
                        '$count files, ${cacheService.formatSize(size)}',
                    showDivider: true,
                    compact: compact,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Clear cache',
                      onPressed: count > 0
                          ? () => _clearCache(cacheService)
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
      dialogTitle: 'Select cache folder for images',
    );

    if (selectedDirectory != null) {
      await cacheService.setCachePath(selectedDirectory);
      if (!mounted) return;
      _refreshFutures();
      setState(() {});
      context.showSnack('Cache folder updated', type: SnackType.success);
    }
  }

  Future<void> _clearCache(ImageCacheService cacheService) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: const Text('Clear cache?'),
        content: const Text(
          'This will delete all locally saved images. '
          'They will be downloaded again during the next sync.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cacheService.clearCache();
      if (!mounted) return;
      _refreshFutures();
      setState(() {});
      context.showSnack('Cache cleared', type: SnackType.success);
    }
  }
}

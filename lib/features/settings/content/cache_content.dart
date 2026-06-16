import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cache_cleanup_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';

class CacheContent extends ConsumerStatefulWidget {
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

    return SettingsGroup(
      title: S.of(context).cacheImageCache,
      children: <Widget>[
        FutureBuilder<bool>(
          future: _enabledFuture,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool enabled = snapshot.data ?? false;
            return SettingsTile(
              title: S.of(context).cacheOfflineMode,
              showChevron: false,
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

        if (!kIsMobile)
          FutureBuilder<String>(
            future: _pathFuture,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              final String path = snapshot.data ?? '...';
              return SettingsTile(
                title: S.of(context).cacheCacheFolder,
                value: path,
                showChevron: false,
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open, size: 18),
                  onPressed: () => _selectCacheFolder(cacheService),
                  tooltip: S.of(context).cacheSelectFolder,
                ),
              );
            },
          ),

        FutureBuilder<(int, int)>(
          future: _statsFuture,
          builder:
              (BuildContext context, AsyncSnapshot<(int, int)> snapshot) {
            final int count = snapshot.data?.$1 ?? 0;
            final int size = snapshot.data?.$2 ?? 0;
            return SettingsTile(
              title: S.of(context).cacheCacheSize,
              value: S.of(context).cacheCacheStats(
                count,
                cacheService.formatSize(size),
              ),
              showChevron: false,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: S.of(context).cacheClearCache,
                onPressed: count > 0 ? _clearCache : null,
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
      context.showSnack(
        S.of(context).cacheFolderUpdated,
        type: SnackType.success,
      );
    }
  }

  Future<void> _clearCache() async {
    final S l10n = S.of(context);
    final bool confirm = await ConfirmDialog.show(
      context,
      title: l10n.cacheClearCacheTitle,
      message: l10n.cacheClearCacheMessage,
      confirmLabel: l10n.clear,
      destructive: false,
    );

    if (!confirm) return;

    final CacheCleanupResult result =
        await ref.read(cacheCleanupServiceProvider).removeOrphans();
    if (!mounted) return;
    _refreshFutures();
    setState(() {});
    context.showSnack(
      S.of(context).cacheOrphansRemoved(result.deletedCount),
      type: SnackType.success,
    );
  }
}

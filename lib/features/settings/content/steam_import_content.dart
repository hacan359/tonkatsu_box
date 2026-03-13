// Контент экрана импорта библиотеки Steam (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/steam_import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/collection_screen.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_group.dart';

/// Контент экрана импорта библиотеки Steam.
///
/// Три состояния: ввод ключей → прогресс → результат.
class SteamImportContent extends ConsumerStatefulWidget {
  /// Создаёт [SteamImportContent].
  const SteamImportContent({super.key});

  @override
  ConsumerState<SteamImportContent> createState() =>
      _SteamImportContentState();
}

class _SteamImportContentState extends ConsumerState<SteamImportContent> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _steamIdController = TextEditingController();

  bool _isImporting = false;
  SteamImportProgress? _progress;
  SteamImportResult? _result;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _steamIdController.dispose();
    super.dispose();
  }

  bool get _canStart =>
      _apiKeyController.text.trim().isNotEmpty &&
      _steamIdController.text.trim().isNotEmpty &&
      !_isImporting;

  bool get _igdbConnected =>
      ref.read(settingsNotifierProvider).connectionStatus ==
      ConnectionStatus.connected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    if (_result != null) {
      return _buildResultSection(l);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_igdbConnected) ...<Widget>[
          _buildIgdbWarning(l),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildInputSection(l),
        if (_isImporting && _progress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildProgressSection(l),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IGDB warning
  // ---------------------------------------------------------------------------

  Widget _buildIgdbWarning(S l) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusDropped.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.statusDropped.withAlpha(77)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: AppColors.statusDropped),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l.steamImportIgdbRequired,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input fields
  // ---------------------------------------------------------------------------

  Widget _buildInputSection(S l) {
    return SettingsGroup(
      title: l.steamImportTitle,
      subtitle: l.steamImportSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _apiKeyController,
                enabled: !_isImporting,
                decoration: InputDecoration(
                  labelText: l.steamImportApiKey,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHelperLink(
                l.steamImportApiKeyHint,
                'https://steamcommunity.com/dev/apikey',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _steamIdController,
                enabled: !_isImporting,
                decoration: InputDecoration(
                  labelText: l.steamImportSteamId,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHelperLink(
                l.steamImportSteamIdHint,
                'https://steamidfinder.com',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.public,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l.steamImportPublicWarning,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.steamImportButton),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Widget _buildProgressSection(S l) {
    final SteamImportProgress progress = _progress!;

    final String stageText;
    switch (progress.stage) {
      case SteamImportStage.fetchingLibrary:
        stageText = l.steamImportFetchingLibrary;
      case SteamImportStage.matchingGames:
        stageText = l.steamImportMatching;
      case SteamImportStage.completed:
        stageText = l.steamImportComplete;
    }

    return SettingsGroup(
      title: stageText,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                  l.steamImportLookingUp(progress.currentName!),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow(
                Icons.check_circle,
                AppColors.statusCompleted,
                l.steamImportImported(progress.importedCount),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.steamImportWishlisted(progress.wishlistedCount),
              ),
              _buildStatRow(
                Icons.skip_next,
                AppColors.textTertiary,
                l.steamImportSkipped(progress.skippedCount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Widget _buildResultSection(S l) {
    final SteamImportResult result = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsGroup(
          title: l.steamImportComplete,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildStatRow(
                    Icons.check_circle,
                    AppColors.statusCompleted,
                    l.steamImportGamesImported(result.imported),
                  ),
                  _buildStatRow(
                    Icons.bookmark_add,
                    AppColors.brand,
                    l.steamImportWishlistedInIgdb(result.wishlisted),
                  ),
                  _buildStatRow(
                    Icons.skip_next,
                    AppColors.textTertiary,
                    l.steamImportSkippedDuplicates(result.skipped),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.steamImportPlayedStatus,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    l.steamImportPlaytimeComment,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => CollectionScreen(
                    collectionId: result.collectionId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.collections_bookmark),
            label: Text(l.steamImportOpenCollection),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.done),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildHelperLink(String text, String url) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.brand,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.brand,
        ),
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
          Expanded(
            child: Text(text, style: AppTypography.body),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Import logic
  // ---------------------------------------------------------------------------

  Future<void> _startImport() async {
    final String apiKey = _apiKeyController.text.trim();
    final String steamId = _steamIdController.text.trim();
    final String authorName =
        ref.read(settingsNotifierProvider).authorName;

    setState(() {
      _isImporting = true;
      _progress = null;
      _result = null;
    });

    try {
      final SteamImportService service =
          ref.read(steamImportServiceProvider);

      final SteamImportResult result = await service.importLibrary(
        apiKey: apiKey,
        steamId: steamId,
        authorName: authorName,
        onProgress: (SteamImportProgress progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );

      if (!mounted) return;

      ref.invalidate(collectionsProvider);
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      setState(() {
        _isImporting = false;
        _result = result;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(e.toString(), type: SnackType.error);
    }
  }
}

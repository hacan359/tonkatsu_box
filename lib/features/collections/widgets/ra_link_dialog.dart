// Диалог привязки игры к RetroAchievements.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/ra_api.dart';
import '../../../core/services/ra_to_igdb_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../core/services/image_cache_service.dart';

/// Результат диалога — выбранная RA игра.
class RaLinkResult {
  /// Создаёт [RaLinkResult].
  const RaLinkResult({
    required this.raGameId,
    required this.title,
    required this.numAchievements,
  });

  /// RA Game ID.
  final int raGameId;

  /// Название в RA.
  final String title;

  /// Количество достижений.
  final int numAchievements;
}

/// Показывает диалог поиска и привязки RA игры.
///
/// [gameName] — название игры из IGDB (для автоподстановки поиска).
/// [platformId] — IGDB platform ID (для определения RA консоли).
Future<RaLinkResult?> showRaLinkDialog(
  BuildContext context, {
  required String gameName,
  required int? platformId,
}) {
  return showDialog<RaLinkResult>(
    context: context,
    builder: (BuildContext context) => _RaLinkDialog(
      gameName: gameName,
      platformId: platformId,
    ),
  );
}

class _RaLinkDialog extends ConsumerStatefulWidget {
  const _RaLinkDialog({
    required this.gameName,
    required this.platformId,
  });

  final String gameName;
  final int? platformId;

  @override
  ConsumerState<_RaLinkDialog> createState() => _RaLinkDialogState();
}

class _RaLinkDialogState extends ConsumerState<_RaLinkDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<RaGameListEntry> _allGames = <RaGameListEntry>[];
  List<RaGameListEntry> _filtered = <RaGameListEntry>[];
  bool _loading = true;
  String? _error;
  String _consoleName = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.gameName;
    _searchController.addListener(_onSearchChanged);
    _loadGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    final RaApi raApi = ref.read(raApiProvider);
    final List<int> consoleIds = widget.platformId != null
        ? RaToIgdbMapper.igdbToRaConsoleIds(widget.platformId!)
        : <int>[];

    if (consoleIds.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Unknown platform';
      });
      return;
    }

    try {
      final List<RaGameListEntry> allGames = <RaGameListEntry>[];
      for (final int consoleId in consoleIds) {
        final List<RaGameListEntry> games =
            await raApi.getGameList(consoleId);
        allGames.addAll(games);
        if (_consoleName.isEmpty && games.isNotEmpty) {
          _consoleName = games.first.consoleName ?? '';
        }
      }

      setState(() {
        _allGames = allGames;
        _loading = false;
      });
      _onSearchChanged();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    final String query =
        RaToIgdbMapper.normalize(_searchController.text);
    if (query.isEmpty) {
      setState(() => _filtered = _allGames);
      return;
    }

    // Сортируем: exact → prefix → contains → остальные.
    final List<_ScoredEntry> scored = <_ScoredEntry>[];
    for (final RaGameListEntry game in _allGames) {
      final String normalized = RaToIgdbMapper.normalize(game.title);
      final int score;
      if (normalized == query) {
        score = 0; // exact
      } else if (normalized.startsWith(query) ||
          query.startsWith(normalized)) {
        score = 1; // prefix
      } else if (normalized.contains(query)) {
        score = 2; // contains
      } else {
        continue; // no match
      }
      scored.add(_ScoredEntry(game: game, score: score));
    }

    scored.sort((
      _ScoredEntry a,
      _ScoredEntry b,
    ) {
      final int cmp = a.score.compareTo(b.score);
      if (cmp != 0) return cmp;
      return a.game.title.compareTo(b.game.title);
    });

    setState(() {
      _filtered = scored
          .map((_ScoredEntry e) => e.game)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l.raLinkTitle,
                style: AppTypography.h3
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Поле поиска.
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l.raLinkSearchHint,
                    hintStyle: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search, size: 16,
                        color: AppColors.textTertiary),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 14,
                                color: AppColors.textTertiary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),

              // Контент.
              Expanded(child: _buildContent(l)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(S l) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.raLinkLoading(_consoleName),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTypography.body
              .copyWith(color: AppColors.error),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l.raLinkNotFound,
          style: AppTypography.body
              .copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (BuildContext context, int index) {
        final RaGameListEntry game = _filtered[index];
        return _buildGameTile(game);
      },
    );
  }

  Widget _buildGameTile(RaGameListEntry game) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 32,
          height: 32,
          child: game.imageUrl != null
              ? CachedImage(
                  imageType: ImageType.gameCover,
                  imageId: 'ra_${game.id}',
                  remoteUrl: game.imageUrl!,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.videogame_asset,
                  color: AppColors.textTertiary, size: 20),
        ),
      ),
      title: Text(
        game.title,
        style: AppTypography.bodySmall
            .copyWith(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        S.of(context).raLinkAchievements(game.numAchievements),
        style: AppTypography.caption
            .copyWith(color: AppColors.textTertiary),
      ),
      onTap: () {
        Navigator.of(context).pop(RaLinkResult(
          raGameId: game.id,
          title: game.title,
          numAchievements: game.numAchievements,
        ));
      },
    );
  }
}

class _ScoredEntry {
  const _ScoredEntry({required this.game, required this.score});
  final RaGameListEntry game;
  final int score;
}

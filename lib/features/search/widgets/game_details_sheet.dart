import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_badge.dart';

/// Bottom sheet с деталями игры.
class GameDetailsSheet extends StatelessWidget {
  /// Создаёт [GameDetailsSheet].
  const GameDetailsSheet({
    required this.game,
    required this.onAddToCollection,
    super.key,
  });

  /// Игра для отображения.
  final Game game;

  /// Callback добавления в коллекцию.
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

              if (game.summary != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  S.of(context).searchDescription,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  game.summary!,
                  style: AppTypography.body,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToCollection();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context).searchAddToCollection),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (game.coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedImage(
                    imageType: ImageType.gameCover,
                    imageId: game.id.toString(),
                    remoteUrl: game.coverUrl!,
                    width: 100,
                    height: 133,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 100, height: 133,
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: Container(
                      width: 100, height: 133,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.videogame_asset,
                          color: AppColors.textSecondary, size: 32),
                    ),
                  ),
                ),
              if (game.coverUrl != null)
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(children: <InlineSpan>[
                        TextSpan(
                          text: game.name,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (game.releaseYear != null)
                          TextSpan(
                            text: '  ${game.releaseYear}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        SourceBadge(
                          source: DataSource.igdb,
                          onTap: game.externalUrl != null
                              ? () => _launchUrl(game.externalUrl!)
                              : null,
                        ),
                        if (game.formattedRating != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.star, size: 14,
                              color: AppColors.ratingStar),
                          const SizedBox(width: 2),
                          Text('${game.formattedRating}',
                              style: AppTypography.bodySmall),
                        ],
                      ],
                    ),
                    if (game.genres != null &&
                        game.genres!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: game.genres!.map(_buildGenreChip).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (game.artworkUrl == null) return content;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: game.artworkUrl!,
            fit: BoxFit.cover,
            errorWidget:
                (BuildContext context, String url, Object error) =>
                    const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withAlpha(180)),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0, height: 40,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        genre,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

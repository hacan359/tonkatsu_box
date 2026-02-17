import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/game.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Обложка и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (game.coverUrl != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        width: 100,
                        height: 133,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 133,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Container(
                          width: 100,
                          height: 133,
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
                        Text(
                          game.name,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (game.releaseYear != null)
                              _buildChip(
                                Icons.calendar_today,
                                game.releaseYear.toString(),
                              ),
                            if (game.formattedRating != null)
                              _buildChip(
                                Icons.star,
                                '${game.formattedRating} (${game.ratingCount ?? 0})',
                              ),
                          ],
                        ),
                        if (game.genres != null &&
                            game.genres!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: game.genres!
                                .map((String genre) =>
                                    Chip(label: Text(genre)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (game.summary != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Description',
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
                  label: const Text('Add to Collection'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: icon == Icons.star ? AppColors.ratingStar : AppColors.gameAccent),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

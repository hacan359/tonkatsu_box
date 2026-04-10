// Секция прогресса просмотра аниме — эпизоды.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_progress_row.dart';
import '../providers/collections_provider.dart';

/// Секция прогресса просмотра аниме с прогресс-баром и кнопками.
///
/// Использует `currentEpisode` для просмотренных эпизодов.
/// `currentSeason` не используется (у AniList аниме нет деления на сезоны).
class AnimeProgressSection extends ConsumerWidget {
  /// Создаёт [AnimeProgressSection].
  const AnimeProgressSection({
    required this.itemId,
    required this.collectionId,
    required this.anime,
    required this.currentEpisode,
    required this.accentColor,
    super.key,
  });

  /// ID элемента коллекции.
  final int itemId;

  /// ID коллекции.
  final int? collectionId;

  /// Данные аниме.
  final Anime? anime;

  /// Текущий просмотренный эпизод (из `collection_items.current_episode`).
  final int currentEpisode;

  /// Акцентный цвет.
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final int? totalEpisodes = anime?.episodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Заголовок
        Row(
          children: <Widget>[
            Icon(Icons.play_circle_outline, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.animeProgress,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Episodes progress
        MediaProgressRow(
          label: l.animeEpisodes,
          current: currentEpisode,
          total: totalEpisodes,
          accentColor: accentColor,
          onIncrement: () => _incrementEpisode(ref, totalEpisodes),
          onEdit: () => _editProgress(context, ref, totalEpisodes),
        ),

        // Next airing episode info
        if (anime != null && anime!.hasNextAiring) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Icon(Icons.schedule, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                l.animeNextEpisode(anime!.nextAiringEpisode!),
                style: AppTypography.caption.copyWith(
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],

        // Mark as completed
        if (totalEpisodes != null &&
            currentEpisode < totalEpisodes) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _markCompleted(ref),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(l.animeMarkCompleted),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _incrementEpisode(WidgetRef ref, int? total) {
    final int next = currentEpisode + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentEpisode: next);
  }

  void _markCompleted(WidgetRef ref) {
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(
          itemId,
          currentEpisode: anime?.episodes ?? currentEpisode,
        );
  }

  Future<void> _editProgress(
    BuildContext context,
    WidgetRef ref,
    int? total,
  ) async {
    final TextEditingController controller = TextEditingController(
        text: currentEpisode > 0 ? currentEpisode.toString() : '');
    final S l = S.of(context);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.animeEpisodes),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: total != null ? '0–$total' : '0+',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (result != null) {
      final int? value = int.tryParse(result);
      if (value != null && value >= 0) {
        final int clamped =
            total != null && value > total ? total : value;
        ref
            .read(collectionItemsNotifierProvider(collectionId).notifier)
            .updateProgress(itemId, currentEpisode: clamped);
      }
    }
    controller.dispose();
  }
}

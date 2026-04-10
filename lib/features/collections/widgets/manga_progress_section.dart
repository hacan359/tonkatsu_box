// Секция прогресса чтения манги — главы и тома.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_progress_row.dart';
import '../providers/collections_provider.dart';

/// Секция прогресса чтения манги с прогресс-барами и кнопками.
///
/// Использует `currentEpisode` для прочитанных глав и `currentSeason`
/// для прочитанных томов (повторное использование существующих полей).
class MangaProgressSection extends ConsumerWidget {
  /// Создаёт [MangaProgressSection].
  const MangaProgressSection({
    required this.itemId,
    required this.collectionId,
    required this.manga,
    required this.currentChapter,
    required this.currentVolume,
    required this.accentColor,
    super.key,
  });

  /// ID элемента коллекции.
  final int itemId;

  /// ID коллекции.
  final int? collectionId;

  /// Данные манги.
  final Manga? manga;

  /// Текущая прочитанная глава (из `currentEpisode`).
  final int currentChapter;

  /// Текущий прочитанный том (из `currentSeason`).
  final int currentVolume;

  /// Акцентный цвет.
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final int? totalChapters = manga?.chapters;
    final int? totalVolumes = manga?.volumes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Заголовок
        Row(
          children: <Widget>[
            Icon(Icons.auto_stories, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.mangaProgress,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Chapters progress
        MediaProgressRow(
          label: l.mangaChapters,
          current: currentChapter,
          total: totalChapters,
          accentColor: accentColor,
          onIncrement: () => _incrementChapter(ref, totalChapters),
          onEdit: () =>
              _editProgress(context, ref, isChapter: true, total: totalChapters),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Volumes progress
        MediaProgressRow(
          label: l.mangaVolumes,
          current: currentVolume,
          total: totalVolumes,
          accentColor: accentColor,
          onIncrement: () => _incrementVolume(ref, totalVolumes),
          onEdit: () =>
              _editProgress(context, ref, isChapter: false, total: totalVolumes),
        ),

        // Mark as completed
        if (totalChapters != null && currentChapter < totalChapters) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _markCompleted(ref),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(l.mangaMarkCompleted),
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

  void _incrementChapter(WidgetRef ref, int? total) {
    final int next = currentChapter + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentEpisode: next);
  }

  void _incrementVolume(WidgetRef ref, int? total) {
    final int next = currentVolume + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentSeason: next);
  }

  void _markCompleted(WidgetRef ref) {
    final int? totalChapters = manga?.chapters;
    final int? totalVolumes = manga?.volumes;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(
          itemId,
          currentEpisode: totalChapters ?? currentChapter,
          currentSeason: totalVolumes ?? currentVolume,
        );
  }

  Future<void> _editProgress(
    BuildContext context,
    WidgetRef ref, {
    required bool isChapter,
    int? total,
  }) async {
    final int current = isChapter ? currentChapter : currentVolume;
    final TextEditingController controller =
        TextEditingController(text: current > 0 ? current.toString() : '');
    final S l = S.of(context);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(isChapter ? l.mangaChapters : l.mangaVolumes),
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
        if (isChapter) {
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .updateProgress(itemId, currentEpisode: clamped);
        } else {
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .updateProgress(itemId, currentSeason: clamped);
        }
      }
    }
    controller.dispose();
  }
}


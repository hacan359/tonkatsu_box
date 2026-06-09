// Reading-progress section for books — pages read.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/book.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_progress_row.dart';
import '../providers/collections_provider.dart';

/// Reading-progress for books. Reuses `currentEpisode` for the page read, the
/// way [AnimeProgressSection] reuses it for episodes.
class BookProgressSection extends ConsumerWidget {
  const BookProgressSection({
    required this.itemId,
    required this.collectionId,
    required this.book,
    required this.currentPage,
    required this.accentColor,
    super.key,
  });

  final int itemId;
  final int? collectionId;
  final Book? book;

  /// Page read, stored in `collection_items.current_episode`.
  final int currentPage;

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final int? totalPages = book?.pageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.menu_book_outlined, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.bookProgress,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MediaProgressRow(
          label: l.bookPages,
          current: currentPage,
          total: totalPages,
          accentColor: accentColor,
          onIncrement: () => _incrementPage(ref, totalPages),
          onEdit: () => _editProgress(context, ref, totalPages),
        ),
        if (totalPages != null && currentPage < totalPages) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _markCompleted(ref),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(l.bookMarkCompleted),
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

  void _incrementPage(WidgetRef ref, int? total) {
    final int next = currentPage + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentEpisode: next);
  }

  void _markCompleted(WidgetRef ref) {
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentEpisode: book?.pageCount ?? currentPage);
  }

  Future<void> _editProgress(
    BuildContext context,
    WidgetRef ref,
    int? total,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentPage > 0 ? currentPage.toString() : '',
    );
    final S l = S.of(context);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.bookPages),
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
        final int clamped = total != null && value > total ? total : value;
        ref
            .read(collectionItemsNotifierProvider(collectionId).notifier)
            .updateProgress(itemId, currentEpisode: clamped);
      }
    }
    controller.dispose();
  }
}

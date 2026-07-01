import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/custom_progress_units.dart';
import '../../../shared/widgets/media_progress_row.dart';
import '../providers/collections_provider.dart';

/// Universal progress tracker for custom items, mirroring manga / anime.
///
/// The fine axis ([unitTotal], backed by `current_episode`) is always shown;
/// the coarse axis ([unitGroupTotal], backed by `current_season`) appears only
/// for display types that have one (series → seasons, manga → volumes). Unit
/// labels follow [displayType] via [CustomProgressUnits].
class CustomProgressSection extends ConsumerWidget {
  const CustomProgressSection({
    required this.itemId,
    required this.collectionId,
    required this.displayType,
    required this.unitTotal,
    required this.unitGroupTotal,
    required this.currentUnit,
    required this.currentGroup,
    required this.accentColor,
    super.key,
  });

  final int itemId;
  final int? collectionId;

  /// Display type the custom item masquerades as — drives the unit labels.
  final MediaType displayType;

  /// Total fine units (episodes / chapters / pages / parts).
  final int? unitTotal;

  /// Total coarse units (seasons / volumes), or `null` when not applicable.
  final int? unitGroupTotal;

  /// Fine units done, from `collection_items.current_episode`.
  final int currentUnit;

  /// Coarse units done, from `collection_items.current_season`.
  final int currentGroup;

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final bool showGroup = CustomProgressUnits.hasGroupAxis(displayType);
    final String? groupLabel = CustomProgressUnits.groupLabel(displayType, l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.timeline, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.customProgress,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        MediaProgressRow(
          label: CustomProgressUnits.fineLabel(displayType, l),
          current: currentUnit,
          total: unitTotal,
          accentColor: accentColor,
          onIncrement: () => _incrementUnit(ref, unitTotal),
          onEdit: () => _editProgress(context, ref, isGroup: false),
        ),

        if (showGroup && groupLabel != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          MediaProgressRow(
            label: groupLabel,
            current: currentGroup,
            total: unitGroupTotal,
            accentColor: accentColor,
            onIncrement: () => _incrementGroup(ref, unitGroupTotal),
            onEdit: () => _editProgress(context, ref, isGroup: true),
          ),
        ],

        if (unitTotal != null && currentUnit < unitTotal!) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _markCompleted(ref),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(l.customMarkCompleted),
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

  void _incrementUnit(WidgetRef ref, int? total) {
    final int next = currentUnit + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentEpisode: next);
  }

  void _incrementGroup(WidgetRef ref, int? total) {
    final int next = currentGroup + 1;
    if (total != null && next > total) return;
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(itemId, currentSeason: next);
  }

  void _markCompleted(WidgetRef ref) {
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateProgress(
          itemId,
          currentEpisode: unitTotal ?? currentUnit,
          currentSeason: unitGroupTotal ?? currentGroup,
        );
  }

  Future<void> _editProgress(
    BuildContext context,
    WidgetRef ref, {
    required bool isGroup,
  }) async {
    final S l = S.of(context);
    final int current = isGroup ? currentGroup : currentUnit;
    final int? total = isGroup ? unitGroupTotal : unitTotal;
    final String label = isGroup
        ? (CustomProgressUnits.groupLabel(displayType, l) ?? l.customProgress)
        : CustomProgressUnits.fineLabel(displayType, l);
    final TextEditingController controller =
        TextEditingController(text: current > 0 ? current.toString() : '');

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(label),
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
        if (isGroup) {
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .updateProgress(itemId, currentSeason: clamped);
        } else {
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .updateProgress(itemId, currentEpisode: clamped);
        }
      }
    }
    controller.dispose();
  }
}

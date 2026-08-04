import 'package:core/models/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/providers/collections_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'collection_picker_dialog.dart';

/// Form-field wrapper around [showCollectionPickerDialog].
///
/// Renders a tap-target styled like the project's text fields (filled,
/// rounded, brand-bordered) showing the picked collection's name. Opening
/// the field shows the shared collection picker — the same dialog used by
/// "Move to collection" / "Add to collection" actions, so the visual
/// language stays in one place.
class CollectionPickerField extends ConsumerWidget {
  const CollectionPickerField({
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.title,
    this.leadingIcon = Icons.folder_outlined,
    this.excludeCollectionId,
    this.enabled = true,
    this.nullLabel,
    this.nullSubtitle,
    this.nullIcon = Icons.all_inbox_outlined,
    super.key,
  });

  /// Selected collection id. `null` either means nothing is picked or — when
  /// [nullLabel] is set — that the "any/all" option is currently chosen; the
  /// field disambiguates with [_summaryForNull].
  final int? value;

  /// Receives the new collection id. Fires with `null` only when [nullLabel]
  /// is set and the user picks the "any/all" tile.
  final ValueChanged<int?> onChanged;

  final String? label;
  final String? hint;
  final String? title;
  final IconData? leadingIcon;
  final int? excludeCollectionId;
  final bool enabled;

  /// Label for the optional top tile representing "any/all/no filter". When
  /// non-null the picker dialog exposes that extra row.
  final String? nullLabel;

  /// Optional subtitle for the "any/all" tile.
  final String? nullSubtitle;

  /// Icon for the "any/all" tile in the dialog. Default differs from the
  /// "without collection" inbox icon so the two cases stay visually distinct.
  final IconData? nullIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Collection> collections =
        ref.watch(collectionsProvider).valueOrNull ?? const <Collection>[];
    Collection? selected;
    if (value != null) {
      for (final Collection c in collections) {
        if (c.id == value) {
          selected = c;
          break;
        }
      }
    }

    final bool hasCollection = selected != null;
    final bool showsNullSummary = value == null && nullLabel != null;
    final bool hasSummary = hasCollection || showsNullSummary;
    final Color border = enabled
        ? AppColors.surfaceBorder
        : AppColors.surfaceBorder.withAlpha(120);
    final Color textColor =
        hasSummary ? AppColors.textPrimary : AppColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _open(context, ref) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: <Widget>[
              if (leadingIcon != null) ...<Widget>[
                Icon(
                  leadingIcon,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (label != null && label!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          label!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    Text(
                      hasCollection
                          ? selected.name
                          : (showsNullSummary
                              ? nullLabel!
                              : (hint ?? '')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                    if (hasCollection && selected.author.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          selected.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else if (showsNullSummary && nullSubtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          nullSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more,
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: title,
      showUncategorized: nullLabel != null,
      uncategorizedLabel: nullLabel,
      uncategorizedSubtitle: nullSubtitle,
      uncategorizedIcon: nullIcon,
      excludeCollectionId: excludeCollectionId,
    );
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        if (collection.id != value) onChanged(collection.id);
      case WithoutCollection():
        if (value != null) onChanged(null);
      case null:
        break;
    }
  }
}

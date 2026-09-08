import 'package:core/models/marked_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../likes/providers/marked_units_provider.dart';
import '../../likes/utils/marked_unit_label.dart';

/// The mark count and the freshest couple of marks, one line each.
class HubLikesPreview extends ConsumerWidget {
  const HubLikesPreview({super.key});

  static const int _shownLines = 2;
  static const double _placeholderHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<MarkedUnitGroup>> async =
        ref.watch(markedUnitsProvider);
    return async.when(
      loading: () => const SizedBox(height: _placeholderHeight),
      error: (Object error, StackTrace _) => Text(
        '${l.settingsError}: $error',
        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      data: (List<MarkedUnitGroup> groups) {
        if (groups.isEmpty) {
          return Text(
            l.likesEmptyTitle,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          );
        }
        final int total = groups.fold<int>(
          0,
          (int sum, MarkedUnitGroup g) => sum + g.units.length,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.likesMarkCount(total),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final MarkedUnitGroup g in groups.take(_shownLines))
              _Line(group: g, l: l),
          ],
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.group, required this.l});

  final MarkedUnitGroup group;
  final S l;

  @override
  Widget build(BuildContext context) {
    // The group's first unit stands for the title; the page has the rest.
    final MarkedUnit unit = group.units.first;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(
            unit.mark.isFavorite
                ? Icons.favorite
                : Icons.sticky_note_2_outlined,
            size: 14,
            color: unit.mark.isFavorite
                ? AppColors.favorite
                : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${group.item.itemName} · ${markedUnitLabel(l, unit)}',
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

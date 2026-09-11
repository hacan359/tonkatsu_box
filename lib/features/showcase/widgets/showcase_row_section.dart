import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist/anilist_types.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../models/showcase_item.dart';
import '../providers/showcase_rows_provider.dart';
import '../providers/showcase_settings_provider.dart';
import 'release_board.dart';
import 'release_card.dart';

const int _shimmerCards = 3;

/// One row from fetch to cards. Each row owns its loading and error state,
/// so a failing source never takes the neighbours down with it.
class ShowcaseRowSection extends ConsumerWidget {
  const ShowcaseRowSection({
    required this.rowId,
    required this.onTap,
    super.key,
  });

  final ShowcaseRowId rowId;
  final void Function(ShowcaseItem item) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final String title = rowId.localizedLabel(l);
    final ShowcaseRowProvider provider = showcaseRowProvider(rowId);
    final bool hideOwned = ref.watch(
      showcaseSettingsProvider.select((ShowcaseSettings s) => s.hideOwned),
    );
    final ShowcaseOwnedIds owned =
        ref.watch(showcaseOwnedIdsProvider).valueOrNull ??
            const ShowcaseOwnedIds();

    return ref.watch(provider).when(
          // Refresh invalidates; without this the stale row hides the reload.
          skipLoadingOnRefresh: false,
          loading: () => _ShimmerBoard(title: title, icon: rowId.icon),
          error: (Object error, StackTrace _) => _ErrorRow(
            title: title,
            icon: rowId.icon,
            message: _messageFor(l, error),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (List<ShowcaseItem> items) {
            final List<ShowcaseItem> visible = hideOwned
                ? items
                    .where((ShowcaseItem i) => !owned.contains(i))
                    .toList()
                : items;
            return ReleaseBoard(
              title: title,
              icon: rowId.icon,
              items: visible.take(showcaseRowLimit).toList(),
              isOwned: owned.contains,
              onTap: onTap,
              allowsDayGrouping: rowId.allowsDayGrouping,
            );
          },
        );
  }

  static String _messageFor(S l, Object error) {
    if (error is AniListRateLimitException) {
      return l.showcaseRetryIn(error.retryAfter.inSeconds);
    }
    return l.showcaseRowError;
  }
}

class _ShimmerBoard extends StatelessWidget {
  const _ShimmerBoard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double height = ReleaseCard.height(
      compact: isCompactScreen(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseRowTitle(title: title, icon: icon),
        const SizedBox(height: AppSpacing.sm),
        ReleaseGrid(
          itemCount: _shimmerCards,
          itemBuilder: (_, _) => ShimmerBox(
            width: double.infinity,
            height: height,
            borderRadius: AppSpacing.radiusMd,
          ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({
    required this.title,
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseRowTitle(title: title, icon: icon),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                // The theme's infinite minimumSize would break inside a Row.
                style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: onRetry,
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

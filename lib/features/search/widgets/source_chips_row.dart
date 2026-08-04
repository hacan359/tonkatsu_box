import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_logo.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import '../utils/filter_ui.dart';

/// Desktop-only row of providers under the filter bar. On narrow screens the
/// vertical budget does not allow it, so sources live in the filter sheet.
///
/// Dimmed means out of this query: either switched off, or unable to answer the
/// picked shared value — showing that is what keeps a shortened result set from
/// reading as "nothing found".
class SourceChipsRow extends ConsumerWidget {
  const SourceChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState state = ref.watch(browseProvider);
    if (state.sources.length < 2) return const SizedBox.shrink();

    final S l = S.of(context);
    final Color accent = filterAccentForType(state.mediaType);
    final Set<String> unsupported = state.unsupportedSourceIds;
    final Set<String> narrowed = state.ownFilterOwners;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: <Widget>[
          Text(
            l.searchSourcesLabel.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final SearchSource source in state.sources) ...<Widget>[
                    _SourceChip(
                      source: source,
                      accent: accent,
                      on: !state.disabledSourceIds.contains(source.id) &&
                          !unsupported.contains(source.id) &&
                          (narrowed.isEmpty || narrowed.contains(source.id)),
                      count: state.itemsBySource[source.id]?.length,
                      loading: state.isSourceLoading(source.id),
                      blockedReason: unsupported.contains(source.id)
                          ? l.searchSourceLacksValue
                          : (narrowed.isNotEmpty &&
                                  !narrowed.contains(source.id)
                              ? l.searchNarrowedBySource
                              : null),
                      onTap: () => ref
                          .read(browseProvider.notifier)
                          .toggleSource(source.id),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
          if (state.textQueryOnly && !state.hasSearchQuery)
            Text(
              l.searchTextOnlyHint,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.source,
    required this.accent,
    required this.on,
    required this.count,
    required this.loading,
    required this.blockedReason,
    required this.onTap,
  });

  final SearchSource source;
  final Color accent;
  final bool on;
  final int? count;

  /// Request in flight — shown instead of the count, which is still the
  /// previous query's.
  final bool loading;

  /// Non-null when the chip is out of the query for a reason other than the
  /// user switching it off; shown as a tooltip.
  final String? blockedReason;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget chip = Material(
      color: on ? accent.withAlpha(30) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        onTap: blockedReason == null ? onTap : null,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            border: Border(
              bottom: BorderSide(
                color: on ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Opacity(
                opacity: on ? 1 : 0.35,
                child: SourceLogo(source: source.dataSource, size: 14),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                source.dataSource.label,
                style: AppTypography.bodySmall.copyWith(
                  color: on ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (loading) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accent,
                  ),
                ),
              ] else if (count != null && on) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$count',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final String? reason = blockedReason;
    if (reason == null) return chip;
    return Tooltip(message: reason, child: chip);
  }
}

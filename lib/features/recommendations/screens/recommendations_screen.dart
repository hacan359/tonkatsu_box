import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../search/handlers/media_handlers.dart';
import '../../search/widgets/collection_chips_row.dart';
import '../providers/recommendations_provider.dart';
import '../widgets/recommendation_row.dart';

/// Shows recommendation rows, or an empty/no-candidates placeholder.
class RecommendationsScreen extends ConsumerStatefulWidget {
  /// Creates a [RecommendationsScreen].
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  late final MediaHandlers _handlers;

  /// Titles added from this screen this session, marked locally — the library
  /// blanks through AsyncLoading on each add and would flash every mark off.
  final Set<String> _added = <String>{};

  @override
  void initState() {
    super.initState();
    // Recs never surface games, so the game handler's platform map stays
    // empty; the add target is read live so a tap resolves current chips.
    _handlers = MediaHandlers(
      ref: ref,
      platformMap: () => const <int, Platform>{},
      targetCollections: () =>
          ref.read(recommendationTargetCollectionsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    // Marks cards whose add happened out of band (details sheet). Sticky
    // union — never removes — so a collected-id reload can't blank a mark.
    ref.listen<AsyncValue<Set<String>>>(collectedRecommendationIdsProvider, (
      AsyncValue<Set<String>>? _,
      AsyncValue<Set<String>> next,
    ) {
      final Set<String>? collected = next.valueOrNull;
      if (collected == null || collected.every(_added.contains)) return;
      setState(() => _added.addAll(collected));
    });
    final AsyncValue<RecommendationResult> async = ref.watch(
      recommendationsProvider,
    );
    final RecommendationResult? result = async.valueOrNull;
    final int? rowCount = result?.status == RecommendationStatus.ready
        ? result?.rows.length
        : null;

    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          _buildHeader(l, rowCount),
          Expanded(child: _buildBody(context, l, async)),
        ],
      ),
    );
  }

  Widget _buildHeader(S l, int? rowCount) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.recommendationsTitle,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rowCount != null)
                  Text(
                    l.recommendationsCount(rowCount),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: l.refresh,
            color: AppColors.textSecondary,
            onPressed: () => ref.invalidate(recommendationsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    S l,
    AsyncValue<RecommendationResult> async,
  ) {
    return async.when(
      // The refresh button invalidates the provider; without this the old
      // rows keep showing through the reload and the tap looks like a no-op.
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: LogoLoader()),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            '${l.settingsError}: $error',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (RecommendationResult result) => switch (result.status) {
        RecommendationStatus.empty => RecommendationsEmptyState(
          icon: Icons.movie_filter_outlined,
          title: l.recommendationsEmpty,
          hint: l.recommendationsEmptyHint,
        ),
        RecommendationStatus.noApiKey => RecommendationsEmptyState(
          icon: Icons.key_off,
          title: l.recommendationsNoApiKey,
          hint: l.recommendationsNoApiKeyHint,
        ),
        RecommendationStatus.noCandidates => RecommendationsEmptyState(
          icon: Icons.search_off,
          title: l.recommendationsNoCandidates,
          hint: l.recommendationsNoCandidatesHint,
        ),
        RecommendationStatus.ready => _buildReady(context, l, result.rows),
      },
    );
  }

  Widget _buildReady(
    BuildContext context,
    S l,
    List<RecommendationRowUi> rows,
  ) {
    return Column(
      children: <Widget>[
        // Pick target collections, then tapping a card adds straight into them
        // (mirrors the Search tab); its own selection, independent of Search.
        CollectionChipsRow(
          targetProvider: recommendationTargetCollectionsProvider,
        ),
        Expanded(child: _buildRows(context, l, rows)),
      ],
    );
  }

  Widget _buildRows(BuildContext context, S l, List<RecommendationRowUi> rows) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        final RecommendationRowUi row = rows[index];
        return RecommendationRowWidget(
          eyebrow: l.recommendationsBecauseLabel,
          headline: row.becauseTitles.join(', '),
          genres: row.genres,
          items: row.items,
          ownedIds: _added,
          onTap: (RecommendedItem item) => _onItemTap(context, item),
        );
      },
    );
  }

  /// With target collections selected the tap adds straight in; otherwise it
  /// opens the same details sheet Search shows, where the user can add it.
  void _onItemTap(BuildContext context, RecommendedItem item) {
    // Direct adds mark the card locally; a sheet add happens out of band and
    // marks on the next collected-id refresh instead.
    final bool addsDirectly = ref
        .read(recommendationTargetCollectionsProvider)
        .isNotEmpty;
    _handlers.onTap(context, item.media, item.mediaType);
    if (addsDirectly) {
      setState(() => _added.add(item.tasteId));
    }
  }
}

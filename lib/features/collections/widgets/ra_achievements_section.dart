import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/models/tracker_achievement.dart';
import 'package:core/models/tracker_game_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/ra_api.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/tracker_provider.dart';

const Color _raBlue = Color(0xFF4A90D9);
const Color _raGold = Color(0xFFD4A843);
const Color _hardcoreColor = Color(0xFFFF8C00);

enum _AchievementFilter {
  all,
  earned,
  locked,
  missable,
  progression,
  winCondition,
}

class RaAchievementsSection extends ConsumerStatefulWidget {
  const RaAchievementsSection({
    required this.gameId,
    this.platformId,
    super.key,
  });

  final int gameId;

  /// Same IGDB game on different platforms holds distinct RA progress; `null`
  /// falls back to the legacy shared record.
  final int? platformId;

  @override
  ConsumerState<RaAchievementsSection> createState() =>
      _RaAchievementsSectionState();
}

class _RaAchievementsSectionState
    extends ConsumerState<RaAchievementsSection> {
  bool _isRefreshing = false;
  _AchievementFilter _filter = _AchievementFilter.all;

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref
          .read(trackerDetailProvider((gameId: widget.gameId, platformId: widget.platformId)).notifier)
          .refreshAchievements();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TrackerDetailState> asyncState =
        ref.watch(trackerDetailProvider((gameId: widget.gameId, platformId: widget.platformId)));

    return asyncState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (TrackerDetailState state) {
        if (!state.hasRaData) return const SizedBox.shrink();

        if (state.achievements == null && !state.isLoadingAchievements) {
          Future<void>.microtask(() {
            ref.read(trackerDetailProvider((gameId: widget.gameId, platformId: widget.platformId)).notifier)
                .loadAchievements();
          });
        }

        return _buildContent(state);
      },
    );
  }

  Widget _buildContent(TrackerDetailState state) {
    final TrackerGameData data = state.gameData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header: logo + title + buttons
        _buildHeader(data),
        const SizedBox(height: 8),

        // Stats block like RA: 2 lines
        _buildStatsBlock(data, state.achievements),

        // Beaten progress + filter chips — only when achievements loaded and not empty
        if (state.achievements != null &&
            !state.isLoadingAchievements &&
            state.achievements!.isNotEmpty) ...<Widget>[
          _buildBeatenProgress(state.achievements!),
          const SizedBox(height: 8),
          _buildFilterChips(state.achievements!),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(
            color: AppColors.surfaceBorder.withAlpha(80),
            height: 1,
          ),
        ),

        if (state.isLoadingAchievements)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: _raBlue),
              ),
            ),
          )
        else if (state.achievements != null)
          Wrap(
            spacing: _AchievementTile.gap,
            runSpacing: _AchievementTile.gap,
            children: <Widget>[
              for (final TrackerAchievement a
                  in _filterAchievements(state.achievements!))
                _AchievementTile(
                  key: ValueKey<String>(a.achievementId),
                  achievement: a,
                  tooltip: _buildTooltip(a),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildBeatenProgress(List<TrackerAchievement> achievements) {
    final List<TrackerAchievement> progression = achievements
        .where((TrackerAchievement a) => a.isProgression)
        .toList();
    final List<TrackerAchievement> winCondition = achievements
        .where((TrackerAchievement a) => a.isWinCondition)
        .toList();

    if (progression.isEmpty && winCondition.isEmpty) {
      return const SizedBox.shrink();
    }

    final int progEarned =
        progression.where((TrackerAchievement a) => a.earned).length;
    final int winEarned =
        winCondition.where((TrackerAchievement a) => a.earned).length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withAlpha(6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.textPrimary.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title
            Text(
              S.of(context).raBeatenProgress,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            // Bars
            Row(
              children: <Widget>[
                if (progression.isNotEmpty)
                  Expanded(
                    child: _beatenBar(
                      icon: Icons.check_circle_outline,
                      label: 'Progression',
                      earned: progEarned,
                      total: progression.length,
                      color: _raBlue,
                      needAll: true,
                    ),
                  ),
                if (progression.isNotEmpty && winCondition.isNotEmpty)
                  const SizedBox(width: 10),
                if (winCondition.isNotEmpty)
                  Expanded(
                    child: _beatenBar(
                      icon: Icons.stars_outlined,
                      label: 'Win Condition',
                      earned: winEarned,
                      total: winCondition.length,
                      color: _raGold,
                      needAll: false,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _beatenBar({
    required IconData icon,
    required String label,
    required int earned,
    required int total,
    required Color color,
    required bool needAll,
  }) {
    final bool complete = needAll ? earned == total : earned > 0;
    final double pct = total > 0 ? earned / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary.withAlpha(180),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Count
        Text(
          '$earned/$total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: complete ? AppColors.success : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: complete ? AppColors.success : color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<TrackerAchievement> achievements) {
    final S l = S.of(context);
    final bool hasMissable =
        achievements.any((TrackerAchievement a) => a.isMissable);
    final bool hasProgression =
        achievements.any((TrackerAchievement a) => a.isProgression);
    final bool hasWinCondition =
        achievements.any((TrackerAchievement a) => a.isWinCondition);

    return Row(
      children: <Widget>[
        _filterChip(
          icon: Icons.list, tooltip: l.all,
          filter: _AchievementFilter.all,
        ),
        const SizedBox(width: 4),
        _filterChip(
          icon: Icons.lock_open, tooltip: l.raFilterEarned,
          filter: _AchievementFilter.earned, color: AppColors.success,
        ),
        const SizedBox(width: 4),
        _filterChip(
          icon: Icons.lock_outline, tooltip: l.raFilterLocked,
          filter: _AchievementFilter.locked,
        ),
        if (hasMissable) ...<Widget>[
          const SizedBox(width: 4),
          _filterChip(
            icon: Icons.error_outline, tooltip: l.raFilterMissable,
            filter: _AchievementFilter.missable, color: AppColors.warning,
          ),
        ],
        if (hasProgression) ...<Widget>[
          const SizedBox(width: 4),
          _filterChip(
            icon: Icons.check_circle_outline, tooltip: l.raFilterProgression,
            filter: _AchievementFilter.progression, color: _raBlue,
          ),
        ],
        if (hasWinCondition) ...<Widget>[
          const SizedBox(width: 4),
          _filterChip(
            icon: Icons.stars_outlined, tooltip: l.raFilterWinCondition,
            filter: _AchievementFilter.winCondition, color: _raGold,
          ),
        ],
      ],
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String tooltip,
    required _AchievementFilter filter,
    Color? color,
  }) {
    final bool selected = _filter == filter;
    final Color chipColor = color ?? AppColors.textTertiary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: selected ? chipColor.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected ? chipColor.withAlpha(80) : _raBlue.withAlpha(20),
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: selected ? chipColor : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  List<TrackerAchievement> _filterAchievements(
    List<TrackerAchievement> achievements,
  ) {
    List<TrackerAchievement> filtered;
    switch (_filter) {
      case _AchievementFilter.all:
        filtered = List<TrackerAchievement>.of(achievements);
      case _AchievementFilter.earned:
        filtered = achievements
            .where((TrackerAchievement a) => a.earned)
            .toList();
      case _AchievementFilter.locked:
        filtered = achievements
            .where((TrackerAchievement a) => !a.earned)
            .toList();
      case _AchievementFilter.missable:
        filtered = achievements
            .where((TrackerAchievement a) => a.isMissable)
            .toList();
      case _AchievementFilter.progression:
        filtered = achievements
            .where((TrackerAchievement a) => a.isProgression)
            .toList();
      case _AchievementFilter.winCondition:
        filtered = achievements
            .where((TrackerAchievement a) => a.isWinCondition)
            .toList();
    }
    // Earned first (newest first), then locked (by displayOrder).
    filtered.sort((TrackerAchievement a, TrackerAchievement b) {
      if (a.earned != b.earned) return a.earned ? -1 : 1;
      if (a.earned) {
        return (b.earnedAt ?? 0).compareTo(a.earnedAt ?? 0);
      }
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return filtered;
  }

  /// Header row: RA logo + title + refresh + open link.
  Widget _buildHeader(TrackerGameData data) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                child: Image.asset(
                  'assets/images/ra_logo.png',
                  width: 18,
                  height: 18,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'RetroAchievements',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (ref.watch(raApiProvider).hasCredentials) ...<Widget>[
          _headerButton(
            icon: Icons.refresh,
            tooltip: S.of(context).raRefresh,
            isLoading: _isRefreshing,
            onTap: _refreshData,
          ),
          _headerButton(
            icon: Icons.link_off,
            tooltip: S.of(context).raUnlinkButton,
            onTap: () => _unlinkRa(context),
          ),
        ],
        _headerButton(
          icon: Icons.open_in_new,
          tooltip: S.of(context).raOpenOnRa,
          color: _raBlue,
          onTap: () => _openRaPage(data),
        ),
      ],
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(6),
              child: CircularProgressIndicator(strokeWidth: 1.5, color: _raBlue),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              iconSize: 15,
              icon: Icon(icon, color: color ?? AppColors.textTertiary.withAlpha(150)),
              tooltip: tooltip,
              onPressed: onTap,
            ),
    );
  }

  /// Stats block — like RA website: line 1 = total, line 2 = unlocked.
  Widget _buildStatsBlock(
    TrackerGameData data,
    List<TrackerAchievement>? achievements,
  ) {
    final int earned = data.achievementsEarned ?? 0;
    final int total = data.achievementsTotal ?? 0;
    final int hardcore = data.achievementsEarnedHardcore ?? 0;
    final String pct = total > 0
        ? '${(earned / total * 100).ceil()}%'
        : '0%';

    int earnedPoints = 0;
    int totalPoints = 0;
    if (achievements != null) {
      for (final TrackerAchievement a in achievements) {
        totalPoints += a.points ?? 0;
        if (a.earned) earnedPoints += a.points ?? 0;
      }
    }

    final TextStyle dim = AppTypography.caption.copyWith(
        color: AppColors.textTertiary);
    final TextStyle bold = AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600, color: AppColors.textPrimary);

    final S l = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Line 1: "67 achievements worth 446 points"
        Text.rich(
          TextSpan(children: <InlineSpan>[
            TextSpan(text: '$total', style: bold),
            TextSpan(text: ' ${l.raStatsAchievements}', style: dim),
            if (totalPoints > 0) ...<InlineSpan>[
              TextSpan(text: ' ${l.raStatsWorth} ', style: dim),
              TextSpan(text: '$totalPoints', style: bold),
              TextSpan(text: ' ${l.raStatsPoints}', style: dim),
            ],
          ]),
        ),
        const SizedBox(height: 2),
        // Line 2: "Unlocked 12 worth 98  HC 12" + award badge
        Row(
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(children: <InlineSpan>[
                  TextSpan(text: '${l.raStatsUnlocked} ', style: dim),
                  TextSpan(
                    text: '$earned',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600, color: _raBlue),
                  ),
                  if (totalPoints > 0) ...<InlineSpan>[
                    TextSpan(text: ' ${l.raStatsWorth} ', style: dim),
                    TextSpan(
                      text: '$earnedPoints',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600, color: _raGold),
                    ),
                  ],
                  if (hardcore > 0 && hardcore != earned) ...<InlineSpan>[
                    TextSpan(text: '  HC ', style: dim),
                    TextSpan(
                      text: '$hardcore',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600, color: _hardcoreColor),
                    ),
                  ],
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Completion % + award
            Text(
              pct,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: earned == total && total > 0
                    ? _raGold
                    : AppColors.textTertiary,
              ),
            ),
            if (data.hasAward) ...<Widget>[
              const SizedBox(width: 6),
              _buildAwardBadge(data),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAwardBadge(TrackerGameData data) {
    final ({String label, Color color, bool filled}) badge =
        _getAwardBadge(data);
    return Tooltip(
      message: badge.label,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: badge.filled ? badge.color : Colors.transparent,
          border: badge.filled
              ? null
              : Border.all(color: badge.color, width: 1.5),
        ),
      ),
    );
  }

  /// Hover card for a tile — the title, points, type, description and unlock
  /// date the old list rows showed inline.
  InlineSpan _buildTooltip(TrackerAchievement achievement) {
    final S l = S.of(context);
    final TextStyle base = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
    );
    final ({Color color, String label})? type =
        _typeBadge(achievement);
    final String? description = achievement.description;
    final DateTime? earnedAt = achievement.earnedDateTime;
    return TextSpan(
      style: base,
      children: <InlineSpan>[
        TextSpan(
          text: achievement.title,
          style: base.copyWith(
            fontWeight: FontWeight.w600,
            color: achievement.earned ? _raGold : AppColors.textPrimary,
          ),
        ),
        if (achievement.points != null)
          TextSpan(text: '  ${achievement.points} ${l.raStatsPoints}'),
        if (type != null)
          TextSpan(
            text: '\n${type.label}',
            style: base.copyWith(color: type.color),
          ),
        if (description != null && description.isNotEmpty)
          TextSpan(text: '\n$description'),
        if (earnedAt != null)
          TextSpan(
            text: '\n${l.raStatsUnlocked} ${_formatDate(earnedAt)}',
            style: base.copyWith(color: AppColors.textTertiary),
          ),
      ],
    );
  }

  ({String label, Color color, bool filled}) _getAwardBadge(
    TrackerGameData data,
  ) {
    if (data.isMastered) {
      return (
        label: S.of(context).raMastered,
        color: const Color(0xFFFFD700),
        filled: true,
      );
    }
    if (data.isBeaten && data.isHardcore) {
      return (
        label: S.of(context).raBeaten,
        color: const Color(0xFFD4D4D8),
        filled: true,
      );
    }
    if (data.isBeaten) {
      return (
        label: S.of(context).raBeatenSoftcore,
        color: const Color(0xFFA1A1AA),
        filled: false,
      );
    }
    return (
      label: S.of(context).raBeaten,
      color: const Color(0xFFD4D4D8),
      filled: true,
    );
  }

  void _openRaPage(TrackerGameData data) {
    final Uri uri = Uri.parse(data.raGameUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _unlinkRa(BuildContext context) async {
    final S l = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: l.raUnlinkTitle,
      message: l.raUnlinkConfirm,
      confirmLabel: l.raUnlinkButton,
    );
    if (!confirmed || !context.mounted) return;

    await ref
        .read(trackerDetailProvider((gameId: widget.gameId, platformId: widget.platformId)).notifier)
        .unlinkRaGame();
  }

  ({Color color, String label})? _typeBadge(
    TrackerAchievement achievement,
  ) {
    final S l = S.of(context);
    if (achievement.isMissable) {
      return (
        color: AppColors.warning,
        label: l.raFilterMissable,
      );
    }
    if (achievement.isProgression) {
      return (
        color: _raBlue,
        label: l.raFilterProgression,
      );
    }
    if (achievement.isWinCondition) {
      return (
        color: _raGold,
        label: l.raFilterWinCondition,
      );
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return S.of(context).releasesToday;
    if (diff.inDays == 1) return S.of(context).raYesterday;
    if (diff.inDays < 7) return S.of(context).raDaysAgo(diff.inDays);
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.dateFormat),
      ),
    );
    return preset.format(
      date,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
  }
}

/// RA-site badge tile: earned in colour with a blue frame, locked as the
/// grey badge RA serves for it. Details live in the tooltip.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.tooltip,
    super.key,
  });

  final TrackerAchievement achievement;
  final InlineSpan tooltip;

  static const double size = 56;
  static const double gap = 6;
  static const double _frame = 2;

  @override
  Widget build(BuildContext context) {
    final bool earned = achievement.earned;
    final String? url =
        earned ? achievement.badgeUrl : achievement.lockedBadgeUrl;
    return Tooltip(
      richMessage: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(_frame),
        decoration: BoxDecoration(
          color: earned ? _raBlue : AppColors.surfaceBorder,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget:
                      (BuildContext context, String url, Object error) =>
                          _fallback(earned),
                )
              : _fallback(earned),
        ),
      ),
    );
  }

  Widget _fallback(bool earned) {
    return Container(
      color: earned ? AppColors.success.withAlpha(20) : AppColors.surface,
      child: Icon(
        earned ? Icons.emoji_events : Icons.lock_outline,
        size: 20,
        color: earned ? AppColors.success : AppColors.textTertiary,
      ),
    );
  }
}

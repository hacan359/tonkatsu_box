// Секция RetroAchievements в карточке игры.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/ra_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tracker_achievement.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/tracker_provider.dart';

/// Цвет RA бренда (голубой из лого).
const Color _raBlue = Color(0xFF4A90D9);

/// Цвет RA бренда (золотой из лого).
const Color _raGold = Color(0xFFD4A843);

/// Цвет hardcore (оранжевый).
const Color _hardcoreColor = Color(0xFFFF8C00);

/// Фильтр/сортировка достижений в развёрнутом списке.
enum _AchievementFilter {
  all,
  earned,
  locked,
  missable,
  progression,
  winCondition,
}

/// Секция RetroAchievements в детальной карточке игры.
///
/// Показывается только если для игры есть tracker_game_data.
/// Достижения подгружаются lazy при появлении секции.
class RaAchievementsSection extends ConsumerStatefulWidget {
  /// Создаёт [RaAchievementsSection].
  const RaAchievementsSection({
    required this.gameId,
    super.key,
  });

  /// IGDB ID игры.
  final int gameId;

  @override
  ConsumerState<RaAchievementsSection> createState() =>
      _RaAchievementsSectionState();
}

class _RaAchievementsSectionState
    extends ConsumerState<RaAchievementsSection> {
  bool _expanded = false;
  bool _isRefreshing = false;
  _AchievementFilter _filter = _AchievementFilter.all;

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref
          .read(trackerDetailProvider(widget.gameId).notifier)
          .refreshAchievements();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TrackerDetailState> asyncState =
        ref.watch(trackerDetailProvider(widget.gameId));

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

        // Lazy load достижений после того как game data загружена.
        if (state.achievements == null && !state.isLoadingAchievements) {
          Future<void>.microtask(() {
            ref.read(trackerDetailProvider(widget.gameId).notifier)
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

        // Expand/collapse toggle + divider
        if (state.achievements != null &&
            !state.isLoadingAchievements &&
            state.achievements!.length > 6)
          _buildViewAllButton(state.achievements!.length),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(
            color: AppColors.surfaceBorder.withAlpha(80),
            height: 1,
          ),
        ),

        // Achievements list
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
        else if (state.achievements != null) ...<Widget>[
          ..._filterAchievements(state.achievements!)
              .take(_expanded ? state.achievements!.length : 6)
              .map(_buildAchievementRow),

          // Collapse внизу — только когда развёрнуто
          if (_expanded && state.achievements!.length > 6)
            _buildViewAllButton(state.achievements!.length),
        ],
      ],
    );
  }

  /// Beaten progress: показывает сколько progression и win_condition
  /// осталось до получения статуса Beaten.
  Widget _buildBeatenProgress(List<TrackerAchievement> achievements) {
    final List<TrackerAchievement> progression = achievements
        .where((TrackerAchievement a) => a.isProgression)
        .toList();
    final List<TrackerAchievement> winCondition = achievements
        .where((TrackerAchievement a) => a.isWinCondition)
        .toList();

    // Нет typed ачивок — нечего показывать.
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
          color: Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title
            Text(
              S.of(context).raBeatenProgress,
              style: const TextStyle(
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
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: complete ? AppColors.success : color,
                borderRadius: BorderRadius.circular(2),
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
          icon: Icons.list, tooltip: l.raFilterAll,
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
            borderRadius: BorderRadius.circular(6),
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
    // Earned первые (по дате, новые сверху), потом locked (по display_order).
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
                borderRadius: BorderRadius.circular(4),
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

  /// Award badge — кружок как на RA (tooltip с названием).
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

  /// Achievement row — like RA: icon + title(pts) + type badge / description / date.
  Widget _buildAchievementRow(TrackerAchievement achievement) {
    final bool earned = achievement.earned;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Badge icon
          _AchievementIcon(
            badgeUrl: earned
                ? achievement.badgeUrl
                : achievement.lockedBadgeUrl,
            earned: earned,
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Title + (points) + type badge
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: earned
                              ? const Color(0xFFCCB044)
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (achievement.points != null)
                      Text(
                        '  (${achievement.points})',
                        style: TextStyle(
                          fontSize: 12,
                          color: earned
                              ? AppColors.textTertiary
                              : AppColors.textTertiary.withAlpha(120),
                        ),
                      ),
                    if (achievement.type != null)
                      _buildTypeBadge(achievement),
                  ],
                ),
                // Description
                if (achievement.description != null)
                  Text(
                    achievement.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary.withAlpha(earned ? 200 : 140),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Date for earned
                if (earned && achievement.earnedDateTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      'Unlocked ${_formatDate(achievement.earnedDateTime!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary.withAlpha(120),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(int total) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          _expanded
              ? S.of(context).raCollapse
              : S.of(context).raViewAll(total),
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: _raBlue),
        ),
      ),
    );
  }

  /// Award данные как на RA: filled = залитый кружок, !filled = outline.
  ({String label, Color color, bool filled}) _getAwardBadge(
    TrackerGameData data,
  ) {
    // Mastered — золотой залитый кружок.
    if (data.isMastered) {
      return (
        label: S.of(context).raMastered,
        color: const Color(0xFFFFD700),
        filled: true,
      );
    }
    // Beaten Hardcore — серебряный залитый кружок.
    if (data.isBeaten && data.isHardcore) {
      return (
        label: S.of(context).raBeaten,
        color: const Color(0xFFD4D4D8),
        filled: true,
      );
    }
    // Beaten Softcore — серебряный outline кружок.
    if (data.isBeaten) {
      return (
        label: S.of(context).raBeatenSoftcore,
        color: const Color(0xFFA1A1AA),
        filled: false,
      );
    }
    // Fallback (не должен вызываться, hasAward проверен выше).
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.raUnlinkTitle),
        content: Text(l.raUnlinkConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.raUnlinkButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(trackerDetailProvider(widget.gameId).notifier)
        .unlinkRaGame();
  }

  Widget _buildTypeBadge(TrackerAchievement achievement) {
    final S l = S.of(context);
    final ({IconData icon, Color color, String tooltip}) badge;
    if (achievement.isMissable) {
      badge = (
        icon: Icons.error_outline,
        color: AppColors.warning,
        tooltip: l.raFilterMissable,
      );
    } else if (achievement.isProgression) {
      badge = (
        icon: Icons.check_circle_outline,
        color: _raBlue,
        tooltip: l.raFilterProgression,
      );
    } else if (achievement.isWinCondition) {
      badge = (
        icon: Icons.stars_outlined,
        color: _raGold,
        tooltip: l.raFilterWinCondition,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: badge.tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(badge.icon, size: 14, color: badge.color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return S.of(context).raToday;
    if (diff.inDays == 1) return S.of(context).raYesterday;
    if (diff.inDays < 7) return S.of(context).raDaysAgo(diff.inDays);
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}

// -- Вспомогательные виджеты --

class _AchievementIcon extends StatelessWidget {
  const _AchievementIcon({
    required this.badgeUrl,
    required this.earned,
  });

  final String? badgeUrl;
  final bool earned;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: _size,
        height: _size,
        child: badgeUrl != null
            ? CachedNetworkImage(
                imageUrl: badgeUrl!,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: earned ? AppColors.success.withAlpha(20) : AppColors.surface,
      child: Icon(
        earned ? Icons.emoji_events : Icons.lock_outline,
        size: 18,
        color: earned ? AppColors.success : AppColors.textTertiary,
      ),
    );
  }
}

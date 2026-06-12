import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/dual_date_picker_dialog.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/release_event.dart';
import '../providers/releases_provider.dart';
import '../widgets/releases_empty_state.dart';

enum _CalendarView { month, week, day }

enum _ReleasesTab { calendar, all }

/// Google-Calendar-style view of tracked shows' episodes.
///
/// Month uses `calendar_view`'s grid with custom cells; week and day are
/// agenda lists (no hour grid, since episodes have no air time). The same
/// poster-and-text event styling is shared across all three and the preview
/// sheet.
class ReleasesScreen extends ConsumerStatefulWidget {
  const ReleasesScreen({super.key});

  @override
  ConsumerState<ReleasesScreen> createState() => _ReleasesScreenState();
}

class _ReleasesScreenState extends ConsumerState<ReleasesScreen> {
  final EventController<Object?> _controller = EventController<Object?>();
  final GlobalKey<MonthViewState<Object?>> _monthKey =
      GlobalKey<MonthViewState<Object?>>();
  _ReleasesTab _tab = _ReleasesTab.all;
  _CalendarView _view = _CalendarView.week;
  DateTime _focusedDay = _dateOnly(DateTime.now());
  DateTime _monthAnchor = _dateOnly(DateTime.now());
  int? _syncedSignature;
  bool _refreshing = false;

  late DateFormatPreset _datePreset;
  late String _localeName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    _datePreset = DateFormatPreset.fromId(
      ref.watch(settingsNotifierProvider.select((SettingsState s) => s.dateFormat)),
    );
    _localeName = Localizations.localeOf(context).toLanguageTag();
    final AsyncValue<ReleasesCalendarData> async =
        ref.watch(releasesProvider);

    return async.when(
      loading: () => const ShimmerList(),
      error: (Object _, StackTrace _) => const Center(
        child: Icon(Icons.error_outline,
            size: 48, color: AppColors.textTertiary),
      ),
      data: (ReleasesCalendarData data) {
        if (data.trackedCount == 0) {
          return ReleasesEmptyState(
            title: l.releasesEmpty,
            hint: l.releasesEmptyHint,
          );
        }
        _scheduleSync(l, data.events);
        return Column(
          children: <Widget>[
            _toolbar(l),
            Expanded(
              child: _tab == _ReleasesTab.calendar
                  ? _calendarBody(l, data)
                  : _allReleasesBody(l, data),
            ),
          ],
        );
      },
    );
  }

  Widget _calendarBody(S l, ReleasesCalendarData data) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedPill<_CalendarView>(
              selected: _view,
              onChanged: (_CalendarView v) => setState(() => _view = v),
              options: <SegmentedPillOption<_CalendarView>>[
                SegmentedPillOption<_CalendarView>(
                  value: _CalendarView.month,
                  label: l.releasesViewMonth,
                ),
                SegmentedPillOption<_CalendarView>(
                  value: _CalendarView.week,
                  label: l.releasesViewWeek,
                ),
                SegmentedPillOption<_CalendarView>(
                  value: _CalendarView.day,
                  label: l.releasesViewDay,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _viewBody(l, data)),
      ],
    );
  }

  /// Every dated event, grouped under a header per day, oldest first.
  Widget _allReleasesBody(S l, ReleasesCalendarData data) {
    final Map<DateTime, List<ReleaseEvent>> byDay = _groupByDay(data.events);
    final List<DateTime> days = byDay.keys.toList()..sort();

    if (days.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: _emptyDay(l),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        children: <Widget>[
          for (final DateTime day in days) ...<Widget>[
            _dayHeader(day),
            for (final ReleaseEvent e in byDay[day] ?? const <ReleaseEvent>[])
              _eventTile(l, e),
          ],
        ],
      ),
    );
  }

  Widget _viewBody(S l, ReleasesCalendarData data) {
    switch (_view) {
      case _CalendarView.month:
        return Column(
          children: <Widget>[
            _navBar(l),
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Expanded(
              child: MonthView<Object?>(
                key: _monthKey,
                controller: _controller,
                monthViewStyle: MonthViewStyle(
                  startDay: WeekDays.monday,
                  useAvailableVerticalSpace: true,
                  borderColor: AppColors.surfaceBorder,
                  initialMonth: _monthAnchor,
                ),
                monthViewBuilders: MonthViewBuilders<Object?>(
                  cellBuilder: _monthCell,
                  weekDayBuilder: _weekDayTile,
                  headerBuilder: (DateTime _) => const SizedBox.shrink(),
                  onPageChange: (DateTime date, int _) {
                    if (mounted) setState(() => _monthAnchor = date);
                  },
                ),
              ),
            ),
          ],
        );
      case _CalendarView.week:
        return _agenda(l, data, week: true);
      case _CalendarView.day:
        return _agenda(l, data, week: false);
    }
  }


  Widget _toolbar(S l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              l.navReleases,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SegmentedPill<_ReleasesTab>(
            selected: _tab,
            onChanged: (_ReleasesTab t) => setState(() => _tab = t),
            options: <SegmentedPillOption<_ReleasesTab>>[
              SegmentedPillOption<_ReleasesTab>(
                value: _ReleasesTab.all,
                label: l.releasesTabAll,
              ),
              SegmentedPillOption<_ReleasesTab>(
                value: _ReleasesTab.calendar,
                label: l.releasesTabCalendar,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: l.releasesRefresh,
            onPressed: _refreshing ? null : _onRefreshPressed,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefreshPressed() async {
    setState(() => _refreshing = true);
    try {
      await _refresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _refresh() async {
    await ref.read(releasesProvider.notifier).refreshFromApi();
    await ref.read(releasesProvider.future);
  }


  void _scheduleSync(S l, List<ReleaseEvent> events) {
    final int signature = Object.hashAll(events.map((ReleaseEvent e) =>
        Object.hash(e.externalId, e.season, e.episode, e.watched, e.isUpcoming)));
    if (signature == _syncedSignature) return;
    _syncedSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clear();
      _controller.addAll(<CalendarEventData<Object?>>[
        for (final ReleaseEvent e in events) _toData(l, e),
      ]);
    });
  }

  CalendarEventData<Object?> _toData(S l, ReleaseEvent e) {
    return CalendarEventData<Object?>(
      date: e.airDate,
      title: e.showTitle,
      description: e.season != null
          ? l.releasesEpisode(e.season!, e.episode!)
          : null,
      color: _colorFor(e),
      event: e,
    );
  }

  Widget _monthCell(
    DateTime date,
    List<CalendarEventData<Object?>> events,
    bool isToday,
    bool isInMonth,
    bool hideDaysNotInMonth,
  ) {
    if (hideDaysNotInMonth && !isInMonth) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _view = _CalendarView.day;
        _focusedDay = _dateOnly(date);
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppColors.brand.withAlpha(20) : null,
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _dayNumber(date, isToday, isInMonth),
            ),
            Expanded(child: _cellEvents(events)),
          ],
        ),
      ),
    );
  }

  /// Fits as many event chips as the cell height allows, collapsing the rest
  /// into a "+N" line — so short cells on small screens never overflow.
  Widget _cellEvents(List<CalendarEventData<Object?>> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    const double chipExtent = 29; // 26 height + 3 top margin
    const double moreExtent = 15;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int capacity = (constraints.maxHeight / chipExtent).floor();
        if (capacity <= 0) {
          return _moreLabel(events.length);
        }
        final bool overflow = events.length > capacity;
        final int reserve =
            overflow && (capacity * chipExtent + moreExtent > constraints.maxHeight)
                ? 1
                : 0;
        final int showCount = overflow ? capacity - reserve : events.length;
        final List<CalendarEventData<Object?>> shown =
            events.take(showCount < 0 ? 0 : showCount).toList();
        final int extra = events.length - shown.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final CalendarEventData<Object?> e in shown) _eventChip(e),
            if (extra > 0) _moreLabel(extra),
          ],
        );
      },
    );
  }

  Widget _moreLabel(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 3),
      child: Text(
        '+$count',
        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _dayNumber(DateTime date, bool isToday, bool isInMonth) {
    if (isToday) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 11,
          color: isInMonth
              ? AppColors.textSecondary
              : AppColors.textTertiary.withAlpha(110),
        ),
      ),
    );
  }

  Widget _eventChip(CalendarEventData<Object?> data) {
    final Object? payload = data.event;
    final ReleaseEvent? e = payload is ReleaseEvent ? payload : null;
    final bool dim = e != null && e.watched && !e.isUpcoming;
    final Color accent = data.color;
    return GestureDetector(
      onTap: () => _open(payload),
      onLongPress: e != null ? () => _showPreview(e) : null,
      onSecondaryTap: e != null ? () => _showPreview(e) : null,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: '${data.title}\n${data.description ?? ''}',
        waitDuration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.only(top: 3),
          height: 26,
          padding: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: accent.withAlpha(dim ? 20 : 44),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 4),
              _thumb(e, width: 16, height: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: dim
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration: dim ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _agenda(S l, ReleasesCalendarData data, {required bool week}) {
    final Map<DateTime, List<ReleaseEvent>> byDay = _groupByDay(data.events);
    final List<DateTime> days =
        week ? _weekDays(_focusedDay) : <DateTime>[_dateOnly(_focusedDay)];
    final int total =
        days.fold(0, (int sum, DateTime d) => sum + (byDay[d]?.length ?? 0));

    return Column(
      children: <Widget>[
        _navBar(l),
        const Divider(height: 1, color: AppColors.surfaceBorder),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: total == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        child: _emptyDay(l),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      AppSpacing.lg,
                    ),
                    children: <Widget>[
                      for (final DateTime day in days)
                        ...<Widget>[
                          if (week && (byDay[day]?.isNotEmpty ?? false))
                            _dayHeader(day),
                          for (final ReleaseEvent e
                              in byDay[day] ?? const <ReleaseEvent>[])
                            _eventTile(l, e),
                        ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _navBar(S l) {
    final String label = switch (_view) {
      _CalendarView.month => _monthYear(_monthAnchor),
      _CalendarView.week => _weekLabel(_focusedDay),
      _CalendarView.day => _fmtDate(_focusedDay),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goPrev,
          ),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _pickJumpDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goNext,
          ),
          TextButton(
            onPressed: _goToday,
            child: Text(l.releasesToday),
          ),
        ],
      ),
    );
  }

  void _goPrev() {
    switch (_view) {
      case _CalendarView.month:
        _monthKey.currentState?.previousPage();
      case _CalendarView.week:
        setState(() =>
            _focusedDay = _focusedDay.subtract(const Duration(days: 7)));
      case _CalendarView.day:
        setState(() =>
            _focusedDay = _focusedDay.subtract(const Duration(days: 1)));
    }
  }

  void _goNext() {
    switch (_view) {
      case _CalendarView.month:
        _monthKey.currentState?.nextPage();
      case _CalendarView.week:
        setState(() => _focusedDay = _focusedDay.add(const Duration(days: 7)));
      case _CalendarView.day:
        setState(() => _focusedDay = _focusedDay.add(const Duration(days: 1)));
    }
  }

  /// Opens the full calendar picker to jump the current view to any date.
  Future<void> _pickJumpDate() async {
    final DateTime initial =
        _view == _CalendarView.month ? _monthAnchor : _focusedDay;
    final DateTime? picked = await showDualDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null || !mounted) return;
    final DateTime day = _dateOnly(picked);
    if (_view == _CalendarView.month) {
      _monthKey.currentState?.animateToMonth(DateTime(day.year, day.month));
    }
    setState(() {
      _focusedDay = day;
      _monthAnchor = DateTime(day.year, day.month);
    });
  }

  void _goToday() {
    final DateTime today = _dateOnly(DateTime.now());
    if (_view == _CalendarView.month) {
      _monthKey.currentState?.animateToMonth(DateTime(today.year, today.month));
      setState(() => _monthAnchor = DateTime(today.year, today.month));
    } else {
      setState(() => _focusedDay = today);
    }
  }

  Widget _dayHeader(DateTime day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xs),
      child: Text(
        _fmtDate(day),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _eventTile(S l, ReleaseEvent e, {bool inSheet = false}) {
    final Color color = _colorFor(e);
    final bool dim = e.watched && !e.isUpcoming;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (inSheet) Navigator.of(context).pop();
            _open(e);
          },
          onLongPress: inSheet ? null : () => _showPreview(e),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _thumb(
                  e,
                  width: inSheet ? 60 : 46,
                  height: inSheet ? 90 : 69,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        e.showTitle,
                        maxLines: inSheet ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dim
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          decoration: dim ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (e.season != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          l.releasesEpisode(e.season!, e.episode!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _fmtDate(e.airDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyDay(S l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.event_busy,
              size: 48, color: AppColors.textTertiary.withAlpha(120)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.releasesNoEpisodes,
              style: const TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }


  void _showPreview(ReleaseEvent e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final S l = S.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _eventTile(l, e, inSheet: true),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _thumb(ReleaseEvent? e, {required double width, required double height}) {
    final Widget placeholder = ColoredBox(
      color: AppColors.surface,
      child: Icon(
        _placeholderIcon(e?.mediaType),
        size: 14,
        color: AppColors.textTertiary,
      ),
    );
    final bool cacheable = e?.posterUrl != null &&
        e?.imageType != null &&
        e?.cacheImageId != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: SizedBox(
        width: width,
        height: height,
        child: cacheable
            ? CachedImage(
                imageType: e!.imageType!,
                imageId: e.cacheImageId!,
                remoteUrl: e.posterUrl!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: placeholder,
                errorWidget: placeholder,
              )
            : placeholder,
      ),
    );
  }

  IconData _placeholderIcon(MediaType? type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie_outlined,
        MediaType.tvShow => Icons.tv_outlined,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
        MediaType.custom => Icons.dashboard_customize,
        null => Icons.event,
      };

  Color _colorFor(ReleaseEvent e) {
    if (e.isUpcoming) return AppColors.statusPlanned;
    if (!e.watched) return AppColors.error;
    return AppColors.statusCompleted;
  }

  void _open(Object? payload) {
    if (payload is! ReleaseEvent) return;
    final int? itemId = payload.itemId;
    if (itemId == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => ItemDetailScreen(
        collectionId: payload.collectionId,
        itemId: itemId,
        isEditable: true,
      ),
    ));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _weekDays(DateTime anchor) {
    final DateTime date = _dateOnly(anchor);
    final DateTime start =
        date.subtract(Duration(days: date.weekday - DateTime.monday));
    return <DateTime>[for (int i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  String _fmtDate(DateTime d) => _datePreset.format(d, locale: _localeName);

  String _monthYear(DateTime d) {
    final String s = DateFormat.yMMMM(_localeName).format(d);
    return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// Dark weekday header tile. [index] 0 = Monday (matches `startDay`).
  Widget _weekDayTile(int index) {
    // 2024-01-01 was a Monday; offset by the column index for the localized name.
    final String name = DateFormat.E(_localeName)
        .format(DateTime(2024, 1, 1).add(Duration(days: index)))
        .toUpperCase();
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
          right: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _weekLabel(DateTime anchor) {
    final List<DateTime> days = _weekDays(anchor);
    return '${_fmtDate(days.first)} – ${_fmtDate(days.last)}';
  }

  Map<DateTime, List<ReleaseEvent>> _groupByDay(List<ReleaseEvent> events) {
    final Map<DateTime, List<ReleaseEvent>> map =
        <DateTime, List<ReleaseEvent>>{};
    for (final ReleaseEvent e in events) {
      (map[_dateOnly(e.airDate)] ??= <ReleaseEvent>[]).add(e);
    }
    for (final List<ReleaseEvent> list in map.values) {
      list.sort((ReleaseEvent a, ReleaseEvent b) =>
          a.showTitle.toLowerCase().compareTo(b.showTitle.toLowerCase()));
    }
    return map;
  }
}

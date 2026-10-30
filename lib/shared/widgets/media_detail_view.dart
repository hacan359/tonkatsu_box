import 'dart:async';

import 'package:core/models/card_link.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/services/image_cache_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_format_preset.dart';
import '../utils/duration_formatter.dart';
import '../utils/stopped_at_progress.dart';
import 'card_link_picker.dart';
import 'dual_date_picker_dialog.dart';
import 'media_detail/desktop_detail_layout.dart';
import 'media_detail/detail_note_section.dart';
import 'media_detail/detail_sections.dart';
import 'media_detail/identity_header.dart';
import 'media_detail/media_cover_image.dart';
import 'media_detail/media_detail_backdrop.dart';
import 'media_detail/media_detail_chip.dart';
import 'media_detail/mobile_detail_layout.dart';
import 'media_detail/progress_tiles.dart';
export 'media_detail/media_detail_chip.dart' show MediaDetailChip;

/// Which activity date an edit targets — distinct from [ItemStatus] even
/// though the names overlap.
/// [both] stamps the same day as start and completion — a single-sitting
/// watch or playthrough.
enum ActivityDateField { started, completed, both }

/// A null [date] clears the field ("unknown date") without touching the
/// item's status.
typedef OnActivityDateChanged =
    Future<void> Function(ActivityDateField field, DateTime? date);

/// Shared card for game / movie / TV detail screens: owns note editing and
/// date picking, then hands the blocks to a desktop or mobile layout.
class MediaDetailView extends ConsumerStatefulWidget {
  const MediaDetailView({
    required this.title,
    required this.placeholderIcon,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.isEditable,
    required this.onAuthorCommentSave,
    required this.onUserCommentSave,
    this.coverUrl,
    this.externalUrl,
    this.backdropUrl,
    this.infoChips = const <MediaDetailChip>[],
    this.description,
    this.statusWidget,
    this.statusListWidget,
    this.tagWidget,
    this.raBadge,
    this.trackerSection,
    this.stoppedAt,
    this.timeSpentMinutes = 0,
    this.onTimeSpentTap,
    this.rewatchCount,
    this.onRewatchCountTap,
    this.extraSections,
    this.mediaGallery,
    this.recommendationSections,
    this.authorComment,
    this.userComment,
    this.userRating,
    this.onUserRatingChanged,
    this.addedAt,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.completionTime,
    this.onActivityDateChanged,
    this.hasAuthorComment = false,
    this.hasUserComment = false,
    this.embedded = false,
    this.cacheImageType,
    this.cacheImageId,
    this.accentColor,
    this.platformOverlayAsset,
    this.onCardLinkTap,
    super.key,
  });

  final String title;
  final String? coverUrl;
  final String? externalUrl;
  final String? backdropUrl;
  final IconData placeholderIcon;
  final DataSource source;
  final IconData typeIcon;
  final String typeLabel;
  final List<MediaDetailChip> infoChips;
  final String? description;
  final Widget? statusWidget;

  /// Labelled vertical status picker for the desktop side column; falls back
  /// to [statusWidget] there.
  final Widget? statusListWidget;
  final Widget? tagWidget;
  final Widget? raBadge;

  /// Tracker section (RA achievements etc.) rendered after the tag row.
  final Widget? trackerSection;

  /// 0 means not set.
  /// The "stopped at" line; `null` hides it for types without progress.
  final StoppedAtProgress? stoppedAt;

  final int timeSpentMinutes;
  final VoidCallback? onTimeSpentTap;

  /// Rewatch counter (0 = completed once, `null` = not tracked). The chip is
  /// shown only when [onRewatchCountTap] is set.
  final int? rewatchCount;
  final VoidCallback? onRewatchCountTap;

  /// Extra type-specific sections (e.g. Progress for TV shows).
  final List<Widget>? extraSections;

  /// Always-visible gallery rendered between author comment and extra sections.
  final Widget? mediaGallery;

  /// Recommendation / review sections rendered after the ExpansionTile, always visible.
  final List<Widget>? recommendationSections;

  /// Author's review — visible to other users on export.
  final String? authorComment;

  /// Private user notes.
  final String? userComment;

  /// 1.0..10.0 (step 0.1).
  final double? userRating;
  final ValueChanged<double?>? onUserRatingChanged;
  final DateTime? addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;

  /// Completion time (startedAt → completedAt).
  final Duration? completionTime;
  final OnActivityDateChanged? onActivityDateChanged;
  final bool hasAuthorComment;
  final bool hasUserComment;
  final bool isEditable;

  /// When true, render only the content without a wrapping Scaffold.
  final bool embedded;

  /// When set together with [cacheImageId], uses a locally cached image
  /// instead of a plain network one for offline support.
  final ImageType? cacheImageType;
  final String? cacheImageId;
  // Nullable so the const constructor needs no non-const default;
  // null falls back to AppColors.brand at use sites.
  final Color? accentColor;

  /// Platform-overlay asset path (PNG 600×900).
  final String? platformOverlayAsset;
  final ValueChanged<String?> onAuthorCommentSave;
  final ValueChanged<String?> onUserCommentSave;

  /// Opens a card cross-link tapped in note text; `null` = links inactive.
  final void Function(CardLinkRef ref)? onCardLinkTap;

  @override
  ConsumerState<MediaDetailView> createState() => _MediaDetailViewState();
}

enum _EditingField { none, author, user }

class _MediaDetailViewState extends ConsumerState<MediaDetailView> {
  _EditingField _editingField = _EditingField.none;
  late final TextEditingController _authorController;
  late final TextEditingController _userController;
  Timer? _autosaveTimer;
  Map<CardLinkRef, CollectionItem> _resolvedCardLinks =
      const <CardLinkRef, CollectionItem>{};

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController(text: widget.authorComment);
    _userController = TextEditingController(text: widget.userComment);
    _authorController.addListener(_onAuthorChanged);
    _userController.addListener(_onUserChanged);
    _resolveCardLinks();
  }

  @override
  void didUpdateWidget(MediaDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers with external changes, but never while editing.
    if (oldWidget.authorComment != widget.authorComment &&
        _editingField != _EditingField.author) {
      _authorController.text = widget.authorComment ?? '';
    }
    if (oldWidget.userComment != widget.userComment &&
        _editingField != _EditingField.user) {
      _userController.text = widget.userComment ?? '';
    }
    if (oldWidget.authorComment != widget.authorComment ||
        oldWidget.userComment != widget.userComment) {
      _resolveCardLinks();
    }
  }

  /// Pre-resolves note `[[card:…]]` tokens so chips render synchronously.
  Future<void> _resolveCardLinks() async {
    if (widget.onCardLinkTap == null) return;
    final Set<CardLinkRef> refs = <CardLinkRef>{
      ...extractCardLinks(widget.authorComment ?? ''),
      ...extractCardLinks(widget.userComment ?? ''),
    };
    if (refs.isEmpty) {
      if (_resolvedCardLinks.isNotEmpty && mounted) {
        setState(() => _resolvedCardLinks = const <CardLinkRef, CollectionItem>{});
      }
      return;
    }

    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<CardLinkRef> links = refs.toList();
    final List<List<CollectionItem>> matchLists = await Future.wait(
      links.map((CardLinkRef link) => db.resolveCardLink(
            mediaType: link.mediaType,
            externalId: link.externalId,
            source: link.source,
            platformId: link.platformId,
            collectionId: link.collectionId,
          )),
    );
    final Map<CardLinkRef, CollectionItem> resolved =
        <CardLinkRef, CollectionItem>{
      for (int i = 0; i < links.length; i++)
        if (matchLists[i].isNotEmpty) links[i]: matchLists[i].first,
    };
    if (mounted) setState(() => _resolvedCardLinks = resolved);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _saveIfEditing();
    _authorController.removeListener(_onAuthorChanged);
    _userController.removeListener(_onUserChanged);
    _authorController.dispose();
    _userController.dispose();
    super.dispose();
  }

  void _onAuthorChanged() {
    if (_editingField != _EditingField.author) return;
    _scheduleAutosave();
  }

  void _onUserChanged() {
    if (_editingField != _EditingField.user) return;
    _maybeTriggerCardLink();
    _scheduleAutosave();
  }

  bool _cardLinkPickerOpen = false;

  /// Opens the picker when the user types `[[`, replacing it with a token.
  void _maybeTriggerCardLink() {
    if (_cardLinkPickerOpen || widget.onCardLinkTap == null) return;
    final TextSelection sel = _userController.selection;
    if (!sel.isValid || !sel.isCollapsed || sel.baseOffset < 2) return;
    if (_userController.text.substring(sel.baseOffset - 2, sel.baseOffset) !=
        '[[') {
      return;
    }
    _cardLinkPickerOpen = true;
    _insertCardLink(fromBracketTrigger: true)
        .whenComplete(() => _cardLinkPickerOpen = false);
  }

  Future<void> _insertCardLink({bool fromBracketTrigger = false}) async {
    final CollectionItem? item = await showCardLinkPicker(context, ref);
    final TextEditingController c = _userController;
    final TextSelection sel = c.selection;
    int start = sel.isValid ? sel.start : c.text.length;
    final int end = sel.isValid ? sel.end : c.text.length;
    if (item == null) return;
    if (fromBracketTrigger) {
      start = (start - 2).clamp(0, c.text.length);
    }
    final String token = buildCardLinkToken(item);
    c.text = '${c.text.substring(0, start)}$token${c.text.substring(end)}';
    c.selection = TextSelection.collapsed(offset: start + token.length);
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 1), _saveIfEditing);
  }

  void _saveIfEditing() {
    if (_editingField == _EditingField.author) {
      final String text = _authorController.text.trim();
      widget.onAuthorCommentSave(text.isEmpty ? null : text);
    } else if (_editingField == _EditingField.user) {
      final String text = _userController.text.trim();
      widget.onUserCommentSave(text.isEmpty ? null : text);
    }
  }

  void _startEditing(_EditingField field) {
    setState(() => _editingField = field);
  }

  void _finishEditing() {
    _autosaveTimer?.cancel();
    _saveIfEditing();
    setState(() => _editingField = _EditingField.none);
  }

  @override
  Widget build(BuildContext context) {
    final DetailSections sections = _buildSections(context);
    final Widget mobile = MobileDetailLayout(sections: sections);
    final Widget content = kIsMobile
        ? mobile
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                constraints.maxWidth < kDesktopDetailMinWidth
                    ? mobile
                    : DesktopDetailLayout(sections: sections),
          );

    final Widget withBackdrop = widget.backdropUrl != null
        ? MediaDetailBackdrop(imageUrl: widget.backdropUrl!, child: content)
        : content;

    if (widget.embedded) return withBackdrop;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.title, style: AppTypography.h2),
      ),
      body: withBackdrop,
    );
  }

  DetailSections _buildSections(BuildContext context) {
    final Color accent = widget.accentColor ?? AppColors.brand;
    return DetailSections(
      title: widget.title,
      cover: MediaCoverFrame(
        cover: MediaCoverImage(
          coverUrl: widget.coverUrl,
          placeholderIcon: widget.placeholderIcon,
          cacheImageType: widget.cacheImageType,
          cacheImageId: widget.cacheImageId,
        ),
        platformOverlayAsset: widget.platformOverlayAsset,
      ),
      badges: IdentityBadges(
        source: widget.source,
        typeIcon: widget.typeIcon,
        typeLabel: widget.typeLabel,
        accentColor: accent,
        externalUrl: widget.externalUrl,
        raBadge: widget.raBadge,
      ),
      chips: widget.infoChips,
      accentColor: accent,
      description: widget.description,
      tags: widget.tagWidget,
      status: widget.statusWidget,
      statusList: widget.statusListWidget,
      rating: widget.userRating,
      onRatingChanged: widget.onUserRatingChanged,
      progress: _buildProgress(context),
      tracker: widget.trackerSection,
      notes: _buildUserNotesSection(context),
      author: _buildAuthorCommentSection(context),
      gallery: widget.mediaGallery,
      extras: widget.extraSections ?? const <Widget>[],
      recommendations: widget.recommendationSections ?? const <Widget>[],
    );
  }

  DetailProgress? _buildProgress(BuildContext context) {
    final DateTime? addedAt = widget.addedAt;
    if (addedAt == null) return null;
    final String systemMeta = _systemMetaParts(context).join('\n');
    return DetailProgress(
      facts: _progressFacts(context),
      added: ProgressFact(
        icon: Icons.history,
        label: S.of(context).activityDatesAdded,
        value: _dateFormatter(context)(addedAt),
        hasValue: true,
        tooltip: systemMeta,
      ),
      systemMeta: systemMeta,
    );
  }

  List<ProgressFact> _progressFacts(BuildContext context) {
    final S l = S.of(context);
    final String Function(DateTime) fmt = _dateFormatter(context);
    final bool editableDates = widget.onActivityDateChanged != null;
    final int hours = widget.timeSpentMinutes ~/ 60;
    final int minutes = widget.timeSpentMinutes % 60;
    final StoppedAtProgress? stoppedAt = widget.stoppedAt;

    return <ProgressFact>[
      if (stoppedAt != null)
        ProgressFact(
          icon: Icons.bookmark_outline,
          label: l.progressStoppedAt,
          value: stoppedAt.value ?? '—',
          hasValue: stoppedAt.value != null,
          tooltip: stoppedAt.tooltip,
        ),
      ProgressFact(
        icon: Icons.play_circle_outline,
        label: l.activityDatesStarted,
        value: widget.startedAt != null ? fmt(widget.startedAt!) : '—',
        hasValue: widget.startedAt != null,
        onTap: editableDates
            ? () => _pickActivityDate(
                  context,
                  ActivityDateField.started,
                  widget.startedAt,
                )
            : null,
      ),
      ProgressFact(
        icon: Icons.check_circle_outline,
        label: l.activityDatesCompleted,
        value: widget.completedAt != null ? fmt(widget.completedAt!) : '—',
        hasValue: widget.completedAt != null,
        tooltip: widget.completionTime != null
            ? formatCompletionTime(widget.completionTime!, l)
            : null,
        onTap: editableDates
            ? () => _pickActivityDate(
                  context,
                  ActivityDateField.completed,
                  widget.completedAt,
                )
            : null,
      ),
      if (widget.onTimeSpentTap != null)
        ProgressFact(
          icon: Icons.timer_outlined,
          label: l.timeSpentTitle,
          value: widget.timeSpentMinutes > 0
              ? l.runtimeHoursMinutes(hours, minutes)
              : '—',
          hasValue: widget.timeSpentMinutes > 0,
          onTap: widget.onTimeSpentTap,
        ),
      if (widget.onRewatchCountTap != null)
        ProgressFact(
          icon: Icons.replay,
          label: l.rewatchCountEdit,
          value: widget.rewatchCount?.toString() ?? '—',
          hasValue: widget.rewatchCount != null,
          onTap: widget.onRewatchCountTap,
        ),
    ];
  }

  String Function(DateTime) _dateFormatter(BuildContext context) {
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.dateFormat),
      ),
    );
    final String localeName = Localizations.localeOf(context).toLanguageTag();
    return (DateTime d) => preset.format(d, locale: localeName);
  }

  /// System metadata the user never sets directly: added / last activity
  /// dates and the auto-derived completion time.
  List<String> _systemMetaParts(BuildContext context) {
    final S l = S.of(context);
    final String Function(DateTime) fmt = _dateFormatter(context);
    return <String>[
      if (widget.addedAt != null)
        '${l.activityDatesAdded}: ${fmt(widget.addedAt!)}',
      if (widget.lastActivityAt != null)
        '${l.sortLastActivityDisplay}: ${fmt(widget.lastActivityAt!)}',
      if (widget.completionTime != null)
        formatCompletionTime(widget.completionTime!, l),
    ];
  }

  Future<void> _pickActivityDate(
    BuildContext context,
    ActivityDateField field,
    DateTime? current,
  ) async {
    final OnActivityDateChanged? onChanged = widget.onActivityDateChanged;
    if (onChanged == null) return;
    final DateTime initialDate = current ?? DateTime.now();
    final DateTime firstDate = DateTime(1980);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DualDateResult? picked = await showDualDatePickerResult(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: field == ActivityDateField.started
          ? S.of(context).activityDatesSelectStart
          : S.of(context).activityDatesSelectCompletion,
      // Nothing to clear while the field is still empty.
      allowClear: current != null,
      allowBoth: true,
    );

    if (picked != null && context.mounted) {
      await onChanged(
        picked.appliesToBoth ? ActivityDateField.both : field,
        picked.date,
      );
    }
  }

  Widget _buildAuthorCommentSection(BuildContext context) {
    final S l = S.of(context);
    final bool isEditing = _editingField == _EditingField.author;
    return DetailNoteSection(
      icon: Icons.format_quote,
      accentColor: AppColors.movieAccent,
      title: l.detailAuthorReview,
      subtitle: l.detailReviewVisibility,
      isEditing: isEditing,
      onToggleEdit: widget.isEditable
          ? (isEditing
              ? _finishEditing
              : () => _startEditing(_EditingField.author))
          : null,
      controller: _authorController,
      hint: l.detailWriteReviewHint,
      onTap: widget.isEditable
          ? () => _startEditing(_EditingField.author)
          : null,
      text: widget.hasAuthorComment ? widget.authorComment : null,
      emptyText: widget.isEditable
          ? l.detailNoReviewEditable
          : l.detailNoReviewReadonly,
      textStyle: AppTypography.body.copyWith(
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      resolvedLinks: _resolvedCardLinks,
      onCardLink: widget.onCardLinkTap,
    );
  }

  Widget _buildUserNotesSection(BuildContext context) {
    final S l = S.of(context);
    final bool isEditing = _editingField == _EditingField.user;
    return DetailNoteSection(
      icon: Icons.note_alt_outlined,
      accentColor: widget.accentColor ?? AppColors.brand,
      title: l.detailMyNotes,
      isEditing: isEditing,
      onToggleEdit: isEditing
          ? _finishEditing
          : () => _startEditing(_EditingField.user),
      controller: _userController,
      hint: l.detailWriteNotesHint,
      onTap: () => _startEditing(_EditingField.user),
      onInsertCardLink:
          widget.onCardLinkTap != null ? () => _insertCardLink() : null,
      text: widget.hasUserComment ? widget.userComment : null,
      emptyText: l.detailNoNotesYet,
      textStyle: AppTypography.body.copyWith(height: 1.5),
      resolvedLinks: _resolvedCardLinks,
      onCardLink: widget.onCardLinkTap,
    );
  }
}

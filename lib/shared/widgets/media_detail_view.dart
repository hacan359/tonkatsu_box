import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gyroscope_parallax_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/database_service.dart';
import '../../core/services/image_cache_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../models/card_link.dart';
import '../models/collection_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_format_preset.dart';
import 'cached_image.dart';
import 'card_link_picker.dart';
import 'dual_date_picker_dialog.dart';
import 'markdown_toolbar.dart';
import 'mini_markdown_text.dart';
import 'source_badge.dart';
import 'fractional_star_rating.dart';
import '../utils/duration_formatter.dart';

/// `type` is either 'started' or 'completed'.
typedef OnActivityDateChanged =
    Future<void> Function(String type, DateTime date);

String _formatActivityDate(
  DateTime date,
  DateFormatPreset preset,
  String localeName,
) =>
    preset.format(date, locale: localeName);

class MediaDetailChip {
  const MediaDetailChip({
    required this.icon,
    required this.text,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color? iconColor;
}

/// Shared layout for game / movie / TV detail screens. Type-specific blocks
/// are injected via [extraSections].
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
    this.tagWidget,
    this.raBadge,
    this.trackerSection,
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
    this.accentColor = AppColors.brand,
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
  final Widget? tagWidget;
  final Widget? raBadge;

  /// Tracker section (RA achievements etc.) rendered after the tag row.
  final Widget? trackerSection;

  /// 0 means not set.
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

  /// When set together with [cacheImageId], uses [CachedImage] instead of
  /// [CachedNetworkImage] for offline support.
  final ImageType? cacheImageType;
  final String? cacheImageId;
  final Color accentColor;

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
    final Map<CardLinkRef, CollectionItem> resolved =
        <CardLinkRef, CollectionItem>{};
    for (final CardLinkRef link in refs) {
      final List<CollectionItem> matches = await db.resolveCardLink(
        mediaType: link.mediaType,
        externalId: link.externalId,
        source: link.source,
        platformId: link.platformId,
        collectionId: link.collectionId,
      );
      if (matches.isNotEmpty) resolved[link] = matches.first;
    }
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
    // The backing stretches edge to edge: the only outer inset is the
    // backing's own padding, so narrow screens don't lose width to a
    // doubled-up margin.
    final Widget content = ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // Material wraps the fill so descendant ListTile/ExpansionTile widgets
        // paint their ink on a Material ancestor — Flutter 3.44 asserts when
        // a coloured DecoratedBox sits between them.
        Material(
          color: AppColors.surface.withAlpha(80),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder.withAlpha(40)),
            ),
            child: _buildBody(context),
          ),
        ),
      ],
    );

    final Widget withBackdrop = widget.backdropUrl != null
        ? Stack(
            children: <Widget>[
              Positioned.fill(
                child: GyroscopeParallaxImage(
                  imageUrl: widget.backdropUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.background.withAlpha(120),
                        AppColors.background.withAlpha(200),
                        AppColors.background,
                      ],
                      stops: const <double>[0.0, 0.35, 0.6],
                    ),
                  ),
                ),
              ),
              content,
            ],
          )
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

  /// Regrouped card: the header keeps only short identity facts beside the
  /// cover; description and tags go full width below; user-set progress
  /// (dates, time, rewatches) is a symmetric tile row; system metadata
  /// (added / last activity / auto completion time) sits behind the info
  /// button next to the tiles.
  Widget _buildBody(BuildContext context) {
    final bool hasDescription =
        widget.description != null && widget.description!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildIdentityHeader(),
        if (hasDescription) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _ExpandableDescription(text: widget.description!),
        ],
        if (widget.tagWidget != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          widget.tagWidget!,
        ],
        if (widget.statusWidget != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildStatusSection(context),
        ],
        if (widget.onUserRatingChanged != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildUserRatingSection(context),
        ],
        if (widget.addedAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildProgressTiles(context),
        ],
        const SizedBox(height: AppSpacing.md),
        _TrackerCommentsLayout(
          trackerSection: widget.trackerSection,
          notesSection: _buildUserNotesSection(context),
          authorSection: _buildAuthorCommentSection(context),
        ),
        if (widget.mediaGallery != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          widget.mediaGallery!,
        ],
        if (widget.extraSections != null && widget.extraSections!.isNotEmpty)
          for (final Widget section in widget.extraSections!) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            section,
          ],
        if (widget.recommendationSections != null &&
            widget.recommendationSections!.isNotEmpty)
          for (final Widget section
              in widget.recommendationSections!) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            section,
          ],
      ],
    );
  }

  /// Cover + short identity facts only: source, type, RA badge, info chips.
  /// Description, tags, time and rewatch counters live elsewhere in the
  /// grouped layout.
  Widget _buildIdentityHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.platformOverlayAsset != null ? 0 : AppSpacing.radiusSm,
          ),
          child: SizedBox(
            width: 100,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildCoverImage(),
                if (widget.platformOverlayAsset != null)
                  Image.asset(widget.platformOverlayAsset!, fit: BoxFit.fill),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  SourceBadge(
                    source: widget.source,
                    size: SourceBadgeSize.medium,
                    onTap: widget.externalUrl != null
                        ? () => _launchExternalUrl(widget.externalUrl!)
                        : null,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        widget.typeIcon,
                        size: 16,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.typeLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (widget.raBadge != null) widget.raBadge!,
                ],
              ),
              if (widget.infoChips.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MediaDetailChip chip in widget.infoChips)
                      _InfoChip(
                        icon: chip.icon,
                        text: chip.text,
                        iconColor: chip.iconColor,
                        onTap: chip.onTap,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Symmetric row (2×N grid on narrow widths) of the user-set progress
  /// facts: started / completed dates, time spent, rewatch count.
  Widget _buildProgressTiles(BuildContext context) {
    final S l = S.of(context);
    final String Function(DateTime) fmt = _dateFormatter(context);
    final bool editableDates = widget.onActivityDateChanged != null;
    final int hours = widget.timeSpentMinutes ~/ 60;
    final int minutes = widget.timeSpentMinutes % 60;

    final List<Widget> tiles = <Widget>[
      _buildProgressTile(
        icon: Icons.play_circle_outline,
        label: l.activityDatesStarted,
        value: widget.startedAt != null ? fmt(widget.startedAt!) : '—',
        hasValue: widget.startedAt != null,
        onTap: editableDates
            ? () => _pickActivityDate(context, 'started', widget.startedAt)
            : null,
      ),
      _buildProgressTile(
        icon: Icons.check_circle_outline,
        label: l.activityDatesCompleted,
        value: widget.completedAt != null ? fmt(widget.completedAt!) : '—',
        hasValue: widget.completedAt != null,
        tooltip: widget.completionTime != null
            ? formatCompletionTime(widget.completionTime!, l)
            : null,
        onTap: editableDates
            ? () => _pickActivityDate(context, 'completed', widget.completedAt)
            : null,
      ),
      if (widget.onTimeSpentTap != null)
        _buildProgressTile(
          icon: Icons.timer_outlined,
          label: l.timeSpentTitle,
          value: widget.timeSpentMinutes > 0
              ? l.timeSpentValue(hours, minutes)
              : '—',
          hasValue: widget.timeSpentMinutes > 0,
          onTap: widget.onTimeSpentTap,
        ),
      if (widget.onRewatchCountTap != null)
        _buildProgressTile(
          icon: Icons.replay,
          label: l.rewatchCountEdit,
          value: widget.rewatchCount?.toString() ?? '—',
          hasValue: widget.rewatchCount != null,
          onTap: widget.onRewatchCountTap,
        ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int perRow =
            constraints.maxWidth < 480 ? 2 : tiles.length;
        final List<Widget> rows = <Widget>[];
        for (int i = 0; i < tiles.length; i += perRow) {
          final int end =
              (i + perRow > tiles.length) ? tiles.length : i + perRow;
          final List<Widget> chunk = tiles.sublist(i, end);
          if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.sm));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int j = 0; j < perRow; j++) ...<Widget>[
                  if (j > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: j < chunk.length ? chunk[j] : const SizedBox(),
                  ),
                ],
              ],
            ),
          );
        }
        final Widget grid = Column(children: rows);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: grid),
            const SizedBox(width: AppSpacing.xs),
            _buildSystemMetaInfoButton(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressTile({
    required IconData icon,
    required String label,
    required String value,
    required bool hasValue,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final Widget body = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: AppColors.brand,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    Widget tile = Material(
      color: AppColors.surfaceLight.withAlpha(120),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: body,
            )
          : body,
    );
    if (tooltip != null) {
      tile = Tooltip(message: tooltip, child: tile);
    }
    return tile;
  }

  String Function(DateTime) _dateFormatter(BuildContext context) {
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.dateFormat),
      ),
    );
    final String localeName = Localizations.localeOf(context).toLanguageTag();
    return (DateTime d) => _formatActivityDate(d, preset, localeName);
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
        '${l.activityDatesLastActivity}: ${fmt(widget.lastActivityAt!)}',
      if (widget.completionTime != null)
        formatCompletionTime(widget.completionTime!, l),
    ];
  }

  Future<void> _pickActivityDate(
    BuildContext context,
    String type,
    DateTime? current,
  ) async {
    final DateTime initialDate = current ?? DateTime.now();
    final DateTime firstDate = DateTime(1980);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDualDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: type == 'started'
          ? S.of(context).activityDatesSelectStart
          : S.of(context).activityDatesSelectCompletion,
    );

    if (picked != null && context.mounted) {
      await widget.onActivityDateChanged!(type, picked);
    }
  }

  Widget _buildSystemMetaInfoButton(BuildContext context) {
    final String text = _systemMetaParts(context).join('\n');
    return IconButton(
      icon: const Icon(
        Icons.info_outline,
        size: 16,
        color: AppColors.textTertiary,
      ),
      visualDensity: VisualDensity.compact,
      tooltip: text,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(S.of(ctx).activityDatesTitle),
          content: SingleChildScrollView(
            child: Text(
              text,
              style: AppTypography.body.copyWith(height: 1.6),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.of(ctx).done),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (widget.coverUrl == null || widget.coverUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final bool useLocalCache =
        widget.cacheImageType != null && widget.cacheImageId != null;

    if (useLocalCache) {
      return CachedImage(
        imageType: widget.cacheImageType!,
        imageId: widget.cacheImageId!,
        remoteUrl: widget.coverUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        placeholder: _buildLoadingPlaceholder(),
        errorWidget: _buildPlaceholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.coverUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      placeholder: (BuildContext ctx, String url) => _buildLoadingPlaceholder(),
      errorWidget: (BuildContext ctx, String url, Object error) =>
          _buildPlaceholder(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        widget.placeholderIcon,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return widget.statusWidget!;
  }

  Widget _buildUserRatingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.star, size: 18, color: AppColors.ratingStar),
            const SizedBox(width: 6),
            Text(
              S.of(context).detailMyRating,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            if (widget.userRating != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                S.of(context).detailRatingValue(
                      widget.userRating!.toStringAsFixed(1),
                    ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        FractionalStarRating(
          value: widget.userRating,
          onChanged: widget.onUserRatingChanged!,
        ),
      ],
    );
  }

  Widget _buildAuthorCommentSection(BuildContext context) {
    final S l = S.of(context);
    final bool isEditing = _editingField == _EditingField.author;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.format_quote,
                    size: 18,
                    color: AppColors.movieAccent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.detailAuthorReview,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isEditable)
              IconButton(
                onPressed: isEditing
                    ? _finishEditing
                    : () => _startEditing(_EditingField.author),
                icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                tooltip: isEditing ? l.done : l.edit,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l.detailReviewVisibility,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 6),
        _buildCommentContainer(
          accentColor: AppColors.movieAccent,
          isEditing: isEditing,
          controller: _authorController,
          hint: l.detailWriteReviewHint,
          hasContent: widget.hasAuthorComment,
          onTap: widget.isEditable
              ? () => _startEditing(_EditingField.author)
              : null,
          displayWidget: widget.hasAuthorComment
              ? MiniMarkdownText(
                  text: widget.authorComment!,
                  style: AppTypography.body.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  resolvedLinks: _resolvedCardLinks,
                  onCardLink: widget.onCardLinkTap,
                )
              : Text(
                  widget.isEditable
                      ? l.detailNoReviewEditable
                      : l.detailNoReviewReadonly,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserNotesSection(BuildContext context) {
    final S l = S.of(context);
    final bool isEditing = _editingField == _EditingField.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.detailMyNotes,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isEditing
                  ? _finishEditing
                  : () => _startEditing(_EditingField.user),
              icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: isEditing ? l.done : l.edit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildCommentContainer(
          accentColor: widget.accentColor,
          isEditing: isEditing,
          controller: _userController,
          hint: l.detailWriteNotesHint,
          hasContent: widget.hasUserComment,
          onTap: () => _startEditing(_EditingField.user),
          onInsertCardLink:
              widget.onCardLinkTap != null ? () => _insertCardLink() : null,
          displayWidget: widget.hasUserComment
              ? MiniMarkdownText(
                  text: widget.userComment!,
                  style: AppTypography.body.copyWith(height: 1.5),
                  resolvedLinks: _resolvedCardLinks,
                  onCardLink: widget.onCardLinkTap,
                )
              : Text(
                  l.detailNoNotesYet,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  /// When [onTap] is set, tapping the view-mode container enters editing
  /// directly. Markdown link taps still work via span recognizers.
  Widget _buildCommentContainer({
    required Color accentColor,
    required bool isEditing,
    required TextEditingController controller,
    required String hint,
    required bool hasContent,
    required Widget displayWidget,
    VoidCallback? onTap,
    VoidCallback? onInsertCardLink,
  }) {
    final BorderRadius radius = BorderRadius.circular(AppSpacing.radiusSm);
    final BoxDecoration decoration = BoxDecoration(
      color: accentColor.withAlpha(20),
      borderRadius: radius,
      border: Border.all(color: accentColor.withAlpha(isEditing ? 80 : 40)),
    );
    const EdgeInsets padding = EdgeInsets.all(AppSpacing.md - 4);

    if (isEditing) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MarkdownToolbar(
              controller: controller,
              onInsertCardLink: onInsertCardLink,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              maxLines: 5,
              minLines: 2,
              autofocus: true,
              style: AppTypography.body.copyWith(height: 1.5),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    final Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: decoration,
      child: displayWidget,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      );
    }
    return content;
  }
}

/// Info chip whose long joined text (genres, studios, tags) truncates to one
/// line; when truncated, tapping expands it to the full multi-line text and
/// back. Chips with an external [onTap] keep their original tap action.
class _InfoChip extends StatefulWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  State<_InfoChip> createState() => _InfoChipState();
}

class _InfoChipState extends State<_InfoChip> {
  /// Horizontal chrome around the text: padding 8+8, icon 12, icon gap 4.
  static const double _chrome = 32;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        bool overflows = false;
        if (constraints.maxWidth.isFinite) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout(
              maxWidth: (constraints.maxWidth - _chrome)
                  .clamp(0.0, double.infinity),
            );
          overflows = painter.didExceedMaxLines;
          painter.dispose();
        }
        final bool expandable =
            widget.onTap == null && (overflows || _expanded);

        final ShapeBorder shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: widget.onTap != null
              ? BorderSide(
                  color: (widget.iconColor ?? AppColors.textSecondary)
                      .withAlpha(60),
                )
              : BorderSide.none,
        );

        final Widget inner = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _expanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: _expanded ? 1 : 0),
                child: Icon(
                  widget.icon,
                  size: 12,
                  color: widget.iconColor ?? AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.text,
                  style: style,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  maxLines: _expanded ? null : 1,
                ),
              ),
            ],
          ),
        );

        return Material(
          color: AppColors.surfaceLight,
          shape: shape,
          child: widget.onTap != null || expandable
              ? InkWell(
                  customBorder: shape,
                  onTap: widget.onTap ??
                      () => setState(() => _expanded = !_expanded),
                  child: inner,
                )
              : inner,
        );
      },
    );
  }
}

/// Full-width description collapsed to a few lines with an expand toggle,
/// shown only when the text actually overflows.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() =>
      _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const int _collapsedLines = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.4,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final bool overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded
                        ? S.of(context).showLess
                        : S.of(context).showMore,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _launchExternalUrl(String url) async {
  try {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } on Exception {
    // External link is best-effort; failure is non-critical.
  }
}

/// Splits tracker + notes + author comment into a two-column layout (50/50)
/// on screens ≥600px when [trackerSection] is set, stacks otherwise.
class _TrackerCommentsLayout extends StatelessWidget {
  const _TrackerCommentsLayout({
    required this.trackerSection,
    required this.notesSection,
    required this.authorSection,
  });

  final Widget? trackerSection;
  final Widget notesSection;
  final Widget authorSection;

  @override
  Widget build(BuildContext context) {
    final Widget commentsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        notesSection,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(
            color: AppColors.surfaceBorder.withAlpha(80),
            height: 1,
          ),
        ),
        authorSection,
      ],
    );

    if (trackerSection == null) return commentsColumn;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 600) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: trackerSection!),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: commentsColumn),
              ],
            ),
          );
        }
        // Narrow window — stack vertically.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            trackerSection!,
            const SizedBox(height: AppSpacing.md),
            commentsColumn,
          ],
        );
      },
    );
  }
}

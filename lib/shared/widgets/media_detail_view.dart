import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'gyroscope_parallax_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/image_cache_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'markdown_toolbar.dart';
import 'mini_markdown_text.dart';
import 'source_badge.dart';
import 'star_rating_bar.dart';
import '../utils/duration_formatter.dart';

/// `type` is either 'started' or 'completed'.
typedef OnActivityDateChanged =
    Future<void> Function(String type, DateTime date);

String _formatActivityDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

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
class MediaDetailView extends StatefulWidget {
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

  /// 1..10.
  final int? userRating;
  final ValueChanged<int?>? onUserRatingChanged;
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

  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

enum _EditingField { none, author, user }

class _MediaDetailViewState extends State<MediaDetailView> {
  _EditingField _editingField = _EditingField.none;
  late final TextEditingController _authorController;
  late final TextEditingController _userController;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController(text: widget.authorComment);
    _userController = TextEditingController(text: widget.userComment);
    _authorController.addListener(_onAuthorChanged);
    _userController.addListener(_onUserChanged);
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
    _scheduleAutosave();
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
    final Widget content = ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(),
                if (widget.statusWidget != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _buildStatusSection(context),
                ],
                if (widget.onUserRatingChanged != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _buildUserRatingSection(context),
                ],
                if (widget.addedAt != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _buildActivityDatesRow(context),
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
                if (widget.extraSections != null &&
                    widget.extraSections!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _buildExtraSectionsExpansion(context),
                ],
                if (widget.recommendationSections != null &&
                    widget.recommendationSections!.isNotEmpty)
                  for (final Widget section
                      in widget.recommendationSections!) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    section,
                  ],
              ],
            ),
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

  Widget _buildHeader() {
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
                  if (widget.tagWidget != null) widget.tagWidget!,
                  if (widget.raBadge != null) widget.raBadge!,
                  if (widget.onTimeSpentTap != null) _buildTimeSpentChip(),
                ],
              ),
              if (widget.infoChips.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MediaDetailChip chip in widget.infoChips)
                      _buildInfoChip(
                        chip.icon,
                        chip.text,
                        iconColor: chip.iconColor,
                        onTap: chip.onTap,
                      ),
                  ],
                ),
              ],
              if (widget.description != null &&
                  widget.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
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

  Widget _buildTimeSpentChip() {
    final int hours = widget.timeSpentMinutes ~/ 60;
    final int minutes = widget.timeSpentMinutes % 60;
    final S l = S.of(context);
    final String display = widget.timeSpentMinutes > 0
        ? l.timeSpentValue(hours, minutes)
        : '—';

    return GestureDetector(
      onTap: widget.onTimeSpentTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: widget.timeSpentMinutes > 0
                ? AppColors.textSecondary
                : AppColors.textTertiary,
          ),
          const SizedBox(width: 3),
          Text(
            display,
            style: AppTypography.caption.copyWith(
              color: widget.timeSpentMinutes > 0
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: onTap != null
            ? Border.all(
                color: (iconColor ?? AppColors.textSecondary).withAlpha(60),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
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
                S.of(context).detailRatingValue(widget.userRating!),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        StarRatingBar(
          rating: widget.userRating,
          onChanged: widget.onUserRatingChanged!,
        ),
      ],
    );
  }

  Widget _buildActivityDatesRow(BuildContext context) {
    final S l = S.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        _buildDateChip(
          icon: Icons.add_circle_outline,
          label: l.activityDatesAdded,
          date: widget.addedAt,
        ),
        _buildDateChip(
          icon: Icons.play_circle_outline,
          label: l.activityDatesStarted,
          date: widget.startedAt,
          editable: widget.onActivityDateChanged != null,
          onTap: widget.onActivityDateChanged != null
              ? () => _pickActivityDate(context, 'started', widget.startedAt)
              : null,
        ),
        _buildDateChip(
          icon: Icons.check_circle_outline,
          label: l.activityDatesCompleted,
          date: widget.completedAt,
          editable: widget.onActivityDateChanged != null,
          onTap: widget.onActivityDateChanged != null
              ? () =>
                    _pickActivityDate(context, 'completed', widget.completedAt)
              : null,
        ),
        if (widget.completionTime != null) _buildCompletionTimeChip(l),
        if (widget.lastActivityAt != null)
          _buildDateChip(
            icon: Icons.update,
            label: l.activityDatesLastActivity,
            date: widget.lastActivityAt,
          ),
      ],
    );
  }

  Widget _buildCompletionTimeChip(S l) {
    final String formatted = formatCompletionTime(widget.completionTime!, l);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.timer_outlined,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          formatted,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    DateTime? date,
    bool editable = false,
    VoidCallback? onTap,
  }) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
        Text(
          date != null ? _formatActivityDate(date) : '\u2014',
          style: AppTypography.bodySmall.copyWith(
            color: date != null
                ? AppColors.textSecondary
                : AppColors.textTertiary,
          ),
        ),
        if (editable) ...<Widget>[
          const SizedBox(width: 2),
          const Icon(Icons.edit_outlined, size: 12, color: AppColors.brand),
        ],
      ],
    );

    if (editable && onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: content,
    );
  }

  Future<void> _pickActivityDate(
    BuildContext context,
    String type,
    DateTime? current,
  ) async {
    final DateTime initialDate = current ?? DateTime.now();
    final DateTime firstDate = DateTime(1980);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
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

  Widget _buildExtraSectionsExpansion(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          S.of(context).detailActivityProgress,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: <Widget>[
          for (final Widget section in widget.extraSections!) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            section,
          ],
        ],
      ),
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
          displayWidget: widget.hasUserComment
              ? MiniMarkdownText(
                  text: widget.userComment!,
                  style: AppTypography.body.copyWith(height: 1.5),
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
            MarkdownToolbar(controller: controller),
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

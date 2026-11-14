import 'package:core/models/tag.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../helpers/tag_name_filter.dart';

/// Wide-screen tag filter: one horizontal chip row above the items view.
/// Supports multi-select: a click toggles a tag, the reset chip clears all.
class TagTopBar extends StatefulWidget {
  const TagTopBar({
    required this.tags,
    required this.counts,
    required this.onTagToggled,
    required this.onGroupToggled,
    this.selectedTagIds = const <int>{},
    this.groupByTags = false,
    super.key,
  });

  final List<Tag> tags;

  /// Per-tag item counts within the current collection.
  final Map<int, int> counts;

  /// Empty set means "show everything".
  final Set<int> selectedTagIds;

  final bool groupByTags;

  /// Called with `null` to reset all filters.
  final ValueChanged<int?> onTagToggled;

  final VoidCallback onGroupToggled;

  static const double height = 38.0;

  @override
  State<TagTopBar> createState() => _TagTopBarState();
}

class _TagTopBarState extends State<TagTopBar> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _queryFocus.addListener(_onQueryFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _query.dispose();
    _queryFocus
      ..removeListener(_onQueryFocusChanged)
      ..dispose();
    super.dispose();
  }

  /// An abandoned empty field folds back into the search chip so the row
  /// does not keep a dead input around.
  void _onQueryFocusChanged() {
    if (!_queryFocus.hasFocus && _query.text.isEmpty && _searchOpen) {
      setState(() => _searchOpen = false);
    }
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _queryFocus.requestFocus();
  }

  void _clearSearch() {
    if (_query.text.isEmpty) {
      setState(() => _searchOpen = false);
      return;
    }
    setState(_query.clear);
    _queryFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool searchable = widget.tags.length >= kTagSearchMinTags;
    final List<Tag> visibleTags = filterTagsByName(
      widget.tags,
      _query.text,
      keepIds: widget.selectedTagIds,
    );
    return Container(
      height: TagTopBar.height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      // Same affordance as the genre-cloud legend row: edge-fade arrows on
      // desktop, wheel remap and touch/mouse drag come with the widget.
      child: ScrollableRowWithArrows(
        controller: _controller,
        height: TagTopBar.height,
        child: ListView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          children: <Widget>[
            _TagBarChip(
              key: const ValueKey<String>('tagTopBarGroup'),
              label: S.of(context).tagSidebarGroup,
              icon: Icons.workspaces_outlined,
              color: AppColors.brand,
              selected: widget.groupByTags,
              onTap: widget.onGroupToggled,
            ),
            if (widget.selectedTagIds.isNotEmpty)
              _TagBarChip(
                key: const ValueKey<String>('tagTopBarReset'),
                label: '${widget.selectedTagIds.length}',
                icon: Icons.filter_alt_off_outlined,
                color: AppColors.textSecondary,
                selected: true,
                onTap: () => widget.onTagToggled(null),
              ),
            if (searchable && !_searchOpen)
              _TagBarChip(
                key: const ValueKey<String>('tagTopBarSearch'),
                label: '',
                icon: Icons.search,
                color: AppColors.textSecondary,
                selected: false,
                onTap: _openSearch,
              ),
            if (searchable && _searchOpen)
              _TagBarSearchField(
                controller: _query,
                focusNode: _queryFocus,
                onChanged: () => setState(() {}),
                onClear: _clearSearch,
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 1,
              color: AppColors.surfaceBorder,
            ),
            if (visibleTags.isEmpty)
              Center(
                child: Text(
                  S.of(context).tagNone,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            for (final Tag tag in visibleTags)
              _TagBarChip(
                key: ValueKey<int>(tag.id),
                label: tag.name,
                count: widget.counts[tag.id] ?? 0,
                color: tag.color != null
                    ? Color(tag.color!)
                    : AppColors.textSecondary,
                labelColor: tag.textColor != null
                    ? Color(tag.textColor!)
                    : null,
                selected: widget.selectedTagIds.contains(tag.id),
                onTap: () => widget.onTagToggled(tag.id),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip-shaped inline input; collapsed decoration keeps it at chip height.
class _TagBarSearchField extends StatelessWidget {
  const _TagBarSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  static const double _width = 160;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Container(
        width: _width,
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.search, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('tagTopBarSearchField'),
                controller: controller,
                focusNode: focusNode,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: S.of(context).tagPickerSearchHint,
                  hintStyle: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            InkWell(
              key: const ValueKey<String>('tagTopBarSearchClear'),
              onTap: onClear,
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close, size: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBarChip extends StatelessWidget {
  const _TagBarChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.labelColor,
    this.count,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final Color? labelColor;
  final int? count;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected
        ? AppColors.textPrimary
        : (labelColor ?? color);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withAlpha(selected ? 70 : 20),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: color.withAlpha(selected ? 255 : 80),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 12, color: textColor),
                if (label.isNotEmpty) const SizedBox(width: 4),
              ],
              if (label.isNotEmpty)
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              if (count != null) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

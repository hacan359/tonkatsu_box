import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../markdown_toolbar.dart';

/// Header row of a comment section: icon + title and an optional edit/done
/// toggle button (hidden when [onToggleEdit] is `null`).
class CommentSectionHeader extends StatelessWidget {
  const CommentSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isEditing,
    this.onToggleEdit,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isEditing;
  final VoidCallback? onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (onToggleEdit != null)
          IconButton(
            onPressed: onToggleEdit,
            icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: isEditing ? l.done : l.edit,
          ),
      ],
    );
  }
}

/// Comment body: markdown toolbar + field while editing, else [displayWidget];
/// [onTap] enters editing from view mode without breaking link recognizers.
class CommentContainer extends StatelessWidget {
  const CommentContainer({
    required this.accentColor,
    required this.isEditing,
    required this.controller,
    required this.hint,
    required this.displayWidget,
    this.onTap,
    this.onInsertCardLink,
    super.key,
  });

  final Color accentColor;
  final bool isEditing;
  final TextEditingController controller;
  final String hint;
  final Widget displayWidget;
  final VoidCallback? onTap;
  final VoidCallback? onInsertCardLink;

  @override
  Widget build(BuildContext context) {
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

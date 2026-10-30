import 'package:core/models/card_link.dart';
import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../mini_markdown_text.dart';
import 'comment_container.dart';

/// A titled note block — the user's notes or the author review — that flips
/// between rendered markdown and an editor.
class DetailNoteSection extends StatelessWidget {
  const DetailNoteSection({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.isEditing,
    required this.controller,
    required this.hint,
    required this.text,
    required this.emptyText,
    required this.textStyle,
    required this.resolvedLinks,
    this.subtitle,
    this.onToggleEdit,
    this.onTap,
    this.onInsertCardLink,
    this.onCardLink,
    super.key,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final bool isEditing;
  final TextEditingController controller;
  final String hint;

  /// Saved text; `null` shows [emptyText] instead.
  final String? text;
  final String emptyText;
  final TextStyle textStyle;
  final Map<CardLinkRef, CollectionItem> resolvedLinks;

  /// `null` hides the edit toggle — a read-only card.
  final VoidCallback? onToggleEdit;
  final VoidCallback? onTap;
  final VoidCallback? onInsertCardLink;
  final void Function(CardLinkRef ref)? onCardLink;

  @override
  Widget build(BuildContext context) {
    final String? text = this.text;
    final String? subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CommentSectionHeader(
          icon: icon,
          iconColor: accentColor,
          title: title,
          isEditing: isEditing,
          onToggleEdit: onToggleEdit,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
        const SizedBox(height: 6),
        CommentContainer(
          accentColor: accentColor,
          isEditing: isEditing,
          controller: controller,
          hint: hint,
          onTap: onTap,
          onInsertCardLink: onInsertCardLink,
          displayWidget: text != null
              ? MiniMarkdownText(
                  text: text,
                  style: textStyle,
                  resolvedLinks: resolvedLinks,
                  onCardLink: onCardLink,
                )
              : Text(
                  emptyText,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }
}

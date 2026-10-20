import 'package:flutter/material.dart';

/// Icon + text descriptor for an info chip in the media detail header.
class MediaDetailChip {
  const MediaDetailChip({
    required this.icon,
    required this.text,
    this.iconColor,
    this.onTap,
    this.tooltip,
    this.isCreator = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color? iconColor;

  /// Names the role when the icon alone is ambiguous (director, publisher).
  final String? tooltip;

  /// A person or company credit; [tooltip] then holds its role.
  final bool isCreator;
}

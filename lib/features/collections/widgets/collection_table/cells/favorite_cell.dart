import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

/// Favorite column cell: a filled heart for favorites, a faint outline
/// otherwise. When [onToggle] is supplied the heart is tappable to flip the
/// flag inline (mirroring the editable rating / status cells).
class FavoriteCell extends StatelessWidget {
  const FavoriteCell({
    required this.isFavorite,
    this.onToggle,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget content = Center(
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 16,
        color: isFavorite ? AppColors.favorite : AppColors.textTertiary,
      ),
    );

    if (onToggle == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }
}

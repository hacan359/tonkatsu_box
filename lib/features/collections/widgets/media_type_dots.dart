import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// Avatar-stack of circular badges, one per media type in a collection.
/// Renders nothing for an empty [types].
class MediaTypeDots extends StatelessWidget {
  const MediaTypeDots({
    required this.types,
    this.dotSize = 20,
    super.key,
  });

  /// Types to show, dominant first (see `CollectionStats.presentMediaTypes`).
  final List<MediaType> types;

  final double dotSize;

  static const int _maxVisible = 5;

  /// Fraction of a dot's width the next one keeps — the rest overlaps.
  static const double _overlapFactor = 0.72;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();

    final bool overflows = types.length > _maxVisible;
    // One slot goes to the "+N" dot, so it never replaces a single type.
    final int shown = overflows ? _maxVisible - 1 : types.length;
    final int hidden = types.length - shown;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < shown; i++)
          _stacked(
            isFirst: i == 0,
            child: _TypeDot(type: types[i], size: dotSize),
          ),
        if (overflows)
          _stacked(
            isFirst: false,
            child: _OverflowDot(count: hidden, size: dotSize),
          ),
      ],
    );
  }

  Widget _stacked({required bool isFirst, required Widget child}) {
    if (isFirst) return child;
    return Align(
      alignment: Alignment.centerRight,
      widthFactor: _overlapFactor,
      child: child,
    );
  }
}

class _TypeDot extends StatelessWidget {
  const _TypeDot({required this.type, required this.size});

  final MediaType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color accent = MediaTypeTheme.colorFor(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Scrim-tinted fill with the accent in the ring and icon, so the
        // badge stays readable over busy poster art.
        color: AppColors.background.withValues(alpha: 0.82),
        border: Border.all(color: accent, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(
        MediaTypeTheme.iconFor(type),
        size: size * 0.58,
        color: accent,
      ),
    );
  }
}

class _OverflowDot extends StatelessWidget {
  const _OverflowDot({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background.withValues(alpha: 0.82),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

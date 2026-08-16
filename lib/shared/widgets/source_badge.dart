import 'package:flutter/material.dart';
export 'package:core/models/data_source.dart';
import 'package:core/models/data_source.dart';

import '../constants/data_source_ui.dart';

/// An [onTap] makes the badge clickable and adds an external-link icon.
class SourceBadge extends StatelessWidget {
  const SourceBadge({
    required this.source,
    this.size = SourceBadgeSize.small,
    this.onTap,
    super.key,
  });

  final DataSource source;

  final SourceBadgeSize size;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size.borderRadius),
        border: Border.all(
          color: source.color.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (source.iconAsset != null) ...<Widget>[
            Image.asset(
              source.iconAsset!,
              width: size.fontSize * 1.4,
              height: size.fontSize * 1.4,
              filterQuality: FilterQuality.medium,
            ),
            SizedBox(width: size.fontSize * 0.4),
          ],
          Text(
            source.label,
            style: TextStyle(
              color: source.color,
              fontSize: size.fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
          if (onTap != null) ...<Widget>[
            SizedBox(width: size.fontSize * 0.3),
            Icon(
              Icons.open_in_new,
              size: size.fontSize,
              color: source.color,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size.borderRadius),
        child: badge,
      );
    }

    return badge;
  }
}

enum SourceBadgeSize {
  small(fontSize: 8, horizontalPadding: 4, verticalPadding: 2, borderRadius: 3),

  medium(fontSize: 10, horizontalPadding: 6, verticalPadding: 3, borderRadius: 4),

  large(fontSize: 12, horizontalPadding: 8, verticalPadding: 4, borderRadius: 6);

  const SourceBadgeSize({
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });

  final double fontSize;

  final double horizontalPadding;

  final double verticalPadding;

  final double borderRadius;
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/url_launch.dart';
import '../source_badge.dart';
import 'media_detail_chip.dart';

/// Cover + short identity facts: source, type, RA badge, info chips.
class IdentityHeader extends StatelessWidget {
  const IdentityHeader({
    required this.cover,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.accentColor,
    required this.infoChips,
    this.externalUrl,
    this.raBadge,
    this.platformOverlayAsset,
    super.key,
  });

  final Widget cover;
  final DataSource source;
  final IconData typeIcon;
  final String typeLabel;
  final Color accentColor;
  final List<MediaDetailChip> infoChips;
  final String? externalUrl;
  final Widget? raBadge;

  /// Platform-overlay asset path (PNG 600×900).
  final String? platformOverlayAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(
            platformOverlayAsset != null ? 0 : AppSpacing.radiusSm,
          ),
          child: SizedBox(
            width: 100,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                cover,
                if (platformOverlayAsset != null)
                  Image.asset(platformOverlayAsset!, fit: BoxFit.fill),
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
                    source: source,
                    size: SourceBadgeSize.medium,
                    onTap: externalUrl != null
                        ? () => launchExternalUrl(externalUrl!)
                        : null,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(typeIcon, size: 16, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  ?raBadge,
                ],
              ),
              if (infoChips.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MediaDetailChip chip in infoChips)
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

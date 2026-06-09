import 'package:flutter/material.dart';

import '../models/data_source.dart';

/// A [DataSource]'s brand logo, with a colored monogram fallback when the
/// source has no logo asset. Set [showGlow] for a soft brand-colored halo.
class SourceLogo extends StatelessWidget {
  const SourceLogo({
    required this.source,
    this.size = 32,
    this.showGlow = false,
    super.key,
  });

  final DataSource source;
  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final String? asset = source.iconAsset;
    final Widget logo = asset != null
        ? Image.asset(
            asset,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
          )
        : _Monogram(source: source, size: size);

    if (!showGlow) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: source.color.withAlpha(80),
            blurRadius: size * 0.55,
            spreadRadius: 1,
          ),
        ],
      ),
      child: logo,
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.source, required this.size});

  final DataSource source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String letter =
        source.label.isNotEmpty ? source.label[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: source.color.withAlpha(40),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: source.color.withAlpha(120)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: source.color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}

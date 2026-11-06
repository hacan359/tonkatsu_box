import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../gyroscope_parallax_image.dart';

/// Artwork along the top of a title block, washed and fading out downwards
/// so the block's own fill takes over before the text gets dense.
class MediaDetailBackdrop extends StatelessWidget {
  const MediaDetailBackdrop({required this.imageUrl, super.key});

  final String imageUrl;

  /// Taller blocks keep the artwork to this band, or a cover fit would zoom
  /// a wide picture into a blurry crop.
  static const double _maxHeight = 420;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double height = c.maxHeight.isFinite
            ? math.min(c.maxHeight, _maxHeight)
            : _maxHeight;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.white, Colors.white.withAlpha(0)],
                stops: const <double>[0.2, 1.0],
              ).createShader(bounds),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  GyroscopeParallaxImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

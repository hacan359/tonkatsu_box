import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../theme/app_assets.dart';

/// The layer sizes below are in the logo asset's own pixels.
const double _kAssetSize = 512;

/// Down-right: light comes from the top left, so the sides show below.
const Offset _kExtrude = Offset(0.41, 0.91);

const int _kMaxSideCopies = 12;
const double _kShadowReach = 1.4;
const double _kShadowBlur = 0.6;
const double _kShadowAlpha = 0.35;
const double _kHighlightAlpha = 0.16;
const double _kHighlightReach = 0.55;

/// One lifting part of the logo. Side colours are the logo's own, shaded,
/// not theme colours: the logo looks the same in every palette.
class _Part {
  const _Part(this.asset, this.depth, this.grow, this.side, this.interval);

  final String asset;
  final double depth;

  /// Scale gained at full lift: a nearer object reads bigger.
  final double grow;
  final Color side;
  final Interval interval;
}

const Color _kClapperSide = Color(0xFF261E1A);
const Color _kPieceSide = Color(0xFFB05026);

/// The clapper rises first, then the cutlets one by one from the left.
final List<_Part> _kParts = <_Part>[
  const _Part(
    AppAssets.logoClapper,
    14,
    0.015,
    _kClapperSide,
    Interval(0, 0.55, curve: Curves.easeOutCubic),
  ),
  for (int i = 0; i < AppAssets.logoPieces.length; i++)
    _Part(
      AppAssets.logoPieces[i],
      10,
      0.03,
      _kPieceSide,
      Interval(0.3 + i * 0.08, 0.68 + i * 0.08, curve: Curves.easeOutBack),
    ),
];

/// The app logo whose clapper and cutlets rise off the flat base as [lift]
/// runs from 0 to 1; at 0 it is pixel for pixel the flat logo.
class VolumetricLogo extends StatelessWidget {
  const VolumetricLogo({required this.lift, this.size = 200, super.key});

  final Animation<double> lift;
  final double size;

  /// Decodes every layer up front so the first frames do not pop in.
  static Future<void> precache(BuildContext context) => Future.wait(
    <String>[
      AppAssets.logoBase,
      for (final _Part p in _kParts) p.asset,
    ].map((String a) => precacheImage(AssetImage(a), context)),
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: lift,
          builder: (BuildContext context, Widget? base) {
            final double t = lift.value.clamp(0.0, 1.0);
            final List<Widget> layers = <Widget>[?base];
            for (final _Part part in _kParts) {
              final double p = part.interval.transform(t);
              layers.addAll(_lifted(part, p));
            }
            return Stack(fit: StackFit.expand, children: layers);
          },
          child: _image(AppAssets.logoBase),
        ),
      ),
    );
  }

  List<Widget> _lifted(_Part part, double p) {
    final double depth = part.depth * p * size / _kAssetSize;
    final Widget top = _scaled(part, p, _highlighted(_image(part.asset), p));
    if (depth < 0.5) return <Widget>[top];
    final int copies = math.min(depth.ceil(), _kMaxSideCopies);
    final double sigma = depth * _kShadowBlur;
    return <Widget>[
      Transform.translate(
        offset: _kExtrude * depth * _kShadowReach,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: _image(
            part.asset,
            tint: Colors.black.withValues(alpha: _kShadowAlpha * p),
          ),
        ),
      ),
      // Back to front, so nearer slices cover farther ones.
      for (int k = copies; k > 0; k--)
        Transform.translate(
          offset: _kExtrude * (depth * k / copies),
          child: _scaled(part, p, _image(part.asset, tint: part.side)),
        ),
      top,
    ];
  }

  static Widget _scaled(_Part part, double p, Widget child) =>
      Transform.scale(scale: 1 + part.grow * p, child: child);

  static Widget _highlighted(Widget child, double p) {
    if (p <= 0) return child;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withValues(alpha: _kHighlightAlpha * p),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, _kHighlightReach],
      ).createShader(bounds),
      child: child,
    );
  }

  static Widget _image(String asset, {Color? tint}) => Image.asset(
    asset,
    fit: BoxFit.contain,
    color: tint,
    colorBlendMode: tint == null ? null : BlendMode.srcIn,
    gaplessPlayback: true,
  );
}

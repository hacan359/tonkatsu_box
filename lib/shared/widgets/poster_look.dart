import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surface.dart';

/// Selectable poster card looks. [id] is the SharedPreferences value: stable,
/// never rename.
enum PosterLook {
  classic('classic'),
  curved('curved'),
  slab('slab'),
  jewel('jewel'),
  cinema('cinema'),
  shelf('shelf'),
  tilt('tilt'),
  kino('kino'),
  minimal('minimal'),
  ribbon('ribbon');

  const PosterLook(this.id);

  final String id;

  static PosterLook fromId(String? id) => PosterLook.values.firstWhere(
    (PosterLook look) => look.id == id,
    orElse: () => PosterLook.classic,
  );
}

/// Hands the chosen look to every card and grid below it.
class PosterLookScope extends InheritedWidget {
  const PosterLookScope({required this.look, required super.child, super.key});

  final PosterLook look;

  /// The looks are drawn for glass, so any other skin gets the classic card.
  static PosterLook of(BuildContext context) {
    final PosterLookScope? scope = context
        .dependOnInheritedWidgetOfExactType<PosterLookScope>();
    if (scope == null || AppSurface.wallpaperBlurSigma <= 0) {
      return PosterLook.classic;
    }
    return scope.look;
  }

  @override
  bool updateShouldNotify(PosterLookScope oldWidget) => look != oldWidget.look;
}

/// The hairline that reads as a glass edge on every palette.
Color posterRim([int alpha = 38]) => AppColors.onOverlay.withAlpha(alpha);

Color posterFrost(int dark, int light) {
  final bool isLight = AppColors.palette.brightness == Brightness.light;
  return AppColors.background.withAlpha(isLight ? light : dark);
}

List<BoxShadow> posterLift(double t) => <BoxShadow>[
  BoxShadow(
    color: AppColors.shadow.withAlpha((40 + 60 * t).round()),
    blurRadius: 14 + 14 * t,
    offset: Offset(0, 6 + 6 * t),
    spreadRadius: -6,
  ),
];

/// The poster as a lifted object with a rim and a hover shadow.
class PosterObject extends StatelessWidget {
  const PosterObject({
    required this.child,
    required this.hover,
    this.radius = AppSpacing.radiusMd,
    super.key,
  });

  final Widget child;
  final Animation<double> hover;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hover,
      builder: (BuildContext context, Widget? child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: posterLift(hover.value),
          ),
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: posterRim(30)),
        ),
        position: DecorationPosition.foreground,
        child: child,
      ),
    );
  }
}

/// Tilts the child toward the pointer in perspective and drags a glare
/// across it, the way a physical case catches the light.
class PosterTilt extends StatefulWidget {
  const PosterTilt({
    required this.child,
    this.radius = AppSpacing.radiusMd,
    super.key,
  });

  final Widget child;
  final double radius;

  @override
  State<PosterTilt> createState() => _PosterTiltState();
}

class _PosterTiltState extends State<PosterTilt> {
  // Pointer position in -1..1 on both axes; zero is the resting pose.
  Offset _target = Offset.zero;
  bool _inside = false;

  static const double _maxAngle = 0.14;
  static const double _perspective = 0.0012;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent event) {
        final Size size = context.size ?? Size.zero;
        if (size.isEmpty) return;
        setState(() {
          _inside = true;
          _target = Offset(
            (event.localPosition.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
            (event.localPosition.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
          );
        });
      },
      onExit: (_) => setState(() {
        _inside = false;
        _target = Offset.zero;
      }),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _target),
        duration: Duration(milliseconds: _inside ? 90 : 320),
        curve: Curves.easeOut,
        builder: (BuildContext context, Offset p, Widget? child) {
          final double strength = p.distance.clamp(0.0, 1.0);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, _perspective)
              ..rotateX(p.dy * _maxAngle)
              ..rotateY(-p.dx * _maxAngle),
            child: Stack(
              fit: StackFit.passthrough,
              children: <Widget>[
                child ?? const SizedBox.shrink(),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.radius),
                        gradient: RadialGradient(
                          center: Alignment(p.dx, p.dy),
                          radius: 0.9,
                          colors: <Color>[
                            AppColors.onOverlay.withAlpha(
                              (70 * strength).round(),
                            ),
                            AppColors.onOverlay.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Fakes a waterfall screen: both side edges fall away into shade with a
/// specular line where the glass bends.
class PosterCurvedGlass extends StatelessWidget {
  const PosterCurvedGlass({
    required this.child,
    this.radius = AppSpacing.radiusLg,
    super.key,
  });

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color shade = AppColors.scrim.withAlpha(165);
    final Color bend = AppColors.scrim.withAlpha(60);
    final Color glint = AppColors.onOverlay.withAlpha(120);
    final Color clear = AppColors.scrim.withAlpha(0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      shade,
                      glint,
                      bend,
                      clear,
                      clear,
                      bend,
                      glint,
                      shade,
                    ],
                    stops: const <double>[
                      0,
                      0.018,
                      0.05,
                      0.13,
                      0.87,
                      0.95,
                      0.982,
                      1,
                    ],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.onOverlay.withAlpha(45),
                        AppColors.onOverlay.withAlpha(0),
                        clear,
                        AppColors.scrim.withAlpha(70),
                      ],
                      stops: const <double>[0, 0.07, 0.93, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A thick block seen slightly from above: the child is the top face, a
/// tinted side shows under it and the face sinks into it on hover.
class PosterSlab extends StatelessWidget {
  const PosterSlab({
    required this.child,
    required this.hover,
    required this.sideColor,
    this.radius = AppSpacing.radiusMd,
    this.depth = 7,
    super.key,
  });

  final Widget child;
  final Animation<double> hover;
  final Color sideColor;
  final double radius;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final Widget side = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: <Color>[
            Color.lerp(sideColor, AppColors.scrim, 0.35) ?? sideColor,
            sideColor,
            Color.lerp(sideColor, AppColors.scrim, 0.5) ?? sideColor,
          ],
          stops: const <double>[0, 0.2, 1],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow.withAlpha(110),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: hover,
      builder: (BuildContext context, Widget? child) {
        final double press =
            depth * 0.65 * Curves.easeOut.transform(hover.value);
        return Stack(
          children: <Widget>[
            Positioned(left: 0, right: 0, top: depth, bottom: 0, child: side),
            Positioned(
              left: 0,
              right: 0,
              top: press,
              bottom: depth - press,
              child: child ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: posterRim(45)),
        ),
        child: child,
      ),
    );
  }
}

/// A plastic case over the child: a bevelled edge lit from the top left, a
/// fixed gloss across the top and a sheen that sweeps over on hover.
class PosterJewel extends StatelessWidget {
  const PosterJewel({
    required this.child,
    required this.hover,
    this.radius = AppSpacing.radiusMd,
    super.key,
  });

  final Widget child;
  final Animation<double> hover;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _JewelPainter(hover: hover, radius: radius),
      child: child,
    );
  }
}

class _JewelPainter extends CustomPainter {
  _JewelPainter({required this.hover, required this.radius})
    : super(repaint: hover);

  final Animation<double> hover;
  final double radius;

  static const double _bevel = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(outer);

    final Path gloss = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.26,
        0,
        size.height * 0.52,
      )
      ..close();
    canvas.drawPath(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.onOverlay.withAlpha(70),
            AppColors.onOverlay.withAlpha(8),
          ],
        ).createShader(rect),
    );

    final double t = hover.value;
    if (t > 0 && t < 1) {
      final double band = size.width * 0.35;
      final double x = -band + (size.width + 2 * band) * t;
      final Path sheen = Path()
        ..moveTo(x, 0)
        ..lineTo(x + band, 0)
        ..lineTo(x + band - size.height * 0.35, size.height)
        ..lineTo(x - size.height * 0.35, size.height)
        ..close();
      canvas.drawPath(
        sheen,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              AppColors.onOverlay.withAlpha(0),
              AppColors.onOverlay.withAlpha(90),
              AppColors.onOverlay.withAlpha(0),
            ],
          ).createShader(Rect.fromLTWH(x - band, 0, 2 * band, size.height)),
      );
    }

    canvas.drawRRect(
      outer.deflate(_bevel / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _bevel
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.onOverlay.withAlpha(170),
            AppColors.onOverlay.withAlpha(20),
            AppColors.scrim.withAlpha(30),
            AppColors.scrim.withAlpha(150),
          ],
          stops: const <double>[0, 0.4, 0.6, 1],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JewelPainter oldDelegate) =>
      radius != oldDelegate.radius || hover != oldDelegate.hover;
}

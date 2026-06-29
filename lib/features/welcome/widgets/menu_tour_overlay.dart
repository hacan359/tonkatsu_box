// Coachmark over the live navigation: dims the screen, cuts a spotlight around
// the real button for the current step, and shows a description card beside it.
// Steps run over the real [AppShell], so the buttons are located by reading the
// shared [navTourKeysProvider] keys' render boxes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/nav_tour_keys.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/menu_tour_provider.dart';
import 'menu_tour_items.dart';
import 'welcome_card.dart';

/// Spotlight tour over the real menu. Drawn full-screen above [AppShell]; ends
/// by flipping [menuTourControllerProvider] off.
class MenuTourOverlay extends ConsumerStatefulWidget {
  /// Creates a [MenuTourOverlay].
  const MenuTourOverlay({super.key});

  @override
  ConsumerState<MenuTourOverlay> createState() => _MenuTourOverlayState();
}

class _MenuTourOverlayState extends ConsumerState<MenuTourOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _index = 0;
  late final AnimationController _pulse;

  /// Inflated rect of the current button, read after layout (see [_syncSpot]).
  Rect? _spot;
  int _retries = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scheduleSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Window resize / rail↔bottom-bar swap → re-read button positions.
    _scheduleSync();
  }

  void _next(int count) {
    if (_index < count - 1) {
      // Drop the old rect so the spotlight never lands on the wrong button for
      // a frame; [_syncSpot] fills in the new one once layout settles.
      setState(() {
        _index++;
        _spot = null;
        _retries = 0;
      });
      _scheduleSync();
    } else {
      _finish();
    }
  }

  void _finish() => ref.read(menuTourControllerProvider.notifier).stop();

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _syncSpot());
  }

  /// Reads the current button's rect after the frame — when its element is
  /// active and laid out, unlike during build — and stores it, retrying a few
  /// frames while it isn't available yet.
  void _syncSpot() {
    if (!mounted) return;
    final List<MenuTourItem> items = buildMenuTourItems(context);
    if (items.isEmpty) return;
    final MenuTourItem item = items[_index.clamp(0, items.length - 1)];
    final Rect? rect = _readRect(item);
    if (rect != null) {
      _retries = 0;
      final Rect spot = rect.inflate(8);
      if (spot != _spot) setState(() => _spot = spot);
    } else if (_retries < 5) {
      _retries++;
      _scheduleSync();
    }
  }

  /// On-screen rect of [item]'s real button, or null if it isn't available.
  Rect? _readRect(MenuTourItem item) {
    final NavTourKeys keys = ref.read(navTourKeysProvider);
    final GlobalKey key = item.isPersonalization
        ? keys.personalization
        : keys.keyFor(item.tab!);
    final RenderObject? box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<MenuTourItem> items = buildMenuTourItems(context);
    if (items.isEmpty) return const SizedBox.shrink();

    final int index = _index.clamp(0, items.length - 1);
    final MenuTourItem item = items[index];
    final bool isLast = index == items.length - 1;
    final Rect? spot = _spot;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _next(items.length),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: _SpotlightPainter(spot: spot, glow: _pulse.value),
                  );
                },
              ),
            ),
          ),
          if (spot != null)
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _CardLayoutDelegate(target: spot),
                child: _TourCard(
                  item: item,
                  position: index + 1,
                  total: items.length,
                  nextLabel: isLast ? l.done : l.next,
                  skipLabel: l.skip,
                  isLast: isLast,
                  onNext: () => _next(items.length),
                  onSkip: _finish,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints the dim layer with a rounded cutout around [spot] plus a pulsing ring.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.spot, required this.glow});

  final Rect? spot;
  final double glow;

  static const double _radius = 14;

  /// Opacity of the dim layer over the app. Dense enough that the real UI's
  /// text behind it stays subdued and doesn't clash with the tour card.
  static const int _scrimAlpha = 200;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    final Paint dim = Paint()..color = Colors.black.withAlpha(_scrimAlpha);

    final Rect? spot = this.spot;
    if (spot == null) {
      canvas.drawRect(full, dim);
      return;
    }

    final RRect hole = RRect.fromRectAndRadius(
      spot,
      const Radius.circular(_radius),
    );
    final Path scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(hole),
    );
    canvas.drawPath(scrim, dim);

    final Paint glowRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.brand.withAlpha(220)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 6 * glow);
    canvas.drawRRect(hole, glowRing);

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.brand.withAlpha((150 + 105 * glow).round());
    canvas.drawRRect(hole, ring);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.spot != spot || oldDelegate.glow != glow;
}

/// Places the card beside the spotlight, on the side with the most room.
class _CardLayoutDelegate extends SingleChildLayoutDelegate {
  _CardLayoutDelegate({required this.target});

  final Rect target;

  static const double _gap = 16;
  static const double _margin = 12;
  static const double _maxCardWidth = 360;

  /// How close to an edge a button must be to count as "on" the bar there.
  static const double _edgeZone = 96;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: (constraints.maxWidth - _margin * 2).clamp(0, _maxCardWidth),
      maxHeight: constraints.maxHeight - _margin * 2,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Pick the side from where the button sits: bottom bar → above, rail (left)
    // → right, gear (top-right) → below, otherwise whichever side has room.
    final bool atBottomBar = target.bottom > size.height - _edgeZone;
    final bool atRail = target.center.dx < size.width * 0.35;
    final bool atTopRight =
        target.top < _edgeZone && target.center.dx > size.width * 0.6;

    double x;
    double y;
    if (atBottomBar) {
      y = target.top - _gap - childSize.height;
      x = target.center.dx - childSize.width / 2;
    } else if (atRail) {
      x = target.right + _gap;
      y = target.center.dy - childSize.height / 2;
    } else if (atTopRight) {
      y = target.bottom + _gap;
      x = target.center.dx - childSize.width / 2;
    } else if (size.width - target.right - _gap >= childSize.width) {
      x = target.right + _gap;
      y = target.center.dy - childSize.height / 2;
    } else {
      x = target.left - _gap - childSize.width;
      y = target.center.dy - childSize.height / 2;
    }

    return Offset(
      x.clamp(_margin, size.width - childSize.width - _margin),
      y.clamp(_margin, size.height - childSize.height - _margin),
    );
  }

  @override
  bool shouldRelayout(_CardLayoutDelegate oldDelegate) =>
      oldDelegate.target != target;
}

/// The description card: icon, label, description and step controls.
class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.item,
    required this.position,
    required this.total,
    required this.nextLabel,
    required this.skipLabel,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final MenuTourItem item;
  final int position;
  final int total;
  final String nextLabel;
  final String skipLabel;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return WelcomeCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(item.activeIcon, size: 22, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(child: Text(item.label, style: AppTypography.h3)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(skipLabel, style: const TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              Text(
                '$position / $total',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.black,
                  // The theme makes FilledButtons full-width; pin a content
                  // min so this one fits inside the Row.
                  minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      nextLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isLast ? Icons.check : Icons.arrow_forward,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

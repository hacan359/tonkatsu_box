import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/poster_grid_delegate.dart';

/// One app-wide shimmer clock: a loading grid would otherwise run one
/// AnimationController per box. Ticks only while at least one box listens.
class _ShimmerTimeline {
  _ShimmerTimeline._();

  static final _ShimmerTimeline instance = _ShimmerTimeline._();

  static const int _periodMs = 1500;

  /// Shared sweep phase, 0..1; every box reads the same value, so all
  /// placeholders on screen shimmer as one synchronized wave.
  final ValueNotifier<double> phase = ValueNotifier<double>(0);

  Ticker? _ticker;
  int _clients = 0;

  void acquire() {
    _clients++;
    if (_ticker != null) return;
    _ticker = Ticker(_onTick)..start();
  }

  void release() {
    if (_clients == 0) return;
    _clients--;
    if (_clients > 0) return;
    _ticker?.dispose();
    _ticker = null;
    // The next batch starts a fresh Ticker from zero elapsed, so leaving the
    // old phase behind would make its first frame jump mid-sweep. Deferred:
    // release runs from didChangeDependencies / dispose, and notifying the
    // boxes still listening would rebuild them mid-build.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (_clients == 0) phase.value = 0;
    });
  }

  void _onTick(Duration elapsed) {
    phase.value = (elapsed.inMilliseconds % _periodMs) / _periodMs;
  }
}

/// Base shimmer block with an animated gradient.
///
/// Building block for loading placeholders.
class ShimmerBox extends StatefulWidget {
  /// Creates a shimmer block.
  const ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
    super.key,
  });

  /// Block width.
  final double width;

  /// Block height.
  final double height;

  /// Corner radius.
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> {
  bool _listening = false;

  // TickerMode gates the shared clock the way it would gate an own
  // controller: boxes on a covered route stop demanding frames.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _listening) return;
    _listening = enabled;
    if (enabled) {
      _ShimmerTimeline.instance.acquire();
    } else {
      _ShimmerTimeline.instance.release();
    }
  }

  @override
  void dispose() {
    if (_listening) {
      _ShimmerTimeline.instance.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hoisted out of the per-frame builder: only the gradient stops move, and
    // a loading grid rebuilds dozens of these every frame.
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    final List<Color> colors = <Color>[
      AppColors.surface,
      AppColors.surfaceLight,
      AppColors.surface,
    ];
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder<double>(
        valueListenable: _ShimmerTimeline.instance.phase,
        builder: (BuildContext context, double phase, Widget? child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * phase, 0),
                end: Alignment(-1.0 + 2.0 * phase + 1.0, 0),
                colors: colors,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Includes the title block so the skeleton gives the poster the same height
/// as a real [MediaPosterCard].
class ShimmerPosterCard extends StatelessWidget {
  /// Creates a poster card shimmer placeholder.
  const ShimmerPosterCard({this.compact = false, super.key});

  /// Mirrors the compact card variant (landscape phone).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Expanded(
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: AppSpacing.radiusMd,
          ),
        ),
        SizedBox(
          height: AppSpacing.cardTitleBlockHeight(
            compact: compact,
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.cardTitleBlockGap(compact: compact),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(width: 100, height: 12),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 60, height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ShimmerTierListCard extends StatelessWidget {
  /// Creates a tier list card shimmer placeholder.
  const ShimmerTierListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            ShimmerBox(width: 32, height: 32, borderRadius: AppSpacing.radiusSm),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 160, height: 16),
                  SizedBox(height: AppSpacing.xs),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            ShimmerBox(width: 24, height: 24, borderRadius: AppSpacing.radiusSm),
          ],
        ),
      ),
    );
  }
}

/// Tier list detail screen placeholder (shimmer).
///
/// A few tier rows (colored label strip plus card placeholders).
class ShimmerTierListDetail extends StatelessWidget {
  /// Creates a tier list detail shimmer placeholder.
  const ShimmerTierListDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const <Widget>[
        _ShimmerTierRow(width: 80),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 120),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 60),
        SizedBox(height: AppSpacing.sm),
        _ShimmerTierRow(width: 100),
        SizedBox(height: AppSpacing.lg),
        // Unranked pool header
        ShimmerBox(width: 140, height: 16),
        SizedBox(height: AppSpacing.sm),
        // Unranked items grid
        _ShimmerUnrankedPool(),
      ],
    );
  }
}

class _ShimmerTierRow extends StatelessWidget {
  const _ShimmerTierRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Tier label
        ShimmerBox(
          width: width,
          height: 56,
          borderRadius: AppSpacing.radiusSm,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Item placeholders
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
        const SizedBox(width: AppSpacing.xs),
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
        const SizedBox(width: AppSpacing.xs),
        const ShimmerBox(width: 48, height: 56, borderRadius: AppSpacing.radiusSm),
      ],
    );
  }
}

class _ShimmerUnrankedPool extends StatelessWidget {
  const _ShimmerUnrankedPool();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: List<Widget>.generate(
        6,
        (_) => const ShimmerBox(
          width: 48,
          height: 56,
          borderRadius: AppSpacing.radiusSm,
        ),
      ),
    );
  }
}

/// List screen placeholder: a column of [ShimmerListTile]s.
class ShimmerList extends StatelessWidget {
  /// Creates a list shimmer placeholder.
  const ShimmerList({this.itemCount = 3, super.key});

  /// Number of placeholder tiles.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const ShimmerListTile(),
    );
  }
}

/// Reads the same geometry helper as the real collection grid, so the
/// skeleton honors the user card scale and every breakpoint.
class ShimmerPosterGrid extends ConsumerWidget {
  /// Creates a poster grid shimmer placeholder.
  const ShimmerPosterGrid({this.itemCount = 12, super.key});

  /// Number of placeholder cards.
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({SliverGridDelegate delegate, double padding}) geometry =
        posterGridGeometry(
      context,
      cardScale: ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.cardScale),
      ),
    );
    final bool compact = useCompactCard(context);
    return GridView.builder(
      padding: EdgeInsets.all(geometry.padding),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: geometry.delegate,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          ShimmerPosterCard(compact: compact),
    );
  }
}

/// Horizontal list tile placeholder (shimmer).
///
/// Poster on the left plus three text lines on the right.
class ShimmerListTile extends StatelessWidget {
  /// Creates a horizontal list tile shimmer placeholder.
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          ShimmerBox(
            width: 64,
            height: 96,
            borderRadius: AppSpacing.radiusSm,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(width: 160, height: 16),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 120, height: 12),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

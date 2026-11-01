import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';

/// Browser-style zoom: the subtree lays out in a window `1 / scale` the real
/// size and is painted scaled back up, so everything reflows and stays sharp.
class UiScaleScope extends ConsumerWidget {
  const UiScaleScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double scale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.uiScale),
    );
    if (scale == SettingsKeys.uiScaleDefault) return child;

    final MediaQueryData media = MediaQuery.of(context);
    final Size size = media.size;
    final Size virtual = Size(size.width / scale, size.height / scale);
    // OverflowBox outside: it bounds-checks the pointer in real coordinates.
    // Inside the transform it rejected the bottom/right bands when zoomed out.
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 0,
      minHeight: 0,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: virtual,
          // Insets and paddings live in real pixels; the subtree measures in
          // virtual ones, so the keyboard and the notch shrink with it.
          child: MediaQuery(
            data: media.copyWith(
              size: virtual,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

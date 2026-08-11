import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';

/// Language-bar-style strip: one accent segment per media type, sized
/// proportionally to its item count. Renders nothing when [counts] is empty.
class MediaTypeSpectrumBar extends StatelessWidget {
  const MediaTypeSpectrumBar({required this.counts, super.key});

  final Map<MediaType, int> counts;

  static const double _height = 3;
  static const double _segmentGap = 1.5;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<MediaType, int>> present = counts.entries
        .where((MapEntry<MediaType, int> e) => e.value > 0)
        .toList()
      ..sort((MapEntry<MediaType, int> a, MapEntry<MediaType, int> b) {
        final int byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });
    if (present.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < present.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: _segmentGap),
            Expanded(
              flex: present[i].value,
              child: ColoredBox(
                color: MediaTypeTheme.colorFor(present[i].key),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

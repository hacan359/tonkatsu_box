import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

/// Hidden for [ItemStatus.notStarted]. Must be placed in a [Stack] inside
/// a widget with `clipBehavior: Clip.antiAlias` (e.g. [Card]).
class StatusRibbon extends StatelessWidget {
  const StatusRibbon({
    required this.status,
    required this.mediaType,
    super.key,
  });

  final ItemStatus status;

  /// Affects the ribbon label.
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    if (status == ItemStatus.notStarted) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 10,
      left: -26,
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Container(
          width: 90,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: status.color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: status.color.withAlpha(80),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            status.materialIcon,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

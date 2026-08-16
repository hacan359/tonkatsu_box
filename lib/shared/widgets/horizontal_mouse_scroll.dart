import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Redirects a mouse wheel into a horizontal [ScrollController]; touch swipes
/// are left alone.
class HorizontalMouseScroll extends StatelessWidget {
  const HorizontalMouseScroll({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent && controller.hasClients) {
          final double offset = controller.offset + event.scrollDelta.dy;
          controller.jumpTo(
            offset.clamp(0.0, controller.position.maxScrollExtent),
          );
        }
      },
      child: child,
    );
  }
}

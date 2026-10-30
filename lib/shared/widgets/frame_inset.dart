import 'package:flutter/widgets.dart';

/// Keeps a whole subtree clear of the frame's zones and clears the reported
/// inset below it. For screens not yet laid out for the frame.
class FrameInset extends StatelessWidget {
  const FrameInset({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = MediaQuery.paddingOf(context);
    return Padding(
      padding: inset,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: child,
      ),
    );
  }
}

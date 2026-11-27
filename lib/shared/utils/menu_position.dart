import 'package:material_ui/material_ui.dart';

/// `showMenu` lays its menu out in the tab navigator's overlay, which starts
/// past the frame's bars; a screen point has to be brought into that space.
Offset toMenuSpace(BuildContext context, Offset global) {
  final RenderObject? overlay = Overlay.maybeOf(context)?.context
      .findRenderObject();
  return overlay is RenderBox ? overlay.globalToLocal(global) : global;
}

/// A menu that opens at the screen point [global].
RelativeRect menuRectAt(BuildContext context, Offset global) {
  final Offset at = toMenuSpace(context, global);
  return RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy);
}

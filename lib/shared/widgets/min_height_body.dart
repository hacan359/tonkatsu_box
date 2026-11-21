import 'package:material_ui/material_ui.dart';

/// A screen of fixed bars over an Expanded area needs this much height before
/// the bars themselves overflow; a landscape phone with the keyboard up has less.
const double kMinBodyHeight = 280;

/// Gives [child] at least [minHeight] and scrolls it when the viewport is
/// shorter, instead of letting a fixed-height Column overflow.
class MinHeightBody extends StatelessWidget {
  const MinHeightBody({
    required this.child,
    this.minHeight = kMinBodyHeight,
    super.key,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedHeight) return child;
        // One tree shape for both cases: swapping wrappers remounts the child,
        // which drops text focus the moment the keyboard shrinks the body.
        final bool fits = constraints.maxHeight >= minHeight;
        return SingleChildScrollView(
          // The screen's own list keeps the route's primary controller.
          primary: false,
          physics: fits ? const NeverScrollableScrollPhysics() : null,
          child: SizedBox(
            height: fits ? constraints.maxHeight : minHeight,
            child: child,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

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
        if (!constraints.hasBoundedHeight ||
            constraints.maxHeight >= minHeight) {
          return child;
        }
        return SingleChildScrollView(
          child: SizedBox(height: minHeight, child: child),
        );
      },
    );
  }
}

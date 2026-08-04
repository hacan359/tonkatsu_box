import 'package:flutter/widgets.dart';

/// Numbers a statistics section cannot derive from its own constraints. Each
/// form factor owns a value in its own file; sections read them via the scope.
@immutable
class StatsLayout {
  /// Creates a layout spec.
  const StatsLayout({
    required this.sectionGap,
    required this.horizontalPadding,
    required this.cardPadding,
    required this.typeCardMinWidth,
    required this.typeCardMaxColumns,
    required this.gridCardMinWidth,
    required this.gridCardMaxColumns,
    required this.showCardTopCovers,
  });

  /// Vertical gap between two consecutive sections.
  final double sectionGap;

  /// Inset of the section content from the page edges.
  final double horizontalPadding;

  /// Inner padding of every stats card.
  final EdgeInsets cardPadding;

  /// Target column width for the per-media-type cards. The section fits as
  /// many whole columns of at least this width as the row allows.
  final double typeCardMinWidth;

  /// Sanity cap only: the page runs full width, so the count must keep
  /// growing on a wide monitor or the cards inflate instead.
  final int typeCardMaxColumns;

  /// Target column width for the platform and format cards.
  final double gridCardMinWidth;

  /// Upper bound on the platform and format columns.
  final int gridCardMaxColumns;

  /// Whether platform and format cards show their top-covers strip. Phones
  /// drop it: two readable columns beat one column with thumbnails.
  final bool showCardTopCovers;
}

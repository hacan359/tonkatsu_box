import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'fractional_star_rating.dart';

/// Opens the star picker right under [anchor]. [onCommit] fires once, on OK
/// or on dismiss, and only when the value changed.
void showRatingPopup(
  BuildContext anchor, {
  required double? initial,
  required ValueChanged<double?> onCommit,
}) {
  final RenderBox box = anchor.findRenderObject()! as RenderBox;
  final Offset offset = box.localToGlobal(Offset.zero);
  final Size size = box.size;

  showMenu<void>(
    context: anchor,
    position: RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height,
      offset.dx + size.width,
      offset.dy + size.height,
    ),
    constraints: const BoxConstraints(maxWidth: 320),
    items: <PopupMenuEntry<void>>[
      RatingPopupItem(initial: initial, onCommit: onCommit),
    ],
  );
}

class RatingPopupItem extends PopupMenuEntry<void> {
  const RatingPopupItem({
    required this.initial,
    required this.onCommit,
    super.key,
  });

  final double? initial;
  final ValueChanged<double?> onCommit;

  @override
  double get height => 72;

  @override
  bool represents(void value) => false;

  @override
  State<RatingPopupItem> createState() => _RatingPopupItemState();
}

class _RatingPopupItemState extends State<RatingPopupItem> {
  static const double _starSize = 20;

  late double? _value = widget.initial;
  bool _committed = false;

  /// Applies the picked value once — on OK, or when the menu is dismissed by
  /// tapping outside (which disposes this entry).
  void _commit() {
    if (_committed) return;
    _committed = true;
    if (_value != widget.initial) widget.onCommit(_value);
  }

  @override
  void dispose() {
    _commit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            // Both dimensions are fixed so the surrounding IntrinsicWidth /
            // IntrinsicHeight never descend into the rating's LayoutBuilder.
            width: FractionalStarRating.naturalWidth(_starSize),
            height: _starSize,
            child: FractionalStarRating(
              value: _value,
              starSize: _starSize,
              onChanged: (double? v) => setState(() => _value = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _value == null ? '—' : _value!.toStringAsFixed(1),
                style: AppTypography.body.copyWith(
                  color: AppColors.ratingStar,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  _commit();
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

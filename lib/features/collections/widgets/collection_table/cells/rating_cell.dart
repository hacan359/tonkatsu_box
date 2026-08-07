import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../../shared/widgets/fractional_star_rating.dart';

class RatingCell extends StatelessWidget {
  const RatingCell({
    required this.rating,
    this.onRatingChanged,
    super.key,
  });

  final double? rating;
  final ValueChanged<double?>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final Widget content = rating == null
        ? Text(
            '—',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.ratingStar,
              ),
              const SizedBox(width: 2),
              Text(
                rating!.toStringAsFixed(1),
                style: AppTypography.body.copyWith(
                  color: AppColors.ratingStar,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          );

    if (onRatingChanged == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRatingPopup(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }

  void _showRatingPopup(BuildContext context) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      items: <PopupMenuEntry<void>>[
        _RatingPopupItem(initial: rating, onCommit: onRatingChanged!),
      ],
    );
  }
}

class _RatingPopupItem extends PopupMenuEntry<void> {
  const _RatingPopupItem({required this.initial, required this.onCommit});

  final double? initial;
  final ValueChanged<double?> onCommit;

  @override
  double get height => 72;

  @override
  bool represents(void value) => false;

  @override
  State<_RatingPopupItem> createState() => _RatingPopupItemState();
}

class _RatingPopupItemState extends State<_RatingPopupItem> {
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

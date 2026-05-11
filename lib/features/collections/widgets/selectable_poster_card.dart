// Обёртка над MediaPosterCard с чекбоксом-оверлеем для bulk selection.
//
// Под Google Photos style: круглая «галка» в верхнем левом углу,
// тап по ней toggle'ит выделение; тап по остальному телу карточки —
// обычный open. При активном селекшне любая карточка показывает
// чекмарк (полупрозрачный для невыделенных, brand-tinted для выделенных).

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Накладывает чекбокс-оверлей на child-карточку.
class SelectablePosterCard extends StatefulWidget {
  /// Создаёт [SelectablePosterCard].
  const SelectablePosterCard({
    required this.child,
    required this.isSelected,
    required this.onToggleSelect,
    required this.selectionActive,
    super.key,
  });

  /// Карточка постера (обычно [MediaPosterCard]).
  final Widget child;

  /// Выделена ли карточка.
  final bool isSelected;

  /// Toggle-колбэк.
  final VoidCallback onToggleSelect;

  /// Активен ли вообще режим выделения (есть выделенные элементы).
  /// Когда активен, чекмарки видны всегда; иначе — только на hover.
  final bool selectionActive;

  @override
  State<SelectablePosterCard> createState() => _SelectablePosterCardState();
}

class _SelectablePosterCardState extends State<SelectablePosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool show = widget.selectionActive ||
        widget.isSelected ||
        _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.child,
          if (widget.isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: show ? 1 : 0,
              child: _CheckCircle(
                isSelected: widget.isSelected,
                interactive: show,
                onTap: widget.onToggleSelect,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.isSelected,
    required this.interactive,
    required this.onTap,
  });

  final bool isSelected;

  /// Если кружок невидим (opacity 0), отключаем его в hit-testing,
  /// чтобы не блокировать клики по карточке.
  final bool interactive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget circle = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brand
                : Colors.black.withAlpha(140),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.brand
                  : Colors.white.withAlpha(200),
              width: 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
    return interactive ? circle : IgnorePointer(child: circle);
  }
}

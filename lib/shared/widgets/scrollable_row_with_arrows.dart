// Горизонтальный список с кнопками-стрелками для десктопа.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'horizontal_mouse_scroll.dart';

/// Горизонтальный список с кнопками-стрелками для навигации на десктопе.
///
/// На экранах >= 600px показывает полупрозрачные кнопки-стрелки
/// поверх списка для удобной навигации колёсиком или кликом.
/// На мобильных устройствах стрелки не отображаются.
class ScrollableRowWithArrows extends StatefulWidget {
  /// Создаёт [ScrollableRowWithArrows].
  const ScrollableRowWithArrows({
    required this.controller,
    required this.child,
    required this.height,
    super.key,
  });

  /// Контроллер горизонтального списка.
  final ScrollController controller;

  /// Дочерний виджет (горизонтальный ListView).
  final Widget child;

  /// Высота области (нужна для позиционирования стрелок).
  final double height;

  @override
  State<ScrollableRowWithArrows> createState() =>
      _ScrollableRowWithArrowsState();
}

class _ScrollableRowWithArrowsState extends State<ScrollableRowWithArrows> {
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateArrows);
    super.dispose();
  }

  void _updateArrows() {
    if (!widget.controller.hasClients || !mounted) return;

    final ScrollPosition pos = widget.controller.position;
    final bool canScrollLeft = pos.pixels > 0;
    final bool canScrollRight = pos.pixels < pos.maxScrollExtent;

    if (canScrollLeft != _showLeftArrow ||
        canScrollRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = canScrollLeft;
        _showRightArrow = canScrollRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!widget.controller.hasClients) return;
    final double target = (widget.controller.offset + delta).clamp(
      0.0,
      widget.controller.position.maxScrollExtent,
    );
    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 600;

    return Stack(
      children: <Widget>[
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: HorizontalMouseScroll(
            controller: widget.controller,
            child: widget.child,
          ),
        ),
        if (isDesktop && _showLeftArrow)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _ArrowButton(
              icon: Icons.chevron_left,
              alignment: Alignment.centerLeft,
              onTap: () => _scrollBy(-300),
            ),
          ),
        if (isDesktop && _showRightArrow)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _ArrowButton(
              icon: Icons.chevron_right,
              alignment: Alignment.centerRight,
              onTap: () => _scrollBy(300),
            ),
          ),
      ],
    );
  }
}

/// Полупрозрачная кнопка-стрелка с градиентным фоном.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.alignment,
    required this.onTap,
  });

  final IconData icon;
  final AlignmentGeometry alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLeft = alignment == Alignment.centerLeft;

    return Container(
      width: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: const <Color>[
            Color(0xDD1A1A2E),
            Color(0x001A1A2E),
          ],
        ),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                icon,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

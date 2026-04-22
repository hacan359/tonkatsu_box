// Общий контейнер карточки коллекции — фокус, hover, InkWell, бордер.
//
// Используется и classic (мозаика), и rich (hero) вариантами — различия
// только в контенте поверх hover-анимации, который они строят сами через
// builder, получая на вход текущую dim-анимацию.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Builder содержимого карточки. Получает текущую dim-анимацию, которую
/// можно использовать в [AnimatedBuilder] для любых hover-эффектов.
typedef CollectionCardContentBuilder = Widget Function(
  BuildContext context,
  Animation<double> dimAnimation,
);

/// Универсальный контейнер карточки коллекции.
///
/// Содержит всю общую механику (фокус-рамка, hover-анимация, InkWell,
/// скругление углов). Классика и rich используют его, чтобы не дублировать
/// одинаковый stateful-шаблон.
class CollectionCardShell extends StatefulWidget {
  /// Создаёт [CollectionCardShell].
  const CollectionCardShell({
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  /// Builder контента карточки — получает dim-анимацию для hover-эффектов.
  final CollectionCardContentBuilder builder;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Callback при правом клике (глобальные координаты).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Callback при изменении фокуса.
  final ValueChanged<bool>? onFocusChanged;

  /// Радиус скругления карточки.
  static const double radius = 16;

  /// Максимальная непрозрачность затемнения вне hover/focus.
  static const double dimOpacity = 0.25;

  @override
  State<CollectionCardShell> createState() => _CollectionCardShellState();
}

class _CollectionCardShellState extends State<CollectionCardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _dimAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dimAnimation = Tween<double>(
      begin: CollectionCardShell.dimOpacity,
      end: 0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: _focusNode,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onSecondaryTapUp: widget.onSecondaryTap != null
          ? (TapUpDetails d) => widget.onSecondaryTap!(d.globalPosition)
          : null,
      onFocusChange: (bool hasFocus) {
        if (hasFocus) {
          _hoverController.forward();
        } else {
          _hoverController.reverse();
        }
        widget.onFocusChanged?.call(hasFocus);
        setState(() => _hasFocus = hasFocus);
      },
      onHover: (bool hovering) {
        if (hovering) {
          _hoverController.forward();
        } else if (!_focusNode.hasFocus) {
          _hoverController.reverse();
        }
      },
      borderRadius: BorderRadius.circular(CollectionCardShell.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(CollectionCardShell.radius),
          border: Border.all(
            color: _hasFocus ? AppColors.brand : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.builder(context, _dimAnimation),
      ),
    );
  }
}

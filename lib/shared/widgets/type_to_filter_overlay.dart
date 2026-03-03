// Плавающий overlay для Type-to-Filter на десктопе.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Overlay для клиентской фильтрации набором текста с клавиатуры.
///
/// На мобильной платформе просто возвращает [child] без overhead.
/// На десктопе перехватывает нажатия клавиш и показывает плавающую строку поиска.
class TypeToFilterOverlay extends StatefulWidget {
  /// Создаёт [TypeToFilterOverlay].
  const TypeToFilterOverlay({
    required this.child,
    required this.onFilterChanged,
    this.hintText,
    super.key,
  });

  /// Основной контент экрана.
  final Widget child;

  /// Вызывается при изменении текста фильтра.
  final ValueChanged<String> onFilterChanged;

  /// Подсказка в поле ввода.
  final String? hintText;

  @override
  State<TypeToFilterOverlay> createState() => TypeToFilterOverlayState();
}

/// State для [TypeToFilterOverlay].
///
/// Публичный для доступа к методу [clear] через GlobalKey.
class TypeToFilterOverlayState extends State<TypeToFilterOverlay>
    with SingleTickerProviderStateMixin {
  final FocusNode _wrapperFocus = FocusNode(debugLabel: 'TypeToFilter-wrapper');
  final FocusNode _textFieldFocus =
      FocusNode(debugLabel: 'TypeToFilter-textField');
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;

  bool _isVisible = false;
  bool _focusRestoreScheduled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _wrapperFocus.dispose();
    _textFieldFocus.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Программный сброс фильтра.
  void clear() {
    if (_isVisible) {
      _hide();
      widget.onFilterChanged('');
    }
  }

  void _show() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
  }

  void _hide() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
        _controller.clear();
        // Возвращаем фокус обёртке ПОСЛЕ перестроения widget tree
        _scheduleWrapperFocusRestore();
      }
    });
  }

  /// Мгновенно закрывает оверлей без анимации (при возврате на маршрут).
  void _dismissInstantly() {
    if (!_isVisible) return;
    _animationController.value = 0;
    setState(() => _isVisible = false);
    _controller.clear();
    widget.onFilterChanged('');
  }

  /// Планирует восстановление фокуса на wrapper после перестроения.
  void _scheduleWrapperFocusRestore() {
    if (_focusRestoreScheduled) return;
    _focusRestoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusRestoreScheduled = false;
      if (!mounted) return;
      if (_wrapperFocus.hasFocus || _textFieldFocus.hasFocus) return;
      if (_isExternalTextFieldFocused()) return;
      _dismissInstantly();
      _wrapperFocus.requestFocus();
    });
  }

  /// Проверяет, находится ли фокус во внешнем EditableText
  /// (не в нашем TextField overlay).
  bool _isExternalTextFieldFocused() {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    // Наш TextField — пропускаем
    if (focus == _textFieldFocus) return false;
    final BuildContext? ctx = focus.context;
    if (ctx == null) return false;
    bool isEditable = false;
    ctx.visitAncestorElements((Element element) {
      if (element.widget is EditableText) {
        isEditable = true;
        return false; // stop traversal
      }
      return true; // continue
    });
    return isEditable;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (kIsMobile) return KeyEventResult.ignored;

    // Только KeyDown и KeyRepeat
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Наш TextField в фокусе — только Escape обрабатываем
    if (_textFieldFocus.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hide();
        widget.onFilterChanged('');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Внешний EditableText в фокусе — не перехватываем
    if (_isExternalTextFieldFocused()) {
      return KeyEventResult.ignored;
    }

    // Escape — clear + hide
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isVisible) {
        _hide();
        widget.onFilterChanged('');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Backspace — удалить символ
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controller.text.isNotEmpty) {
        _controller.text =
            _controller.text.substring(0, _controller.text.length - 1);
        if (_controller.text.isEmpty) {
          _hide();
          widget.onFilterChanged('');
        } else {
          widget.onFilterChanged(_controller.text);
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Печатный символ (codeUnit >= 32)
    final String? char = event.character;
    if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
      _show();
      // Атомарное обновление текста и курсора
      final String newText = _controller.text + char;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      widget.onFilterChanged(newText);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // На мобильной платформе — zero overhead
    if (kIsMobile) return widget.child;

    // Восстанавливаем фокус если потерян (после навигации назад и т.п.)
    // ModalRoute.of регистрирует зависимость → didChangeDependencies →
    // build вызывается при смене статуса маршрута.
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null && route.isCurrent &&
        !_wrapperFocus.hasFocus && !_textFieldFocus.hasFocus) {
      _scheduleWrapperFocusRestore();
    }

    return Focus(
      focusNode: _wrapperFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: <Widget>[
          widget.child,
          if (_isVisible) _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final String hint =
        widget.hintText ?? S.of(context).typeToFilterHint;
    final BorderRadius borderRadius =
        BorderRadius.circular(AppSpacing.radiusMd);

    return Positioned(
      top: AppSpacing.sm,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              elevation: 8,
              borderRadius: borderRadius,
              color: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _textFieldFocus,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            _hide();
                            widget.onFilterChanged('');
                          } else {
                            widget.onFilterChanged(value);
                          }
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        'Esc',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.textTertiary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          _hide();
                          widget.onFilterChanged('');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

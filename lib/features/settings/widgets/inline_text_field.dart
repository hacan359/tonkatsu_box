// Inline текстовое поле — тап для редактирования, blur/Enter для сохранения.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Текстовое поле с inline редактированием.
///
/// Тап по полю включает режим ввода, blur или Enter сохраняет значение.
/// Никаких AlertDialog — всё прямо на месте.
class InlineTextField extends StatefulWidget {
  /// Создаёт [InlineTextField].
  const InlineTextField({
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.obscureText = false,
    this.compact = false,
    super.key,
  });

  /// Текущее значение.
  final String value;

  /// Вызывается при сохранении (blur или Enter).
  final ValueChanged<String> onChanged;

  /// Метка над полем.
  final String? label;

  /// Текст-заглушка при пустом значении.
  final String? placeholder;

  /// Скрывать ли текст (для паролей/ключей).
  final bool obscureText;

  /// Уменьшенный размер для мобильных экранов.
  final bool compact;

  @override
  State<InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<InlineTextField> {
  static final BorderRadius _borderRadius =
      BorderRadius.circular(AppSpacing.radiusSm);
  static const String _obscuredDots =
      '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022';

  late TextEditingController _controller;
  late FocusNode _focusNode;
  late FocusNode _tapFocusNode;
  bool _editing = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _tapFocusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_editing) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commit();
    }
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  void _commit() {
    final String trimmed = _controller.text.trim();
    if (trimmed != widget.value) {
      widget.onChanged(trimmed);
    }
    setState(() => _editing = false);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _tapFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Фиксированная длина — не раскрываем длину реального значения.
  String get _displayValue {
    if (widget.value.isEmpty) return widget.placeholder ?? '';
    if (widget.obscureText && _obscured) return _obscuredDots;
    return widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.compact ? 38 : 42;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(widget.label!, style: AppTypography.bodySmall),
          ),
        // Actions > Focus для поддержки D-pad/gamepad навигации.
        Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (!_editing) _startEditing();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _tapFocusNode,
            child: GestureDetector(
              onTap: _editing ? null : _startEditing,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: _borderRadius,
                  border: Border.all(
                    color: _editing
                        ? AppColors.brand.withValues(alpha: 0.5)
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _editing
                          ? TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              obscureText: widget.obscureText && _obscured,
                              style: AppTypography.body,
                              decoration: InputDecoration(
                                hintText: widget.placeholder,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _commit(),
                            )
                          : Text(
                              _displayValue,
                              style: AppTypography.body.copyWith(
                                color: widget.value.isEmpty
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (widget.obscureText)
                      InkWell(
                        onTap: () => setState(() => _obscured = !_obscured),
                        borderRadius: _borderRadius,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            _obscured ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Общий диалог выбора цвета: палитра пресетов + HSL-слайдеры + hex-превью.
//
// Используется в тегах коллекции и в тир-листах.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Стандартная палитра для всех диалогов выбора цвета (теги, тир-листы,
/// профили). Покрывает цветовой круг + нейтральные тона.
const List<Color> kDefaultColorPalette = <Color>[
  // Saturated wheel
  Color(0xFFEF5350), // Red
  Color(0xFFEC407A), // Pink
  Color(0xFFAB47BC), // Purple
  Color(0xFF7E57C2), // Deep Purple
  Color(0xFF5C6BC0), // Indigo
  Color(0xFF42A5F5), // Blue
  Color(0xFF29B6F6), // Light Blue
  Color(0xFF26C6DA), // Cyan
  Color(0xFF26A69A), // Teal
  Color(0xFF66BB6A), // Green
  Color(0xFF9CCC65), // Light Green
  Color(0xFFD4E157), // Lime
  Color(0xFFFFEE58), // Yellow
  Color(0xFFFFCA28), // Amber
  Color(0xFFFFA726), // Orange
  Color(0xFFFF7043), // Deep Orange
  // Earthy / neutral
  Color(0xFF8D6E63), // Brown
  Color(0xFF78909C), // Blue Grey
  // Grayscale
  Color(0xFFFFFFFF), // White
  Color(0xFFBDBDBD), // Light Gray
  Color(0xFF616161), // Dark Gray
  Color(0xFF212121), // Near-black
];

/// Диалог выбора цвета с палитрой пресетов и HSL-слайдерами.
///
/// Возвращает выбранный [Color] через `Navigator.pop`; `null` при отмене;
/// [noColorSentinel], если пользователь нажал «Без цвета» (только когда
/// [allowNoColor] = `true`).
class ColorPickerDialog extends StatefulWidget {
  /// Создаёт [ColorPickerDialog].
  const ColorPickerDialog({
    this.palette = kDefaultColorPalette,
    this.currentColor,
    this.allowNoColor = false,
    super.key,
  });

  /// Текущий выбранный цвет (для инициализации HSL).
  final Color? currentColor;

  /// Пресет-палитра для быстрого выбора.
  final List<Color> palette;

  /// Показывать кнопку «Без цвета».
  final bool allowNoColor;

  /// Значение, возвращаемое при нажатии «Без цвета».
  ///
  /// Позволяет вызывающему коду отличить «без цвета» от «отменено» (`null`).
  static const Color noColorSentinel = Color(0x00000000);

  /// Показывает диалог и возвращает результат.
  static Future<Color?> show({
    required BuildContext context,
    Color? currentColor,
    List<Color> palette = kDefaultColorPalette,
    bool allowNoColor = false,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext ctx) => ColorPickerDialog(
        palette: palette,
        currentColor: currentColor,
        allowNoColor: allowNoColor,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSLColor _hsl;

  @override
  void initState() {
    super.initState();
    _hsl = widget.currentColor != null
        ? HSLColor.fromColor(widget.currentColor!)
        : const HSLColor.fromAHSL(1, 200, 0.7, 0.5);
  }

  Color get _currentColor => _hsl.toColor();

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l.colorPickerTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              // Палитра пресетов
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Color c in widget.palette) _buildSwatch(c),
                ],
              ),
              const SizedBox(height: 16),

              // Превью + hex
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _currentColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '#${_currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: AppTypography.body.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // HSL слайдеры
              _HslSlider(
                label: 'H',
                value: _hsl.hue,
                max: 360,
                activeColor: _currentColor,
                gradient: LinearGradient(
                  colors: <Color>[
                    for (int i = 0; i <= 360; i += 60)
                      HSLColor.fromAHSL(
                        1,
                        i.toDouble(),
                        _hsl.saturation,
                        _hsl.lightness,
                      ).toColor(),
                  ],
                ),
                onChanged: (double v) =>
                    setState(() => _hsl = _hsl.withHue(v.clamp(0, 360))),
              ),
              const SizedBox(height: 8),
              _HslSlider(
                label: 'S',
                value: _hsl.saturation * 100,
                max: 100,
                activeColor: _currentColor,
                gradient: LinearGradient(
                  colors: <Color>[
                    HSLColor.fromAHSL(1, _hsl.hue, 0, _hsl.lightness).toColor(),
                    HSLColor.fromAHSL(1, _hsl.hue, 1, _hsl.lightness).toColor(),
                  ],
                ),
                onChanged: (double v) => setState(
                  () => _hsl = _hsl.withSaturation((v / 100).clamp(0, 1)),
                ),
              ),
              const SizedBox(height: 8),
              _HslSlider(
                label: 'L',
                value: _hsl.lightness * 100,
                max: 100,
                activeColor: _currentColor,
                gradient: LinearGradient(
                  colors: <Color>[
                    HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 0).toColor(),
                    HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 0.5)
                        .toColor(),
                    HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 1).toColor(),
                  ],
                ),
                onChanged: (double v) => setState(
                  () => _hsl = _hsl.withLightness((v / 100).clamp(0, 1)),
                ),
              ),
              const SizedBox(height: 20),

              if (widget.allowNoColor) ...<Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(ColorPickerDialog.noColorSentinel),
                    icon: const Icon(Icons.format_color_reset, size: 18),
                    label: Text(l.colorPickerNoColor),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_currentColor),
                      child: Text(l.colorPickerApply),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color) {
    final bool isActive = _currentColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _hsl = HSLColor.fromColor(color)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                isActive ? Border.all(color: Colors.white, width: 2.5) : null,
            boxShadow: isActive
                ? <BoxShadow>[
                    BoxShadow(color: color.withAlpha(120), blurRadius: 6),
                  ]
                : null,
          ),
          child: isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _HslSlider extends StatelessWidget {
  const _HslSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.activeColor,
    required this.gradient,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final Color activeColor;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              thumbColor: Colors.white,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              overlayColor: activeColor.withAlpha(40),
              trackShape: _GradientTrackShape(gradient: gradient),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: value.clamp(0, max),
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.round().toString(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const _GradientTrackShape({required this.gradient});

  final LinearGradient gradient;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final RRect rRect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(5),
    );
    final Paint paint = Paint()..shader = gradient.createShader(trackRect);
    context.canvas.drawRRect(rRect, paint);
  }
}

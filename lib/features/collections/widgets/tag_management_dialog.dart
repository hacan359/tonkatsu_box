// Диалог управления тегами коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collection_tags_provider.dart';

/// Предустановленная палитра цветов для тегов.
const List<Color> kTagPalette = <Color>[
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
  Color(0xFF8D6E63), // Brown
  Color(0xFF78909C), // Blue Grey
];

/// Диалог для управления тегами коллекции (создание, переименование, удаление).
class TagManagementDialog extends ConsumerStatefulWidget {
  /// Создаёт [TagManagementDialog].
  const TagManagementDialog({required this.collectionId, super.key});

  /// ID коллекции.
  final int collectionId;

  /// Показывает диалог.
  static Future<void> show(BuildContext context, int collectionId) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          TagManagementDialog(collectionId: collectionId),
    );
  }

  @override
  ConsumerState<TagManagementDialog> createState() =>
      _TagManagementDialogState();
}

class _TagManagementDialogState extends ConsumerState<TagManagementDialog> {
  final TextEditingController _newTagController = TextEditingController();
  final FocusNode _newTagFocus = FocusNode();
  Color? _selectedColor;

  @override
  void dispose() {
    _newTagController.dispose();
    _newTagFocus.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final String name = _newTagController.text.trim();
    if (name.isEmpty) return;

    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .create(name, color: _selectedColor?.toARGB32());
    _newTagController.clear();
    setState(() => _selectedColor = null);
    _newTagFocus.requestFocus();
  }

  Future<void> _renameTag(CollectionTag tag) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: tag.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tagRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == tag.name) return;
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .rename(tag.id, newName);
  }

  Future<void> _changeColor(CollectionTag tag) async {
    final Color? picked = await showDialog<Color?>(
      context: context,
      builder: (BuildContext ctx) => _ColorPickerDialog(
        currentColor: tag.color != null ? Color(tag.color!) : null,
      ),
    );
    // picked == null means dismissed, _noColorSentinel means "remove color"
    if (picked == null) return;
    final int? colorValue =
        picked == _noColorSentinel ? null : picked.toARGB32();
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .updateColor(tag.id, colorValue);
  }

  Future<void> _deleteTag(CollectionTag tag) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tagDelete),
        content: Text(l.tagDeleteConfirm(tag.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .delete(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<CollectionTag>> tagsAsync =
        ref.watch(collectionTagsProvider(widget.collectionId));

    return AlertDialog(
      title: Text(l.tagManage),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Поле создания нового тега
            Row(
              children: <Widget>[
                // Цвет
                _ColorDot(
                  color: _selectedColor,
                  size: 24,
                  onTap: () async {
                    final Color? picked = await showDialog<Color?>(
                      context: context,
                      builder: (BuildContext ctx) => _ColorPickerDialog(
                        currentColor: _selectedColor,
                      ),
                    );
                    if (picked == null) return;
                    setState(() {
                      _selectedColor =
                          picked == _noColorSentinel ? null : picked;
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    focusNode: _newTagFocus,
                    decoration: InputDecoration(
                      hintText: l.tagCreateHint,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _createTag(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createTag,
                  tooltip: l.tagCreate,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Список тегов
            tagsAsync.when(
              data: (List<CollectionTag> tags) {
                if (tags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      l.tagNone,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final CollectionTag tag in tags)
                      ListTile(
                        dense: true,
                        leading: _ColorDot(
                          color: tag.color != null
                              ? Color(tag.color!)
                              : null,
                          size: 20,
                          onTap: () => _changeColor(tag),
                        ),
                        title: Text(tag.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _renameTag(tag),
                              tooltip: l.tagRename,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteTag(tag),
                              tooltip: l.tagDelete,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
              error: (Object e, StackTrace? stack) => SelectableText(
                'Error: $e\n\n$stack',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}

// Sentinel для «без цвета» — отличаем от dismissed (null).
const Color _noColorSentinel = Color(0x00000000);

// ---------------------------------------------------------------------------
// Точка-кружок цвета тега
// ---------------------------------------------------------------------------

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.size,
    this.onTap,
  });

  final Color? color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: color != null
                  ? color!.withAlpha(180)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: color == null
              ? Icon(
                  Icons.palette_outlined,
                  size: size * 0.6,
                  color: AppColors.textTertiary,
                )
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Диалог выбора цвета: палитра + HSL-пикер
// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.currentColor});

  final Color? currentColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
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
              Text(l.colorPickerTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),

              // Палитра пресетов
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Color c in kTagPalette)
                    _buildSwatch(c),
                ],
              ),
              const SizedBox(height: 16),

              // Превью + hex код
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _currentColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withAlpha(40),
                      ),
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
                      HSLColor.fromAHSL(1, i.toDouble(), _hsl.saturation, _hsl.lightness).toColor(),
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
                onChanged: (double v) =>
                    setState(() => _hsl = _hsl.withSaturation((v / 100).clamp(0, 1))),
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
                    HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 0.5).toColor(),
                    HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 1).toColor(),
                  ],
                ),
                onChanged: (double v) =>
                    setState(() => _hsl = _hsl.withLightness((v / 100).clamp(0, 1))),
              ),
              const SizedBox(height: 20),

              // Кнопки
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_noColorSentinel),
                  icon: const Icon(Icons.format_color_reset, size: 18),
                  label: Text(l.colorPickerNoColor),
                ),
              ),
              const SizedBox(height: 8),
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
    final bool isActive =
        _currentColor.toARGB32() == color.toARGB32();
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
            border: isActive
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: isActive
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withAlpha(120),
                      blurRadius: 6,
                    ),
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

// ---------------------------------------------------------------------------
// HSL slider с градиентным треком
// ---------------------------------------------------------------------------

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
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 7,
              ),
              thumbColor: Colors.white,
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 14,
              ),
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

/// Кастомный трек слайдера с градиентной заливкой.
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
    final Paint paint = Paint()
      ..shader = gradient.createShader(trackRect);
    context.canvas.drawRRect(rRect, paint);
  }
}

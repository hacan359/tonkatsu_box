// Горизонтальная легенда типов медиа с цветными точками.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/media_type_theme.dart';
import '../models/media_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Горизонтальная легенда типов медиа.
///
/// Показывает ряд цветных точек с подписями для каждого [MediaType].
/// Кнопка «скрыть» позволяет убрать легенду через [onHide].
class MediaTypeLegend extends StatelessWidget {
  /// Создаёт [MediaTypeLegend].
  const MediaTypeLegend({
    required this.onHide,
    this.visibleTypes,
    super.key,
  });

  /// Callback для скрытия легенды.
  final VoidCallback onHide;

  /// Типы для отображения. Если null — показываются все.
  final Set<MediaType>? visibleTypes;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<MediaType> types = visibleTypes != null
        ? MediaType.values
            .where((MediaType t) => visibleTypes!.contains(t))
            .toList()
        : MediaType.values;

    if (types.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < types.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    _LegendItem(
                      color: MediaTypeTheme.colorFor(types[i]),
                      label: types[i].localizedLabel(l),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onHide,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

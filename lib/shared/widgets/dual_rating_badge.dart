// Бейдж двойного рейтинга (пользовательский + API).

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Бейдж двойного рейтинга: пользовательский и API.
///
/// Формат отображения:
/// - Оба рейтинга: `★ 8 / 7.5`
/// - Только пользовательский: `★ 8`
/// - Только API: `★ 7.5`
/// - Ни одного: не отображается (caller отвечает за скрытие)
///
/// [compact] уменьшает размеры для ландшафтного режима.
/// [inline] убирает фон и использует текстовый стиль (для list mode).
class DualRatingBadge extends StatelessWidget {
  /// Создаёт бейдж двойного рейтинга.
  const DualRatingBadge({
    this.userRating,
    this.apiRating,
    this.compact = false,
    this.inline = false,
    super.key,
  });

  /// Пользовательский рейтинг (1–10, целое).
  final int? userRating;

  /// API рейтинг (0.0–10.0, нормализованный).
  final double? apiRating;

  /// Компактный режим (уменьшенные размеры для ландшафта).
  final bool compact;

  /// Inline-режим (без фона, текстовый стиль для list mode).
  final bool inline;

  /// Есть ли хотя бы один рейтинг для отображения.
  bool get hasRating => userRating != null || _hasApiRating;

  bool get _hasApiRating => apiRating != null && apiRating! > 0;

  /// Форматированная строка рейтинга.
  String get formattedRating {
    final bool hasUser = userRating != null;
    final bool hasApi = _hasApiRating;

    if (hasUser && hasApi) {
      return '$userRating / ${apiRating!.toStringAsFixed(1)}';
    }
    if (hasUser) {
      return userRating.toString();
    }
    if (hasApi) {
      return apiRating!.toStringAsFixed(1);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasRating) return const SizedBox.shrink();

    if (inline) {
      return _buildInline();
    }
    return _buildBadge();
  }

  Widget _buildBadge() {
    final double fontSize = compact ? 8.0 : 11.0;
    final double iconSize = compact ? 8.0 : 11.0;
    final double hPad = compact ? 3.0 : 5.0;
    final double vPad = compact ? 1.0 : 2.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.star,
            size: iconSize,
            color: AppColors.ratingStar,
          ),
          SizedBox(width: compact ? 1 : 2),
          Text(
            formattedRating,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInline() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.star,
          size: 14,
          color: AppColors.ratingStar,
        ),
        const SizedBox(width: 2),
        Text(
          formattedRating,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

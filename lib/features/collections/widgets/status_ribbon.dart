// Диагональная ленточка статуса для карточек коллекции.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

/// Диагональная ленточка статуса в верхнем левом углу карточки.
///
/// Используется в list-карточках для визуальной индикации статуса.
/// Только для отображения — без интерактивности.
///
/// Для [ItemStatus.notStarted] ленточка не показывается.
/// Должна размещаться в [Stack] внутри виджета с
/// `clipBehavior: Clip.antiAlias` (например, [Card]).
class StatusRibbon extends StatelessWidget {
  /// Создаёт [StatusRibbon].
  const StatusRibbon({
    required this.status,
    required this.mediaType,
    super.key,
  });

  /// Статус для отображения.
  final ItemStatus status;

  /// Тип медиа (влияет на метку).
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    if (status == ItemStatus.notStarted) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 10,
      left: -26,
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Container(
          width: 90,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: status.color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: status.color.withAlpha(80),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            '${status.icon} ${status.localizedLabel(S.of(context), mediaType)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

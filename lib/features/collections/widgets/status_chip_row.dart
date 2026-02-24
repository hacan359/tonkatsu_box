// Полоса кнопок-сегментов для выбора статуса элемента коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

/// Полоса кнопок-сегментов для выбора статуса (стиль «пианино»).
///
/// Все статусы отображаются в один ряд с равной шириной, вплотную друг к другу.
/// Каждый сегмент залит цветом статуса, выбранный — полностью,
/// невыбранные — приглушённые. Тап на сегмент вызывает [onChanged].
class StatusChipRow extends StatelessWidget {
  /// Создаёт [StatusChipRow].
  const StatusChipRow({
    required this.status,
    required this.mediaType,
    required this.onChanged,
    super.key,
  });

  /// Текущий выбранный статус.
  final ItemStatus status;

  /// Тип медиа (влияет на метки статусов).
  final MediaType mediaType;

  /// Callback при изменении статуса.
  final void Function(ItemStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    const List<ItemStatus> statuses = ItemStatus.values;
    return Row(
      children: <Widget>[
        for (final ItemStatus s in statuses)
          Expanded(
            child: _StatusSegment(
              status: s,
              mediaType: mediaType,
              isSelected: s == status,
              onTap: () => onChanged(s),
            ),
          ),
      ],
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({
    required this.status,
    required this.mediaType,
    required this.isSelected,
    required this.onTap,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.color;

    return Tooltip(
      message: status.localizedLabel(S.of(context), mediaType),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 36,
          color: isSelected ? statusColor : statusColor.withAlpha(30),
          alignment: Alignment.center,
          child: Icon(
            status.materialIcon,
            size: 20,
            color: isSelected ? Colors.white : statusColor.withAlpha(140),
          ),
        ),
      ),
    );
  }
}

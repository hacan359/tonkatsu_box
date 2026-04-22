// Полоса кнопок-сегментов для выбора статуса элемента коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

const String _kStatusMenuPrefix = 'status:';

/// Декодирует значение из `showMenu`, если это выбор статуса через
/// [statusChipPopupMenuEntries]. Возвращает `null` для обычных пунктов меню.
ItemStatus? tryDecodeStatusMenuValue(String value) {
  if (!value.startsWith(_kStatusMenuPrefix)) return null;
  return ItemStatus.fromString(value.substring(_kStatusMenuPrefix.length));
}

/// Строит набор `PopupMenuEntry` с разделителем и полосой статусов.
///
/// Тап по сегменту закрывает меню через `Navigator.pop` с закодированным
/// значением — вызывающий код декодирует его через [tryDecodeStatusMenuValue].
List<PopupMenuEntry<String>> statusChipPopupMenuEntries({
  required BuildContext context,
  required CollectionItem item,
  double height = 40,
}) {
  return <PopupMenuEntry<String>>[
    const PopupMenuDivider(),
    PopupMenuItem<String>(
      enabled: false,
      padding: EdgeInsets.zero,
      height: height,
      child: StatusChipRow(
        status: item.status,
        mediaType: item.displayMediaType,
        height: height,
        onChanged: (ItemStatus newStatus) => Navigator.of(context)
            .pop('$_kStatusMenuPrefix${newStatus.value}'),
      ),
    ),
  ];
}

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
    this.height = 36,
    super.key,
  });

  /// Текущий выбранный статус.
  final ItemStatus status;

  /// Тип медиа (влияет на метки статусов).
  final MediaType mediaType;

  /// Callback при изменении статуса.
  final void Function(ItemStatus) onChanged;

  /// Высота сегментов.
  final double height;

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
              height: height,
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
    required this.height,
    required this.onTap,
  });

  final ItemStatus status;
  final MediaType mediaType;
  final bool isSelected;
  final double height;
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
          height: height,
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

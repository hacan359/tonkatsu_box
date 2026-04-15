// Shared helper для синхронизации RA данных в collection_items.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';
import '../database/database_service.dart';
import '../../features/collections/providers/collections_provider.dart';

/// Обновляет status, dates в collection_items.
///
/// Если [ref] передан — оптимистично обновляет UI без перезагрузки списка.
/// Используется из RA import service (без ref) и tracker provider (с ref).
///
/// Правила слияния статуса вынесены в [mergeExternalStatus]: защита
/// локального `dropped`, блокировка внешнего `dropped` для `notStarted`/
/// `planned`, не-понижение статуса.
Future<void> syncRaDataToCollectionItem({
  required DatabaseService db,
  required int itemId,
  required int? collectionId,
  required ItemStatus? status,
  ItemStatus? currentStatus,
  Ref? ref,
  DateTime? startedAt,
  DateTime? lastActivityAt,
  DateTime? completedAt,
}) async {
  // Применяем правила слияния статуса с внешнего источника.
  // RA — авторитетный источник прогресса, разрешаем понижение
  // (completed → inProgress если юзер сбросил часть достижений).
  ItemStatus? effectiveStatus;
  if (status != null && currentStatus != null) {
    effectiveStatus = mergeExternalStatus(
      currentStatus: currentStatus,
      externalStatus: status,
      allowDowngrade: true,
    );
  } else if (status != null) {
    // currentStatus неизвестен (первая запись) — принимаем как есть.
    effectiveStatus = status;
  }

  if (effectiveStatus != null) {
    await db.updateItemStatus(
        itemId, effectiveStatus, mediaType: MediaType.game);
  }
  await db.updateItemActivityDates(
    itemId,
    startedAt: startedAt,
    lastActivityAt: lastActivityAt,
    completedAt: completedAt,
  );

  // Оптимистичный update UI — только если ref доступен.
  if (ref != null) {
    ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .updateItemDates(
          itemId,
          startedAt: startedAt,
          lastActivityAt: lastActivityAt,
          completedAt: completedAt,
          status: effectiveStatus,
        );
  }
}

// Диспетчер карточки коллекции для грида главного экрана.
//
// Ветвит на [ClassicCollectionCard] (мозаика 3+3) или [RichCollectionCard]
// (hero-изображение на всю карточку) в зависимости от включённости
// rich-режима и наличия hero у коллекции.
//
// Публичный API сохраняется: [CollectionCard] и [UncategorizedCard].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_hero_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/rich_collections_provider.dart';
import 'classic/classic_collection_card.dart';
import 'collection_card_shell.dart';
import 'rich/rich_collection_card.dart';

/// Карточка коллекции (диспетчер classic/rich).
class CollectionCard extends ConsumerWidget {
  /// Создаёт [CollectionCard].
  const CollectionCard({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Callback при правом клике (глобальные координаты для showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Callback при изменении фокуса.
  final ValueChanged<bool>? onFocusChanged;

  /// Радиус скругления карточки (для выравнивания внешних обрамлений).
  static const double mosaicRadius = CollectionCardShell.radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool richEnabled = ref.watch(richCollectionsEnabledProvider);
    final String? heroFile = collection.heroImagePath;

    String? heroAbsPath;
    if (richEnabled && heroFile != null) {
      try {
        heroAbsPath =
            ref.watch(collectionHeroServiceProvider).resolve(heroFile);
      } on Object {
        heroAbsPath = null;
      }
    }

    if (heroAbsPath != null) {
      return RichCollectionCard(
        collection: collection,
        heroAbsolutePath: heroAbsPath,
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onFocusChanged: onFocusChanged,
      );
    }
    // Rich-режим без hero: показываем classic с описанием (если оно есть).
    return ClassicCollectionCard(
      collection: collection,
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onFocusChanged: onFocusChanged,
      showDescription: richEnabled,
    );
  }
}

/// Карточка для uncategorized-элементов в стиле «iOS папка».
///
/// Вместо мозаики — иконка `inbox` на фоне `surfaceLight`.
class UncategorizedCard extends StatelessWidget {
  /// Создаёт [UncategorizedCard].
  const UncategorizedCard({
    required this.count,
    this.onTap,
    super.key,
  });

  /// Количество uncategorized элементов.
  final int count;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CollectionCard.mosaicRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(CollectionCard.mosaicRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Center(
                child: Icon(
                  Icons.inbox_rounded,
                  color: AppColors.brand,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.collectionsUncategorized,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            l.collectionsUncategorizedItems(count),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

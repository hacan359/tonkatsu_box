// Rich-карточка коллекции: hero-изображение на всю площадь с общим
// text-overlay (имя/описание/stats) поверх. Использует [CollectionCardShell]
// для фокуса/hover/рамки — структурно идентична classic-карточке.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../providers/collections_provider.dart';
import '../collection_card_overlay.dart';
import '../collection_card_shell.dart';
import '../collection_hero_background.dart';

/// Rich-карточка с hero-изображением на всю площадь.
class RichCollectionCard extends ConsumerWidget {
  /// Создаёт [RichCollectionCard].
  const RichCollectionCard({
    required this.collection,
    required this.heroAbsolutePath,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  /// Коллекция для отображения.
  final Collection collection;

  /// Абсолютный путь к hero-файлу.
  final String heroAbsolutePath;

  /// Callback при нажатии.
  final VoidCallback? onTap;

  /// Callback при долгом нажатии.
  final VoidCallback? onLongPress;

  /// Callback при правом клике (глобальные координаты для showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Callback при изменении фокуса.
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));

    return CollectionCardShell(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onFocusChanged: onFocusChanged,
      builder: (BuildContext context, Animation<double> dim) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CollectionHeroBackground(
            imagePath: heroAbsolutePath,
            strength: HeroGradientStrength.soft,
            child: CollectionCardOverlay(
              name: collection.name,
              description: collection.description,
              statsAsync: statsAsync,
            ),
          ),
          AnimatedBuilder(
            animation: dim,
            builder: (BuildContext context, Widget? child) {
              final double t = 1.0 - (dim.value / CollectionCardShell.dimOpacity);
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.brand.withValues(alpha: 0.10 * t),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

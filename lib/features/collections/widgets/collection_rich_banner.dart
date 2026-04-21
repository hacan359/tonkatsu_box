// Полноразмерный hero-баннер для rich-режима детали коллекции.
//
// Сверху — hero-картинка с двумя градиентами (слева и снизу), в нижней
// левой части — крупное название и описание. Баннер адаптивен по высоте:
// на десктопе — max 360px, на мобильных — 40% высоты экрана.

import 'package:flutter/material.dart';

import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'collection_hero_background.dart';

/// Полноразмерный hero-баннер для экрана коллекции.
class CollectionRichBanner extends StatelessWidget {
  /// Создаёт [CollectionRichBanner].
  const CollectionRichBanner({
    required this.collection,
    required this.heroAbsolutePath,
    super.key,
  });

  /// Коллекция для отображения (имя, описание).
  final Collection collection;

  /// Абсолютный путь к hero-файлу.
  final String heroAbsolutePath;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool isMobile = screen.width < 720;

    final double height = isMobile
        ? (screen.height * 0.38).clamp(240, 420)
        : (screen.height * 0.42).clamp(280, 380);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CollectionHeroBackground(
        imagePath: heroAbsolutePath,
        isMobile: isMobile,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? AppSpacing.md : AppSpacing.xl,
              0,
              isMobile ? AppSpacing.md : AppSpacing.xl,
              isMobile ? AppSpacing.md : AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screen.width : 560,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    collection.name,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: isMobile ? 30 : 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.8,
                      shadows: const <Shadow>[
                        Shadow(color: Colors.black87, blurRadius: 12),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (collection.description != null &&
                      collection.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      collection.description!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        shadows: const <Shadow>[
                          Shadow(color: Colors.black87, blurRadius: 8),
                        ],
                      ),
                      maxLines: isMobile ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

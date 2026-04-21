// Фоновая подложка для персонализированных коллекций.
//
// Картинка рисуется с `BoxFit.cover, alignment: Alignment.topRight`,
// поверх накладываются два градиента:
//   • слева направо: тёмный слева → прозрачный (защита для читаемости текста);
//   • снизу вверх:   тёмный снизу → прозрачный (плавное втекание в фон).
//
// Оба градиента заканчиваются в [AppColors.background], чтобы край картинки
// не резал по фону. На мобильных градиенты шире.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Подложка hero-картинки с градиентами.
///
/// Используется и в `CollectionCard` (карточка грида), и в `CollectionScreen`
/// (полноразмерный баннер). Сама картинка рендерится на весь размер родителя —
/// родитель задаёт размеры и скругление углов.
class CollectionHeroBackground extends StatelessWidget {
  /// Создаёт [CollectionHeroBackground].
  const CollectionHeroBackground({
    required this.imagePath,
    this.isMobile = false,
    this.strength = HeroGradientStrength.standard,
    this.child,
    super.key,
  });

  /// Абсолютный путь к hero-файлу.
  final String imagePath;

  /// Mobile-режим: градиенты шире для лучшей читаемости в portrait.
  final bool isMobile;

  /// Сила затемнения (для мелкой карточки можно делать мягче, для баннера —
  /// стандарт).
  final HeroGradientStrength strength;

  /// Контент поверх картинки (текст, кнопки). Без `Positioned` — родитель
  /// сам размещает через `Stack`, или можно передать `Align`.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    const Color bg = AppColors.background;
    final double leftStop = isMobile ? 0.75 : 0.55;
    final double bottomStop = isMobile ? 0.70 : 0.55;
    final double leftDark = strength.leftDarkOpacity;
    final double bottomDark = strength.bottomDarkOpacity;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1) Картинка: top-right как смысловой центр.
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.surface),
          ),

          // 2) Затемнение слева → прозрачное справа.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  bg.withValues(alpha: leftDark),
                  bg.withValues(alpha: leftDark * 0.55),
                  Colors.transparent,
                ],
                stops: <double>[0.0, leftStop * 0.5, leftStop],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // 3) Затемнение снизу → прозрачное сверху (фон приложения внизу).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  bg,
                  bg.withValues(alpha: bottomDark * 0.65),
                  Colors.transparent,
                ],
                stops: <double>[0.0, bottomStop * 0.45, bottomStop],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          ?child,
        ],
      ),
    );
  }
}

/// Сила градиентов hero.
enum HeroGradientStrength {
  /// Для карточек грида (мягче, чтобы не забивать маленькое изображение).
  soft(leftDarkOpacity: 0.75, bottomDarkOpacity: 0.90),

  /// Для полноразмерного баннера.
  standard(leftDarkOpacity: 0.85, bottomDarkOpacity: 1.0);

  const HeroGradientStrength({
    required this.leftDarkOpacity,
    required this.bottomDarkOpacity,
  });

  /// Непрозрачность левой части.
  final double leftDarkOpacity;

  /// Непрозрачность нижней части (в самом низу — полностью фон).
  final double bottomDarkOpacity;
}

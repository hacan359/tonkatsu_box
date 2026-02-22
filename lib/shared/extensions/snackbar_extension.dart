// Extension для показа compact SnackBar уведомлений.

import 'package:flutter/material.dart';

import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Тип уведомления SnackBar.
enum SnackType {
  /// Успешная операция (зелёный акцент).
  success,

  /// Ошибка или сбой (красный акцент).
  error,

  /// Информационное уведомление (brand акцент).
  info,
}

/// Extension на [BuildContext] для единого показа compact SnackBar.
///
/// Все уведомления в приложении должны использовать [showSnack].
/// Для изменения стиля достаточно изменить этот файл.
extension SnackBarExtension on BuildContext {
  /// Показывает compact floating SnackBar.
  ///
  /// Автоматически скрывает предыдущий SnackBar.
  /// По умолчанию [type] = [SnackType.info], [duration] = 2 секунды.
  /// [loading] заменяет иконку на [CircularProgressIndicator].
  void showSnack(
    String message, {
    SnackType type = SnackType.info,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool loading = false,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();

    final Widget leadingIcon = loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          )
        : Icon(
            switch (type) {
              SnackType.success => Icons.check_circle_outline,
              SnackType.error => Icons.error_outline,
              SnackType.info => Icons.info_outline,
            },
            size: 18,
            color: switch (type) {
              SnackType.success => AppColors.success,
              SnackType.error => AppColors.error,
              SnackType.info => AppColors.brand,
            },
          );

    final Color borderColor = switch (type) {
      SnackType.success => AppColors.success.withAlpha(128),
      SnackType.error => AppColors.error.withAlpha(128),
      SnackType.info => AppColors.surfaceBorder,
    };

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            leadingIcon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: BorderSide(color: borderColor),
        ),
        width: kIsMobile ? null : 360,
        margin: kIsMobile
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : null,
        elevation: 4,
        duration: duration,
        action: action,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Скрывает текущий SnackBar (если есть).
  void hideSnack() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}

// Extension для показа SnackBar из BuildContext.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Extension на [BuildContext] для удобного показа SnackBar.
extension SnackBarExtension on BuildContext {
  /// Показывает SnackBar с заданным сообщением.
  ///
  /// По умолчанию фон — [AppColors.brand] (success).
  /// При [isError] = true — [AppColors.error].
  void showAppSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.brand,
      ),
    );
  }
}

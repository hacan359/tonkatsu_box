// Виджет отображения ошибки API с кнопкой копирования деталей.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../extensions/snackbar_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Виджет для отображения ошибки API.
///
/// Показывает иконку ошибки, сообщение и кнопку "Скопировать детали",
/// если доступна подробная отладочная информация.
class ApiErrorDisplay extends StatelessWidget {
  /// Создаёт [ApiErrorDisplay].
  const ApiErrorDisplay({
    required this.message,
    this.detail,
    super.key,
  });

  /// User-friendly сообщение об ошибке.
  final String message;

  /// Подробная отладочная информация (URL, метод, причина).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: detail!));
                  context.showSnack(
                    l.errorDetailsCopied,
                    type: SnackType.info,
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l.copyErrorDetails),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: AppTypography.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

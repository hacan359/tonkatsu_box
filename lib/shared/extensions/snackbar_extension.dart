import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/error_details_dialog.dart';

enum SnackType {
  success,
  error,
  info,
}

/// Single entry point for app snackbars; change styling here to change it
/// everywhere.
extension SnackBarExtension on BuildContext {
  /// Hides any current snackbar first. [loading] swaps the type icon for a
  /// spinner; [countdown] shows the seconds left of [duration].
  void showSnack(
    String message, {
    SnackType type = SnackType.info,
    Duration duration = const Duration(milliseconds: 750),
    SnackBarAction? action,
    bool loading = false,
    bool countdown = false,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();

    final Widget leadingIcon = loading
        ? SizedBox(
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (countdown) ...<Widget>[
              const SizedBox(width: 8),
              _SnackCountdown(duration: duration),
            ],
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
        // Flutter keeps a snack with an action open until tapped; every
        // caller here passes a duration it expects to be honoured.
        persist: false,
        action: action,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  void hideSnack() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  /// Error snack with a «Details» action opening a copyable dialog with the
  /// full [message] and optional debug [detail].
  void showErrorSnack(String message, {String? detail}) {
    showSnack(
      message,
      type: SnackType.error,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: S.of(this).errorDetailsShow,
        textColor: AppColors.brand,
        onPressed: () {
          if (!mounted) return;
          showErrorDetailsDialog(this, message: message, detail: detail);
        },
      ),
    );
  }
}

class _SnackCountdown extends StatelessWidget {
  const _SnackCountdown({required this.duration});

  final Duration duration;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: duration,
      builder: (BuildContext context, double left, Widget? _) {
        final int seconds = (left * duration.inMilliseconds / 1000).ceil();
        return SizedBox.square(
          dimension: _size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: left,
                strokeWidth: 2,
                color: AppColors.brand,
                backgroundColor: AppColors.surfaceBorder,
              ),
              Text(
                '$seconds',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

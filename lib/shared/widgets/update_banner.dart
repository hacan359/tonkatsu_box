// Баннер уведомления о доступном обновлении приложения.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Баннер, показывающий уведомление о доступном обновлении.
///
/// Читает [updateCheckProvider] и показывает баннер если есть
/// более новая версия. Можно закрыть крестиком — баннер исчезает
/// до следующего запуска приложения.
class UpdateBanner extends ConsumerWidget {
  /// Создаёт баннер обновления.
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UpdateInfo?> updateAsync = ref.watch(updateCheckProvider);

    return updateAsync.when(
      data: (UpdateInfo? info) {
        if (info == null || !info.hasUpdate) return const SizedBox.shrink();
        return _UpdateBannerContent(info: info);
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
    );
  }
}

class _UpdateBannerContent extends StatefulWidget {
  const _UpdateBannerContent({required this.info});

  final UpdateInfo info;

  @override
  State<_UpdateBannerContent> createState() => _UpdateBannerContentState();
}

class _UpdateBannerContentState extends State<_UpdateBannerContent> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withAlpha(20),
        border: Border.all(color: AppColors.brand.withAlpha(60)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.system_update, color: AppColors.brand, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Update available: v${widget.info.latestVersion}',
                  style: AppTypography.body.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Current: v${widget.info.currentVersion}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              launchUrl(
                Uri.parse(widget.info.releaseUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Update'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _dismissed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

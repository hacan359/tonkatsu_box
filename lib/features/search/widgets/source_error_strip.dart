import 'package:flutter/material.dart';

import '../../../core/api/api_error_extract.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_logo.dart';
import '../models/search_source.dart';

/// One failed provider, reported inline so the other sources' results stay on
/// screen — a fan-out query must not be blanked by a single dead API.
class SourceErrorStrip extends StatelessWidget {
  const SourceErrorStrip({
    required this.source,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final SearchSource source;
  final ApiError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: AppColors.error.withAlpha(90)),
        color: AppColors.error.withAlpha(20),
      ),
      child: Row(
        children: <Widget>[
          SourceLogo(source: source.dataSource, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            source.dataSource.label,
            style: AppTypography.bodySmall
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            // The API's own message, not just "failed": an expired key and a
            // dead network need different reactions from the user.
            child: Tooltip(
              message: error.detail ?? error.message,
              child: Text(
                error.message.isEmpty
                    ? l.searchSourceNoResponse
                    : error.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, AppSpacing.buttonHeightDense),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onRetry,
            child: Text(
              l.retry,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

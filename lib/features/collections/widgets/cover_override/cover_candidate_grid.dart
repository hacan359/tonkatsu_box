import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

const double _dialogWidth = 560;
const double _dialogHeight = 600;
const double _tileMaxExtent = 130;
const double _posterAspect = 2 / 3;

/// One cover a provider offers: a light [thumbUrl] for the grid and the
/// [fullUrl] that becomes the override once picked.
class CoverCandidate {
  const CoverCandidate({
    required this.id,
    required this.thumbUrl,
    required this.fullUrl,
    this.tooltip,
  });

  final String id;
  final String thumbUrl;
  final String fullUrl;
  final String? tooltip;
}

/// Frame shared by the provider pickers: title, an optional [header] (a game
/// chooser), the grid state and a cancel button. Pops with the picked URL.
class CoverCandidateDialog extends StatelessWidget {
  const CoverCandidateDialog({
    required this.title,
    required this.loading,
    required this.failed,
    required this.candidates,
    this.header,
    super.key,
  });

  final String title;
  final bool loading;
  final bool failed;
  final List<CoverCandidate> candidates;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _dialogWidth,
          maxHeight: _dialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              ?header,
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildBody(l)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(S l) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (failed || candidates.isEmpty) {
      return Center(
        child: Text(
          failed ? l.coverPickerLoadFailed : l.coverPickerEmpty,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _tileMaxExtent,
        childAspectRatio: _posterAspect,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: candidates.length,
      itemBuilder: (BuildContext context, int i) {
        final CoverCandidate candidate = candidates[i];
        return _CandidateTile(
          key: ValueKey<String>(candidate.id),
          candidate: candidate,
          onTap: () => Navigator.of(context).pop(candidate.fullUrl),
        );
      },
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.onTap,
    super.key,
  });

  final CoverCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget tile = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Material(
        color: AppColors.surfaceLight,
        child: InkWell(
          onTap: onTap,
          // Thumbs only: the full-size picture is fetched once, when picked.
          child: CachedNetworkImage(
            imageUrl: candidate.thumbUrl,
            fit: BoxFit.cover,
            memCacheWidth: (_tileMaxExtent * 2).toInt(),
            errorWidget: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
    final String? tooltip = candidate.tooltip;
    return tooltip == null ? tile : Tooltip(message: tooltip, child: tile);
  }
}

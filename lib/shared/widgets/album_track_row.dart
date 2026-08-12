import 'package:core/models/album_track.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// `385000` → `6:25`.
String formatTrackLength(int ms) {
  final int totalSeconds = ms ~/ 1000;
  return '${totalSeconds ~/ 60}:'
      '${(totalSeconds % 60).toString().padLeft(2, '0')}';
}

/// Track rows with disc headers interleaved when the album spans discs.
List<Widget> buildAlbumTrackList({
  required List<AlbumTrack> tracks,
  required String Function(int discNumber) discLabel,
  required Widget Function(AlbumTrack track) rowBuilder,
}) {
  final bool multiDisc = tracks.any((AlbumTrack t) => t.discNumber > 1);
  final List<Widget> rows = <Widget>[];
  for (int i = 0; i < tracks.length; i++) {
    final AlbumTrack track = tracks[i];
    if (multiDisc &&
        (i == 0 || track.discNumber != tracks[i - 1].discNumber)) {
      rows.add(Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: Text(
          discLabel(track.discNumber),
          style:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ));
    }
    rows.add(rowBuilder(track));
  }
  return rows;
}

/// One track line — plain in the search sheet, checkable in the collection
/// tracker when [listened] and [onTap] are set.
class AlbumTrackRow extends StatelessWidget {
  const AlbumTrackRow({
    required this.track,
    this.listened,
    this.onTap,
    this.accentColor,
    super.key,
  });

  final AlbumTrack track;

  /// Null renders a plain row without a toggle mark.
  final bool? listened;

  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final bool? isListened = listened;
    final Widget row = Padding(
      padding: EdgeInsets.symmetric(
        vertical: isListened != null ? AppSpacing.xs : 3,
      ),
      child: Row(
        children: <Widget>[
          if (isListened != null) ...<Widget>[
            Icon(
              isListened ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: isListened
                  ? (accentColor ?? AppColors.textSecondary)
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: 24,
            child: Text(
              '${track.position}',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              track.title,
              style: AppTypography.bodySmall.copyWith(
                color: (isListened ?? false)
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (track.lengthMs != null)
            Text(
              formatTrackLength(track.lengthMs!),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}

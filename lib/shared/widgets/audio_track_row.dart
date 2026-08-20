import 'package:core/models/audio_track.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Width of the date cell in podcast episode rows (dd.mm.yyyy and friends).
const double kEpisodeDateLeadingWidth = 76;

/// `385000` → `6:25`.
String formatTrackLength(int ms) {
  final int totalSeconds = ms ~/ 1000;
  return '${totalSeconds ~/ 60}:'
      '${(totalSeconds % 60).toString().padLeft(2, '0')}';
}

/// Track rows with disc headers interleaved when the album spans discs.
List<Widget> buildAudioTrackList({
  required List<AudioTrack> tracks,
  required String Function(int discNumber) discLabel,
  required Widget Function(AudioTrack track) rowBuilder,
}) {
  final bool multiDisc = tracks.any((AudioTrack t) => t.discNumber > 1);
  final List<Widget> rows = <Widget>[];
  for (int i = 0; i < tracks.length; i++) {
    final AudioTrack track = tracks[i];
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
/// tracker when [listened] and [onTap] are set. The circle toggles the mark;
/// a tap anywhere else unfolds an ellipsized title.
class AudioTrackRow extends StatefulWidget {
  const AudioTrackRow({
    required this.track,
    this.listened,
    this.onTap,
    this.accentColor,
    this.positionLabel,
    this.leadingWidth = 24,
    super.key,
  });

  final AudioTrack track;

  /// Null renders a plain row without a toggle mark.
  final bool? listened;

  final VoidCallback? onTap;
  final Color? accentColor;

  /// Replaces the track number — podcast episodes show the publish date, the
  /// raw [AudioTrack.position] there is a meaningless provider id.
  final String? positionLabel;

  final double leadingWidth;

  @override
  State<AudioTrackRow> createState() => _AudioTrackRowState();
}

class _AudioTrackRowState extends State<AudioTrackRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool? isListened = widget.listened;
    final Widget row = Padding(
      padding: EdgeInsets.symmetric(
        vertical: isListened != null ? AppSpacing.xs : 3,
      ),
      child: Row(
        children: <Widget>[
          if (isListened != null) ...<Widget>[
            InkResponse(
              onTap: widget.onTap,
              radius: 18,
              child: Icon(
                isListened ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isListened
                    ? (widget.accentColor ?? AppColors.textSecondary)
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: widget.leadingWidth,
            child: Text(
              widget.positionLabel ?? '${widget.track.position}',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              widget.track.title,
              style: AppTypography.bodySmall.copyWith(
                color: (isListened ?? false)
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              maxLines: _expanded ? null : 1,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
          ),
          if (widget.track.lengthMs != null)
            Text(
              formatTrackLength(widget.track.lengthMs!),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}

import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Presentation extras for [ItemStatus].
extension ItemStatusUi on ItemStatus {
  Color get color {
    switch (this) {
      case ItemStatus.notStarted:
        return AppColors.textSecondary;
      case ItemStatus.inProgress:
        return AppColors.statusInProgress;
      case ItemStatus.completed:
        return AppColors.statusCompleted;
      case ItemStatus.dropped:
        return AppColors.statusDropped;
      case ItemStatus.planned:
        return AppColors.statusPlanned;
      case ItemStatus.replaying:
        return AppColors.statusReplaying;
    }
  }

  IconData get materialIcon {
    switch (this) {
      case ItemStatus.notStarted:
        return Icons.radio_button_unchecked;
      case ItemStatus.inProgress:
        return Icons.play_arrow_rounded;
      case ItemStatus.completed:
        return Icons.check_circle;
      case ItemStatus.dropped:
        return Icons.pause_circle_filled;
      case ItemStatus.planned:
        return Icons.bookmark;
      case ItemStatus.replaying:
        return Icons.replay_circle_filled;
    }
  }

  /// Localised label adapted to [mediaType] (Playing / Watching / Reading).
  String localizedLabel(S l, MediaType mediaType) {
    switch (this) {
      case ItemStatus.notStarted:
        return l.statusNotStarted;
      case ItemStatus.inProgress:
        return mediaType == MediaType.game ? l.statusPlaying : l.statusWatching;
      case ItemStatus.completed:
        return l.statusCompleted;
      case ItemStatus.dropped:
        return l.statusDropped;
      case ItemStatus.planned:
        return l.statusPlanned;
      case ItemStatus.replaying:
        switch (mediaType) {
          case MediaType.game:
          case MediaType.visualNovel:
            return l.statusReplaying;
          case MediaType.manga:
          case MediaType.book:
            return l.statusRereading;
          case MediaType.movie:
          case MediaType.tvShow:
          case MediaType.animation:
          case MediaType.anime:
          case MediaType.custom:
            return l.statusRewatching;
        }
    }
  }

  /// Localised label not tied to a media type, for contexts where the type
  /// is unknown (table headers, filters).
  String genericLabel(S l) {
    switch (this) {
      case ItemStatus.notStarted:
        return l.statusNotStarted;
      case ItemStatus.inProgress:
        return l.statusInProgress;
      case ItemStatus.completed:
        return l.statusCompleted;
      case ItemStatus.dropped:
        return l.statusDropped;
      case ItemStatus.planned:
        return l.statusPlanned;
      case ItemStatus.replaying:
        return l.statusReplay;
    }
  }
}

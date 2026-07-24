import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'media_type.dart';

/// Universal collection-item status with media-type-aware labels.
enum ItemStatus {
  notStarted('not_started'),

  inProgress('in_progress'),

  completed('completed'),

  dropped('dropped'),

  planned('planned'),

  /// Replaying / rewatching / rereading a previously finished item.
  ///
  /// A bare indicator status: switching to it never touches
  /// `startedAt`/`completedAt` (the item was already completed once).
  replaying('replaying');

  const ItemStatus(this.value);

  /// Stored value for the DB `status` column.
  final String value;

  /// Returns [notStarted] for unknown stored values.
  static ItemStatus fromString(String value) {
    for (final ItemStatus status in ItemStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return ItemStatus.notStarted;
  }

  /// Like [fromString], but returns `null` for an unknown value.
  static ItemStatus? tryFromString(String value) {
    for (final ItemStatus status in ItemStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return null;
  }

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

  /// English display name (locale-independent).
  ///
  /// For non-localised contexts such as text export and MAL export.
  String get displayLabel {
    switch (this) {
      case ItemStatus.notStarted:
        return 'Not Started';
      case ItemStatus.inProgress:
        return 'In Progress';
      case ItemStatus.completed:
        return 'Completed';
      case ItemStatus.dropped:
        return 'Dropped';
      case ItemStatus.planned:
        return 'Planned';
      case ItemStatus.replaying:
        return 'Replay';
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

  /// Sort priority (lower = higher in the list): active items first,
  /// finished last.
  int get statusSortPriority {
    switch (this) {
      case ItemStatus.inProgress:
        return 0;
      case ItemStatus.replaying:
        return 1;
      case ItemStatus.planned:
        return 2;
      case ItemStatus.notStarted:
        return 3;
      case ItemStatus.completed:
        return 4;
      case ItemStatus.dropped:
        return 5;
    }
  }
}

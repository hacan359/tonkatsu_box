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

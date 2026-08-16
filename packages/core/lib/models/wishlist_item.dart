import 'media_type.dart';

/// A free-text note about content to track down later.
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mediaTypeHint,
    this.note,
    this.isResolved = false,
    this.resolvedAt,
    this.tag,
  });

  factory WishlistItem.fromDb(Map<String, dynamic> row) {
    final String? mediaTypeHintValue = row['media_type_hint'] as String?;
    return WishlistItem(
      id: row['id'] as int,
      text: row['text'] as String,
      mediaTypeHint: mediaTypeHintValue != null
          ? MediaType.fromString(mediaTypeHintValue)
          : null,
      note: row['note'] as String?,
      isResolved: (row['is_resolved'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
      resolvedAt: row['resolved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (row['resolved_at'] as int) * 1000,
            )
          : null,
      tag: row['tag'] as String?,
    );
  }

  final int id;

  /// The content's name, as typed.
  final String text;

  final MediaType? mediaTypeHint;

  /// Free-form extras: platform, year, where the user heard about it.
  final String? note;

  final bool isResolved;

  final DateTime createdAt;

  /// Set once the item is found and added to a collection.
  final DateTime? resolvedAt;

  /// Grouping tag, e.g. an importer's auto-tag.
  final String? tag;

  bool get hasNote => note != null && note!.isNotEmpty;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'media_type_hint': mediaTypeHint?.value,
      'note': note,
      'is_resolved': isResolved ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'resolved_at': resolvedAt != null
          ? resolvedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'tag': tag,
    };
  }

  WishlistItem copyWith({
    int? id,
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
    String? tag,
    bool clearTag = false,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      mediaTypeHint:
          clearMediaTypeHint ? null : (mediaTypeHint ?? this.mediaTypeHint),
      note: clearNote ? null : (note ?? this.note),
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt:
          clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WishlistItem(id: $id, text: $text, resolved: $isResolved)';
}

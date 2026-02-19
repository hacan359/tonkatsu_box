// Элемент вишлиста — заметка для отложенного поиска контента.

import 'media_type.dart';

/// Элемент вишлиста.
///
/// Представляет текстовую заметку о контенте, который нужно найти позже.
class WishlistItem {
  /// Создаёт экземпляр [WishlistItem].
  const WishlistItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mediaTypeHint,
    this.note,
    this.isResolved = false,
    this.resolvedAt,
  });

  /// Создаёт [WishlistItem] из записи базы данных.
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
    );
  }

  /// Уникальный идентификатор записи.
  final int id;

  /// Текст заметки (название контента).
  final String text;

  /// Опциональный хинт типа медиа.
  final MediaType? mediaTypeHint;

  /// Дополнительная заметка (платформа, год, откуда узнал).
  final String? note;

  /// Найдено и добавлено в коллекцию.
  final bool isResolved;

  /// Дата создания заметки.
  final DateTime createdAt;

  /// Дата разрешения (когда элемент найден и добавлен).
  final DateTime? resolvedAt;

  /// Есть ли дополнительная заметка.
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Преобразует в Map для сохранения в базу данных.
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
    };
  }

  /// Создаёт копию с изменёнными полями.
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

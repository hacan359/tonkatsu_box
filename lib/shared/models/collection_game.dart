import 'collection_item.dart';
import 'game.dart';
import 'item_status.dart';
import 'media_type.dart';
import 'platform.dart';

/// Статус прохождения игры.
enum GameStatus {
  /// Не начата.
  notStarted('not_started', 'Not Started', '⬜'),

  /// В процессе.
  playing('playing', 'Playing', '🎮'),

  /// Пройдена.
  completed('completed', 'Completed', '✅'),

  /// Брошена.
  dropped('dropped', 'Dropped', '⏸️'),

  /// Запланирована.
  planned('planned', 'Planned', '📋');

  const GameStatus(this.value, this.label, this.icon);

  /// Строковое значение для базы данных.
  final String value;

  /// Отображаемое название.
  final String label;

  /// Иконка статуса (эмодзи).
  final String icon;

  /// Создаёт [GameStatus] из строки.
  static GameStatus fromString(String value) {
    return GameStatus.values.firstWhere(
      (GameStatus status) => status.value == value,
      orElse: () => GameStatus.notStarted,
    );
  }

  /// Возвращает отображаемый текст с иконкой.
  String get displayText => '$icon $label';

  /// Конвертирует в универсальный [ItemStatus].
  ItemStatus toItemStatus() {
    switch (this) {
      case GameStatus.notStarted:
        return ItemStatus.notStarted;
      case GameStatus.playing:
        return ItemStatus.inProgress;
      case GameStatus.completed:
        return ItemStatus.completed;
      case GameStatus.dropped:
        return ItemStatus.dropped;
      case GameStatus.planned:
        return ItemStatus.planned;
    }
  }

  /// Создаёт [GameStatus] из [ItemStatus].
  static GameStatus fromItemStatus(ItemStatus itemStatus) {
    switch (itemStatus) {
      case ItemStatus.notStarted:
        return GameStatus.notStarted;
      case ItemStatus.inProgress:
        return GameStatus.playing;
      case ItemStatus.completed:
        return GameStatus.completed;
      case ItemStatus.dropped:
        return GameStatus.dropped;
      case ItemStatus.planned:
        return GameStatus.planned;
      case ItemStatus.onHold:
        // onHold не существует в GameStatus — маппим на dropped
        return GameStatus.dropped;
    }
  }
}

/// Модель игры в коллекции.
///
/// Связывает игру с коллекцией и хранит дополнительную информацию:
/// статус прохождения, комментарии автора и пользователя.
class CollectionGame {
  /// Создаёт экземпляр [CollectionGame].
  const CollectionGame({
    required this.id,
    required this.collectionId,
    required this.igdbId,
    required this.platformId,
    required this.status,
    required this.addedAt,
    this.authorComment,
    this.userComment,
    this.game,
    this.platform,
  });

  /// Создаёт [CollectionGame] из записи базы данных.
  factory CollectionGame.fromDb(Map<String, dynamic> row) {
    return CollectionGame(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      igdbId: row['igdb_id'] as int,
      platformId: row['platform_id'] as int,
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
      status: GameStatus.fromString(row['status'] as String),
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['added_at'] as int) * 1000,
      ),
    );
  }

  /// Создаёт [CollectionGame] из [CollectionItem] (адаптер).
  ///
  /// Используется для обратной совместимости UI до Stage 18.
  /// Работает только с элементами типа [MediaType.game].
  factory CollectionGame.fromCollectionItem(CollectionItem item) {
    return CollectionGame(
      id: item.id,
      collectionId: item.collectionId,
      igdbId: item.externalId,
      platformId: item.platformId ?? 0,
      authorComment: item.authorComment,
      userComment: item.userComment,
      status: GameStatus.fromItemStatus(item.status),
      addedAt: item.addedAt,
      game: item.game,
      platform: item.platform,
    );
  }

  /// Создаёт [CollectionGame] из записи базы данных с join-данными.
  factory CollectionGame.fromDbWithJoins(
    Map<String, dynamic> row, {
    Game? game,
    Platform? platform,
  }) {
    return CollectionGame(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      igdbId: row['igdb_id'] as int,
      platformId: row['platform_id'] as int,
      authorComment: row['author_comment'] as String?,
      userComment: row['user_comment'] as String?,
      status: GameStatus.fromString(row['status'] as String),
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['added_at'] as int) * 1000,
      ),
      game: game,
      platform: platform,
    );
  }

  /// Уникальный идентификатор записи.
  final int id;

  /// ID коллекции.
  final int collectionId;

  /// ID игры в IGDB.
  final int igdbId;

  /// ID платформы.
  final int platformId;

  /// Комментарий автора коллекции.
  final String? authorComment;

  /// Личный комментарий пользователя.
  final String? userComment;

  /// Статус прохождения.
  final GameStatus status;

  /// Дата добавления в коллекцию.
  final DateTime addedAt;

  /// Данные игры (joined).
  final Game? game;

  /// Данные платформы (joined).
  final Platform? platform;

  /// Возвращает название игры или placeholder.
  String get gameName => game?.name ?? 'Unknown Game';

  /// Возвращает название платформы или placeholder.
  String get platformName => platform?.displayName ?? 'Unknown Platform';

  /// Возвращает true, если есть комментарий автора.
  bool get hasAuthorComment =>
      authorComment != null && authorComment!.isNotEmpty;

  /// Возвращает true, если есть личный комментарий.
  bool get hasUserComment => userComment != null && userComment!.isNotEmpty;

  /// Возвращает true, если игра пройдена.
  bool get isCompleted => status == GameStatus.completed;

  /// Конвертирует в универсальный [CollectionItem].
  CollectionItem toCollectionItem() {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: MediaType.game,
      externalId: igdbId,
      platformId: platformId,
      status: status.toItemStatus(),
      authorComment: authorComment,
      userComment: userComment,
      addedAt: addedAt,
      game: game,
      platform: platform,
    );
  }

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'igdb_id': igdbId,
      'platform_id': platformId,
      'author_comment': authorComment,
      'user_comment': userComment,
      'status': status.value,
      'added_at': addedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в JSON для экспорта (только данные автора).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'igdb_id': igdbId,
      'platform_id': platformId,
      'comment': authorComment,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CollectionGame copyWith({
    int? id,
    int? collectionId,
    int? igdbId,
    int? platformId,
    String? authorComment,
    String? userComment,
    GameStatus? status,
    DateTime? addedAt,
    Game? game,
    Platform? platform,
  }) {
    return CollectionGame(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      igdbId: igdbId ?? this.igdbId,
      platformId: platformId ?? this.platformId,
      authorComment: authorComment ?? this.authorComment,
      userComment: userComment ?? this.userComment,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      game: game ?? this.game,
      platform: platform ?? this.platform,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionGame && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CollectionGame(id: $id, igdbId: $igdbId, status: ${status.value})';
}

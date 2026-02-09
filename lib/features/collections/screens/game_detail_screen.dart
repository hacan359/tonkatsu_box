import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_game.dart';
import '../../../shared/models/game.dart';
import '../../../shared/widgets/media_detail_view.dart';
import '../../../shared/widgets/source_badge.dart';
import '../providers/collections_provider.dart';
import '../widgets/status_dropdown.dart';

/// Экран детального просмотра игры в коллекции.
///
/// Позволяет просматривать полную информацию об игре,
/// изменять статус и редактировать комментарии.
class GameDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [GameDetailScreen].
  const GameDetailScreen({
    required this.collectionId,
    required this.gameId,
    required this.isEditable,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// ID записи игры в коллекции.
  final int gameId;

  /// Можно ли редактировать комментарий автора.
  final bool isEditable;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionGame>> gamesAsync =
        ref.watch(collectionGamesNotifierProvider(widget.collectionId));

    return gamesAsync.when(
      data: (List<CollectionGame> games) {
        final CollectionGame? collectionGame = _findGame(games);
        if (collectionGame == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Game not found')),
          );
        }
        return _buildContent(collectionGame);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  CollectionGame? _findGame(List<CollectionGame> games) {
    for (final CollectionGame game in games) {
      if (game.id == widget.gameId) {
        return game;
      }
    }
    return null;
  }

  Widget _buildContent(CollectionGame collectionGame) {
    final Game? game = collectionGame.game;

    return MediaDetailView(
      title: collectionGame.gameName,
      coverUrl: game?.coverUrl,
      placeholderIcon: Icons.videogame_asset,
      source: DataSource.igdb,
      typeIcon: Icons.sports_esports,
      typeLabel: collectionGame.platformName,
      infoChips: _buildInfoChips(game),
      description: game?.summary,
      statusWidget: StatusDropdown(
        status: collectionGame.status,
        onChanged: (GameStatus status) =>
            _updateStatus(collectionGame.id, status),
      ),
      authorComment: collectionGame.authorComment,
      userComment: collectionGame.userComment,
      hasAuthorComment: collectionGame.hasAuthorComment,
      hasUserComment: collectionGame.hasUserComment,
      isEditable: widget.isEditable,
      onAuthorCommentSave: (String? text) =>
          _saveAuthorComment(collectionGame.id, text),
      onUserCommentSave: (String? text) =>
          _saveUserComment(collectionGame.id, text),
    );
  }

  List<MediaDetailChip> _buildInfoChips(Game? game) {
    final List<MediaDetailChip> chips = <MediaDetailChip>[];
    if (game?.releaseYear != null) {
      chips.add(MediaDetailChip(
        icon: Icons.calendar_today_outlined,
        text: game!.releaseYear.toString(),
      ));
    }
    if (game?.formattedRating != null) {
      chips.add(MediaDetailChip(
        icon: Icons.star_outline,
        text: '${game!.formattedRating}/10',
      ));
    }
    if (game?.genres != null && game!.genres!.isNotEmpty) {
      chips.add(MediaDetailChip(
        icon: Icons.category_outlined,
        text: game.genresString!,
      ));
    }
    return chips;
  }

  Future<void> _updateStatus(int id, GameStatus status) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status);
  }

  Future<void> _saveAuthorComment(int id, String? text) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateAuthorComment(id, text);
  }

  Future<void> _saveUserComment(int id, String? text) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateUserComment(id, text);
  }
}

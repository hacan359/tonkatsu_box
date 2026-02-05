import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection_game.dart';
import '../../../shared/models/game.dart';
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
        return _buildContent(context, collectionGame);
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

  Widget _buildContent(BuildContext context, CollectionGame collectionGame) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Game? game = collectionGame.game;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // AppBar с обложкой
          _buildSliverAppBar(context, collectionGame, game, colorScheme),

          // Контент
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Информация об игре
                  _buildGameInfo(context, collectionGame, game),

                  const SizedBox(height: 24),

                  // Статус
                  _buildStatusSection(context, collectionGame),

                  // Описание
                  if (game?.summary != null) ...<Widget>[
                    const SizedBox(height: 24),
                    _buildSummarySection(context, game!),
                  ],

                  // Комментарий автора
                  const SizedBox(height: 24),
                  _buildAuthorCommentSection(context, collectionGame),

                  // Личные заметки
                  const SizedBox(height: 24),
                  _buildUserNotesSection(context, collectionGame),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    CollectionGame collectionGame,
    Game? game,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          collectionGame.gameName,
          style: const TextStyle(
            shadows: <Shadow>[
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Обложка
            if (game?.coverUrl != null)
              CachedNetworkImage(
                imageUrl: game!.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        _buildPlaceholderCover(colorScheme),
              )
            else
              _buildPlaceholderCover(colorScheme),

            // Градиент для читаемости текста
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const <double>[0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset,
        size: 80,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildGameInfo(
    BuildContext context,
    CollectionGame collectionGame,
    Game? game,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Платформа
        Row(
          children: <Widget>[
            Icon(
              Icons.sports_esports,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              collectionGame.platformName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Жанры и год
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            if (game?.genres != null && game!.genres!.isNotEmpty)
              _buildInfoChip(
                Icons.category_outlined,
                game.genresString!,
                colorScheme,
              ),
            if (game?.releaseYear != null)
              _buildInfoChip(
                Icons.calendar_today_outlined,
                game!.releaseYear.toString(),
                colorScheme,
              ),
            if (game?.formattedRating != null)
              _buildInfoChip(
                Icons.star_outline,
                '${game!.formattedRating}/10',
                colorScheme,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, CollectionGame game) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StatusDropdown(
          status: game.status,
          onChanged: (GameStatus status) => _updateStatus(game.id, status),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, Game game) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          game.summary!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorCommentSection(
    BuildContext context,
    CollectionGame game,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.format_quote,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Author's Comment",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.isEditable)
              TextButton.icon(
                onPressed: () => _editAuthorComment(game),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.tertiaryContainer,
            ),
          ),
          child: game.hasAuthorComment
              ? Text(
                  game.authorComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                )
              : Text(
                  widget.isEditable
                      ? 'No comment yet. Tap Edit to add one.'
                      : 'No comment from the author.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserNotesSection(BuildContext context, CollectionGame game) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.note_alt_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _editUserNotes(game),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primaryContainer,
            ),
          ),
          child: game.hasUserComment
              ? Text(
                  game.userComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                )
              : Text(
                  'No notes yet. Tap Edit to add your personal notes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(int id, GameStatus status) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status);
  }

  Future<void> _editAuthorComment(CollectionGame game) async {
    final String? result = await _showCommentDialog(
      title: "Edit Author's Comment",
      hint: 'Write a comment about this game...',
      initialValue: game.authorComment,
    );

    if (result == null) return;

    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateAuthorComment(game.id, result.isEmpty ? null : result);
  }

  Future<void> _editUserNotes(CollectionGame game) async {
    final String? result = await _showCommentDialog(
      title: 'Edit My Notes',
      hint: 'Write your personal notes...',
      initialValue: game.userComment,
    );

    if (result == null) return;

    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateUserComment(game.id, result.isEmpty ? null : result);
  }

  Future<String?> _showCommentDialog({
    required String title,
    required String hint,
    String? initialValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

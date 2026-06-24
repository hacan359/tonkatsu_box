import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/theme/app_colors.dart';
import '../../collections/providers/collections_provider.dart';
import '../services/search_collection_adder.dart';
import '../widgets/item_details_sheet.dart';
import 'media_action_handler.dart';

/// Game source handler (IGDB).
///
/// Picker does not block any collection: the same game on a different
/// platform is intentionally allowed. Platform is chosen via a dedicated
/// dialog before the add.
class GameHandler implements MediaActionHandler {
  GameHandler({
    required WidgetRef ref,
    required SearchCollectionAdder adder,
    required Map<int, Platform> Function() platformMap,
    required Set<int> Function() targetCollections,
    void Function(Game game)? onGameSelected,
  })  : _ref = ref,
        _adder = adder,
        _platformMap = platformMap,
        _targetCollections = targetCollections,
        _onGameSelected = onGameSelected;

  final WidgetRef _ref;
  final SearchCollectionAdder _adder;
  final Map<int, Platform> Function() _platformMap;
  final Set<int> Function() _targetCollections;
  final void Function(Game game)? _onGameSelected;

  @override
  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final Game game = item as Game;
    if (_onGameSelected != null) {
      _onGameSelected(game);
      return;
    }
    final Set<int> targets = _targetCollections();
    if (targets.isNotEmpty) {
      await _addToCollections(context, targets, game);
      return;
    }
    showDetails(context, game, mediaType);
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final Game game = item as Game;
    final List<CollectedItemInfo> infos = await _collectedInfos(game.id);
    if (!context.mounted) return;

    // Same game on a different platform is allowed — pass empty alreadyIn.
    final PickedCollection? picked = await _adder.pickCollection(
      context: context,
      alreadyIn: const <int?>{},
    );
    if (picked == null || !context.mounted) return;

    final Set<int> alreadyPlatforms = infos
        .where((CollectedItemInfo i) => i.collectionId == picked.id)
        .map((CollectedItemInfo i) => i.platformId)
        .whereType<int>()
        .toSet();

    final int? platformId = await _selectPlatform(
      context,
      game,
      alreadyPlatforms,
    );
    if (platformId == null || !context.mounted) return;

    await _adder.addToCollection(
      context: context,
      collectionId: picked.id,
      collectionName: picked.name,
      mediaType: MediaType.game,
      externalId: game.id,
      platformId: platformId,
      title: game.name,
      upsert: () => _ref.read(gameDaoProvider).upsertGame(game),
      imageType: ImageType.gameCover,
      imageId: game.id.toString(),
      imageUrl: game.coverUrl,
    );
  }

  @override
  void showDetails(BuildContext context, Object item, MediaType mediaType) {
    final Game game = item as Game;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => ItemDetailsSheet.game(
        game,
        onAddToCollection: () => addToAnyCollection(context, game, mediaType),
      ),
    );
  }

  /// Adds [game] to all [collectionIds] (multi-select add). The platform is
  /// asked once, then reused for every target collection.
  Future<void> _addToCollections(
    BuildContext context,
    Set<int> collectionIds,
    Game game,
  ) async {
    final List<CollectedItemInfo> infos = await _collectedInfos(game.id);
    // Platforms already present in any of the target collections — used only to
    // mark them in the picker, not to block (same game on a new platform is OK).
    final Set<int> alreadyPlatforms = infos
        .where((CollectedItemInfo i) =>
            i.collectionId != null && collectionIds.contains(i.collectionId))
        .map((CollectedItemInfo i) => i.platformId)
        .whereType<int>()
        .toSet();

    if (!context.mounted) return;
    final int? platformId = await _selectPlatform(
      context,
      game,
      alreadyPlatforms,
    );
    if (platformId == null || !context.mounted) return;

    await _adder.addToCollections(
      context: context,
      collectionIds: collectionIds,
      mediaType: MediaType.game,
      externalId: game.id,
      platformId: platformId,
      title: game.name,
      upsert: () => _ref.read(gameDaoProvider).upsertGame(game),
      imageType: ImageType.gameCover,
      imageId: game.id.toString(),
      imageUrl: game.coverUrl,
    );
  }

  Future<List<CollectedItemInfo>> _collectedInfos(int gameId) async {
    final Map<int, List<CollectedItemInfo>> collected =
        await _ref.read(collectedGameIdsProvider.future);
    return collected[gameId] ?? <CollectedItemInfo>[];
  }

  Future<int?> _selectPlatform(
    BuildContext context,
    Game game,
    Set<int> alreadyAdded,
  ) async {
    final List<int>? platformIds = game.platformIds;
    if (platformIds == null || platformIds.isEmpty) return -1;
    if (platformIds.length == 1) return platformIds.first;

    final Map<int, Platform> map = _platformMap();
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(S.of(context).searchSelectPlatform),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: platformIds.map((int id) {
            final Platform? platform = map[id];
            final String name = platform?.displayName ?? 'Platform $id';
            final bool already = alreadyAdded.contains(id);
            return ListTile(
              leading: Icon(
                already ? Icons.check_circle : Icons.videogame_asset,
                size: 24,
                color: already ? AppColors.success : null,
              ),
              title: Text(name),
              onTap: () => Navigator.of(context).pop(id),
            );
          }).toList(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).cancel),
          ),
        ],
      ),
    );
  }
}

// Фильтр режимов игры IGDB (single / multi / co-op / split screen / MMO).

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../models/search_source.dart';

/// Фильтр режимов IGDB game_modes.
///
/// ID-шники зафиксированы IGDB и не меняются:
///   1 Single player, 2 Multiplayer, 3 Co-operative,
///   4 Split screen, 5 MMO, 6 Battle Royale.
class IgdbGameModeFilter extends SearchFilter {
  @override
  String get key => 'gameMode';

  @override
  bool get multiSelect => true;

  @override
  String placeholder(S l) => l.browseFilterGameMode;

  @override
  FilterOption get allOption => const FilterOption(
        id: 'any',
        label: 'Any',
        value: null,
      );

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async {
    return <FilterOption>[
      FilterOption(id: '1', label: l.gameModeSinglePlayer, value: 1),
      FilterOption(id: '2', label: l.gameModeMultiplayer, value: 2),
      FilterOption(id: '3', label: l.gameModeCoOperative, value: 3),
      FilterOption(id: '4', label: l.gameModeSplitScreen, value: 4),
      FilterOption(id: '5', label: l.gameModeMmo, value: 5),
      FilterOption(id: '6', label: l.gameModeBattleRoyale, value: 6),
    ];
  }
}

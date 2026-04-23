import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/igdb_game_mode_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('IgdbGameModeFilter', () {
    late IgdbGameModeFilter filter;
    late MockS mockL;

    setUp(() {
      filter = IgdbGameModeFilter();
      mockL = MockS();
      when(() => mockL.browseFilterGameMode).thenReturn('Game mode');
      when(() => mockL.gameModeSinglePlayer).thenReturn('Single player');
      when(() => mockL.gameModeMultiplayer).thenReturn('Multiplayer');
      when(() => mockL.gameModeCoOperative).thenReturn('Co-operative');
      when(() => mockL.gameModeSplitScreen).thenReturn('Split screen');
      when(() => mockL.gameModeMmo).thenReturn('MMO');
      when(() => mockL.gameModeBattleRoyale).thenReturn('Battle Royale');
    });

    test('key is "gameMode" — binds to IGDB game_modes', () {
      expect(filter.key, 'gameMode');
    });

    test('is multi-select — a game can combine modes (single+multi+co-op)',
        () {
      expect(filter.multiSelect, isTrue);
    });

    test('options use canonical IGDB game_mode IDs (1-6)', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(),
          <int>[1, 2, 3, 4, 5, 6]);
    });
  });
}

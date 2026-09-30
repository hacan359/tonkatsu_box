import 'package:core/models/steamgriddb_game.dart';
import 'package:core/models/steamgriddb_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/api/steamgriddb_api.dart';
import '../../../../l10n/app_localizations.dart';
import 'cover_candidate_grid.dart';

final Logger _log = Logger('SteamGridDbCoverPicker');

/// Full-size URL of the grid the user picked for [gameName], or `null`.
/// There is no stored IGDB→SteamGridDB link, so the game is found by name.
Future<String?> pickSteamGridDbCover(
  BuildContext context, {
  required String gameName,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => SteamGridDbCoverPicker(gameName: gameName),
  );
}

class SteamGridDbCoverPicker extends ConsumerStatefulWidget {
  const SteamGridDbCoverPicker({required this.gameName, super.key});

  final String gameName;

  @override
  ConsumerState<SteamGridDbCoverPicker> createState() =>
      _SteamGridDbCoverPickerState();
}

class _SteamGridDbCoverPickerState
    extends ConsumerState<SteamGridDbCoverPicker> {
  List<SteamGridDbGame> _games = const <SteamGridDbGame>[];
  SteamGridDbGame? _selected;
  List<CoverCandidate> _candidates = const <CoverCandidate>[];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final List<SteamGridDbGame> games =
          await ref.read(steamGridDbApiProvider).searchGames(widget.gameName);
      if (!mounted) return;
      setState(() => _games = games);
      if (games.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      await _select(games.first);
    } on SteamGridDbApiException catch (e) {
      _log.warning('Search failed for "${widget.gameName}"', e);
      if (mounted) setState(_fail);
    }
  }

  Future<void> _select(SteamGridDbGame game) async {
    setState(() {
      _selected = game;
      _loading = true;
      _failed = false;
    });
    try {
      final List<SteamGridDbImage> grids =
          await ref.read(steamGridDbApiProvider).getGrids(game.id);
      if (!mounted || _selected != game) return;
      setState(() {
        _candidates = <CoverCandidate>[
          // Grids also come as wide Steam capsules; only posters fit a cover.
          for (final SteamGridDbImage g in grids)
            if (g.height > g.width)
              CoverCandidate(
                id: '${g.id}',
                thumbUrl: g.thumb,
                fullUrl: g.url,
                tooltip: '${g.dimensions} • ${g.style}',
              ),
        ];
        _loading = false;
      });
    } on SteamGridDbApiException catch (e) {
      _log.warning('Grids failed for SteamGridDB game ${game.id}', e);
      if (mounted && _selected == game) setState(_fail);
    }
  }

  void _fail() {
    _loading = false;
    _failed = true;
    _candidates = const <CoverCandidate>[];
  }

  @override
  Widget build(BuildContext context) {
    return CoverCandidateDialog(
      title: S.of(context).steamGridDbPanelTitle,
      loading: _loading,
      failed: _failed,
      candidates: _candidates,
      header: _games.length > 1 ? _buildGameChooser() : null,
    );
  }

  Widget _buildGameChooser() {
    return DropdownButton<SteamGridDbGame>(
      value: _selected,
      isExpanded: true,
      items: <DropdownMenuItem<SteamGridDbGame>>[
        for (final SteamGridDbGame game in _games)
          DropdownMenuItem<SteamGridDbGame>(
            value: game,
            child: Text(game.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (SteamGridDbGame? game) {
        if (game != null && game != _selected) _select(game);
      },
    );
  }
}

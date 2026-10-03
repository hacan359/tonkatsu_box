import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/api/igdb_api.dart';
import '../../../../l10n/app_localizations.dart';
import 'cover_candidate_grid.dart';

final Logger _log = Logger('IgdbCoverPicker');

// 2x keeps a cover sharp on the detail screen; the grid needs far less.
const String _fullSize = 't_cover_big_2x';
const String _thumbSize = 't_cover_big';

/// Full-size URL of the IGDB cover the user picked for [igdbGameId].
Future<String?> pickIgdbCover(
  BuildContext context, {
  required int igdbGameId,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => IgdbCoverPicker(igdbGameId: igdbGameId),
  );
}

class IgdbCoverPicker extends ConsumerStatefulWidget {
  const IgdbCoverPicker({required this.igdbGameId, super.key});

  final int igdbGameId;

  @override
  ConsumerState<IgdbCoverPicker> createState() => _IgdbCoverPickerState();
}

class _IgdbCoverPickerState extends ConsumerState<IgdbCoverPicker> {
  List<CoverCandidate> _candidates = const <CoverCandidate>[];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<String> ids = await ref
          .read(igdbApiProvider)
          .getCoverImageIds(widget.igdbGameId);
      if (!mounted) return;
      setState(() {
        _candidates = <CoverCandidate>[
          for (final String id in ids)
            CoverCandidate(
              id: id,
              thumbUrl: IgdbApi.imageUrl(id, size: _thumbSize),
              fullUrl: IgdbApi.imageUrl(id, size: _fullSize),
            ),
        ];
        _loading = false;
      });
    } on IgdbApiException catch (e) {
      _log.warning('Covers failed for IGDB game ${widget.igdbGameId}', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoverCandidateDialog(
      title: S.of(context).coverSourceIgdb,
      loading: _loading,
      failed: _failed,
      candidates: _candidates,
    );
  }
}

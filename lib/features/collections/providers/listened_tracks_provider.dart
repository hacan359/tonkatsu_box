import 'package:core/models/data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/utils/highest_pair.dart';

typedef ListenedTracksArg = ({int collectionId, DataSource source, int audioId});

/// Highest listened (disc, track) of an album, or `null` when nothing is
/// marked. The tracker section invalidates it after every mark.
final AutoDisposeFutureProviderFamily<(int, int)?, ListenedTracksArg>
    lastListenedTrackProvider =
    FutureProvider.autoDispose.family<(int, int)?, ListenedTracksArg>(
  (Ref ref, ListenedTracksArg arg) async {
    final Map<(int, int), DateTime?> listened = await ref
        .watch(audioDaoProvider)
        .getListenedTracks(arg.collectionId, arg.source, arg.audioId);
    return highestPair(listened.keys);
  },
);

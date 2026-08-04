import 'package:core/models/media_type.dart';
import 'package:flutter/widgets.dart';

import '../models/library_stats.dart';
import '../widgets/stats_crowd_section.dart';
import '../widgets/stats_formats_section.dart';
import '../widgets/stats_platforms_section.dart';
import '../widgets/stats_subgenres_section.dart';
import '../widgets/stats_versus_section.dart';

/// Sections below the activity ribbon, in order, empty ones left out. Shared,
/// so a new section is not something to remember in two page files.
List<Widget> statsSectionsAfterMonths(
  LibraryStats stats,
  String titleLanguage,
) {
  return <Widget>[
    if (stats.versus.isNotEmpty)
      StatsVersusSection(pairs: stats.versus, titleLanguage: titleLanguage),
    if (stats.platforms.isNotEmpty) StatsPlatformsSection(stats: stats),
    if (stats.hasFormats(MediaType.anime))
      StatsFormatsSection(stats: stats, mediaType: MediaType.anime),
    if (stats.hasFormats(MediaType.manga))
      StatsFormatsSection(stats: stats, mediaType: MediaType.manga),
    if (stats.subgenres.isNotEmpty) StatsSubgenresSection(stats: stats),
    if (stats.hasCrowdDeltas)
      StatsCrowdSection(stats: stats, titleLanguage: titleLanguage),
  ];
}

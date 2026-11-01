import 'package:flutter/material.dart';

import 'media_detail_chip.dart';
import 'progress_tiles.dart';

/// The card's blocks, built once by the detail view's state (which owns note
/// editing and date picking) and arranged by a desktop or mobile layout.
class DetailSections {
  const DetailSections({
    required this.title,
    required this.cover,
    required this.badges,
    required this.chips,
    required this.notes,
    required this.author,
    required this.accentColor,
    this.description,
    this.tags,
    this.status,
    this.statusList,
    this.rating,
    this.onRatingChanged,
    this.progress,
    this.tracker,
    this.gallery,
    this.extras = const <Widget>[],
    this.recommendations = const <Widget>[],
  });

  final String title;

  /// Fills its parent; each layout gives it the poster size.
  final Widget cover;
  final Widget badges;
  final List<MediaDetailChip> chips;
  final Widget notes;
  final Widget author;
  final Color accentColor;
  final String? description;
  final Widget? tags;

  /// Chip row; the desktop side column prefers [statusList].
  final Widget? status;
  final Widget? statusList;

  /// 1.0..10.0; the rating block is hidden while [onRatingChanged] is null.
  final double? rating;
  final ValueChanged<double?>? onRatingChanged;
  final DetailProgress? progress;
  final Widget? tracker;
  final Widget? gallery;
  final List<Widget> extras;
  final List<Widget> recommendations;
}

/// User-set progress facts plus the system metadata (added / last activity
/// dates) that each layout tucks behind a tooltip.
class DetailProgress {
  const DetailProgress({
    required this.facts,
    required this.added,
    required this.systemMeta,
  });

  final List<ProgressFact> facts;
  final ProgressFact added;
  final String systemMeta;
}

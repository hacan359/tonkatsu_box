import '../widgets/mood_grid_cell_media.dart';

/// Tokens accepted by [renderRowCaption]. Used by the editor dialog for
/// chip insertion and by tests to assert the supported surface area.
const List<String> kMoodGridCaptionTokens = <String>[
  'name',
  'year',
  'genre',
  'rating',
];

/// Substitutes `{{token}}` placeholders in [template] from [media]. Missing
/// values render empty; spaces collapse and the result is trimmed.
String renderRowCaption(String template, MoodGridCellMedia media) {
  final String name = media.title ?? '';
  final String year = media.year?.toString() ?? '';
  final String genre = media.genre ?? '';
  final String rating =
      media.rating == null ? '' : media.rating!.toStringAsFixed(1);

  String out = template
      .replaceAll('{{name}}', name)
      .replaceAll('{{year}}', year)
      .replaceAll('{{genre}}', genre)
      .replaceAll('{{rating}}', rating);

  out = out.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  return out;
}

import '../models/data_source.dart';
import '../models/media_type.dart';

/// Multi-provider types namespace covers by source (`anilist_1995`) so one does
/// not overwrite another. Must be used by both the write and the read side.
String coverImageId({
  required MediaType mediaType,
  required int externalId,
  DataSource? source,
  String? coverUrl,
}) {
  if (!mediaType.isMultiSource) return externalId.toString();

  final String base = '${(source ?? mediaType.defaultSource).name}_$externalId';
  if (mediaType != MediaType.book) return base;

  // A Fantlab cover belongs to one edition, so key by it — otherwise picking a
  // different edition stales the same `work` file.
  final RegExpMatch? edition =
      coverUrl != null ? _fantlabEditionId.firstMatch(coverUrl) : null;
  return edition != null ? '${base}_e${edition.group(1)}' : base;
}

final RegExp _fantlabEditionId = RegExp(r'/images/editions/\w+/(\d+)');

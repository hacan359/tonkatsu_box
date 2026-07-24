import 'collection_item.dart';
import 'data_source.dart';
import 'media_type.dart';

/// Content-based reference to a collection item, decoded from a `[[card:…]]`
/// note token; survives export/import since it carries no autoincrement id.
class CardLinkRef {
  const CardLinkRef({
    required this.mediaType,
    required this.externalId,
    required this.display,
    this.source,
    this.platformId,
    this.collectionId,
  });

  final MediaType mediaType;
  final int externalId;

  /// Manga identity component; `null` for other media types.
  final DataSource? source;

  /// Game platform / animation source component; `null` when not applicable.
  final int? platformId;

  /// Resolution hint, not part of the content identity.
  final int? collectionId;

  /// Fallback label shown when the target can't be resolved.
  final String display;

  @override
  bool operator ==(Object other) =>
      other is CardLinkRef &&
      other.mediaType == mediaType &&
      other.externalId == externalId &&
      other.source == source &&
      other.platformId == platformId &&
      other.collectionId == collectionId;

  @override
  int get hashCode =>
      Object.hash(mediaType, externalId, source, platformId, collectionId);
}

/// Builds the `[[card:…|display]]` token for [item]. Games get the platform
/// appended (`God of War (PS2)`) to stay distinguishable in plain text.
String buildCardLinkToken(CollectionItem item) {
  final StringBuffer payload = StringBuffer()
    ..write('mt=${item.mediaType.value}')
    ..write(';id=${item.externalId}');

  if (item.mediaType == MediaType.manga && item.source != null) {
    payload.write(';src=${item.source!.name}');
  }
  if (item.platformId != null) {
    payload.write(';pf=${item.platformId}');
  }
  if (item.collectionId != null) {
    payload.write(';col=${item.collectionId}');
  }

  return '[[card:${payload.toString()}|${_buildDisplay(item)}]]';
}

String _buildDisplay(CollectionItem item) {
  final String base = item.mediaType == MediaType.game && item.platformId != null
      ? '${item.itemName} (${item.platformName})'
      : item.itemName;
  return sanitizeCardLinkDisplay(base);
}

/// Strips characters that would break the `[[…|…]]` grammar.
String sanitizeCardLinkDisplay(String value) =>
    value.replaceAll(RegExp(r'[\]\[|]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Matches a whole `[[card:payload|display]]` token in note text.
final RegExp cardLinkTokenPattern =
    RegExp(r'\[\[card:([^\]|]*)(?:\|([^\]]*))?\]\]');

/// Extracts every parseable card-link reference from [text].
List<CardLinkRef> extractCardLinks(String text) {
  final List<CardLinkRef> refs = <CardLinkRef>[];
  for (final RegExpMatch match in cardLinkTokenPattern.allMatches(text)) {
    final CardLinkRef? ref = parseCardLink(match.group(1) ?? '', match.group(2));
    if (ref != null) refs.add(ref);
  }
  return refs;
}

/// Parses a token's `payload` and optional `display`; `null` when payload lacks
/// a valid media type or external id.
CardLinkRef? parseCardLink(String payload, String? display) {
  final Map<String, String> fields = <String, String>{};
  for (final String part in payload.split(';')) {
    final int eq = part.indexOf('=');
    if (eq <= 0) continue;
    fields[part.substring(0, eq).trim()] = part.substring(eq + 1).trim();
  }

  final String? mt = fields['mt'];
  final String? rawId = fields['id'];
  if (mt == null || rawId == null) return null;

  final int? externalId = int.tryParse(rawId);
  if (externalId == null) return null;

  final MediaType? mediaType = MediaType.tryFromString(mt);
  if (mediaType == null) return null;

  final String? rawSrc = fields['src'];
  final String? rawPf = fields['pf'];
  final String? rawCol = fields['col'];

  return CardLinkRef(
    mediaType: mediaType,
    externalId: externalId,
    source: rawSrc != null ? DataSource.fromName(rawSrc) : null,
    platformId: rawPf != null ? int.tryParse(rawPf) : null,
    collectionId: rawCol != null ? int.tryParse(rawCol) : null,
    display: (display == null || display.trim().isEmpty)
        ? mediaType.displayLabel
        : display.trim(),
  );
}

import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tag.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/item_card_progress.dart';
import 'table_fields.dart';
import '../../../../shared/constants/item_status_ui.dart';
import '../../../../shared/constants/media_type_ui.dart';

/// Builds grid rows for the collection table. Cell values are the plain
/// sortable/filterable representations; widgets come from column renderers.
List<TrinaRow<dynamic>> buildCollectionTableRows({
  required List<CollectionItem> items,
  required Set<int> selectedIds,
  required String anilistTitleLanguage,
  required S l,
  required List<Tag> tags,
  required Map<int, List<int>> itemTags,
}) {
  final Map<int, Tag> tagById = tags.byId;
  return items.map((CollectionItem item) {
    return TrinaRow<dynamic>(
      data: item,
      checked: selectedIds.contains(item.id),
      cells: <String, TrinaCell>{
        TableFields.drag: TrinaCell(value: ''),
        TableFields.thumb: TrinaCell(value: ''),
        TableFields.name: TrinaCell(
          value: item.displayName(anilistTitleLanguage),
        ),
        TableFields.platform: TrinaCell(value: _platformLabel(item)),
        TableFields.type: TrinaCell(value: item.mediaType.localizedLabel(l)),
        TableFields.status: TrinaCell(value: item.status.genericLabel(l)),
        TableFields.progress:
            TrinaCell(value: itemCardProgress(item)?.label ?? ''),
        TableFields.favorite: TrinaCell(value: item.isFavorite ? 1 : 0),
        TableFields.rating: TrinaCell(value: item.userRating ?? 0),
        TableFields.externalRating: TrinaCell(value: item.apiRating ?? 0),
        TableFields.year: TrinaCell(value: item.releaseYear ?? 0),
        // All tag names joined so a "contains" filter matches any tag; sort
        // still keys off the leading (primary) tag.
        TableFields.tags: TrinaCell(
          value: tagById
              .orderedFor(itemTags[item.id])
              .map((Tag t) => t.name)
              .join(', '),
        ),
      },
    );
  }).toList();
}

String _platformLabel(CollectionItem item) {
  if (item.mediaType != MediaType.game) return '';
  return item.platform?.abbreviation ?? item.platform?.name ?? '';
}

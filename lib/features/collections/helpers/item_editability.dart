import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';

/// An uncategorized item has no collection to defer to, so it is always
/// editable; any other item follows its collection, unknown ones stay locked.
bool isItemEditable(CollectionItem item, List<Collection>? collections) {
  if (item.isUncategorized) return true;
  for (final Collection c in collections ?? const <Collection>[]) {
    if (c.id == item.collectionId) return c.isEditable;
  }
  return false;
}

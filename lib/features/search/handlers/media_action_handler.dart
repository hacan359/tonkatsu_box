import 'package:flutter/material.dart';

import '../../../shared/models/media_type.dart';

/// Contract for source-specific search actions.
///
/// Argument type is `Object` (not a generic): Dart generics are invariant,
/// so a single registry of `MediaActionHandler<T>` cannot be built — each
/// handler downcasts internally. Animation is a sub-mode of Movie/TvShow
/// and is dispatched via [MediaType], not a separate handler.
abstract class MediaActionHandler {
  Future<void> onTap(BuildContext context, Object item, MediaType mediaType);

  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  );

  void showDetails(BuildContext context, Object item, MediaType mediaType);
}

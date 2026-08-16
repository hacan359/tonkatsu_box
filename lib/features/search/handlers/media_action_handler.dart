import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

/// Items are `Object`, not a generic: invariance would forbid one registry of
/// `MediaActionHandler<T>`. Animation dispatches via [MediaType], no handler.
abstract class MediaActionHandler {
  Future<void> onTap(BuildContext context, Object item, MediaType mediaType);

  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  );

  void showDetails(BuildContext context, Object item, MediaType mediaType);
}

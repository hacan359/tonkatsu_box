import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Opens the form on the collection [source] filled last time when the caller
/// gave none. Read once: a rerun must not rebuild the form mid-import.
class RememberedImportCollection extends ConsumerStatefulWidget {
  const RememberedImportCollection({
    required this.source,
    required this.initialCollectionId,
    required this.builder,
    super.key,
  });

  final ImportSourceKind source;
  final int? initialCollectionId;
  final Widget Function(int? collectionId) builder;

  @override
  ConsumerState<RememberedImportCollection> createState() =>
      _RememberedImportCollectionState();
}

class _RememberedImportCollectionState
    extends ConsumerState<RememberedImportCollection> {
  late Future<int?> _collectionId = _resolve();

  Future<int?> _resolve() async {
    final int? given = widget.initialCollectionId;
    if (given != null) return given;
    try {
      final CollectionImport? last = await ref
          .read(databaseServiceProvider)
          .collectionImportDao
          .getLatestForSource(widget.source);
      return last?.collectionId;
    } on Exception {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant RememberedImportCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCollectionId != widget.initialCollectionId ||
        oldWidget.source != widget.source) {
      _collectionId = _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _collectionId,
      builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return widget.builder(snapshot.data);
      },
    );
  }
}

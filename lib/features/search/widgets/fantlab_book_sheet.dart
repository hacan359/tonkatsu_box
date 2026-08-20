import 'package:core/models/book.dart';
import 'package:flutter/material.dart';

import '../../../core/api/fantlab_api.dart';
import '../../collections/widgets/fantlab_edition_picker.dart';
import 'item_details_sheet.dart';

/// Picking an edition swaps cover and metadata live — the cover cache is keyed
/// by edition — and reports it via [onEditionChanged] so enrich saves it.
class FantlabBookSheet extends StatefulWidget {
  const FantlabBookSheet({
    required this.work,
    required this.onAddToCollection,
    required this.onEditionChanged,
    this.overviewLoader,
    super.key,
  });

  final Book work;
  final VoidCallback onAddToCollection;
  final void Function(String workId, FantlabEdition? edition) onEditionChanged;
  final Future<String?> Function()? overviewLoader;

  @override
  State<FantlabBookSheet> createState() => _FantlabBookSheetState();
}

class _FantlabBookSheetState extends State<FantlabBookSheet> {
  FantlabEdition? _selected;

  @override
  void initState() {
    super.initState();
    // Clear any selection left over from a previously opened sheet.
    widget.onEditionChanged(widget.work.nativeId, null);
  }

  /// The work with the picked edition's cover / metadata overlaid (or the bare
  /// work before any pick).
  Book get _current => _selected != null
      ? applyFantlabEdition(widget.work, _selected!)
      : widget.work;

  void _onSelected(FantlabEdition edition) {
    setState(() => _selected = edition);
    widget.onEditionChanged(widget.work.nativeId, edition);
  }

  @override
  Widget build(BuildContext context) {
    final Book current = _current;
    return ItemDetailsSheet.book(
      current,
      onAddToCollection: widget.onAddToCollection,
      overviewLoader: widget.overviewLoader,
      editionsSection: FantlabEditionsSection(
        workId: widget.work.nativeId,
        selectedEditionId:
            _selected?.editionId ?? editionIdFromCoverUrl(current.coverUrl),
        onSelected: _onSelected,
      ),
    );
  }
}

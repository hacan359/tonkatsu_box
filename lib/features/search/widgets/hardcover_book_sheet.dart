import 'package:core/models/book.dart';
import 'package:flutter/material.dart';

import '../../../core/api/hardcover_api.dart';
import '../../collections/widgets/hardcover_edition_picker.dart';
import 'item_details_sheet.dart';

/// Stateful host for a Hardcover book's detail sheet. Shows an inline editions
/// strip; picking one swaps the cover / localized title / metadata live and is
/// reported via [onEditionChanged] so the handler's enrich step saves it on
/// add — the Fantlab sheet pattern.
class HardcoverBookSheet extends StatefulWidget {
  const HardcoverBookSheet({
    required this.book,
    required this.onAddToCollection,
    required this.onEditionChanged,
    this.overviewLoader,
    super.key,
  });

  final Book book;
  final VoidCallback onAddToCollection;
  final void Function(String bookId, HardcoverEdition? edition)
      onEditionChanged;
  final Future<String?> Function()? overviewLoader;

  @override
  State<HardcoverBookSheet> createState() => _HardcoverBookSheetState();
}

class _HardcoverBookSheetState extends State<HardcoverBookSheet> {
  HardcoverEdition? _selected;

  @override
  void initState() {
    super.initState();
    // Clear any selection left over from a previously opened sheet.
    widget.onEditionChanged(widget.book.nativeId, null);
  }

  /// The book with the picked edition overlaid (or the bare book before any
  /// pick).
  Book get _current => _selected != null
      ? applyHardcoverEdition(widget.book, _selected!)
      : widget.book;

  void _onSelected(HardcoverEdition edition) {
    setState(() => _selected = edition);
    widget.onEditionChanged(widget.book.nativeId, edition);
  }

  @override
  Widget build(BuildContext context) {
    final Book current = _current;
    return ItemDetailsSheet.book(
      current,
      onAddToCollection: widget.onAddToCollection,
      overviewLoader: widget.overviewLoader,
      editionsSection: HardcoverEditionsSection(
        bookId: widget.book.nativeId,
        selectedEditionId: _selected?.id ??
            hardcoverEditionIdFromExternalUrl(current.externalUrl) ??
            hardcoverEditionIdFromCoverUrl(current.coverUrl),
        onSelected: _onSelected,
      ),
    );
  }
}

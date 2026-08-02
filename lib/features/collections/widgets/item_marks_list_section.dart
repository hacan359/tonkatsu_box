// Branch B marks UI: an "add mark" form plus a list of existing marks, for
// media that has no ready-made unit list (anime, manga, custom, books…).

import 'package:core/models/item_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/item_marks_provider.dart';
import 'item_mark_controls.dart';

/// Lists existing marks for an item and offers an "add mark" form. Does not
/// synthesise empty unit rows — only marks the user actually created are shown.
class ItemMarksListSection extends ConsumerWidget {
  /// Creates an [ItemMarksListSection].
  const ItemMarksListSection({
    required this.itemId,
    required this.accentColor,
    this.unitPresets = kUnitPresets,
    super.key,
  });

  /// Owning `collection_items.id`.
  final int itemId;

  /// Accent color for the section header and add button.
  final Color accentColor;

  /// Unit types offered in the add form.
  final List<String> unitPresets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final ItemMarksState marks = ref.watch(itemMarksProvider(itemId));
    final List<ItemMark> all = marks.all
      ..sort((ItemMark a, ItemMark b) {
        final int byType = a.unitType.compareTo(b.unitType);
        if (byType != 0) return byType;
        return a.displayNumber.compareTo(b.displayNumber);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.bookmark_outline, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.itemMarkSectionTitle,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              l.itemMarkEmpty,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ...all.map((ItemMark m) => _MarkRow(
                key: ValueKey<String>(
                  '${m.unitType}:${m.parentNumber}:${m.unitNumber}',
                ),
                itemId: itemId,
                mark: m,
                accentColor: accentColor,
              )),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddForm(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.itemMarkAdd),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddForm(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => _AddMarkDialog(
        itemId: itemId,
        unitPresets: unitPresets,
      ),
    );
  }
}

class _MarkRow extends ConsumerStatefulWidget {
  const _MarkRow({
    required this.itemId,
    required this.mark,
    required this.accentColor,
    super.key,
  });

  final int itemId;
  final ItemMark mark;
  final Color accentColor;

  @override
  ConsumerState<_MarkRow> createState() => _MarkRowState();
}

class _MarkRowState extends ConsumerState<_MarkRow> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final int itemId = widget.itemId;
    final ItemMark mark = widget.mark;
    final S l = S.of(context);
    final String label = l.itemMarkUnitLabel(
      unitTypeLabel(l, mark.unitType),
      mark.displayNumber,
    );
    final String? note = mark.note;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ),
              ItemMarkControls(
                itemId: itemId,
                unitType: mark.unitType,
                parentNumber: mark.parentNumber,
                unitNumber: mark.unitNumber,
                onNotePressed: () =>
                    setState(() => _editingNote = !_editingNote),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: l.delete,
                color: AppColors.textTertiary,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(AppSpacing.xs),
                onPressed: () => ref
                    .read(itemMarksProvider(itemId).notifier)
                    .deleteMark(
                      mark.unitType,
                      mark.parentNumber,
                      mark.unitNumber,
                    ),
              ),
            ],
          ),
          if (_editingNote)
            ItemMarkNoteEditor(
              itemId: itemId,
              unitType: mark.unitType,
              parentNumber: mark.parentNumber,
              unitNumber: mark.unitNumber,
              accentColor: widget.accentColor,
              onDone: () => setState(() => _editingNote = false),
            )
          else if (note != null)
            MarkNoteText(note: note, accentColor: widget.accentColor),
        ],
      ),
    );
  }
}

class _AddMarkDialog extends ConsumerStatefulWidget {
  const _AddMarkDialog({
    required this.itemId,
    required this.unitPresets,
  });

  final int itemId;
  final List<String> unitPresets;

  @override
  ConsumerState<_AddMarkDialog> createState() => _AddMarkDialogState();
}

class _AddMarkDialogState extends ConsumerState<_AddMarkDialog> {
  late String _unitType;
  bool _customType = false;
  final TextEditingController _customTypeController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _unitType = widget.unitPresets.isNotEmpty
        ? widget.unitPresets.first
        : kUnitEpisode;
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _numberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final int? number = int.tryParse(_numberController.text.trim());
    if (number == null || number < 0) return false;
    if (_customType && _customTypeController.text.trim().isEmpty) return false;
    return _liked || _noteController.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    final int? number = int.tryParse(_numberController.text.trim());
    if (number == null) return;
    final String unitType = _customType
        ? _customTypeController.text.trim()
        : _unitType;
    final ({int parent, int unit}) coords =
        unitCoordsFor(unitType, number);
    final ItemMarksNotifier notifier =
        ref.read(itemMarksProvider(widget.itemId).notifier);
    if (_liked) {
      await notifier.setFavorite(
        unitType,
        coords.parent,
        coords.unit,
        value: true,
      );
    }
    final String note = _noteController.text.trim();
    if (note.isNotEmpty) {
      await notifier.setComment(unitType, coords.parent, coords.unit, note);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.itemMarkAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _customType ? _kCustomSentinel : _unitType,
              decoration: InputDecoration(labelText: l.type),
              items: <DropdownMenuItem<String>>[
                for (final String type in widget.unitPresets)
                  DropdownMenuItem<String>(
                    value: type,
                    child: Text(unitTypeLabel(l, type)),
                  ),
                DropdownMenuItem<String>(
                  value: _kCustomSentinel,
                  child: Text(l.mediaTypeCustom),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) return;
                setState(() {
                  if (value == _kCustomSentinel) {
                    _customType = true;
                  } else {
                    _customType = false;
                    _unitType = value;
                  }
                });
              },
            ),
            if (_customType) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customTypeController,
                decoration:
                    InputDecoration(labelText: l.itemMarkCustomType),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.itemMarkNumber,
                hintText: l.itemMarkNumberHint,
                helperText: l.itemMarkNumberHelper,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l.itemMarkNote,
                hintText: l.itemMarkNoteHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.itemMarkLike),
              value: _liked,
              onChanged: (bool value) => setState(() => _liked = value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: _canSave ? _save : null,
          child: Text(l.save),
        ),
      ],
    );
  }
}

const String _kCustomSentinel = '__custom__';

// Reusable like + note controls for a single unit of a collection item.

import 'dart:async';

import 'package:core/models/item_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/item_marks_provider.dart';

/// Localised label for a unit type. Falls back to the raw string for
/// user-defined (custom) types.
String unitTypeLabel(S l, String unitType) {
  switch (unitType) {
    case kUnitEpisode:
      return l.unitEpisode;
    case kUnitSeason:
      return l.unitSeason;
    case kUnitChapter:
      return l.unitChapter;
    case kUnitVolume:
      return l.unitVolume;
    case kUnitPage:
      return l.unitPage;
    case kUnitPart:
      return l.unitPart;
    default:
      return unitType;
  }
}

/// Rounded accent-tinted container shared by the note text and the note
/// editor — same look as the notes block on the item card, so a note is
/// recognisable at a glance. [emphasized] draws the stronger editing border.
BoxDecoration markNoteDecoration(Color accentColor, {bool emphasized = false}) {
  return BoxDecoration(
    color: accentColor.withAlpha(20),
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    border: Border.all(color: accentColor.withAlpha(emphasized ? 80 : 40)),
  );
}

/// Inline text of a mark's note: always visible in full, no tap needed —
/// the editor is only for changing it.
class MarkNoteText extends StatelessWidget {
  /// Creates a [MarkNoteText].
  const MarkNoteText({
    required this.note,
    required this.accentColor,
    super.key,
  });

  /// The note text to show.
  final String note;

  /// Accent color of the hosting section, tints the container.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: markNoteDecoration(accentColor),
      child: Text(
        note,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// A compact like-heart plus note-button pair bound to one unit of an item.
/// The like writes through [itemMarksProvider]; the note button only toggles
/// the host's inline [ItemMarkNoteEditor] — no dialogs (they stutter on
/// phones).
class ItemMarkControls extends ConsumerWidget {
  /// Creates [ItemMarkControls].
  const ItemMarkControls({
    required this.itemId,
    required this.unitType,
    required this.parentNumber,
    required this.unitNumber,
    required this.onNotePressed,
    this.showLike = true,
    this.iconSize = 18,
    super.key,
  });

  /// Owning `collection_items.id`.
  final int itemId;

  /// Unit type (see [kUnitPresets]).
  final String unitType;

  /// Season / volume number (0 when not applicable).
  final int parentNumber;

  /// Episode / chapter number (0 for a season/volume-level mark).
  final int unitNumber;

  /// Toggles the host's inline note editor.
  final VoidCallback onNotePressed;

  /// Whether to show the like heart (season headers show note only).
  final bool showLike;

  /// Icon size for both buttons.
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select only this unit's flags so a write to one unit doesn't rebuild
    // every controls row mounted for the item.
    final ({bool liked, bool hasNote}) mark = ref.watch(
      itemMarksProvider(itemId).select(
        (ItemMarksState s) => (
          liked: s.isLiked(unitType, parentNumber, unitNumber),
          hasNote: s.noteFor(unitType, parentNumber, unitNumber) != null,
        ),
      ),
    );
    final bool liked = mark.liked;
    final bool hasNote = mark.hasNote;
    final S l = S.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showLike)
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: liked ? AppColors.favorite : AppColors.textTertiary,
            ),
            tooltip: l.itemMarkLike,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(AppSpacing.xs),
            onPressed: () => ref
                .read(itemMarksProvider(itemId).notifier)
                .toggleFavorite(unitType, parentNumber, unitNumber),
          ),
        IconButton(
          icon: Icon(
            hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
            size: iconSize,
            color: hasNote ? AppColors.brand : AppColors.textTertiary,
          ),
          tooltip: l.itemMarkNote,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(AppSpacing.xs),
          onPressed: onNotePressed,
        ),
      ],
    );
  }
}

/// Inline autosaving note editor for a unit, shown in place of the note text
/// while editing (same pattern as the notes block in the item card). Saves
/// after a 1s pause and flushes the pending text on dispose.
class ItemMarkNoteEditor extends ConsumerStatefulWidget {
  /// Creates an [ItemMarkNoteEditor].
  const ItemMarkNoteEditor({
    required this.itemId,
    required this.unitType,
    required this.parentNumber,
    required this.unitNumber,
    required this.onDone,
    required this.accentColor,
    super.key,
  });

  /// Owning `collection_items.id`.
  final int itemId;

  /// Unit type (see [kUnitPresets]).
  final String unitType;

  /// Season / volume number (0 when not applicable).
  final int parentNumber;

  /// Episode / chapter number (0 for a season/volume-level mark).
  final int unitNumber;

  /// Called when the user taps the done button; the host hides the editor.
  final VoidCallback onDone;

  /// Accent color of the hosting section, tints the container.
  final Color accentColor;

  @override
  ConsumerState<ItemMarkNoteEditor> createState() =>
      _ItemMarkNoteEditorState();
}

class _ItemMarkNoteEditorState extends ConsumerState<ItemMarkNoteEditor> {
  late final TextEditingController _controller;
  late final ItemMarksNotifier _notifier;
  late String _lastSaved;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    // Capture the notifier now: dispose() flushes the pending save, and `ref`
    // is unusable once the widget is disposed.
    _notifier = ref.read(itemMarksProvider(widget.itemId).notifier);
    _lastSaved = ref
            .read(itemMarksProvider(widget.itemId))
            .noteFor(
              widget.unitType,
              widget.parentNumber,
              widget.unitNumber,
            ) ??
        '';
    _controller = TextEditingController(text: _lastSaved);
    _controller.addListener(_scheduleAutosave);
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 1), _save);
  }

  void _save() {
    final String text = _controller.text;
    if (text == _lastSaved) return;
    _lastSaved = text;
    _notifier.setComment(
      widget.unitType,
      widget.parentNumber,
      widget.unitNumber,
      text,
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _save();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration:
                markNoteDecoration(widget.accentColor, emphasized: true),
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              style: AppTypography.bodySmall,
              decoration: InputDecoration(
                hintText: l.itemMarkNoteHint,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, size: 18),
          tooltip: l.done,
          visualDensity: VisualDensity.compact,
          onPressed: () {
            _save();
            widget.onDone();
          },
        ),
      ],
    );
  }
}

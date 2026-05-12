import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/mood_grid.dart';
import '../../../shared/theme/app_spacing.dart';
import '../providers/mood_grids_provider.dart';

/// Dialog to create a new mood grid. Returns the created grid via `Navigator.pop`.
class CreateMoodGridDialog extends ConsumerStatefulWidget {
  /// Creates a [CreateMoodGridDialog].
  const CreateMoodGridDialog({super.key});

  @override
  ConsumerState<CreateMoodGridDialog> createState() =>
      _CreateMoodGridDialogState();
}

class _CreateMoodGridDialogState extends ConsumerState<CreateMoodGridDialog> {
  final TextEditingController _nameController =
      TextEditingController(text: kDefaultMoodGridTitle);
  MoodGridPreset _preset = MoodGridPreset.aboutMeTonkatsuBox;
  int _rows = 3;
  int _cols = 3;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool isBlank = _preset == MoodGridPreset.blank;

    return AlertDialog(
      title: Text(l.moodGridCreateTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l.moodGridName),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l.moodGridPresetLabel),
            RadioGroup<MoodGridPreset>(
              groupValue: _preset,
              onChanged: (MoodGridPreset? v) {
                if (v == null) return;
                setState(() => _preset = v);
              },
              child: Column(
                children: <Widget>[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.moodGridPresetAboutMe),
                    subtitle: Text(l.moodGridPresetAboutMeSubtitle),
                    leading: const Radio<MoodGridPreset>(
                      value: MoodGridPreset.aboutMeTonkatsuBox,
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.moodGridPresetBlank),
                    subtitle: Text(l.moodGridPresetBlankSubtitle),
                    leading: const Radio<MoodGridPreset>(
                      value: MoodGridPreset.blank,
                    ),
                  ),
                ],
              ),
            ),
            if (isBlank) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StepInput(
                      label: l.moodGridRows,
                      value: _rows,
                      min: 1,
                      max: 10,
                      onChanged: (int v) => setState(() => _rows = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StepInput(
                      label: l.moodGridCols,
                      value: _cols,
                      min: 1,
                      max: 10,
                      onChanged: (int v) => setState(() => _cols = v),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _create,
          child: Text(l.moodGridCreate),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final String name = _nameController.text.trim().isEmpty
        ? kDefaultMoodGridTitle
        : _nameController.text.trim();
    final MoodGrid grid =
        await ref.read(moodGridsProvider.notifier).create(
              name: name,
              preset: _preset,
              rows: _rows,
              cols: _cols,
            );
    if (mounted) Navigator.of(context).pop(grid);
  }
}

class _StepInput extends StatelessWidget {
  const _StepInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text(value.toString()),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

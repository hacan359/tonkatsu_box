// Диалог ввода потраченного времени (часы + минуты).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Диалог ввода времени в часах и минутах.
///
/// Возвращает количество минут (`int`) через `Navigator.pop`.
/// [initialMinutes] — начальное значение для редактирования (0 для добавления).
/// [isEdit] — true для режима «редактировать общее», false для «добавить».
class AddTimeDialog extends StatefulWidget {
  /// Создаёт [AddTimeDialog].
  const AddTimeDialog({
    this.initialMinutes = 0,
    this.isEdit = false,
    super.key,
  });

  /// Начальное значение в минутах.
  final int initialMinutes;

  /// Режим редактирования (true) или добавления (false).
  final bool isEdit;

  /// Показывает диалог и возвращает введённые минуты (или null при отмене).
  static Future<int?> show(
    BuildContext context, {
    int initialMinutes = 0,
    bool isEdit = false,
  }) {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) => AddTimeDialog(
        initialMinutes: initialMinutes,
        isEdit: isEdit,
      ),
    );
  }

  @override
  State<AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<AddTimeDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    final int hours = widget.initialMinutes ~/ 60;
    final int minutes = widget.initialMinutes % 60;
    _hoursController = TextEditingController(
      text: hours > 0 ? hours.toString() : '',
    );
    _minutesController = TextEditingController(
      text: minutes > 0 ? minutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int _computeMinutes() {
    final int hours = int.tryParse(_hoursController.text) ?? 0;
    final int minutes = int.tryParse(_minutesController.text) ?? 0;
    return hours * 60 + minutes;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.isEdit ? l.timeSpentEdit : l.timeSpentAdd,
        style: AppTypography.h2,
      ),
      content: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: l.timeSpentHours,
                hintText: '0',
              ),
              autofocus: true,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: l.timeSpentMinutes,
                hintText: '0',
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final int minutes = _computeMinutes();
            Navigator.of(context).pop(minutes);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

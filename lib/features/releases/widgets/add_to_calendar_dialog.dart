import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/calendar_recurrence.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/dual_date_picker_dialog.dart';

/// Result of [showAddToCalendarDialog].
class AddToCalendarResult {
  const AddToCalendarResult(this.date, this.recurrence);

  final DateTime date;
  final CalendarRecurrence recurrence;
}

/// Google-Calendar-style add dialog: pick a date and a repeat option. Returns
/// null if cancelled. [initialDate] pre-selects the item's future release date.
Future<AddToCalendarResult?> showAddToCalendarDialog(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDialog<AddToCalendarResult>(
    context: context,
    builder: (BuildContext context) =>
        _AddToCalendarDialog(initialDate: initialDate),
  );
}

class _AddToCalendarDialog extends StatefulWidget {
  const _AddToCalendarDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddToCalendarDialog> createState() => _AddToCalendarDialogState();
}

class _AddToCalendarDialogState extends State<_AddToCalendarDialog> {
  late DateTime _date = widget.initialDate;
  CalendarRecurrence _recurrence = CalendarRecurrence.once;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDualDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(_date.year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return AlertDialog(
      title: Text(l.calendarAddTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l.calendarDate),
            subtitle: Text(
              MaterialLocalizations.of(context).formatMediumDate(_date),
            ),
            trailing: TextButton(
              onPressed: _pickDate,
              child: Text(MaterialLocalizations.of(context).dateInputLabel),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l.calendarRepeat),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<CalendarRecurrence>(
            showSelectedIcon: false,
            segments: <ButtonSegment<CalendarRecurrence>>[
              for (final CalendarRecurrence r in CalendarRecurrence.values)
                ButtonSegment<CalendarRecurrence>(
                  value: r,
                  label: Text(r.localizedLabel(l)),
                ),
            ],
            selected: <CalendarRecurrence>{_recurrence},
            onSelectionChanged: (Set<CalendarRecurrence> s) =>
                setState(() => _recurrence = s.first),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            AddToCalendarResult(_date, _recurrence),
          ),
          child: Text(l.calendarAddAction),
        ),
      ],
    );
  }
}

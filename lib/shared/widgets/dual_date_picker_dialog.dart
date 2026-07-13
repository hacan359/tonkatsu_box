import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../theme/app_spacing.dart';

const String _isoPattern = 'yyyy-MM-dd';

Future<DateTime?> showDualDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext ctx) => DualDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    ),
  );
}

class DualDatePickerDialog extends StatefulWidget {
  const DualDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.helpText,
    super.key,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? helpText;

  @override
  State<DualDatePickerDialog> createState() => _DualDatePickerDialogState();
}

class _DualDatePickerDialogState extends State<DualDatePickerDialog> {
  late DateTime _selected;
  late final TextEditingController _controller;
  final DateFormat _isoFormat = DateFormat(_isoPattern);
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _selected = _clamp(widget.initialDate);
    _controller = TextEditingController(text: _isoFormat.format(_selected));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return DateTime(d.year, d.month, d.day);
  }

  bool _inRange(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  void _onCalendarChanged(DateTime date) {
    setState(() {
      _selected = date;
      _controller.text = _isoFormat.format(date);
      _errorKey = null;
    });
  }

  void _onTextChanged(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorKey = 'empty');
      return;
    }
    try {
      final DateTime parsed = _isoFormat.parseStrict(trimmed);
      if (!_inRange(parsed)) {
        setState(() => _errorKey = 'range');
        return;
      }
      setState(() {
        _selected = parsed;
        _errorKey = null;
      });
    } on FormatException {
      setState(() => _errorKey = 'format');
    }
  }

  String? _resolveError(S l) {
    switch (_errorKey) {
      case 'empty':
        return l.dualDatePickerErrorEmpty;
      case 'format':
        return l.dualDatePickerErrorFormat;
      case 'range':
        return l.dualDatePickerErrorRange;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
    final bool isMobile = kIsMobile;
    final String? errorText = _resolveError(l);

    final Widget calendar = SizedBox(
      width: 320,
      height: 340,
      child: CalendarDatePicker(
        initialDate: _selected,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        onDateChanged: _onCalendarChanged,
      ),
    );

    final Widget textInput = TextField(
      controller: _controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: l.date,
        hintText: _isoPattern,
        errorText: errorText,
      ),
      onChanged: _onTextChanged,
    );

    // Side-by-side needs the calendar plus the input column to fit; when the
    // dialog is squeezed narrower (small window), fall back to stacking.
    const double sideBySideMinWidth = 320 + AppSpacing.md + 220;
    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked =
            isMobile || constraints.maxWidth < sideBySideMinWidth;
        return SingleChildScrollView(
          child: stacked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.md),
                    textInput,
                    const SizedBox(height: AppSpacing.md),
                    calendar,
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    calendar,
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(width: 220, child: textInput),
                  ],
                ),
        );
      },
    );

    final MediaQueryData mq = MediaQuery.of(context);
    final double maxHeight = mq.size.height - mq.viewInsets.bottom - 48;
    final double dialogWidth = isMobile ? 360 : 620;
    final double dialogHeight =
        (isMobile ? 520.0 : 440.0).clamp(240.0, maxHeight);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.helpText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    widget.helpText!,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              Expanded(child: body),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: _errorKey == null
                        ? () => Navigator.of(context).pop(_selected)
                        : null,
                    child: Text(l.confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Comparison used by a table filter rule.
enum TableFilterCondition {
  contains,
  equals,
  startsWith,
  endsWith,
  atLeast,
  atMost;

  TrinaFilterType get trinaType => switch (this) {
        contains => const TrinaFilterTypeContains(),
        equals => const TrinaFilterTypeEquals(),
        startsWith => const TrinaFilterTypeStartsWith(),
        endsWith => const TrinaFilterTypeEndsWith(),
        atLeast => const TrinaFilterTypeGreaterThanOrEqualTo(),
        atMost => const TrinaFilterTypeLessThanOrEqualTo(),
      };

  String label(S l) => switch (this) {
        contains => l.tableFilterCondContains,
        equals => l.tableFilterCondEquals,
        startsWith => l.tableFilterCondStartsWith,
        endsWith => l.tableFilterCondEndsWith,
        atLeast => l.tableFilterCondAtLeast,
        atMost => l.tableFilterCondAtMost,
      };
}

/// One row of the table filter: column + condition + value.
class TableFilterRule {
  const TableFilterRule({
    required this.field,
    required this.condition,
    required this.value,
  });

  final String field;
  final TableFilterCondition condition;
  final String value;
}

class _RuleDraft {
  _RuleDraft({
    required this.field,
    required this.condition,
    required String value,
  }) : controller = TextEditingController(text: value);

  String field;
  TableFilterCondition condition;
  final TextEditingController controller;
}

/// Filter editor: a list of column/condition/value rules combined with AND.
/// Pops the new rule list on apply, an empty list on clear, null on cancel.
class TableFilterDialog extends StatefulWidget {
  const TableFilterDialog({
    required this.rules,
    required this.columns,
    this.enumOptions = const <String, List<String>>{},
    super.key,
  });

  final List<TableFilterRule> rules;

  /// Field id → localized column label.
  final Map<String, String> columns;

  /// Field id → fixed list of allowed values. Such columns show a value
  /// dropdown and always filter by "equals".
  final Map<String, List<String>> enumOptions;

  @override
  State<TableFilterDialog> createState() => _TableFilterDialogState();
}

class _TableFilterDialogState extends State<TableFilterDialog> {
  late final List<_RuleDraft> _drafts = widget.rules
      .map(
        (TableFilterRule r) => _RuleDraft(
          field: r.field,
          condition: r.condition,
          value: r.value,
        ),
      )
      .toList();

  // Removed drafts are disposed with the dialog, not at removal time —
  // their TextField is still alive during the removing rebuild.
  final List<_RuleDraft> _removed = <_RuleDraft>[];

  @override
  void dispose() {
    for (final _RuleDraft draft in _drafts) {
      draft.controller.dispose();
    }
    for (final _RuleDraft draft in _removed) {
      draft.controller.dispose();
    }
    super.dispose();
  }

  bool _isEnum(String field) => widget.enumOptions.containsKey(field);

  void _addRule() {
    setState(() {
      final String field = widget.columns.keys.first;
      _drafts.add(
        _RuleDraft(
          field: field,
          condition: _isEnum(field)
              ? TableFilterCondition.equals
              : TableFilterCondition.contains,
          value: _isEnum(field) ? widget.enumOptions[field]!.first : '',
        ),
      );
    });
  }

  /// Keeps a rule valid after its column changes: enum columns force "equals"
  /// and default to the first allowed value.
  void _onFieldChanged(_RuleDraft draft, String field) {
    setState(() {
      draft.field = field;
      if (_isEnum(field)) {
        draft.condition = TableFilterCondition.equals;
        final List<String> options = widget.enumOptions[field]!;
        if (!options.contains(draft.controller.text)) {
          draft.controller.text = options.first;
        }
      }
    });
  }

  List<TableFilterRule> _collect() => _drafts
      .where((_RuleDraft d) => d.controller.text.trim().isNotEmpty)
      .map(
        (_RuleDraft d) => TableFilterRule(
          field: d.field,
          condition: d.condition,
          value: d.controller.text.trim(),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    // AlertDialog measures content with IntrinsicWidth, so a LayoutBuilder
    // here would crash (no intrinsic size); use MediaQuery for the budget.
    final double available =
        MediaQuery.sizeOf(context).width - 2 * AppSpacing.xl;
    final double width = available.clamp(0.0, 560.0);
    final bool stacked = width < 460;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      title: Text(l.collectionFilterFilters),
      // A fixed 560 would clamp each control to a sliver on phones: cap at
      // 560 but shrink to available width, stacking rules when narrow.
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.tableFilterHint,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final _RuleDraft draft in _drafts) ...<Widget>[
                _buildRuleRow(l, draft, stacked: stacked),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _addRule,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l.tableFilterAddRule),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const <TableFilterRule>[]),
          child: Text(l.filtersClear),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
          ),
          onPressed: () => Navigator.of(context).pop(_collect()),
          child: Text(l.apply),
        ),
      ],
    );
  }

  Widget _buildRuleRow(S l, _RuleDraft draft, {required bool stacked}) {
    final Widget fieldControl = _dropdown<String>(
      value: draft.field,
      items: <DropdownMenuItem<String>>[
        for (final MapEntry<String, String> e in widget.columns.entries)
          DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
      ],
      onChanged: (String? v) => _onFieldChanged(draft, v ?? draft.field),
    );

    final Widget deleteButton = IconButton(
      icon: const Icon(Icons.close, size: 16),
      visualDensity: VisualDensity.compact,
      color: AppColors.textTertiary,
      onPressed: () => setState(() {
        _drafts.remove(draft);
        _removed.add(draft);
      }),
    );

    // Condition control: enum columns show a static "equals" label, others a
    // condition dropdown.
    final Widget conditionControl = _isEnum(draft.field)
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              TableFilterCondition.equals.label(l),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        : _dropdown<TableFilterCondition>(
            value: draft.condition,
            items: <DropdownMenuItem<TableFilterCondition>>[
              for (final TableFilterCondition c in TableFilterCondition.values)
                DropdownMenuItem<TableFilterCondition>(
                  value: c,
                  child: Text(c.label(l)),
                ),
            ],
            onChanged: (TableFilterCondition? v) =>
                setState(() => draft.condition = v ?? draft.condition),
          );

    // Value control: enum → value dropdown, others → free text.
    final List<String>? options = widget.enumOptions[draft.field];
    final Widget valueControl = options != null
        ? _dropdown<String>(
            value: options.contains(draft.controller.text)
                ? draft.controller.text
                : options.first,
            items: <DropdownMenuItem<String>>[
              for (final String opt in options)
                DropdownMenuItem<String>(value: opt, child: Text(opt)),
            ],
            onChanged: (String? v) => setState(
              () => draft.controller.text = v ?? draft.controller.text,
            ),
          )
        : TextField(
            controller: draft.controller,
            decoration: const InputDecoration(isDense: true),
            style: AppTypography.body,
          );

    if (stacked) {
      // Field gets its own row so each control has full width instead of
      // a cramped three-way split on narrow screens.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: fieldControl),
              deleteButton,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(flex: 2, child: conditionControl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 3, child: valueControl),
            ],
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(flex: 3, child: fieldControl),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 3, child: conditionControl),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 4, child: valueControl),
        const SizedBox(width: AppSpacing.xs),
        deleteButton,
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        style: AppTypography.body,
        iconEnabledColor: AppColors.textTertiary,
      ),
    );
  }
}

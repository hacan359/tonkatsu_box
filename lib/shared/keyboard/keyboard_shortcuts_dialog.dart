// Диалог справки по клавиатурным сочетаниям (F1).

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'keyboard_shortcuts.dart';

/// Диалог с контекстной справкой по клавиатурным сочетаниям.
///
/// Показывает глобальные хоткеи (навигация) и хоткеи текущего экрана.
class KeyboardShortcutsDialog extends StatelessWidget {
  /// Создаёт [KeyboardShortcutsDialog].
  const KeyboardShortcutsDialog({
    required this.screenGroups,
    super.key,
  });

  /// Группы хоткеев текущего экрана (без глобальных).
  final List<ShortcutGroup> screenGroups;

  /// Показывает диалог справки по хоткеям.
  static void show(
    BuildContext context, {
    List<ShortcutGroup> screenGroups = const <ShortcutGroup>[],
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => KeyboardShortcutsDialog(
        screenGroups: screenGroups,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.keyboard, color: AppColors.textSecondary),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Клавиатурные сочетания',
            style: AppTypography.h2,
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildGroup(globalShortcutGroup),
              for (final ShortcutGroup group in screenGroups) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _buildGroup(group),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildGroup(ShortcutGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          group.title,
          style: AppTypography.h3.copyWith(color: AppColors.brand),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final ShortcutEntry entry in group.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: _KeyBadge(keys: entry.keys),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.description,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Бейдж с отображением клавиш (Ctrl+N, F5 и т.д.).
class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.keys});

  final String keys;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = keys.split('+');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '+',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              parts[i],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Боковая панель тегов-закладок для фильтрации коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// Боковая панель с тегами в виде закладок.
///
/// Отображается справа от контента коллекции.
/// Поддерживает мультивыбор: клик переключает тег, «All» сбрасывает всё.
class TagSidebar extends StatelessWidget {
  const TagSidebar({
    required this.tags,
    required this.onTagToggled,
    this.selectedTagIds = const <int>{},
    super.key,
  });

  /// Все теги коллекции.
  final List<CollectionTag> tags;

  /// ID выбранных тегов (пустой = показать все).
  final Set<int> selectedTagIds;

  /// Callback при переключении тега (null = сброс всех фильтров).
  final ValueChanged<int?> onTagToggled;

  /// Ширина боковой панели.
  static const double width = 32.0;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          // «Все» — сброс фильтра
          _TagTab(
            label: S.of(context).tagSidebarAll,
            color: AppColors.brand,
            isSelected: selectedTagIds.isEmpty,
            onTap: () => onTagToggled(null),
          ),
          const SizedBox(height: 4),
          // Разделитель
          Container(
            width: 20,
            height: 1,
            color: AppColors.surfaceBorder,
          ),
          const SizedBox(height: 4),
          // Теги
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: tags.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (BuildContext context, int index) {
                final CollectionTag tag = tags[index];
                final Color tagColor = tag.color != null
                    ? Color(tag.color!)
                    : AppColors.textSecondary;
                return _TagTab(
                  label: tag.name,
                  color: tagColor,
                  isSelected: selectedTagIds.contains(tag.id),
                  onTap: () => onTagToggled(tag.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна закладка-таб тега.
class _TagTab extends StatefulWidget {
  const _TagTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TagTab> createState() => _TagTabState();
}

class _TagTabState extends State<_TagTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;
    final Color color = widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: TagSidebar.width,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? color.withAlpha(30)
                  : _hovered
                      ? color.withAlpha(15)
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: active ? color : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  widget.label,
                  style: AppTypography.caption.copyWith(
                    color: active || _hovered
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

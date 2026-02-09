// Базовый виджет для экранов деталей медиа в коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'source_badge.dart';

/// Чип с иконкой и текстом для отображения метаинформации.
class MediaDetailChip {
  /// Создаёт [MediaDetailChip].
  const MediaDetailChip({required this.icon, required this.text});

  /// Иконка чипа.
  final IconData icon;

  /// Текст чипа.
  final String text;
}

/// Базовый виджет экрана деталей медиа в коллекции.
///
/// Отображает единый layout для игр, фильмов и сериалов:
/// постер + информация, статус, комментарии, заметки.
/// Специфичные секции передаются через [extraSections].
class MediaDetailView extends StatelessWidget {
  /// Создаёт [MediaDetailView].
  const MediaDetailView({
    required this.title,
    required this.placeholderIcon,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.isEditable,
    required this.onAuthorCommentSave,
    required this.onUserCommentSave,
    this.coverUrl,
    this.infoChips = const <MediaDetailChip>[],
    this.description,
    this.statusWidget,
    this.extraSections,
    this.authorComment,
    this.userComment,
    this.hasAuthorComment = false,
    this.hasUserComment = false,
    this.embedded = false,
    super.key,
  });

  /// Название для AppBar.
  final String title;

  /// URL обложки/постера.
  final String? coverUrl;

  /// Иконка-заглушка при отсутствии обложки.
  final IconData placeholderIcon;

  /// Источник данных (IGDB, TMDB).
  final DataSource source;

  /// Иконка типа контента.
  final IconData typeIcon;

  /// Текст типа контента (платформа, "Movie", "TV Show").
  final String typeLabel;

  /// Чипы с метаинформацией (год, рейтинг, жанры и т.д.).
  final List<MediaDetailChip> infoChips;

  /// Описание/обзор контента.
  final String? description;

  /// Виджет выбора статуса.
  final Widget? statusWidget;

  /// Дополнительные секции (например, Progress для сериалов).
  final List<Widget>? extraSections;

  /// Комментарий автора коллекции.
  final String? authorComment;

  /// Личные заметки пользователя.
  final String? userComment;

  /// Есть ли комментарий автора.
  final bool hasAuthorComment;

  /// Есть ли личные заметки.
  final bool hasUserComment;

  /// Можно ли редактировать комментарий автора.
  final bool isEditable;

  /// Встраиваемый режим (без Scaffold и AppBar).
  ///
  /// Если true, виджет возвращает только контент без обёртки в Scaffold.
  /// Используется когда MediaDetailView встроен в другой экран (например,
  /// в TabBarView на GameDetailScreen).
  final bool embedded;

  /// Колбэк сохранения комментария автора.
  final ValueChanged<String?> onAuthorCommentSave;

  /// Колбэк сохранения личных заметок.
  final ValueChanged<String?> onUserCommentSave;

  @override
  Widget build(BuildContext context) {
    final Widget content = ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeader(context),
        if (statusWidget != null) ...<Widget>[
          const SizedBox(height: 16),
          _buildStatusSection(context),
        ],
        if (extraSections != null)
          for (final Widget section in extraSections!) ...<Widget>[
            const SizedBox(height: 16),
            section,
          ],
        const SizedBox(height: 16),
        _buildAuthorCommentSection(context),
        const SizedBox(height: 16),
        _buildUserNotesSection(context),
        const SizedBox(height: 24),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: content,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Обложка/постер
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 80,
            height: 120,
            child: coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: coverUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 180,
                    placeholder: (BuildContext ctx, String url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget:
                        (BuildContext ctx, String url, Object error) =>
                            _buildPlaceholder(colorScheme),
                  )
                : _buildPlaceholder(colorScheme),
          ),
        ),
        const SizedBox(width: 12),
        // Информация
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SourceBadge(
                    source: source,
                    size: SourceBadgeSize.medium,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    typeIcon,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (infoChips.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MediaDetailChip chip in infoChips)
                      _buildInfoChip(chip.icon, chip.text, colorScheme),
                  ],
                ),
              ],
              if (description != null &&
                  description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        placeholderIcon,
        size: 32,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        statusWidget!,
      ],
    );
  }

  Widget _buildAuthorCommentSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.format_quote,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Author's Comment",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isEditable)
              TextButton.icon(
                onPressed: () => _editComment(
                  context,
                  title: "Edit Author's Comment",
                  hint: 'Write a comment...',
                  initialValue: authorComment,
                  onSave: onAuthorCommentSave,
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.tertiaryContainer,
            ),
          ),
          child: hasAuthorComment
              ? Text(
                  authorComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                )
              : Text(
                  isEditable
                      ? 'No comment yet. Tap Edit to add one.'
                      : 'No comment from the author.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserNotesSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.note_alt_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'My Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _editComment(
                context,
                title: 'Edit My Notes',
                hint: 'Write your personal notes...',
                initialValue: userComment,
                onSave: onUserCommentSave,
              ),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.primaryContainer,
            ),
          ),
          child: hasUserComment
              ? Text(
                  userComment!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                )
              : Text(
                  'No notes yet. Tap Edit to add your personal notes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _editComment(
    BuildContext context, {
    required String title,
    required String hint,
    required ValueChanged<String?> onSave,
    String? initialValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    onSave(result.isEmpty ? null : result);
  }
}

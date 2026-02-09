// BottomSheet для фильтров поиска фильмов и сериалов.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/tmdb_api.dart';

/// BottomSheet для фильтров поиска медиа (год + жанры).
///
/// Позволяет задать год релиза и выбрать жанры для фильтрации.
class MediaFilterSheet extends StatefulWidget {
  /// Создаёт [MediaFilterSheet].
  const MediaFilterSheet({
    required this.genres,
    required this.selectedGenreIds,
    required this.onApply,
    this.selectedYear,
    super.key,
  });

  /// Список доступных жанров.
  final List<TmdbGenre> genres;

  /// Текущий выбранный год (может быть null).
  final int? selectedYear;

  /// Текущие выбранные ID жанров.
  final List<int> selectedGenreIds;

  /// Callback при применении фильтров.
  final void Function({int? year, required List<int> genreIds}) onApply;

  @override
  State<MediaFilterSheet> createState() => _MediaFilterSheetState();
}

class _MediaFilterSheetState extends State<MediaFilterSheet> {
  late TextEditingController _yearController;
  late List<int> _selectedGenreIds;

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(
      text: widget.selectedYear?.toString() ?? '',
    );
    _selectedGenreIds = List<int>.from(widget.selectedGenreIds);
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  int? get _parsedYear {
    final String text = _yearController.text.trim();
    if (text.isEmpty) return null;
    final int? year = int.tryParse(text);
    if (year == null || year < 1900 || year > 2100) return null;
    return year;
  }

  void _toggleGenre(int genreId) {
    setState(() {
      if (_selectedGenreIds.contains(genreId)) {
        _selectedGenreIds.remove(genreId);
      } else {
        _selectedGenreIds.add(genreId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _yearController.clear();
      _selectedGenreIds.clear();
    });
  }

  void _apply() {
    widget.onApply(
      year: _parsedYear,
      genreIds: _selectedGenreIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Text(
                    'Filters',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_selectedGenreIds.isNotEmpty ||
                      _yearController.text.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  // Year section
                  Text(
                    'Release Year',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2024',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Genres section
                  Text(
                    'Genres',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (widget.genres.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No genres available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.genres.map((TmdbGenre genre) {
                        final bool isSelected =
                            _selectedGenreIds.contains(genre.id);
                        return FilterChip(
                          label: Text(genre.name),
                          selected: isSelected,
                          onSelected: (_) => _toggleGenre(genre.id),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

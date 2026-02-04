import 'package:flutter/material.dart';

import '../../../shared/models/platform.dart';

/// BottomSheet для выбора платформ с поиском.
///
/// Позволяет фильтровать список платформ по названию
/// и выбирать несколько платформ через чекбоксы.
class PlatformFilterSheet extends StatefulWidget {
  /// Создаёт [PlatformFilterSheet].
  const PlatformFilterSheet({
    required this.platforms,
    required this.selectedIds,
    required this.onApply,
    super.key,
  });

  /// Список всех доступных платформ.
  final List<Platform> platforms;

  /// Список ID выбранных платформ.
  final List<int> selectedIds;

  /// Callback при применении фильтра.
  final void Function(List<int> selectedIds) onApply;

  @override
  State<PlatformFilterSheet> createState() => _PlatformFilterSheetState();
}

class _PlatformFilterSheetState extends State<PlatformFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late List<int> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List<int>.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Platform> get _filteredPlatforms {
    if (_searchQuery.isEmpty) {
      return widget.platforms;
    }

    final String query = _searchQuery.toLowerCase();
    return widget.platforms.where((Platform p) {
      return p.name.toLowerCase().contains(query) ||
          (p.abbreviation?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _togglePlatform(int platformId) {
    setState(() {
      if (_selectedIds.contains(platformId)) {
        _selectedIds.remove(platformId);
      } else {
        _selectedIds.add(platformId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _apply() {
    widget.onApply(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<Platform> filtered = _filteredPlatforms;

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
                    'Select Platforms',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search platforms...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 8),

            // Selected count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Text(
                    '${_selectedIds.length} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} platforms',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Platform list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(theme, colorScheme)
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Platform platform = filtered[index];
                        final bool isSelected =
                            _selectedIds.contains(platform.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _togglePlatform(platform.id),
                          title: Text(platform.name),
                          subtitle: platform.abbreviation != null
                              ? Text(platform.abbreviation!)
                              : null,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
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
                        child: Text(_selectedIds.isEmpty
                            ? 'Show All'
                            : 'Apply (${_selectedIds.length})'),
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No platforms found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

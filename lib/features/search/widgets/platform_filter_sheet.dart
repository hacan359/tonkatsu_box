import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;

/// BottomSheet для выбора платформ с поиском.
///
/// Позволяет фильтровать список платформ по названию
/// и выбирать несколько платформ через чекбоксы.
class PlatformFilterSheet extends ConsumerStatefulWidget {
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
  ConsumerState<PlatformFilterSheet> createState() => _PlatformFilterSheetState();
}

class _PlatformFilterSheetState extends ConsumerState<PlatformFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late List<int> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List<int>.from(widget.selectedIds);
    // Автофокус на поле поиска
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
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
              padding: const EdgeInsets.only(top: 12, bottom: AppSpacing.sm),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  const Text(
                    'Select Platforms',
                    style: AppTypography.h2,
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

            const SizedBox(height: AppSpacing.sm),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Selected count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Text(
                    '${_selectedIds.length} selected',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} platforms',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: AppSpacing.md),

            // Platform list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Platform platform = filtered[index];
                        final bool isSelected =
                            _selectedIds.contains(platform.id);

                        return ListTile(
                          leading: _buildPlatformLogo(platform),
                          title: Text(platform.name),
                          subtitle: platform.abbreviation != null
                              ? Text(platform.abbreviation!)
                              : null,
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _togglePlatform(platform.id),
                          ),
                          dense: true,
                          onTap: () => _togglePlatform(platform.id),
                        );
                      },
                    ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
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

  Widget _buildPlatformLogo(Platform platform) {
    if (platform.logoUrl != null && platform.logoImageId != null) {
      return app_cached.CachedImage(
        imageType: ImageType.platformLogo,
        imageId: platform.logoImageId!,
        remoteUrl: platform.logoUrl!,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        placeholder: const Icon(Icons.devices, size: 24),
        errorWidget: const Icon(Icons.devices, size: 24),
      );
    }
    return const Icon(Icons.devices, size: 24);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No platforms found',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try a different search term',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }
}

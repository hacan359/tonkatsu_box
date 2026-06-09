import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart' as model;
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'custom_item/cover_image_picker.dart';
import 'custom_item/custom_item_data.dart';
import 'custom_item/multi_select_genre_dialog.dart';
import 'custom_item/searchable_list_dialog.dart';

export 'custom_item/custom_item_data.dart' show CustomItemData;

/// Full-screen create / edit form for a custom collection item.
class CreateCustomItemDialog extends ConsumerStatefulWidget {
  const CreateCustomItemDialog({this.existing, super.key});

  final CustomMedia? existing;

  static Future<CustomItemData?> show(BuildContext context) {
    return Navigator.of(context).push<CustomItemData>(
      MaterialPageRoute<CustomItemData>(
        builder: (BuildContext context) => const CreateCustomItemDialog(),
      ),
    );
  }

  static Future<CustomItemData?> edit(
    BuildContext context,
    CustomMedia existing,
  ) {
    return Navigator.of(context).push<CustomItemData>(
      MaterialPageRoute<CustomItemData>(
        builder: (BuildContext context) =>
            CreateCustomItemDialog(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<CreateCustomItemDialog> createState() =>
      _CreateCustomItemDialogState();
}

class _CreateCustomItemDialogState
    extends ConsumerState<CreateCustomItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _altTitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _genresController;
  late final TextEditingController _platformController;
  late final TextEditingController _externalUrlController;

  late MediaType _selectedType;
  String? _titleError;
  int? _selectedYear;
  String? _localCoverPath;
  String? _cachedCoverPath;

  List<model.Platform> _platforms = <model.Platform>[];
  List<String> _allGenres = <String>[];
  bool _refsLoaded = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final CustomMedia? e = widget.existing;
    _selectedType = e?.displayType ?? MediaType.custom;
    _titleController = TextEditingController(text: e?.title ?? '');
    _altTitleController = TextEditingController(text: e?.altTitle ?? '');
    _descriptionController =
        TextEditingController(text: e?.description ?? '');
    _coverUrlController = TextEditingController(text: e?.coverUrl ?? '');
    _genresController = TextEditingController(text: e?.genres ?? '');
    _platformController = TextEditingController(text: e?.platformName ?? '');
    _externalUrlController =
        TextEditingController(text: e?.externalUrl ?? '');
    _selectedYear = e?.year;
    _loadReferences();
    if (_isEditing) _loadCachedCover();
  }

  Future<void> _loadCachedCover() async {
    final ImageCacheService cache = ref.read(imageCacheServiceProvider);
    final String path = await cache.getLocalImagePath(
      ImageType.customCover,
      widget.existing!.id.toString(),
    );
    final File file = File(path);
    if (await file.exists() && mounted) {
      setState(() => _cachedCoverPath = path);
    }
  }

  Future<void> _loadReferences() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<Object> results = await Future.wait(<Future<Object>>[
      db.gameDao.getAllPlatforms(),
      db.gameDao.getIgdbGenres(),
      db.movieDao.getTmdbGenreMap('movie'),
      db.movieDao.getTmdbGenreMap('tv'),
    ]);
    _platforms = results[0] as List<model.Platform>;
    final List<Map<String, dynamic>> igdbRows =
        results[1] as List<Map<String, dynamic>>;
    final List<String> igdbGenres =
        igdbRows.map((Map<String, dynamic> r) => r['name'] as String).toList();
    final Map<String, String> movieGenres = results[2] as Map<String, String>;
    final Map<String, String> tvGenres = results[3] as Map<String, String>;
    _allGenres = <String>{
      ...igdbGenres,
      ...movieGenres.values,
      ...tvGenres.values,
    }.toList()
      ..sort();
    if (mounted) setState(() => _refsLoaded = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _altTitleController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _genresController.dispose();
    _platformController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = S.of(context).customItemErrorEmptyTitle);
      return;
    }

    Navigator.of(context).pop(CustomItemData(
      title: title,
      mediaType: _selectedType,
      altTitle: _altTitleController.text.trim().isNotEmpty
          ? _altTitleController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      year: _selectedYear,
      coverUrl: _coverUrlController.text.trim().isNotEmpty
          ? _coverUrlController.text.trim()
          : null,
      localCoverPath: _localCoverPath,
      genres: _genresController.text.trim().isNotEmpty
          ? _genresController.text.trim()
          : null,
      platform: _platformController.text.trim().isNotEmpty
          ? _platformController.text.trim()
          : null,
      externalUrl: _externalUrlController.text.trim().isNotEmpty
          ? _externalUrlController.text.trim()
          : null,
    ));
  }

  Color get _accentColor => MediaTypeTheme.colorFor(_selectedType);

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _isEditing ? l.customItemEdit : l.customItemCreate,
          style: AppTypography.h2,
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _submit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(
                _isEditing ? l.save : l.customItemCreateButton,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _buildHeader(l),
          const SizedBox(height: AppSpacing.md),
          _buildMediaTypeChips(l),
          const SizedBox(height: AppSpacing.md),
          _buildGenresSection(l),
          const SizedBox(height: AppSpacing.md),
          _buildDescriptionSection(l),
          const SizedBox(height: AppSpacing.md),
          _buildExternalUrlSection(l),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeader(S l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CustomCoverPreview(
          localPath: _localCoverPath,
          cachedPath: _cachedCoverPath,
          url: _coverUrlController.text.trim(),
          onTap: _pickCover,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    MediaTypeTheme.iconFor(_selectedType),
                    size: 16,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedType.localizedLabel(S.of(context)),
                    style: AppTypography.bodySmall.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: l.customItemTitleHint,
                  errorText: _titleError,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTypography.h2,
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              TextField(
                controller: _altTitleController,
                decoration: InputDecoration(
                  hintText: l.customItemAltTitleHint,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _buildYearChip(l),
                  if (_selectedType == MediaType.game ||
                      _selectedType == MediaType.custom)
                    _buildPlatformChip(l),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCover() async {
    final CoverPickResult? result = await pickCustomCoverImage(
      context,
      currentUrl: _coverUrlController.text,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.localPath != null) {
        _localCoverPath = result.localPath;
        _coverUrlController.clear();
      } else if (result.url != null) {
        _coverUrlController.text = result.url!;
        _localCoverPath = null;
      }
    });
  }

  Widget _buildYearChip(S l) {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 14),
      label: Text(_selectedYear?.toString() ?? l.customItemYear),
      labelStyle: AppTypography.caption.copyWith(
        color: _selectedYear != null
            ? AppColors.textPrimary
            : AppColors.textTertiary,
      ),
      onPressed: _pickYear,
    );
  }

  Future<void> _pickYear() async {
    final int currentYear = DateTime.now().year;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? currentYear),
      firstDate: DateTime(1950),
      lastDate: DateTime(currentYear + 5),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() => _selectedYear = picked.year);
    }
  }

  Widget _buildPlatformChip(S l) {
    final bool hasValue = _platformController.text.isNotEmpty;
    final VoidCallback? onTap =
        _refsLoaded && _platforms.isNotEmpty ? _pickPlatform : null;
    return ActionChip(
      avatar: const Icon(Icons.sports_esports, size: 14),
      label: Text(hasValue ? _platformController.text : l.customItemPlatform),
      labelStyle: AppTypography.caption.copyWith(
        color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      onPressed: onTap,
    );
  }

  Future<void> _pickPlatform() async {
    final String? result = await SearchableListDialog.show(
      context,
      title: S.of(context).customItemPlatform,
      items: _platforms
          .map((model.Platform p) => p.displayName)
          .toList(),
      allowCustom: true,
      currentValue: _platformController.text,
    );
    if (result != null && mounted) {
      setState(() => _platformController.text = result);
    }
  }

  Widget _buildGenresSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              l.customItemGenres,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_refsLoaded && _allGenres.isNotEmpty)
              TextButton.icon(
                onPressed: _pickGenres,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l.customItemAddGenre),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _genresController,
          decoration: InputDecoration(
            hintText: l.customItemGenresHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _pickGenres() async {
    final Set<String> current = _genresController.text
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toSet();

    final Set<String>? result = await MultiSelectGenreDialog.show(
      context,
      title: S.of(context).customItemGenres,
      items: _allGenres,
      selected: current,
    );
    if (result != null && mounted) {
      _genresController.text = result.join(', ');
      setState(() {});
    }
  }

  Widget _buildMediaTypeChips(S l) {
    // Derived from MediaType.values (custom first) so every type — including
    // any newly added one — is offerable as a custom card's display type.
    final List<MediaType> types = <MediaType>[
      MediaType.custom,
      ...MediaType.values.where((MediaType t) => t != MediaType.custom),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: types.map((MediaType type) {
        final bool isSelected = type == _selectedType;
        final Color typeColor = MediaTypeTheme.colorFor(type);
        return ChoiceChip(
          label: Text(type.localizedLabel(l)),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) setState(() => _selectedType = type);
          },
          selectedColor: typeColor.withValues(alpha: 0.3),
          side: isSelected
              ? BorderSide(color: typeColor, width: 1.5)
              : null,
          labelStyle: TextStyle(
            color: isSelected ? typeColor : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
            fontSize: 12,
          ),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.customItemDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l.customItemDescriptionHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildExternalUrlSection(S l) {
    return TextField(
      controller: _externalUrlController,
      decoration: InputDecoration(
        labelText: l.customItemExternalUrl,
        hintText: 'https://...',
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
      ),
      keyboardType: TextInputType.url,
    );
  }
}

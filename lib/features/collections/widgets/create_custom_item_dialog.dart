// Полноэкранная форма создания/редактирования кастомного элемента.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart' as model;
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Результат формы создания/редактирования кастомного элемента.
class CustomItemData {
  /// Создаёт экземпляр [CustomItemData].
  const CustomItemData({
    required this.title,
    required this.mediaType,
    this.altTitle,
    this.description,
    this.year,
    this.coverUrl,
    this.localCoverPath,
    this.genres,
    this.platform,
    this.externalUrl,
  });

  /// Основное название.
  final String title;

  /// Альтернативное название (оригинальный язык).
  final String? altTitle;

  /// Тип медиа.
  final MediaType mediaType;

  /// Описание.
  final String? description;

  /// Год выпуска.
  final int? year;

  /// URL обложки.
  final String? coverUrl;

  /// Локальный путь к обложке (с ПК).
  final String? localCoverPath;

  /// Жанры (через запятую).
  final String? genres;

  /// Платформа (для игр).
  final String? platform;

  /// Внешний URL.
  final String? externalUrl;
}

/// Полноэкранная форма создания/редактирования кастомного элемента.
class CreateCustomItemDialog extends ConsumerStatefulWidget {
  /// Создаёт [CreateCustomItemDialog].
  const CreateCustomItemDialog({this.existing, super.key});

  /// Существующий элемент для редактирования (null = создание нового).
  final CustomMedia? existing;

  /// Открывает полноэкранную форму создания.
  static Future<CustomItemData?> show(BuildContext context) {
    return Navigator.of(context).push<CustomItemData>(
      MaterialPageRoute<CustomItemData>(
        builder: (BuildContext context) => const CreateCustomItemDialog(),
      ),
    );
  }

  /// Открывает полноэкранную форму редактирования.
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

  MediaType _selectedType = MediaType.custom;
  String? _titleError;
  int? _selectedYear;
  String? _localCoverPath;
  int? _userRating;

  // Справочники для автокомплита
  List<model.Platform> _platforms = <model.Platform>[];
  List<String> _igdbGenres = <String>[];
  List<String> _tmdbGenres = <String>[];
  bool _refsLoaded = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final CustomMedia? e = widget.existing;
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
  }

  Future<void> _loadReferences() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<Object> results = await Future.wait(<Future<Object>>[
      db.getAllPlatforms(),
      db.getIgdbGenres(),
      db.movieDao.getTmdbGenreMap('movie'),
      db.movieDao.getTmdbGenreMap('tv'),
    ]);
    _platforms = results[0] as List<model.Platform>;
    final List<Map<String, dynamic>> igdbRows =
        results[1] as List<Map<String, dynamic>>;
    _igdbGenres =
        igdbRows.map((Map<String, dynamic> r) => r['name'] as String).toList();
    final Map<String, String> movieGenres = results[2] as Map<String, String>;
    final Map<String, String> tvGenres = results[3] as Map<String, String>;
    _tmdbGenres = <String>{...movieGenres.values, ...tvGenres.values}
        .toList()
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

  List<String> get _currentGenres =>
      _selectedType == MediaType.game ? _igdbGenres : _tmdbGenres;

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
          if (!_isEditing) _buildMediaTypeChips(l),
          if (!_isEditing) const SizedBox(height: AppSpacing.md),
          _buildRatingSection(l),
          _buildDivider(),
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

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Divider(
          color: AppColors.surfaceBorder.withAlpha(80),
          height: 1,
        ),
      );

  // ==================== Header ====================

  Widget _buildHeader(S l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Обложка (тап для загрузки)
        GestureDetector(
          onTap: _pickCoverImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 100,
              height: 150,
              color: AppColors.surfaceLight,
              child: _buildCoverPreview(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Бейдж типа
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

              // Название
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

              // Альтернативное название
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

              // Год + Платформа
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

  // ==================== Cover ====================

  Widget _buildCoverPreview() {
    if (_localCoverPath != null) {
      return Image.file(
        File(_localCoverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _buildCoverPlaceholder(),
      );
    }
    if (_coverUrlController.text.trim().isNotEmpty) {
      return Image.network(
        _coverUrlController.text.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, Object e, StackTrace? s) =>
            _buildCoverPlaceholder(),
      );
    }
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    final S l = S.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 4),
        Text(
          l.customItemAddCover,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _pickCoverImage() async {
    final S l = S.of(context);
    // Показываем выбор: файл или URL
    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => SimpleDialog(
        title: Text(l.customItemCoverSource),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('file'),
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l.customItemCoverFromFile),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('url'),
            child: ListTile(
              leading: const Icon(Icons.link),
              title: Text(l.customItemCoverFromUrl),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );

    if (choice == 'file') {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final String? path = result.files.first.path;
        if (path != null && mounted) {
          setState(() {
            _localCoverPath = path;
            _coverUrlController.clear();
          });
        }
      }
    } else if (choice == 'url') {
      if (!mounted) return;
      final TextEditingController urlCtrl =
          TextEditingController(text: _coverUrlController.text);
      final String? url = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.customItemCoverUrl),
          content: TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(hintText: 'https://...'),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim()),
              child: Text(l.confirm),
            ),
          ],
        ),
      );
      urlCtrl.dispose();
      if (url != null && url.isNotEmpty && mounted) {
        setState(() {
          _coverUrlController.text = url;
          _localCoverPath = null;
        });
      }
    }
  }

  // ==================== Year Picker ====================

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

  // ==================== Platform Autocomplete ====================

  Widget _buildPlatformChip(S l) {
    if (!_refsLoaded || _platforms.isEmpty) {
      return ActionChip(
        avatar: const Icon(Icons.sports_esports, size: 14),
        label: Text(_platformController.text.isNotEmpty
            ? _platformController.text
            : l.customItemPlatform),
        labelStyle: AppTypography.caption.copyWith(
          color: _platformController.text.isNotEmpty
              ? AppColors.textPrimary
              : AppColors.textTertiary,
        ),
        onPressed: null,
      );
    }

    return ActionChip(
      avatar: const Icon(Icons.sports_esports, size: 14),
      label: Text(_platformController.text.isNotEmpty
          ? _platformController.text
          : l.customItemPlatform),
      labelStyle: AppTypography.caption.copyWith(
        color: _platformController.text.isNotEmpty
            ? AppColors.textPrimary
            : AppColors.textTertiary,
      ),
      onPressed: _pickPlatform,
    );
  }

  Future<void> _pickPlatform() async {
    final String? result = await _showSearchableListDialog(
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

  // ==================== Genres ====================

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
            if (_refsLoaded && _currentGenres.isNotEmpty)
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
    final String? result = await _showSearchableListDialog(
      title: S.of(context).customItemGenres,
      items: _currentGenres,
      allowCustom: true,
      currentValue: null,
    );
    if (result != null && mounted) {
      final String current = _genresController.text.trim();
      if (current.isEmpty) {
        _genresController.text = result;
      } else {
        _genresController.text = '$current, $result';
      }
      setState(() {});
    }
  }

  // ==================== Media Type Chips ====================

  Widget _buildMediaTypeChips(S l) {
    const List<MediaType> types = <MediaType>[
      MediaType.custom,
      MediaType.game,
      MediaType.movie,
      MediaType.tvShow,
      MediaType.animation,
      MediaType.visualNovel,
      MediaType.manga,
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

  // ==================== Rating ====================

  Widget _buildRatingSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'My Rating',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List<Widget>.generate(10, (int index) {
            final int starValue = index + 1;
            final bool isFilled =
                _userRating != null && starValue <= _userRating!;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _userRating =
                      _userRating == starValue ? null : starValue;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  isFilled
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 28,
                  color: isFilled ? _accentColor : AppColors.textTertiary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==================== Description ====================

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

  // ==================== External URL ====================

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

  // ==================== Searchable List Dialog ====================

  Future<String?> _showSearchableListDialog({
    required String title,
    required List<String> items,
    required bool allowCustom,
    String? currentValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _SearchableListDialog(
        title: title,
        items: items,
        allowCustom: allowCustom,
        currentValue: currentValue,
      ),
    );
  }
}

// ==================== Searchable List Dialog Widget ====================

class _SearchableListDialog extends StatefulWidget {
  const _SearchableListDialog({
    required this.title,
    required this.items,
    required this.allowCustom,
    this.currentValue,
  });

  final String title;
  final List<String> items;
  final bool allowCustom;
  final String? currentValue;

  @override
  State<_SearchableListDialog> createState() => _SearchableListDialogState();
}

class _SearchableListDialogState extends State<_SearchableListDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtered = <String>[];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    if (widget.currentValue != null) {
      _searchController.text = widget.currentValue!;
      _filter(widget.currentValue!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    if (query.isEmpty) {
      _filtered = widget.items;
    } else {
      final String lower = query.toLowerCase();
      _filtered = widget.items
          .where((String item) => item.toLowerCase().contains(lower))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l.customItemSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: _filter,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final String item = _filtered[index];
                    return ListTile(
                      title: Text(item, style: AppTypography.bodySmall),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: () => Navigator.of(ctx).pop(item),
                    );
                  },
                ),
              ),
              if (widget.allowCustom) ...<Widget>[
                const Divider(),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        final String text = _searchController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.of(context).pop(text);
                        }
                      },
                      child: Text(l.customItemUseCustom),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

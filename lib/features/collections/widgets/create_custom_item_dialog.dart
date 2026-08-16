import 'dart:io';

import 'package:core/api/image_proxy.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart' as model;
import 'package:core/models/tag.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/selfhost/server_origin.dart';
import '../../../core/import/sources/custom_file/custom_card_entry.dart';
import '../../../core/import/sources/custom_file/custom_cards_import_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/custom_cards_parse_error_l10n.dart';
import '../../../shared/utils/custom_progress_units.dart';
import '../../../shared/utils/media_format.dart';
import 'custom_item/cover_image_picker.dart';
import 'custom_item/custom_item_data.dart';
import 'custom_item/multi_select_genre_dialog.dart';
import 'custom_item/searchable_list_dialog.dart';
import '../../../shared/constants/media_type_ui.dart';
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
  late final TextEditingController _unitTotalController;
  late final TextEditingController _unitGroupTotalController;
  late final TextEditingController _externalUrlController;
  late final TextEditingController _commentController;
  late final TextEditingController _tagsController;

  late MediaType _selectedType;
  String? _titleError;
  int? _selectedYear;
  int? _selectedPlatformId;
  String? _selectedFormat;
  Uint8List? _coverBytes;

  /// A `file:` path on desktop, the server's `/img` URL on web.
  Uri? _cachedCoverUri;

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
    _unitTotalController =
        TextEditingController(text: e?.unitTotal?.toString() ?? '');
    _unitGroupTotalController =
        TextEditingController(text: e?.unitGroupTotal?.toString() ?? '');
    _externalUrlController =
        TextEditingController(text: e?.externalUrl ?? '');
    _commentController = TextEditingController();
    _tagsController = TextEditingController();
    _selectedYear = e?.year;
    _selectedPlatformId = e?.platformId;
    _selectedFormat = e?.format;
    _loadReferences();
    if (_isEditing) _loadCachedCover();
  }

  Future<void> _loadCachedCover() async {
    if (kIsWebBuild) {
      // The web build's cover cache is the server's, but only an uploaded
      // cover is guaranteed there — a URL cover previews via the url branch.
      if (!CustomMedia.isLocalCover(widget.existing?.coverUrl ?? '')) return;
      final String url = imageProxyUrl(
        baseUrl: serverBaseUrl(),
        type: ImageType.customCover,
        imageId: '${widget.existing!.id}',
      );
      setState(() => _cachedCoverUri = Uri.parse(url));
      return;
    }
    final ImageCacheService cache = ref.read(imageCacheServiceProvider);
    final String path = await cache.getLocalImagePath(
      ImageType.customCover,
      widget.existing!.id.toString(),
    );
    final File file = File(path);
    if (await file.exists() && mounted) {
      setState(() => _cachedCoverUri = Uri.file(path));
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
    _unitTotalController.dispose();
    _unitGroupTotalController.dispose();
    _externalUrlController.dispose();
    _commentController.dispose();
    _tagsController.dispose();
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
      coverBytes: _coverBytes,
      genres: _genresController.text.trim().isNotEmpty
          ? _genresController.text.trim()
          : null,
      platform: _selectedType == MediaType.game &&
              _platformController.text.trim().isNotEmpty
          ? _platformController.text.trim()
          : null,
      platformId:
          _selectedType == MediaType.game ? _selectedPlatformId : null,
      format: _selectedType == MediaType.manga ||
              _selectedType == MediaType.anime
          ? _selectedFormat
          : null,
      unitTotal: _parsePositiveInt(_unitTotalController.text),
      unitGroupTotal: CustomProgressUnits.hasGroupAxis(_selectedType)
          ? _parsePositiveInt(_unitGroupTotalController.text)
          : null,
      externalUrl: _externalUrlController.text.trim().isNotEmpty
          ? _externalUrlController.text.trim()
          : null,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      tags: Tag.dedupeNames(_tagsController.text.split(',')),
    ));
  }

  /// Prefills the form from a JSON/CSV file via the bulk-import parser;
  /// with several entries the first valid one is used.
  Future<void> _fillFromFile() async {
    final S l = S.of(context);
    // Mobile pickers don't reliably filter custom extensions (SAF/UTI).
    final bool useAny = kIsMobile;
    // withData: the browser only ever hands out bytes, and reading them at
    // pick time keeps one code path for every platform.
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      dialogTitle: l.customItemFillFromFile,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['json', 'csv'],
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final PlatformFile file = picked.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || !mounted) return;

    final List<CustomCardRow> rows;
    try {
      rows = ref
          .read(customCardsImportServiceProvider)
          .parseFile(bytes, fileName: file.name);
    } on CustomCardsParseException catch (e) {
      if (!mounted) return;
      context.showErrorSnack(localizedParseError(S.of(context), e.code));
      return;
    }
    if (!mounted) return;

    CustomCardEntry? entry;
    for (final CustomCardRow row in rows) {
      if (row.entry != null) {
        entry = row.entry;
        break;
      }
    }
    if (entry == null) {
      context.showErrorSnack(S.of(context).customItemFileNoValidRows);
      return;
    }

    _applyEntry(entry);
    if (rows.length > 1) {
      context.showSnack(
        S.of(context).customItemFileMultipleRows(rows.length),
        type: SnackType.info,
      );
    }
  }

  /// Only fields present in the file overwrite current values; personal
  /// fields beyond note/tags belong to the item detail screen and are ignored.
  void _applyEntry(CustomCardEntry entry) {
    setState(() {
      _selectedType = entry.type;
      _titleController.text = entry.title;
      _titleError = null;
      if (entry.altTitle != null) {
        _altTitleController.text = entry.altTitle!;
      }
      if (entry.description != null) {
        _descriptionController.text = entry.description!;
      }
      if (entry.comment != null) {
        _commentController.text = entry.comment!;
      }
      if (entry.tags.isNotEmpty) {
        _tagsController.text = entry.tags.join(', ');
      }
      if (entry.year != null) {
        _selectedYear = entry.year;
      }
      if (entry.genres != null) {
        _genresController.text = entry.genres!;
      }
      if (entry.coverUrl != null) {
        _coverUrlController.text = entry.coverUrl!;
        _coverBytes = null;
      }
      if (entry.link != null) {
        _externalUrlController.text = entry.link!;
      }
      if (entry.unitTotal != null) {
        _unitTotalController.text = entry.unitTotal!.toString();
      }
      if (entry.unitGroupTotal != null) {
        _unitGroupTotalController.text = entry.unitGroupTotal!.toString();
      }

      if (entry.type == MediaType.game) {
        if (entry.platform != null) {
          _platformController.text = entry.platform!;
          _selectedPlatformId = _resolvePlatformId(entry.platform!);
        }
      } else {
        _selectedPlatformId = null;
        _platformController.clear();
      }

      final List<String>? formatCodes = switch (entry.type) {
        MediaType.manga => MediaFormat.mangaOrder,
        MediaType.anime => MediaFormat.animeOrder,
        _ => null,
      };
      if (formatCodes == null) {
        _selectedFormat = null;
      } else if (entry.format != null && formatCodes.contains(entry.format)) {
        _selectedFormat = entry.format;
      } else if (!formatCodes.contains(_selectedFormat)) {
        _selectedFormat = null;
      }
    });
  }

  // Same rule as the bulk importer: name or abbreviation, case-insensitive.
  int? _resolvePlatformId(String name) {
    final String needle = name.trim().toLowerCase();
    for (final model.Platform p in _platforms) {
      if (p.name.trim().toLowerCase() == needle ||
          p.abbreviation?.trim().toLowerCase() == needle) {
        return p.id;
      }
    }
    return null;
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
          IconButton(
            onPressed: _fillFromFile,
            icon: const Icon(Icons.upload_file),
            tooltip: l.customItemFillFromFile,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _submit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(
                _isEditing ? l.save : l.create,
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
          _buildCountsSection(l),
          const SizedBox(height: AppSpacing.md),
          _buildDescriptionSection(l),
          const SizedBox(height: AppSpacing.md),
          _buildExternalUrlSection(l),
          // Note and tags live on the collection item, not the card — the
          // edit flow manages them on the item detail screen instead.
          if (!_isEditing) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _buildCommentSection(l),
            const SizedBox(height: AppSpacing.md),
            _buildTagsSection(l),
          ],
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
          bytes: _coverBytes,
          cachedUri: _cachedCoverUri,
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
                  if (_selectedType == MediaType.game) _buildPlatformChip(l),
                  if (_selectedType == MediaType.manga ||
                      _selectedType == MediaType.anime)
                    _buildFormatChip(l),
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
      if (result.bytes != null) {
        _coverBytes = result.bytes;
        _coverUrlController.clear();
      } else if (result.url != null) {
        _coverUrlController.text = result.url!;
        _coverBytes = null;
      }
    });
  }

  Widget _buildYearChip(S l) {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 14),
      label: Text(_selectedYear?.toString() ?? l.year),
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
      label: Text(hasValue ? _platformController.text : l.platform),
      labelStyle: AppTypography.caption.copyWith(
        color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      onPressed: onTap,
    );
  }

  Future<void> _pickPlatform() async {
    final String? result = await SearchableListDialog.show(
      context,
      title: S.of(context).platform,
      items: _platforms
          .map((model.Platform p) => p.displayName)
          .toList(),
      allowCustom: false,
      currentValue: _platformController.text,
    );
    if (result == null || !mounted) return;
    model.Platform? picked;
    for (final model.Platform p in _platforms) {
      if (p.displayName == result) {
        picked = p;
        break;
      }
    }
    setState(() {
      _platformController.text = result;
      _selectedPlatformId = picked?.id;
    });
  }

  Widget _buildFormatChip(S l) {
    final List<String> codes = _selectedType == MediaType.manga
        ? MediaFormat.mangaOrder
        : MediaFormat.animeOrder;
    final bool hasValue =
        _selectedFormat != null && codes.contains(_selectedFormat);
    return ActionChip(
      avatar: const Icon(Icons.category_outlined, size: 14),
      label: Text(
        hasValue
            ? MediaFormat.label(_selectedType, _selectedFormat!)
            : l.format,
      ),
      labelStyle: AppTypography.caption.copyWith(
        color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
      ),
      onPressed: _pickFormat,
    );
  }

  Future<void> _pickFormat() async {
    final List<String> codes = _selectedType == MediaType.manga
        ? MediaFormat.mangaOrder
        : MediaFormat.animeOrder;
    final Map<String, String> labelToCode = <String, String>{
      for (final String code in codes)
        MediaFormat.label(_selectedType, code): code,
    };
    final String? current = _selectedFormat != null
        ? MediaFormat.label(_selectedType, _selectedFormat!)
        : null;
    final String? result = await SearchableListDialog.show(
      context,
      title: S.of(context).format,
      items: labelToCode.keys.toList(),
      allowCustom: false,
      currentValue: current,
    );
    if (result != null && mounted) {
      setState(() => _selectedFormat = labelToCode[result]);
    }
  }

  Widget _buildGenresSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              l.genres,
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
                label: Text(l.add),
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
              borderSide: BorderSide(color: AppColors.surfaceBorder),
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
      title: S.of(context).genres,
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
            if (!selected) return;
            setState(() {
              _selectedType = type;
              // Drop subtype values that no longer apply to the new type so a
              // stale platform / format is never submitted.
              if (type != MediaType.game) {
                _selectedPlatformId = null;
                _platformController.clear();
              }
              if (type != MediaType.manga && type != MediaType.anime) {
                _selectedFormat = null;
              } else if (type == MediaType.manga &&
                  !MediaFormat.mangaOrder.contains(_selectedFormat)) {
                _selectedFormat = null;
              } else if (type == MediaType.anime &&
                  !MediaFormat.animeOrder.contains(_selectedFormat)) {
                _selectedFormat = null;
              }
            });
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

  static int? _parsePositiveInt(String text) {
    final int? value = int.tryParse(text.trim());
    return value != null && value > 0 ? value : null;
  }

  /// The fine progress field always shows; the coarse one only for types
  /// with a sub-division (series → seasons, manga → volumes).
  Widget _buildCountsSection(S l) {
    final bool showGroup = CustomProgressUnits.hasGroupAxis(_selectedType);
    final String? groupLabel =
        CustomProgressUnits.groupLabel(_selectedType, l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.progress,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildCountField(
                label: CustomProgressUnits.fineLabel(_selectedType, l),
                controller: _unitTotalController,
              ),
            ),
            if (showGroup && groupLabel != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildCountField(
                  label: groupLabel,
                  controller: _unitGroupTotalController,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCountField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
      ),
    );
  }

  Widget _buildDescriptionSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.description,
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
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.detailMyNotes,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: const ValueKey<String>('customItemNoteField'),
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l.customItemMyNoteHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.tagsLabel,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          key: const ValueKey<String>('customItemTagsField'),
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: l.customItemTagsHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            isDense: true,
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
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
      ),
      keyboardType: TextInputType.url,
    );
  }
}

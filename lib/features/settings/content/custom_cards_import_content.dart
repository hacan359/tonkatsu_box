import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/models/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/import/sources/custom_file/custom_card_entry.dart';
import '../../../core/import/sources/custom_file/custom_cards_import_service.dart';
import '../../../core/import/sources/custom_file/custom_cards_template.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/custom_cards_parse_error_l10n.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/custom_cards_preview_screen.dart';
import '../widgets/settings_group.dart';

/// Flow: JSON/CSV file pick → parse + validate → target collection →
/// preview screen with per-row checkboxes → import.
class CustomCardsImportContent extends ConsumerStatefulWidget {
  const CustomCardsImportContent({super.key});

  @override
  ConsumerState<CustomCardsImportContent> createState() =>
      _CustomCardsImportContentState();
}

class _CustomCardsImportContentState
    extends ConsumerState<CustomCardsImportContent> {
  String? _fileName;
  List<CustomCardRow>? _rows;
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildFileSection(context),
        if (_rows != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildTargetSection(context),
        ],
      ],
    );
  }

  Widget _buildFileSection(BuildContext context) {
    final S l = S.of(context);
    return SettingsGroup(
      title: l.customImportTitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.customImportDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle,
                  color: AppColors.statusCompleted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _fileName ?? '',
                    style: AppTypography.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _pickFile,
                  child: Text(l.change),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(l.customImportSelectFile),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => _saveTemplate(
                    fileName: CustomCardsTemplate.csvFileName,
                    content: CustomCardsTemplate.csv(),
                    extension: 'csv',
                  ),
                  icon: const Icon(Icons.grid_on, size: 18),
                  label: Text(l.customImportCsvTemplate),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => _saveTemplate(
                    fileName: CustomCardsTemplate.jsonFileName,
                    content: CustomCardsTemplate.json(),
                    extension: 'json',
                  ),
                  icon: const Icon(Icons.data_object, size: 18),
                  label: Text(l.customImportJsonTemplate),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSection(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final S l = S.of(context);

    return SettingsGroup(
      title: l.importTargetCollection,
      children: <Widget>[
        RadioGroup<bool>(
          groupValue: _useNewCollection,
          onChanged: (bool? value) {
            if (value == null) return;
            setState(() {
              _useNewCollection = value;
              if (value) _selectedCollectionId = null;
            });
          },
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(l.importCreateNew),
                leading: const Radio<bool>(value: true),
                dense: true,
                onTap: () => setState(() {
                  _useNewCollection = true;
                  _selectedCollectionId = null;
                }),
              ),
              ListTile(
                title: Text(l.importUseExisting),
                leading: const Radio<bool>(value: false),
                dense: true,
                onTap: () => setState(() {
                  _useNewCollection = false;
                }),
              ),
            ],
          ),
        ),
        if (!_useNewCollection)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: collectionsAsync.when(
              data: (List<Collection> collections) {
                if (collections.isEmpty) {
                  return Text(
                    l.noCollectionsYet,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                final bool selectedExists = _selectedCollectionId != null &&
                    collections.any(
                      (Collection c) => c.id == _selectedCollectionId,
                    );
                return CollectionPickerField(
                  value: selectedExists ? _selectedCollectionId : null,
                  hint: l.importSelectCollection,
                  title: l.importSelectCollection,
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.collectionsFailedToLoad,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canPreview ? _openPreview : null,
            icon: const Icon(Icons.playlist_add_check),
            label: Text(l.customImportPreviewButton),
          ),
        ),
      ],
    );
  }

  bool get _canPreview =>
      _rows != null && (_useNewCollection || _selectedCollectionId != null);

  Future<void> _pickFile() async {
    final S l = S.of(context);
    // Android's SAF does not reliably filter custom extensions.
    final bool useAny = kIsMobile;
    // withData: the browser only ever hands out bytes, and reading them at
    // pick time keeps one code path for every platform.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: l.customImportSelectFile,
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : <String>['json', 'csv'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final PlatformFile picked = result.files.single;
    final Uint8List? bytes = picked.bytes;
    if (bytes == null || !mounted) return;

    final CustomCardsImportService service =
        ref.read(customCardsImportServiceProvider);
    try {
      final List<CustomCardRow> rows =
          service.parseFile(bytes, fileName: picked.name);
      if (!mounted) return;
      setState(() {
        _fileName = picked.name;
        _rows = rows;
      });
    } on CustomCardsParseException catch (e) {
      if (!mounted) return;
      context.showErrorSnack(localizedParseError(S.of(context), e.code));
    }
  }

  Future<void> _saveTemplate({
    required String fileName,
    required String content,
    required String extension,
  }) async {
    final S l = S.of(context);
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: fileName,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[extension],
      // On Android/iOS the picker writes the bytes itself; on web this is a
      // browser download that answers null.
      bytes: utf8.encode(content),
    );
    if (kIsWebBuild) {
      if (mounted) context.showSnack(l.customImportTemplateSaved);
      return;
    }
    if (path == null || !mounted) return;

    // On desktop saveFile only returns the path; write the content ourselves.
    if (!kIsMobile) {
      await File(path).writeAsString(content);
    }
    if (!mounted) return;
    context.showSnack(l.customImportTemplateSaved);
  }

  Future<void> _openPreview() async {
    final List<CustomCardRow> rows = _rows!;
    final int? collectionId = _useNewCollection ? null : _selectedCollectionId;
    final CustomCardsImportService service =
        ref.read(customCardsImportServiceProvider);
    final Set<int> duplicates = await service.duplicateRowIndexes(
      collectionId: collectionId,
      rows: rows,
    );
    if (!mounted) return;

    final String author = ref.read(settingsNotifierProvider).authorName;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CustomCardsPreviewScreen(
          rows: rows,
          duplicateIndexes: duplicates,
          collectionId: collectionId,
          author: author,
        ),
      ),
    );
  }
}

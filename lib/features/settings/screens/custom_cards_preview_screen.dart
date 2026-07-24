import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/import/sources/custom_file/custom_card_entry.dart';
import '../../../core/import/sources/custom_file/custom_cards_import_service.dart';
import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/universal_import_result.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/providers/global_tags_provider.dart';
import '../../collections/providers/item_tags_provider.dart';
import '../../home/providers/all_items_provider.dart';
import 'import_result_screen.dart';
import '../../../shared/constants/media_type_ui.dart';

/// Preview of a parsed custom-cards file: a summary, select-all controls and
/// a lazy checkbox list (problem rows first), ending in the import action.
class CustomCardsPreviewScreen extends ConsumerStatefulWidget {
  const CustomCardsPreviewScreen({
    required this.rows,
    required this.duplicateIndexes,
    required this.collectionId,
    required this.author,
    super.key,
  });

  final List<CustomCardRow> rows;

  /// Row indexes flagged as duplicates (unchecked by default).
  final Set<int> duplicateIndexes;

  /// Target collection; `null` means "create a new collection".
  final int? collectionId;

  final String author;

  @override
  ConsumerState<CustomCardsPreviewScreen> createState() =>
      _CustomCardsPreviewScreenState();
}

class _CustomCardsPreviewScreenState
    extends ConsumerState<CustomCardsPreviewScreen> {
  /// Rows re-ordered for display: invalid first, then duplicates, then valid.
  late final List<CustomCardRow> _sorted;
  late final Set<int> _checked;
  late final int _validCount;

  @override
  void initState() {
    super.initState();
    _validCount = widget.rows.where((CustomCardRow r) => r.isValid).length;
    int rank(CustomCardRow row) {
      if (!row.isValid) return 0;
      return widget.duplicateIndexes.contains(row.index) ? 1 : 2;
    }

    _sorted = List<CustomCardRow>.of(widget.rows)
      ..sort((CustomCardRow a, CustomCardRow b) {
        final int byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.index.compareTo(b.index);
      });
    _checked = <int>{
      for (final CustomCardRow row in widget.rows)
        if (row.isValid && !widget.duplicateIndexes.contains(row.index))
          row.index,
    };
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final int errorCount = widget.rows.length - _validCount;

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: l.customImportPreviewTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.customImportSummary(
                  _validCount,
                  errorCount,
                  widget.duplicateIndexes.length,
                ),
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Wrap, not Row: on narrow screens the buttons plus the counter
              // exceed the width and must flow onto a second line.
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: _selectAll,
                    child: Text(l.selectAll),
                  ),
                  TextButton(
                    onPressed:
                        _checked.isEmpty ? null : () => setState(_checked.clear),
                    child: Text(l.customImportSelectNone),
                  ),
                  Text(
                    l.customImportSelectedCount(_checked.length, _validCount),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _sorted.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildRow(context, _sorted[index]),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _checked.isEmpty ? null : _startImport,
            icon: const Icon(Icons.download),
            label: Text(l.customImportStart),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, CustomCardRow row) {
    final S l = S.of(context);
    final String title =
        row.sourceTitle ?? l.customImportRowLabel(row.index);

    if (!row.isValid) {
      return ListTile(
        dense: true,
        leading: const Icon(
          Icons.error_outline,
          color: AppColors.statusDropped,
        ),
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          row.issues
              .map((CustomCardIssue issue) => _issueText(l, issue))
              .join(' · '),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.statusDropped,
          ),
        ),
      );
    }

    final CustomCardEntry entry = row.entry!;
    final bool isDuplicate = widget.duplicateIndexes.contains(row.index);
    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: _checked.contains(row.index),
      onChanged: (bool? checked) => setState(() {
        if (checked ?? false) {
          _checked.add(row.index);
        } else {
          _checked.remove(row.index);
        }
      }),
      title: Text(entry.title, overflow: TextOverflow.ellipsis),
      subtitle: _validRowSubtitle(l, row, entry, isDuplicate),
    );
  }

  Widget _validRowSubtitle(
    S l,
    CustomCardRow row,
    CustomCardEntry entry,
    bool isDuplicate,
  ) {
    if (isDuplicate) {
      return Text(
        l.customImportDuplicate,
        style: AppTypography.bodySmall.copyWith(color: AppColors.statusPlanned),
      );
    }
    if (row.issues.isNotEmpty) {
      return Text(
        row.issues.map((CustomCardIssue issue) => _issueText(l, issue)).join(' · '),
        style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
      );
    }
    return Text(
      entry.type.localizedLabel(l),
      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
    );
  }

  void _selectAll() => setState(() {
        for (final CustomCardRow row in widget.rows) {
          if (row.isValid) _checked.add(row.index);
        }
      });

  String _issueText(S l, CustomCardIssue issue) {
    switch (issue.code) {
      case CustomCardIssueCode.notAnObject:
        return l.customImportIssueNotAnObject;
      case CustomCardIssueCode.missingTitle:
        return l.customImportIssueMissingTitle;
      case CustomCardIssueCode.missingType:
        return l.customImportIssueMissingType;
      case CustomCardIssueCode.unknownType:
        return l.customImportIssueUnknownType(issue.value ?? '');
      case CustomCardIssueCode.invalidNumber:
        return l.customImportIssueInvalidNumber(
          issue.field ?? '',
          issue.value ?? '',
        );
      case CustomCardIssueCode.unknownStatus:
        return l.customImportIssueUnknownStatus(issue.value ?? '');
      case CustomCardIssueCode.unknownFormat:
        return l.customImportIssueUnknownFormat(issue.value ?? '');
      case CustomCardIssueCode.formatNotApplicable:
        return l.customImportIssueFormatNotApplicable;
      case CustomCardIssueCode.invalidCoverUrl:
        return l.customImportIssueInvalidCover;
      case CustomCardIssueCode.invalidDate:
        return l.customImportIssueInvalidDate(issue.field ?? '', issue.value ?? '');
      case CustomCardIssueCode.invalidBool:
        return l.customImportIssueInvalidBool(issue.value ?? '');
    }
  }

  Future<void> _startImport() async {
    final CustomCardsImportService service =
        ref.read(customCardsImportServiceProvider);
    final List<CustomCardEntry> entries = <CustomCardEntry>[
      for (final CustomCardRow row in widget.rows)
        if (row.entry != null && _checked.contains(row.index)) row.entry!,
    ];

    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);
    UniversalImportResult? importResult;

    final Future<UniversalImportResult> importFuture = service
        .importSelected(
      collectionId: widget.collectionId,
      author: widget.author,
      entries: entries,
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    )
        .then((UniversalImportResult result) {
      importResult = result;
      return result;
    });

    try {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => _ImportProgressDialog(
          progressNotifier: progressNotifier,
          importFuture: importFuture,
        ),
      );
    } finally {
      progressNotifier.dispose();
    }
    if (importResult == null || !mounted) return;

    final UniversalImportResult result = importResult!;
    if (result.success) {
      ref.invalidate(collectionsProvider);
      final int? cid = result.effectiveCollectionId;
      if (cid != null) {
        ref.invalidate(collectionStatsProvider(cid));
        ref.invalidate(collectionCoversProvider(cid));
        ref.invalidate(collectionItemsNotifierProvider(cid));
        ref.invalidate(canvasNotifierProvider(cid));
      }
      ref.invalidate(allItemsNotifierProvider);
      // Tags may have been created and assigned by the import.
      ref.invalidate(globalTagsProvider);
      ref.invalidate(itemTagsProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImportResultScreen(result: result),
        ),
      );
    } else if (result.fatalError != null) {
      context.showErrorSnack(result.fatalError!, detail: result.fatalDetail);
    }
  }
}

class _ImportProgressDialog extends StatelessWidget {
  const _ImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
  });

  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<UniversalImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).customImportImporting),
      content: ValueListenableBuilder<ImportProgress?>(
        valueListenable: progressNotifier,
        builder:
            (BuildContext context, ImportProgress? progress, Widget? child) {
          if (progress == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                progress.stage.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (progress.currentItem != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  progress.currentItem!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.total > 0 ? progress.progress : null,
              ),
              if (progress.total > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '${progress.current} / ${progress.total}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
      actions: <Widget>[
        FutureBuilder<UniversalImportResult>(
          future: importFuture,
          builder: (BuildContext context,
              AsyncSnapshot<UniversalImportResult> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).done),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

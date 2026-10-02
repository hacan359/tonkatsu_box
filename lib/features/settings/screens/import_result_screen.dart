import 'package:core/models/media_type.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/error_details_dialog.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../collections/screens/collection_screen.dart';
import '../../../shared/constants/media_type_ui.dart';

class ImportResultScreen extends StatelessWidget {
  const ImportResultScreen({
    required this.result,
    super.key,
  });

  final UniversalImportResult result;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: l.importResultTitle),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context, l),
                const SizedBox(height: AppSpacing.lg),
                if (result.totalImported > 0) ...<Widget>[
                  _ResultCard(
                    title: l.importResultImported,
                    icon: Icons.check_circle,
                    iconColor: AppColors.statusCompleted,
                    total: result.totalImported,
                    breakdown: result.importedByType,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (result.hasWishlistItems) ...<Widget>[
                  _ResultCard(
                    title: l.importResultWishlisted,
                    icon: Icons.bookmark_add,
                    iconColor: AppColors.brand,
                    total: result.totalWishlisted,
                    breakdown: result.wishlistedByType,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      l.importResultWishlistHint,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (result.totalUpdated > 0) ...<Widget>[
                  _ResultCard(
                    title: l.importResultUpdated,
                    icon: Icons.sync,
                    iconColor: AppColors.statusInProgress,
                    total: result.totalUpdated,
                    breakdown: result.updatedByType,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (result.skipped > 0)
                  _StatRow(
                    icon: Icons.skip_next,
                    color: AppColors.textTertiary,
                    text: l.importResultSkipped(result.skipped),
                  ),
                if (result.unresolvedTitles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _LinesCard(
                    lines: result.unresolvedTitles,
                    title: l.importResultUnresolved,
                    copiedMessage: l.importResultUnresolvedCopied,
                    icon: Icons.call_split,
                    color: AppColors.textSecondary,
                  ),
                ],
                if (result.errors.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _LinesCard(
                    lines: result.errors,
                    title: l.importResultErrors(result.errors.length),
                    copiedMessage: l.importResultErrorsCopied,
                    icon: Icons.error_outline,
                    color: AppColors.error,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildActions(context, l),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, S l) {
    return Column(
      children: <Widget>[
        Icon(
          result.success ? Icons.celebration : Icons.error_outline,
          size: 56,
          color: result.success ? AppColors.brand : AppColors.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          result.success
              ? l.importResultComplete(result.sourceName)
              : l.importResultFailed(result.sourceName),
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        if (result.fatalError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            result.fatalError!,
            style: AppTypography.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: () => copyErrorDetails(
              context,
              message: result.fatalError!,
              detail: result.fatalDetail,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l.copyErrorDetails),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: AppTypography.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, S l) {
    final int? collectionId = result.effectiveCollectionId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (collectionId != null)
          FilledButton.icon(
            onPressed: () {
              // push (not pushReplacement): keep the result screen underneath
              // so backing out of the opened collection returns here.
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => CollectionScreen(
                    collectionId: collectionId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.collections_bookmark),
            label: Text(l.importResultOpenCollection),
          ),
        if (collectionId != null) const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.done),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.total,
    required this.breakdown,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final int total;
  final Map<MediaType, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$total',
                style: AppTypography.h3.copyWith(color: iconColor),
              ),
            ],
          ),
          if (breakdown.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...breakdown.entries.map(
              (MapEntry<MediaType, int> entry) => _buildTypeRow(l, entry),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeRow(S l, MapEntry<MediaType, int> entry) {
    final MediaType type = entry.key;
    final int count = entry.value;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            MediaTypeTheme.iconFor(type),
            size: 16,
            color: MediaTypeTheme.colorFor(type),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              type.localizedLabel(l),
              style: AppTypography.bodySmall,
            ),
          ),
          Text(
            '$count',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-item import errors: expandable list with a copy-all button.
/// A collapsible, copyable list: per-item errors or titles left unresolved.
class _LinesCard extends StatefulWidget {
  const _LinesCard({
    required this.lines,
    required this.title,
    required this.copiedMessage,
    required this.icon,
    required this.color,
  });

  final List<String> lines;
  final String title;
  final String copiedMessage;
  final IconData icon;
  final Color color;

  @override
  State<_LinesCard> createState() => _LinesCardState();
}

class _LinesCardState extends State<_LinesCard> {
  static const int _collapsedCount = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<String> visible = _expanded
        ? widget.lines
        : widget.lines.take(_collapsedCount).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: widget.color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(widget.icon, size: 20, color: widget.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.lines.join('\n')),
                  );
                  context.showSnack(
                    widget.copiedMessage,
                    type: SnackType.info,
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                tooltip: l.copyErrorDetails,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          for (final String line in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                line,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (widget.lines.length > _collapsedCount)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                textStyle: AppTypography.bodySmall,
              ),
              child: Text(_expanded ? l.showLess : l.showMore),
            ),
        ],
      ),
    );
  }
}

/// Single stat row.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

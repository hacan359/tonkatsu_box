import 'package:flutter/material.dart';

import '../../core/import/import_progress.dart';
import '../../l10n/app_localizations.dart';
import '../constants/import_stage_ui.dart';
import '../theme/app_spacing.dart';
import 'logo_loader.dart';

/// Locked until the import future settles: a dismissed dialog would leave
/// the write running with nothing on screen to report it.
class ImportProgressDialog<T> extends StatelessWidget {
  const ImportProgressDialog({
    required this.title,
    required this.progressNotifier,
    required this.importFuture,
    super.key,
  });

  final String title;
  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<T> importFuture;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return FutureBuilder<T>(
      future: importFuture,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        final bool done = snapshot.connectionState == ConnectionState.done;
        return PopScope(
          canPop: done,
          child: AlertDialog(
            scrollable: true,
            title: Text(title),
            content: ValueListenableBuilder<ImportProgress?>(
              valueListenable: progressNotifier,
              builder: (BuildContext context, ImportProgress? p, Widget? _) =>
                  p == null
                      ? const SizedBox(
                          height: 100,
                          child: Center(child: LogoLoader()),
                        )
                      : _ProgressBody(progress: p, running: !done),
            ),
            actions: <Widget>[
              if (done)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l.done),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.progress, required this.running});

  final ImportProgress progress;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final String? crumb = _crumb(l);
    final bool hasTallies = progress.imported > 0 ||
        progress.customCards > 0 ||
        progress.ambiguous > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                progress.stage.label(l),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (running) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: AppSpacing.md,
                height: AppSpacing.md,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        if (crumb != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(crumb, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
        ],
        const SizedBox(height: AppSpacing.md),
        LinearProgressIndicator(
          value: progress.total > 0 ? progress.progress : null,
        ),
        if (progress.total > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${progress.current} / ${progress.total}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (hasTallies) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.importTallies(
              progress.imported,
              progress.customCards,
              progress.ambiguous,
            ),
            style: muted,
          ),
        ],
      ],
    );
  }

  /// What is happening right now: the row and the source being asked, else
  /// the row alone, else the free-form message a source import sends.
  String? _crumb(S l) {
    final String? item = progress.currentItem;
    final String? source = progress.source?.label;
    if (item != null && source != null) return l.importBreadcrumb(item, source);
    return item ?? progress.message;
  }
}

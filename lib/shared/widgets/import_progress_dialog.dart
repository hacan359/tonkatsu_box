import 'package:flutter/material.dart';

import '../../core/import/import_progress.dart';
import '../../l10n/app_localizations.dart';
import '../constants/import_stage_ui.dart';
import '../theme/app_spacing.dart';
import 'logo_loader.dart';

typedef ImportTalliesBuilder = String? Function(S l, ImportProgress progress);

typedef ImportResultBuilder<T> = Widget? Function(BuildContext context, T result);

/// Locked until the import future settles: a dismissed dialog would leave
/// the write running with nothing on screen to report it.
class ImportProgressDialog<T> extends StatefulWidget {
  const ImportProgressDialog({
    required this.title,
    required this.progressNotifier,
    required this.importFuture,
    this.onCancel,
    this.talliesBuilder,
    this.resultBuilder,
    super.key,
  });

  final String title;
  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<T> importFuture;

  /// Shows a Stop button while running; the runner is expected to finish
  /// its current step and settle the future soon after.
  final VoidCallback? onCancel;

  /// Replaces the title-lookup tallies line; null from the builder hides it.
  final ImportTalliesBuilder? talliesBuilder;

  /// Extra content under the progress once the future has settled.
  final ImportResultBuilder<T>? resultBuilder;

  @override
  State<ImportProgressDialog<T>> createState() =>
      _ImportProgressDialogState<T>();
}

class _ImportProgressDialogState<T> extends State<ImportProgressDialog<T>> {
  bool _stopRequested = false;

  void _requestStop() {
    setState(() => _stopRequested = true);
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return FutureBuilder<T>(
      future: widget.importFuture,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        final bool done = snapshot.connectionState == ConnectionState.done;
        final T? result = snapshot.data;
        final Widget? resultView = done && result != null
            ? widget.resultBuilder?.call(context, result)
            : null;
        return PopScope(
          canPop: done,
          child: AlertDialog(
            scrollable: true,
            title: Text(widget.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ValueListenableBuilder<ImportProgress?>(
                  valueListenable: widget.progressNotifier,
                  builder:
                      (BuildContext context, ImportProgress? p, Widget? _) =>
                          p == null
                              ? const SizedBox(
                                  height: 100,
                                  child: Center(child: LogoLoader()),
                                )
                              : _ProgressBody(
                                  progress: p,
                                  running: !done,
                                  talliesBuilder: widget.talliesBuilder,
                                ),
                ),
                if (resultView != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  resultView,
                ],
              ],
            ),
            actions: <Widget>[
              if (!done && widget.onCancel != null)
                TextButton(
                  onPressed: _stopRequested ? null : _requestStop,
                  child: Text(l.stop),
                ),
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
  const _ProgressBody({
    required this.progress,
    required this.running,
    this.talliesBuilder,
  });

  final ImportProgress progress;
  final bool running;
  final ImportTalliesBuilder? talliesBuilder;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final String? crumb = _crumb(l);
    final String? tallies = _tallies(l);

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
        if (tallies != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(tallies, style: muted),
        ],
      ],
    );
  }

  String? _tallies(S l) {
    final ImportTalliesBuilder? custom = talliesBuilder;
    if (custom != null) return custom(l, progress);
    final bool hasTallies = progress.imported > 0 ||
        progress.customCards > 0 ||
        progress.ambiguous > 0;
    if (!hasTallies) return null;
    return l.importTallies(
      progress.imported,
      progress.customCards,
      progress.ambiguous,
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

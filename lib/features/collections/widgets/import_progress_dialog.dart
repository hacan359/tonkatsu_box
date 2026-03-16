// Диалог прогресса импорта коллекции.

import 'package:flutter/material.dart';

import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';

/// Диалог прогресса импорта коллекции.
///
/// Показывает этап, прогресс-бар и сообщение. Закрывается кнопкой "Done"
/// после завершения.
class ImportProgressDialog extends StatelessWidget {
  /// Создаёт [ImportProgressDialog].
  const ImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
    super.key,
  });

  /// Нотификатор прогресса импорта.
  final ValueNotifier<ImportProgress?> progressNotifier;

  /// Future результата импорта.
  final Future<ImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).collectionsImporting),
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
              if (progress.message != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  progress.message!,
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
        FutureBuilder<ImportResult>(
          future: importFuture,
          builder:
              (BuildContext context, AsyncSnapshot<ImportResult> snapshot) {
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

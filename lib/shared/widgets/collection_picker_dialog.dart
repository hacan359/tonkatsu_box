// Shared диалог выбора коллекции для добавления/перемещения элементов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/collection.dart';
import '../../features/collections/providers/collections_provider.dart';

/// Выбор пользователя в диалоге выбора коллекции.
sealed class CollectionChoice {
  /// Создаёт [CollectionChoice].
  const CollectionChoice();
}

/// Добавить в конкретную коллекцию.
class ChosenCollection extends CollectionChoice {
  /// Создаёт [ChosenCollection].
  const ChosenCollection(this.collection);

  /// Выбранная коллекция.
  final Collection collection;
}

/// Добавить без коллекции (Uncategorized).
class WithoutCollection extends CollectionChoice {
  /// Создаёт [WithoutCollection].
  const WithoutCollection();
}

/// Показывает диалог выбора коллекции.
///
/// [excludeCollectionId] — скрыть коллекцию с данным ID из списка.
/// [showUncategorized] — показывать ли опцию "Without Collection".
/// [title] — заголовок диалога.
///
/// Возвращает [CollectionChoice] при выборе или null при отмене.
Future<CollectionChoice?> showCollectionPickerDialog({
  required BuildContext context,
  required WidgetRef ref,
  int? excludeCollectionId,
  bool showUncategorized = true,
  String? title,
}) async {
  final String resolvedTitle = title ?? S.of(context).chooseCollection;
  final AsyncValue<List<Collection>> collectionsAsync =
      ref.read(collectionsProvider);

  final List<Collection> collections =
      collectionsAsync.valueOrNull ?? <Collection>[];
  final List<Collection> editableCollections = collections
      .where(
        (Collection c) =>
            c.isEditable && c.id != excludeCollectionId,
      )
      .toList();

  return showDialog<CollectionChoice>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(resolvedTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount:
              editableCollections.length + (showUncategorized ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (showUncategorized && index == 0) {
              return ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: Text(S.of(context).withoutCollection),
                subtitle: Text(S.of(context).collectionsUncategorized),
                onTap: () => Navigator.of(context)
                    .pop(const WithoutCollection()),
              );
            }
            final int collectionIndex =
                showUncategorized ? index - 1 : index;
            final Collection collection =
                editableCollections[collectionIndex];
            return ListTile(
              leading: Icon(
                collection.type == CollectionType.own
                    ? Icons.folder
                    : Icons.fork_right,
              ),
              title: Text(collection.name),
              subtitle: Text(collection.author),
              onTap: () => Navigator.of(context)
                  .pop(ChosenCollection(collection)),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel),
        ),
      ],
    ),
  );
}

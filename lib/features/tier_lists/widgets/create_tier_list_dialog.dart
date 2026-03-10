// Диалог создания нового тир-листа.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/tier_list.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/tier_lists_provider.dart';

/// Диалог создания нового тир-листа.
///
/// Позволяет выбрать scope: все элементы или конкретная коллекция.
class CreateTierListDialog extends ConsumerStatefulWidget {
  /// Создаёт [CreateTierListDialog].
  ///
  /// [preselectedCollectionId] — если задан, радио-кнопка "From collection"
  /// выбрана автоматически и dropdown скрыт.
  const CreateTierListDialog({
    this.preselectedCollectionId,
    super.key,
  });

  /// Предвыбранная коллекция (при создании из экрана коллекции).
  final int? preselectedCollectionId;

  @override
  ConsumerState<CreateTierListDialog> createState() =>
      _CreateTierListDialogState();
}

class _CreateTierListDialogState
    extends ConsumerState<CreateTierListDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isGlobal = true;
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCollectionId != null) {
      _isGlobal = false;
      _selectedCollectionId = widget.preselectedCollectionId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return AlertDialog(
      title: Text(l.tierListCreate),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.tierListNameHint,
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.md),

            // Scope выбор
            if (widget.preselectedCollectionId == null) ...<Widget>[
              RadioGroup<bool>(
                groupValue: _isGlobal,
                onChanged: (bool? value) {
                  if (value == null) return;
                  setState(() => _isGlobal = value);
                },
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(l.tierListScopeAll),
                      leading: const Radio<bool>(value: true),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      title: Text(l.tierListScopeCollection),
                      leading: const Radio<bool>(value: false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (!_isGlobal)
                collectionsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (Object e, StackTrace s) => Text(e.toString()),
                  data: (List<Collection> collections) {
                    if (collections.isEmpty) {
                      return Text(
                        l.tierListNoCollections,
                        style: const TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    return DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedCollectionId,
                      hint: Text(l.tierListScopeCollection),
                      dropdownColor: AppColors.surface,
                      items: collections.map((Collection c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _selectedCollectionId = value;
                        });
                      },
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => _submit(context),
          child: Text(l.create),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final int? collectionId = _isGlobal ? null : _selectedCollectionId;

    final TierList tierList = await ref
        .read(tierListsProvider.notifier)
        .create(name, collectionId: collectionId);

    if (context.mounted) {
      Navigator.of(context).pop(tierList);
    }
  }
}

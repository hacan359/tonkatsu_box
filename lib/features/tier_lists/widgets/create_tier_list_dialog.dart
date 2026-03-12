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
  String? _nameError;
  String? _collectionError;

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

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 800;
    final double dialogWidth = isDesktop ? 520 : 400;

    return AlertDialog(
      title: Text(l.tierListCreate),
      contentPadding: isDesktop
          ? const EdgeInsets.fromLTRB(28, 20, 28, 0)
          : const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: isDesktop
          ? const EdgeInsets.fromLTRB(28, 16, 28, 20)
          : const EdgeInsets.fromLTRB(24, 8, 24, 12),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            TextField(
              controller: _nameController,
              autofocus: true,
              style: isDesktop ? const TextStyle(fontSize: 16) : null,
              decoration: InputDecoration(
                hintText: l.tierListNameHint,
                errorText: _nameError,
                contentPadding: isDesktop
                    ? const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.lg),

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
                      dense: !isDesktop,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => setState(() => _isGlobal = true),
                    ),
                    ListTile(
                      title: Text(l.tierListScopeCollection),
                      leading: const Radio<bool>(value: false),
                      dense: !isDesktop,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => setState(() => _isGlobal = false),
                    ),
                  ],
                ),
              ),
              if (!_isGlobal)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: collectionsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (Object e, StackTrace s) => Text(e.toString()),
                    data: (List<Collection> collections) {
                      if (collections.isEmpty) {
                        return Text(
                          l.tierListNoCollections,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          DropdownButton<int>(
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
                                _collectionError = null;
                              });
                            },
                          ),
                          if (_collectionError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                                left: AppSpacing.sm,
                              ),
                              child: Text(
                                _collectionError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: Text(l.create),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final S l = S.of(context);
    final String name = _nameController.text.trim();

    // Валидация
    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _nameError = l.tierListErrorEmptyName);
      hasError = true;
    }
    final int? collectionId = _isGlobal ? null : _selectedCollectionId;
    if (!_isGlobal && collectionId == null) {
      setState(() => _collectionError = l.tierListErrorNoCollection);
      hasError = true;
    }
    if (hasError) return;

    final TierList tierList;
    if (collectionId != null) {
      tierList = await ref
          .read(collectionTierListsProvider(collectionId).notifier)
          .create(name);
    } else {
      tierList = await ref
          .read(tierListsProvider.notifier)
          .create(name);
    }

    if (context.mounted) {
      Navigator.of(context).pop(tierList);
    }
  }
}

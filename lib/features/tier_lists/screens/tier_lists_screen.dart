// Экран списка тир-листов.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/models/tier_list.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../providers/tier_lists_provider.dart';
import '../widgets/create_tier_list_dialog.dart';
import 'tier_list_detail_screen.dart';

/// Экран списка тир-листов.
///
/// Если [collectionId] указан — показывает только тир-листы этой коллекции.
/// Если null — показывает все тир-листы (глобальная вкладка навигации).
class TierListsScreen extends ConsumerStatefulWidget {
  /// Создаёт [TierListsScreen].
  const TierListsScreen({this.collectionId, super.key});

  /// ID коллекции для фильтрации. Null = все тир-листы.
  final int? collectionId;

  /// Группа хоткеев этого экрана для легенды F1.
  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Тир-листы',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+N', description: 'Создать тир-лист'),
      ShortcutEntry(keys: 'Enter', description: 'Открыть тир-лист'),
      ShortcutEntry(keys: 'Delete', description: 'Удалить тир-лист'),
      ShortcutEntry(keys: 'F2', description: 'Переименовать'),
    ],
  );

  @override
  ConsumerState<TierListsScreen> createState() => _TierListsScreenState();
}

class _TierListsScreenState extends ConsumerState<TierListsScreen> {
  TierList? _focusedTierList;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final int? collectionId = widget.collectionId;
    final AsyncValue<List<TierList>> tierListsAsync = collectionId != null
        ? ref.watch(collectionTierListsProvider(collectionId))
        : ref.watch(tierListsProvider);

    return CallbackShortcuts(
      bindings: kIsMobile
          ? const <ShortcutActivator, VoidCallback>{}
          : <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                  () => _showCreateDialog(context),
              const SingleActivator(LogicalKeyboardKey.delete): () {
                if (_focusedTierList != null) _handleDelete(context, _focusedTierList!);
              },
              const SingleActivator(LogicalKeyboardKey.f2): () {
                if (_focusedTierList != null) _handleRename(context, _focusedTierList!);
              },
            },
      child: Focus(
        canRequestFocus: false,
        child: Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: tierListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Text(l.errorPrefix(error.toString())),
        ),
        data: (List<TierList> tierLists) {
          if (tierLists.isEmpty) {
            return Center(
              child: Text(
                l.tierListEmpty,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: tierLists.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final TierList tierList = tierLists[index];
              return _TierListCard(
                tierList: tierList,
                collectionId: collectionId,
                onFocusChanged: (bool focused) {
                  setState(() {
                    _focusedTierList = focused ? tierList : null;
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        tooltip: kIsMobile ? null : '${l.tierListCreate} (Ctrl+N)',
        backgroundColor: AppColors.brand,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final TierList? result = await showDialog<TierList>(
      context: context,
      builder: (BuildContext context) => CreateTierListDialog(
        preselectedCollectionId: widget.collectionId,
      ),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            TierListDetailScreen(tierListId: result.id),
      ));
    }
  }

  Future<void> _handleRename(BuildContext context, TierList tierList) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: tierList.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      if (widget.collectionId != null) {
        await ref
            .read(collectionTierListsProvider(widget.collectionId!).notifier)
            .rename(tierList.id, newName);
      } else {
        await ref
            .read(tierListsProvider.notifier)
            .rename(tierList.id, newName);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, TierList tierList) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.tierListDeleteConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (widget.collectionId != null) {
        await ref
            .read(collectionTierListsProvider(widget.collectionId!).notifier)
            .delete(tierList.id);
      } else {
        await ref.read(tierListsProvider.notifier).delete(tierList.id);
      }
    }
  }
}

class _TierListCard extends ConsumerWidget {
  const _TierListCard({
    required this.tierList,
    this.collectionId,
    this.onFocusChanged,
  });

  final TierList tierList;
  final int? collectionId;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.surfaceLight,
      child: Focus(
        onFocusChange: onFocusChanged,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  TierListDetailScreen(tierListId: tierList.id),
            ));
          },
          onLongPress: () => _showContextMenu(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.leaderboard,
                  color: AppColors.brand,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        tierList.name,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tierList.isGlobal
                            ? S.of(context).tierListScopeAll
                            : S.of(context).tierListScopeCollection,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l.rename),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleRename(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  l.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDelete(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: tierList.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      if (collectionId != null) {
        await ref
            .read(collectionTierListsProvider(collectionId!).notifier)
            .rename(tierList.id, newName);
      } else {
        await ref
            .read(tierListsProvider.notifier)
            .rename(tierList.id, newName);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.tierListDeleteConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (collectionId != null) {
        await ref
            .read(collectionTierListsProvider(collectionId!).notifier)
            .delete(tierList.id);
      } else {
        await ref.read(tierListsProvider.notifier).delete(tierList.id);
      }
    }
  }
}

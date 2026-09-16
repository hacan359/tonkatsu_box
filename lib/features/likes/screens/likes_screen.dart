import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../collections/helpers/item_editability.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../providers/marked_units_provider.dart';
import '../widgets/marked_group_tile.dart';

/// Every liked or noted unit in the library, grouped by title.
class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  late final StateController<bool> _searchActive;

  @override
  void initState() {
    super.initState();
    _searchActive = ref.read(likesSearchActiveProvider.notifier);
    // Claims the shared top-bar field for the page's lifetime. Deferred:
    // a provider may not change while the tree is being built or torn down.
    _setSearchActive(true);
  }

  @override
  void dispose() {
    _setSearchActive(false);
    super.dispose();
  }

  void _setSearchActive(bool value) {
    Future<void>.microtask(() {
      // The whole scope may be gone by now (tab closed, app shut down).
      if (_searchActive.mounted) _searchActive.state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final LikesFilter filter = ref.watch(likesFilterProvider);
    final List<MediaType> types = ref.watch(markedMediaTypesProvider);
    final AsyncValue<List<MarkedUnitGroup>> groups =
        ref.watch(filteredMarkedUnitsProvider);
    final bool hasAnyMarks =
        ref.watch(likesEntriesProvider).valueOrNull?.isNotEmpty ?? false;

    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          if (hasAnyMarks) _FilterRow(filter: filter, types: types),
          Expanded(
            child: groups.when(
              loading: () => const Center(child: LogoLoader()),
              error: (Object error, StackTrace _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    '${l.settingsError}: $error',
                    textAlign: TextAlign.center,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              data: (List<MarkedUnitGroup> shown) => shown.isEmpty
                  ? _Empty(
                      title: hasAnyMarks ? l.likesNoMatches : l.likesEmptyTitle,
                      body: hasAnyMarks ? null : l.likesEmptyBody,
                    )
                  : _GroupList(groups: shown, onOpen: _openItem),
            ),
          ),
        ],
      ),
    );
  }

  void _openItem(MarkedUnitGroup group) {
    final bool editable = isItemEditable(
      group.item,
      ref.read(collectionsProvider).valueOrNull,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ItemDetailScreen(
          collectionId: group.item.collectionId,
          itemId: group.item.id,
          isEditable: editable,
        ),
      ),
    );
  }
}

/// One scrolling row: the three kind toggles, then a chip per media type
/// present. Nothing selected and everything selected both mean "all".
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.filter, required this.types});

  final LikesFilter filter;
  final List<MediaType> types;

  static const double _separatorHeight = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final LikesFilterNotifier notifier = ref.read(likesFilterProvider.notifier);
    final bool allKinds = filter.kinds.isEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          _FilterChip(
            key: const ValueKey<LikesKind>(LikesKind.liked),
            tooltip: l.itemMarkFilterLiked,
            icon: Icons.favorite,
            color: AppColors.favorite,
            active: allKinds || filter.kinds.contains(LikesKind.liked),
            onTap: () => notifier.toggleKind(LikesKind.liked),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            key: const ValueKey<LikesKind>(LikesKind.noted),
            tooltip: l.itemMarkFilterCommented,
            icon: Icons.sticky_note_2_outlined,
            color: AppColors.textSecondary,
            active: allKinds || filter.kinds.contains(LikesKind.noted),
            onTap: () => notifier.toggleKind(LikesKind.noted),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            key: const ValueKey<LikesKind>(LikesKind.rewatched),
            tooltip: l.likesRewatchFilter,
            icon: Icons.replay,
            color: AppColors.statusReplaying,
            active: allKinds || filter.kinds.contains(LikesKind.rewatched),
            onTap: () => notifier.toggleKind(LikesKind.rewatched),
          ),
          if (types.length > 1) ...<Widget>[
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            SizedBox(
              height: _separatorHeight,
              child: VerticalDivider(
                width: 1,
                thickness: 0.5,
                color: AppColors.surfaceBorder,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            for (int i = 0; i < types.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                key: ValueKey<MediaType>(types[i]),
                tooltip: types[i].localizedLabel(l),
                icon: MediaTypeTheme.placeholderIconFor(types[i]),
                color: MediaTypeTheme.colorFor(types[i]),
                active: filter.types.isEmpty || filter.types.contains(types[i]),
                onTap: () => notifier.toggleType(types[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Icon-only pill; the tooltip carries the name so the row stays compact.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xs,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: active ? color.withAlpha(24) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: active ? color.withAlpha(96) : AppColors.surfaceBorder,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: _iconSize,
            color: active ? color : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// A replayed title lands in the replay block with all its rows, so nothing
/// shows up twice under the marked-titles heading.
class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups, required this.onOpen});

  final List<MarkedUnitGroup> groups;
  final ValueChanged<MarkedUnitGroup> onOpen;

  static const double _maxWidth = 920;

  /// A heading and then its cards, flattened so the list stays lazy.
  List<_Row> _rows(S l) {
    final List<_Row> replays = <_Row>[
      for (final MarkedUnitGroup g in groups)
        if (g.isReplayed) _Card(g),
    ];
    final List<_Row> marks = <_Row>[
      for (final MarkedUnitGroup g in groups)
        if (!g.isReplayed) _Card(g),
    ];
    return <_Row>[
      if (replays.isNotEmpty) ...<_Row>[_Heading(l.likesSectionRewatch), ...replays],
      if (marks.isNotEmpty) ...<_Row>[_Heading(l.likesSectionMarks), ...marks],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_Row> rows = _rows(S.of(context));
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (BuildContext context, int index) =>
              switch (rows[index]) {
            _Heading(:final String title) =>
              _SectionTitle(title: title, first: index == 0),
            _Card(:final MarkedUnitGroup group) => MarkedGroupTile(
                key: ValueKey<int>(group.item.id),
                group: group,
                onOpen: () => onOpen(group),
              ),
          },
        ),
      ),
    );
  }
}

sealed class _Row {
  const _Row();
}

class _Heading extends _Row {
  const _Heading(this.title);

  final String title;
}

class _Card extends _Row {
  const _Card(this.group);

  final MarkedUnitGroup group;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.first});

  final String title;

  /// The list's own padding already spaces the first heading off the top.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xs,
        top: first ? 0 : AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final String? body = this.body;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            if (body != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

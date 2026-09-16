import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../search/handlers/media_handlers.dart';
import '../../search/widgets/collection_chips_row.dart';
import '../models/showcase_item.dart';
import '../providers/showcase_rows_provider.dart';
import '../providers/showcase_settings_provider.dart';
import '../widgets/showcase_group_title.dart';
import '../widgets/showcase_row_section.dart';
import '../widgets/showcase_settings_sheet.dart';

final Logger _log = Logger('ShowcaseScreen');

/// Add-target chips of this screen, independent of the Search tab's pick.
final StateProvider<Set<int>> showcaseTargetCollectionsProvider =
    StateProvider<Set<int>>((Ref ref) => <int>{});

/// What is out now and what people watch, one poster row per feed.
class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen> {
  late final MediaHandlers _handlers;

  /// The game sheet labels platforms by id; loaded once, empty until then.
  Map<int, Platform> _platformMap = <int, Platform>{};

  @override
  void initState() {
    super.initState();
    _handlers = MediaHandlers(
      ref: ref,
      platformMap: () => _platformMap,
      targetCollections: () => ref.read(showcaseTargetCollectionsProvider),
    );
    _loadPlatforms();
  }

  /// Without the map the game sheet only loses platform labels, so a failure
  /// is logged and the screen stays up.
  Future<void> _loadPlatforms() async {
    final List<Platform> platforms;
    try {
      platforms =
          await ref.read(databaseServiceProvider).gameDao.getAllPlatforms();
    } on Object catch (e, st) {
      _log.warning('Platform list failed to load', e, st);
      return;
    }
    if (!mounted) return;
    setState(() {
      _platformMap = <int, Platform>{for (final Platform p in platforms) p.id: p};
    });
  }

  void _onItemTap(ShowcaseItem item) {
    _handlers.onTap(context, item.media, item.mediaType);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          _Header(
            onRefresh: () => refreshShowcase(ref),
            onSettings: () => ShowcaseSettingsSheet.show(context),
          ),
          CollectionChipsRow(
            targetProvider: showcaseTargetCollectionsProvider,
          ),
          Expanded(child: _buildBody(l)),
        ],
      ),
    );
  }

  Widget _buildBody(S l) {
    final ShowcaseSettings settings = ref.watch(showcaseSettingsProvider);
    final List<Widget> children = <Widget>[];
    for (final ShowcaseGroup group in ShowcaseGroup.values) {
      final List<ShowcaseRowId> rows = ref
          .watch(showcaseRowOrderProvider(group))
          .where(settings.isEnabled)
          .toList();
      if (rows.isEmpty) continue;
      children.add(ShowcaseGroupTitle(group: group));
      for (final ShowcaseRowId row in rows) {
        children
          ..add(ShowcaseRowSection(
            key: ValueKey<ShowcaseRowId>(row),
            rowId: row,
            onTap: _onItemTap,
          ))
          ..add(const SizedBox(height: AppSpacing.lg));
      }
    }
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l.showcaseAllRowsHidden,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: children,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.onSettings});

  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l.showcaseHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: l.refresh,
            color: AppColors.textSecondary,
            onPressed: onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: l.showcaseSettingsTitle,
            color: AppColors.textSecondary,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

// Fantlab edition picker. A Fantlab work has many editions (`издания`), each
// with its own cover; this sheet lets the user pick which one a book carries.
// Grouped by Fantlab's blocks (Издания / Иностранные / …), covers first.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/fantlab_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/book.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';

/// Cache of editions providers keyed by Fantlab work id.
final Map<String, FutureProvider<List<FantlabEditionBlock>>>
    _editionProviders = <String, FutureProvider<List<FantlabEditionBlock>>>{};

FutureProvider<List<FantlabEditionBlock>> _getEditionsProvider(String workId) {
  return _editionProviders.putIfAbsent(
    workId,
    () => FutureProvider<List<FantlabEditionBlock>>(
      (Ref ref) => ref.watch(fantlabApiProvider).getEditions(workId),
    ),
  );
}

/// Opens the edition picker for a Fantlab work. Resolves to the chosen edition,
/// or null if the sheet is dismissed without a pick.
Future<FantlabEdition?> showFantlabEditionPicker(
  BuildContext context, {
  required String workId,
  int? currentEditionId,
}) {
  return showModalBottomSheet<FantlabEdition>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) => _FantlabEditionPickerSheet(
      workId: workId,
      currentEditionId: currentEditionId,
    ),
  );
}

/// Overlays [edition]'s cover and bibliographic fields onto [book], keeping its
/// work identity (`id` / `nativeId` / `source`) untouched.
Book applyFantlabEdition(Book book, FantlabEdition edition) {
  final String? isbn = edition.isbn;
  return book.copyWith(
    coverUrl: edition.coverUrl,
    publishYear: edition.year ?? book.publishYear,
    pageCount: edition.pages ?? book.pageCount,
    isbn13: isbn != null && isbn.length == 13 ? isbn : book.isbn13,
    isbn10: isbn != null && isbn.length == 10 ? isbn : book.isbn10,
    languages: edition.langCode != null
        ? <String>[edition.langCode!]
        : book.languages,
    publishers: edition.publisher != null
        ? <String>[edition.publisher!]
        : book.publishers,
  );
}

/// Parses the edition id back out of a Fantlab cover URL
/// (`/images/editions/big/24724`), so the picker can mark the current cover.
int? editionIdFromCoverUrl(String? coverUrl) {
  if (coverUrl == null) return null;
  final RegExpMatch? m =
      RegExp(r'/images/editions/\w+/(\d+)').firstMatch(coverUrl);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

/// Inline editions strip for a book's detail sheet — mirrors the games'
/// ScreenScraper gallery. Horizontal covers (covers first); tapping one calls
/// [onSelected]. Hidden while loading / on error / when the work has none.
class FantlabEditionsSection extends ConsumerStatefulWidget {
  const FantlabEditionsSection({
    required this.workId,
    required this.onSelected,
    this.selectedEditionId,
    super.key,
  });

  final String workId;
  final void Function(FantlabEdition edition) onSelected;
  final int? selectedEditionId;

  @override
  ConsumerState<FantlabEditionsSection> createState() =>
      _FantlabEditionsSectionState();
}

class _FantlabEditionsSectionState
    extends ConsumerState<FantlabEditionsSection> {
  final ScrollController _controller = ScrollController();

  static const double _rowHeight = 210;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<FantlabEditionBlock>> async =
        ref.watch(_getEditionsProvider(widget.workId));

    return async.maybeWhen(
      data: (List<FantlabEditionBlock> blocks) {
        final List<FantlabEdition> editions = <FantlabEdition>[
          for (final FantlabEditionBlock b in blocks) ...b.editions,
        ];
        if (editions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.menu_book,
                        color: AppColors.brand, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.editionPickerTitle,
                      style: AppTypography.cardTitle
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: _rowHeight,
                child: ScrollableRowWithArrows(
                  controller: _controller,
                  height: _rowHeight,
                  child: ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: editions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int i) {
                      final FantlabEdition edition = editions[i];
                      return _EditionCard(
                        edition: edition,
                        selected:
                            edition.editionId == widget.selectedEditionId,
                        onTap: () => widget.onSelected(edition),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _FantlabEditionPickerSheet extends ConsumerWidget {
  const _FantlabEditionPickerSheet({
    required this.workId,
    this.currentEditionId,
  });

  final String workId;
  final int? currentEditionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<FantlabEditionBlock>> async =
        ref.watch(_getEditionsProvider(workId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l.editionPickerTitle,
                      style: AppTypography.h3
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (List<FantlabEditionBlock> blocks) => blocks.isEmpty
                    ? Center(child: Text(l.editionPickerEmpty))
                    : _EditionBlockList(
                        blocks: blocks,
                        currentEditionId: currentEditionId,
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l.editionPickerEmpty)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionBlockList extends StatelessWidget {
  const _EditionBlockList({
    required this.blocks,
    required this.currentEditionId,
  });

  final List<FantlabEditionBlock> blocks;
  final int? currentEditionId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: blocks.length,
      itemBuilder: (BuildContext context, int index) {
        final FantlabEditionBlock block = blocks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '${block.title} (${block.editions.length})',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final FantlabEdition edition in block.editions)
                  _EditionCard(
                    edition: edition,
                    selected: edition.editionId == currentEditionId,
                    onTap: () => Navigator.of(context).pop(edition),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  final FantlabEdition edition;
  final bool selected;
  final VoidCallback onTap;

  static const double _width = 104;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _cover(),
                    if (selected)
                      const ColoredBox(color: Color(0x33000000)),
                    if (selected)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.check_circle,
                              color: AppColors.brand, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _caption(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    if (!edition.hasCover) return _placeholder();
    // `big` (200×316) — `small` is only 60×94 and looks blurry in the card.
    return Image.network(
      edition.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (BuildContext _, Widget child, ImageChunkEvent? p) =>
          p == null ? child : _placeholder(),
    );
  }

  Widget _placeholder() => const ColoredBox(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(Icons.menu_book, color: AppColors.textTertiary),
        ),
      );

  String _caption() {
    final List<String> parts = <String>[
      if (edition.year != null) '${edition.year}',
      if (edition.publisher != null) edition.publisher!,
      if (edition.langCode != null) edition.langCode!.toUpperCase(),
    ];
    return parts.join(' · ');
  }
}

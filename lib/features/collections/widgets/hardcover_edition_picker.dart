// Hardcover edition picker. A Hardcover book has many editions (localized
// titles, own covers, languages); this strip lets the user pick which one a
// book carries — the Fantlab editions strip pattern, plus language chips.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/hardcover_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/book.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';

/// Cache of editions providers keyed by Hardcover book id.
final Map<String, FutureProvider<List<HardcoverEdition>>> _editionProviders =
    <String, FutureProvider<List<HardcoverEdition>>>{};

FutureProvider<List<HardcoverEdition>> _getEditionsProvider(String bookId) {
  return _editionProviders.putIfAbsent(
    bookId,
    () => FutureProvider<List<HardcoverEdition>>(
      (Ref ref) => ref.watch(hardcoverApiProvider).getEditions(bookId),
    ),
  );
}

/// Opens the edition picker for a Hardcover book, grouped by language.
/// Resolves to the chosen edition, or null if the sheet is dismissed without
/// a pick.
Future<HardcoverEdition?> showHardcoverEditionPicker(
  BuildContext context, {
  required String bookId,
  int? currentEditionId,
}) {
  return showModalBottomSheet<HardcoverEdition>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) => _HardcoverEditionPickerSheet(
      bookId: bookId,
      currentEditionId: currentEditionId,
    ),
  );
}

/// Overlays [edition]'s cover, localized title and bibliographic fields onto
/// [book], keeping its work identity (`id` / `nativeId` / `source`) untouched.
/// The edition id is recorded as a fragment on the external URL — fragments
/// never reach the server, so the link resolves exactly as before while the
/// pick survives a "refresh from source".
Book applyHardcoverEdition(Book book, HardcoverEdition edition) {
  final bool hasTitle = edition.title.isNotEmpty;
  final bool titleChanges = hasTitle && edition.title != book.title;
  return book.copyWith(
    title: hasTitle ? edition.title : null,
    originalTitle:
        book.originalTitle ?? (titleChanges ? book.title : null),
    coverUrl: edition.coverUrl,
    pageCount: edition.pages,
    publishYear: edition.releaseYear,
    isbn10: edition.isbn10,
    isbn13: edition.isbn13,
    languages: edition.languageCode != null
        ? <String>[edition.languageCode!]
        : null,
    publishers:
        edition.publisher != null ? <String>[edition.publisher!] : null,
    externalUrl: _withEditionFragment(book, edition.id),
  );
}

String _withEditionFragment(Book book, int editionId) {
  final String base =
      (book.externalUrl ?? 'https://hardcover.app/id/book/${book.nativeId}')
          .split('#')
          .first;
  return '$base#edition-$editionId';
}

/// The explicitly picked edition, recorded by [applyHardcoverEdition] as a
/// `#edition-{id}` fragment on the external URL.
int? hardcoverEditionIdFromExternalUrl(String? externalUrl) {
  if (externalUrl == null) return null;
  final RegExpMatch? m =
      RegExp(r'#edition-(\d+)$').firstMatch(externalUrl);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

/// Edition id embedded in an edition-hosted cover URL
/// (`assets.hardcover.app/edition[s]/{id}/…`). Book-level covers may instead
/// live under `external_data/` and carry no id — then this returns null.
int? hardcoverEditionIdFromCoverUrl(String? coverUrl) {
  if (coverUrl == null) return null;
  final RegExpMatch? m = RegExp(r'assets\.hardcover\.app/editions?/(\d+)/')
      .firstMatch(coverUrl);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

/// Refresh helper: re-applies the edition the user picked (recovered from the
/// cached row) onto the freshly fetched [fresh] book. Returns [fresh] as-is
/// when nothing was picked, when the cover simply came with the book rather
/// than from a pick, or when the edition no longer belongs to this book — so
/// a failed recovery can never lose more than the pick itself.
Future<Book> reapplyHardcoverEdition(
  HardcoverApi api, {
  required Book cached,
  required Book fresh,
}) async {
  final int? explicitId =
      hardcoverEditionIdFromExternalUrl(cached.externalUrl);
  final int? pickedId =
      explicitId ?? hardcoverEditionIdFromCoverUrl(cached.coverUrl);
  if (pickedId == null) return fresh;
  // A cover-derived id equal to the fresh default cover's is not a pick.
  if (explicitId == null &&
      pickedId == hardcoverEditionIdFromCoverUrl(fresh.coverUrl)) {
    return fresh;
  }

  final HardcoverEdition? edition = await api.getEdition(pickedId);
  if (edition == null || edition.bookId.toString() != fresh.nativeId) {
    return fresh;
  }
  return applyHardcoverEdition(fresh, edition);
}

/// Inline editions strip for a Hardcover book's detail sheet — the Fantlab
/// strip pattern plus language filter chips (shown when editions span more
/// than one language). Hidden while loading / on error / with no editions.
class HardcoverEditionsSection extends ConsumerStatefulWidget {
  const HardcoverEditionsSection({
    required this.bookId,
    required this.onSelected,
    this.selectedEditionId,
    super.key,
  });

  final String bookId;
  final void Function(HardcoverEdition edition) onSelected;
  final int? selectedEditionId;

  @override
  ConsumerState<HardcoverEditionsSection> createState() =>
      _HardcoverEditionsSectionState();
}

class _HardcoverEditionsSectionState
    extends ConsumerState<HardcoverEditionsSection> {
  final ScrollController _controller = ScrollController();

  /// Selected language chip; null = all languages.
  String? _language;

  static const double _rowHeight = 210;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Distinct language codes ordered by how many editions carry each.
  List<String> _languagesOf(List<HardcoverEdition> editions) {
    final Map<String, int> counts = <String, int>{};
    for (final HardcoverEdition edition in editions) {
      final String? code = edition.languageCode;
      if (code != null) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    final List<String> codes = counts.keys.toList()
      ..sort((String a, String b) => counts[b]!.compareTo(counts[a]!));
    return codes;
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<HardcoverEdition>> async =
        ref.watch(_getEditionsProvider(widget.bookId));

    return async.maybeWhen(
      data: (List<HardcoverEdition> editions) {
        if (editions.isEmpty) return const SizedBox.shrink();

        final List<String> languages = _languagesOf(editions);
        final List<HardcoverEdition> visible = _language == null
            ? editions
            : editions
                .where((HardcoverEdition e) => e.languageCode == _language)
                .toList();

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
              if (languages.length > 1)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      _languageChip(
                        label: l.homeFilterAll,
                        selected: _language == null,
                        onTap: () => setState(() => _language = null),
                      ),
                      for (final String code in languages)
                        _languageChip(
                          label: code.toUpperCase(),
                          selected: _language == code,
                          onTap: () => setState(() => _language = code),
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
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int i) {
                      final HardcoverEdition edition = visible[i];
                      return _EditionCard(
                        edition: edition,
                        selected: edition.id == widget.selectedEditionId,
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

  Widget _languageChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HardcoverEditionPickerSheet extends ConsumerWidget {
  const _HardcoverEditionPickerSheet({
    required this.bookId,
    this.currentEditionId,
  });

  final String bookId;
  final int? currentEditionId;

  /// Editions bucketed by language, most-covered language first, editions
  /// without one last.
  List<(String?, List<HardcoverEdition>)> _groups(
    List<HardcoverEdition> editions,
  ) {
    final Map<String?, List<HardcoverEdition>> byLanguage =
        <String?, List<HardcoverEdition>>{};
    for (final HardcoverEdition edition in editions) {
      byLanguage
          .putIfAbsent(edition.languageCode, () => <HardcoverEdition>[])
          .add(edition);
    }
    final List<(String?, List<HardcoverEdition>)> groups =
        <(String?, List<HardcoverEdition>)>[
      for (final MapEntry<String?, List<HardcoverEdition>> e
          in byLanguage.entries)
        (e.key, e.value),
    ]..sort(((String?, List<HardcoverEdition>) a,
            (String?, List<HardcoverEdition>) b) {
          if (a.$1 == null) return 1;
          if (b.$1 == null) return -1;
          return b.$2.length.compareTo(a.$2.length);
        });
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<HardcoverEdition>> async =
        ref.watch(_getEditionsProvider(bookId));

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
                data: (List<HardcoverEdition> editions) => editions.isEmpty
                    ? Center(child: Text(l.editionPickerEmpty))
                    : _EditionGroupList(
                        groups: _groups(editions),
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

class _EditionGroupList extends StatelessWidget {
  const _EditionGroupList({
    required this.groups,
    required this.currentEditionId,
  });

  final List<(String?, List<HardcoverEdition>)> groups;
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
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int index) {
        final (String? language, List<HardcoverEdition> editions) =
            groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '${language?.toUpperCase() ?? '—'} (${editions.length})',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final HardcoverEdition edition in editions)
                  _EditionCard(
                    edition: edition,
                    selected: edition.id == currentEditionId,
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

  final HardcoverEdition edition;
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
    final String? url = edition.coverUrl;
    if (url == null) return _placeholder();
    return Image.network(
      url,
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
      if (edition.releaseYear != null) '${edition.releaseYear}',
      if (edition.publisher != null) edition.publisher!,
      if (edition.languageCode != null) edition.languageCode!.toUpperCase(),
    ];
    return parts.join(' · ');
  }
}

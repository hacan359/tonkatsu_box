// "More by this author" strip at the bottom of a Google Books volume's search
// detail sheet. Display-only: covers + title + year, hover reveals the
// description, tap copies the title. Adding a book goes through the normal
// search flow, so this strip never adds anything itself.

import 'package:core/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/google_books_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/book_carousel.dart';

const int _pageSize = 20;

/// Lazily-paged horizontal strip of other books by [author], excluding the
/// volume the sheet was opened for ([excludeNativeId]).
class GoogleBooksMoreByAuthorSection extends ConsumerStatefulWidget {
  const GoogleBooksMoreByAuthorSection({
    required this.author,
    required this.excludeNativeId,
    super.key,
  });

  final String author;

  /// `volumeId` of the sheet's own book — dropped from the results.
  final String excludeNativeId;

  @override
  ConsumerState<GoogleBooksMoreByAuthorSection> createState() =>
      _GoogleBooksMoreByAuthorSectionState();
}

class _GoogleBooksMoreByAuthorSectionState
    extends ConsumerState<GoogleBooksMoreByAuthorSection> {
  final List<Book> _books = <Book>[];
  final Set<String> _seen = <String>{};
  int _startIndex = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      // Strip embedded quotes — they would close the `inauthor:"…"` term early
      // and corrupt the query.
      final String author = widget.author.replaceAll('"', '');
      final (List<Book> books, bool hasMore) =
          await ref.read(googleBooksApiProvider).searchVolumes(
                'inauthor:"$author"',
                startIndex: _startIndex,
                maxResults: _pageSize,
              );
      if (!mounted) return;
      setState(() {
        for (final Book b in books) {
          if (b.nativeId == widget.excludeNativeId) continue;
          if (_seen.add(b.nativeId)) _books.add(b);
        }
        _startIndex += _pageSize;
        _hasMore = hasMore;
        _loading = false;
        _initialLoaded = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasMore = false;
        _initialLoaded = true;
      });
    }
  }

  void _copyTitle(Book book) {
    Clipboard.setData(ClipboardData(text: book.title));
    context.showSnack(S.of(context).bookTitleCopied);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoaded) return const BookCarouselShimmer();
    if (_books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          S.of(context).bookMoreByAuthorTitle,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        BookCarousel(
          books: _books,
          showRating: false,
          onTap: _copyTitle,
          tooltipOf: (Book b) => b.description,
          onEndReached: _loadMore,
          loadingMore: _loading,
        ),
      ],
    );
  }
}

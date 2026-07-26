// "Similar books" for a Google Books volume. Google's native `associated`
// endpoint is effectively empty, so similarity is approximated by searching the
// book's primary category (`subject:`) and dropping the book itself. Renders
// the shared [BookSimilarsCarousel], mirroring [BookSimilarsSection].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/google_books_api.dart';
import '../../../shared/models/book.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/widgets/book_carousel.dart';
import '../providers/collections_provider.dart';
import 'book_similars_carousel.dart';

/// Cache of category-based similar providers keyed by Google `volumeId`.
final Map<String, FutureProvider<List<Book>>> _similarProviders =
    <String, FutureProvider<List<Book>>>{};

FutureProvider<List<Book>> _getSimilarProvider(Book book) {
  return _similarProviders.putIfAbsent(
    book.nativeId,
    () => FutureProvider<List<Book>>((Ref ref) async {
      if (book.subjects.isEmpty) return const <Book>[];
      // Strip embedded quotes — they would close the `subject:"…"` term early
      // and corrupt the query.
      final String category = book.subjects.first.replaceAll('"', '');
      final (List<Book> books, _) = await ref
          .watch(googleBooksApiProvider)
          .searchVolumes('subject:"$category"', maxResults: 20);
      return books
          .where((Book b) => b.nativeId != book.nativeId)
          .take(15)
          .toList();
    }),
  );
}

/// Horizontal row of books sharing the viewed book's primary category. Hidden
/// while loading fails or returns nothing.
class GoogleBooksSimilarsSection extends ConsumerWidget {
  const GoogleBooksSimilarsSection({
    required this.book,
    this.onAddBook,
    super.key,
  });

  final Book book;

  /// Adds a tapped similar book to a collection.
  final void Function(Book book)? onAddBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Book>> async =
        ref.watch(_getSimilarProvider(book));
    final Set<(DataSource, int)> ownedKeys =
        ref.watch(collectedBookIdsProvider).valueOrNull?.sourceKeys ??
            const <(DataSource, int)>{};

    return async.when(
      data: (List<Book> books) => books.isEmpty
          ? const SizedBox.shrink()
          : BookSimilarsCarousel(
              books: books,
              ownedKeys: ownedKeys,
              onAddBook: onAddBook,
            ),
      loading: () => const BookCarouselShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

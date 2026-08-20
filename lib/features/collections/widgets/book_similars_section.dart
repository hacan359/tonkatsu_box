import 'package:core/models/book.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/fantlab_api.dart';
import '../../../shared/widgets/book_carousel.dart';
import '../providers/collections_provider.dart';
import 'book_similars_carousel.dart';

final Map<String, FutureProvider<List<Book>>> _similarProviders =
    <String, FutureProvider<List<Book>>>{};

FutureProvider<List<Book>> _getSimilarProvider(String workId) {
  return _similarProviders.putIfAbsent(
    workId,
    () => FutureProvider<List<Book>>(
      (Ref ref) => ref.watch(fantlabApiProvider).getSimilars(workId),
    ),
  );
}

/// Fantlab only — the one book provider with a native similars endpoint.
/// Hidden when loading fails or returns nothing.
class BookSimilarsSection extends ConsumerWidget {
  const BookSimilarsSection({
    required this.workId,
    this.onAddBook,
    super.key,
  });

  /// Fantlab native work id (`book.nativeId`).
  final String workId;

  final void Function(Book book)? onAddBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Book>> async =
        ref.watch(_getSimilarProvider(workId));
    // Keyed by source: book providers hand out colliding numeric ids, so a
    // plain id match badges a different provider's title as owned.
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

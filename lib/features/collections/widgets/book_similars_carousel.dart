// Shared presentation for the book "similar" carousels (Fantlab native
// similars and Google Books category matches): a titled [BookCarousel] that
// opens a tapped book's sheet and routes adds through [onAddBook].

import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/book_carousel.dart';
import '../../search/widgets/item_details_sheet.dart';

class BookSimilarsCarousel extends StatelessWidget {
  const BookSimilarsCarousel({
    required this.books,
    required this.ownedKeys,
    this.onAddBook,
    super.key,
  });

  final List<Book> books;

  /// `(source, externalIdInt)` of the books already in a collection.
  final Set<(DataSource, int)> ownedKeys;
  final void Function(Book book)? onAddBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          S.of(context).bookSimilarTitle,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        BookCarousel(
          books: books,
          ownedKeys: ownedKeys,
          onTap: (Book book) => _showBook(context, book),
        ),
      ],
    );
  }

  void _showBook(BuildContext context, Book book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.book(
        book,
        onAddToCollection: () => onAddBook?.call(book),
      ),
    );
  }
}

// Sub-type of a [Book] record — prose book vs. comic / graphic novel.

/// Discriminates a [Book] as prose or a comic.
///
/// Comics (ComicVine) and books (OpenLibrary / Fantlab) share the `book`
/// [MediaType]; [BookKind] is the stored discriminator that keeps them
/// separable later without a dedicated media type. Persisted in the
/// `books_cache.kind` column and carried through export / import.
enum BookKind {
  /// Prose book (OpenLibrary, Fantlab).
  book('book'),

  /// Comic / graphic novel volume (ComicVine).
  comic('comic');

  const BookKind(this.value);

  /// Stable storage value written to the DB / export payload.
  final String value;

  /// Parses a [BookKind] from its stored [value]. Unknown / null values fall
  /// back to [BookKind.book], so pre-existing rows without the column stay
  /// prose books.
  static BookKind fromName(String? value) {
    if (value == null) return BookKind.book;
    for (final BookKind kind in BookKind.values) {
      if (kind.value == value) return kind;
    }
    return BookKind.book;
  }
}

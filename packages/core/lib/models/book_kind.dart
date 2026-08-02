/// Comics and prose books share the `book` [MediaType]; this is the stored
/// discriminator in `books_cache.kind`, carried through export / import.
enum BookKind {
  /// Prose book (OpenLibrary, Fantlab).
  book('book'),

  /// Comic / graphic novel volume (ComicVine).
  comic('comic');

  const BookKind(this.value);

  /// Stable storage value written to the DB / export payload.
  final String value;

  /// Unknown / null falls back to [BookKind.book], so rows predating the column
  /// stay prose.
  static BookKind fromName(String? value) {
    if (value == null) return BookKind.book;
    for (final BookKind kind in BookKind.values) {
      if (kind.value == value) return kind;
    }
    return BookKind.book;
  }
}

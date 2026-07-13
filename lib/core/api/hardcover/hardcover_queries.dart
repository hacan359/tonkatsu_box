/// GraphQL documents for the Hardcover API (Hasura + Typesense search).
abstract class HardcoverQueries {
  /// Token check — returns the token owner. `me` comes back as a list.
  static const String me = '''
query Me {
  me {
    id
    username
  }
}
''';

  /// Typesense-backed book search. A search document already carries the whole
  /// card (authors, genres, image, rating, ISBNs), so no detail follow-up is
  /// needed. [sort] is a `field:direction` pair over the document's numeric
  /// fields (`users_count:desc`, `release_year:desc`, …); null means relevance.
  static const String search = '''
query SearchBooks(\$query: String!, \$perPage: Int!, \$page: Int!, \$sort: String) {
  search(query: \$query, query_type: "Book", per_page: \$perPage, page: \$page, sort: \$sort) {
    results
  }
}
''';

  /// Full book by numeric id — used for refetch of a stored item.
  static const String bookById = '''
query BookById(\$id: Int!) {
  books_by_pk(id: \$id) {
    id
    title
    subtitle
    description
    release_year
    pages
    rating
    ratings_count
    slug
    book_category_id
    cached_tags
    image {
      url
    }
    contributions {
      author {
        name
      }
    }
    book_series {
      position
      series {
        name
      }
    }
    default_physical_edition {
      isbn_10
      isbn_13
      publisher {
        name
      }
      language {
        code2
      }
    }
  }
}
''';

  /// Editions of a book, most-owned first — feeds the edition picker strip.
  static const String editionsByBook = '''
query EditionsByBook(\$bookId: Int!, \$limit: Int!) {
  editions(
    where: {book_id: {_eq: \$bookId}}
    order_by: [{users_count: desc_nulls_last}, {id: asc}]
    limit: \$limit
  ) {
    id
    book_id
    title
    users_count
    pages
    isbn_10
    isbn_13
    release_date
    language {
      code2
    }
    publisher {
      name
    }
    image {
      url
    }
    cached_image
  }
}
''';

  /// One edition by id — restores the user's picked edition on refresh.
  static const String editionById = '''
query EditionById(\$id: Int!) {
  editions_by_pk(id: \$id) {
    id
    book_id
    title
    users_count
    pages
    isbn_10
    isbn_13
    release_date
    language {
      code2
    }
    publisher {
      name
    }
    image {
      url
    }
    cached_image
  }
}
''';

  /// Distinguishes "user not found" from "empty library".
  static const String userLookup = '''
query UserLookup(\$username: citext!) {
  users(where: {username: {_eq: \$username}}, limit: 1) {
    id
    username
  }
}
''';

  /// Library size — drives the import progress bar.
  static const String userBooksCount = '''
query UserBooksCount(\$username: citext!) {
  user_books_aggregate(where: {user: {username: {_eq: \$username}}}) {
    aggregate {
      count
    }
  }
}
''';

  /// One page of a user's library. A book can have several `user_books` rows,
  /// so `distinct_on: book_id` (which requires the matching `order_by`) keeps
  /// one per book — same approach as Hardcover's own import guide.
  static const String userBooks = '''
query UserBooks(\$username: citext!, \$limit: Int!, \$offset: Int!) {
  user_books(
    where: {user: {username: {_eq: \$username}}}
    limit: \$limit
    offset: \$offset
    distinct_on: book_id
    order_by: {book_id: asc}
  ) {
    status_id
    rating
    read_count
    first_started_reading_date
    first_read_date
    last_read_date
    date_added
    review
    private_notes
    owned
    book {
      id
      title
      subtitle
      description
      release_year
      pages
      rating
      ratings_count
      slug
      book_category_id
      cached_tags
      image {
        url
      }
      contributions {
        author {
          name
        }
      }
      book_series {
        position
        series {
          name
        }
      }
    }
  }
}
''';
}

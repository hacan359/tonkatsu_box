# OpenLibrary API

REST client for OpenLibrary, the global open book catalog (~40M works, CC0/ODbL). No auth.

- Docs: https://openlibrary.org/developers/api
- Endpoint: `https://openlibrary.org`
- Covers CDN: `https://covers.openlibrary.org`

## Layers

| File | Purpose |
|---|---|
| `../openlibrary_api.dart` | Facade. Entry point for the rest of the code (`openLibraryApiProvider`). |
| `openlibrary_types.dart` | `OpenLibraryApiException`. |
| `openlibrary_http_client.dart` | Dio transport: base URL, required User-Agent, Dio → `OpenLibraryApiException` mapping. |
| `openlibrary_search_api.dart` | `search` (`/search.json`) → lightweight `Book`s for the grid. |
| `openlibrary_works_api.dart` | `getWork` (`/works/{OLID}.json` + `/ratings.json` + `/authors/{OLID}.json`) → full `Book`. |

## Key points

- **User-Agent required.** Anonymous bots can be blocked, so `OpenLibraryHttpClient` always sends `TonkatsuBox/<ver> (<repo>)`.
- **Identity.** Works have no numeric id — only the OLID string `OL[1-9]\d{0,7}W`. `Book` stores the digits in `id` (`27448`) and the full OLID in `nativeId` (`OL27448W`); both are produced in `Book.fromOpenLibrary*`. See `dev/backlog/integrations/books.md`.
- **Two construction paths.** Search results come from `search.json` `docs[]` (`Book.fromOpenLibrarySearchDoc`, lightweight); the detail view loads the full work (`Book.fromOpenLibraryWork`, with description / subjects / rating / authors).
- **Ratings scale.** `/ratings.json` `summary.average` is 1–5; `Book.fromOpenLibraryWork` doubles it to the app's 1–10 scale.
- **Author fan-out.** `work.authors[]` holds only `/authors/{OLID}` refs; names are resolved with parallel lookups capped at 5. A failed ratings / author call degrades gracefully (null / dropped) rather than sinking the work load.
- **Covers.** `covers.openlibrary.org/b/id/{id}-L.jpg` 302-redirects to the CDN; Dio follows redirects by default. `covers[]` can contain nulls — `Book._firstCoverId` skips them.
- **No browse.** OpenLibrary has no clean "popular" feed, so `OpenLibrarySource.supportsBrowse` is false — a text query is required.

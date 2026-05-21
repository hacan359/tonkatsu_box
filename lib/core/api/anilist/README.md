# AniList API

GraphQL-клиент AniList. Публичный endpoint, без авторизации, лимит ~90 req/min.

- Docs: https://anilist.gitbook.io/anilist-apiv2-docs
- Endpoint: `https://graphql.anilist.co`

## Слои

| Файл | Назначение |
|---|---|
| `../anilist_api.dart` | Фасад. Точка входа для остального кода (`aniListApiProvider`). |
| `anilist_types.dart` | Исключения и data-классы (`AniListListEntry`, `AniListMalLookupResult`). |
| `anilist_queries.dart` | GraphQL-запросы как `static const`. Поля подобраны под реальное использование. |
| `anilist_graphql_client.dart` | Dio + маппинг ошибок Dio → `AniListApiException` / `AniListRateLimitException`. |
| `anilist_media_parser.dart` | Чистые парсеры `Page { media }` и fuzzy-дат. |
| `anilist_media_api.dart` | Поиск, бровзинг и получение по id для аниме и манги. |
| `anilist_mal_lookup_api.dart` | MAL id → AniList media. `*Tolerant` варианты переживают rate-limit и сообщают список несрезолвленных id. |
| `anilist_user_list_api.dart` | `MediaListCollection` — публичные списки пользователя (anime/manga). |

## Ключевые моменты

- **Батчинг.** AniList ограничивает `perPage` 50 элементов — см. `aniListMaxPerPage` в `anilist_queries.dart`. Запросы списком id режутся на батчи автоматически.
- **Rate limit.** HTTP 429 превращается в `AniListRateLimitException` с распарсенным `retryAfter` (`Retry-After` → `X-RateLimit-Reset` → 60s по умолчанию). `*Tolerant`-методы в MAL lookup ждут и повторяют батч до `maxRateLimitRetries` раз, остальные пробрасывают наверх.
- **GraphQL-ошибки приходят с HTTP 200.** Их разбирает caller через `unwrapData` / `logErrors`. В user-list дополнительно разбираются сообщения `"not found"` / `"private"` → типизированные исключения.
- **User lists.** Custom lists скипаются (дублируют записи из канонических). `isAdult: true` фильтруется.
- **Поля в запросах.** В запросах оставлены только поля, которые реально читаются в UI/моделях. Старые колонки БД (`mean_score`, `popularity`, `season`, `season_year`, `country_of_origin`, `next_airing_at`) сохранены для совместимости со старыми записями, но из API больше не приходят.

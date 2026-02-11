# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [Unreleased]

### Added
- Добавлена дизайн-система для тёмной темы: `AppColors`, `AppSpacing`, `AppTypography` (`lib/shared/theme/`)
- Добавлен `NavigationShell` с `NavigationRail` — боковая навигация (Home, Search, Settings)
- Добавлены виджеты: `SectionHeader` (заголовок секции с кнопкой действия)

### Removed
- Удалён неиспользуемый виджет `RatingBadge` (`lib/shared/widgets/rating_badge.dart`) и его тесты
- Удалён неиспользуемый виджет `PosterCard` (`lib/shared/widgets/poster_card.dart`) и его тесты
- Удалена неиспользуемая константа `AppColors.statusBacklog`
- Удалена неиспользуемая константа `AppSpacing.radiusLg`
- Удалена зависимость `cupertino_icons` (не используется в Windows-приложении)
- Удалены dev-зависимости `mockito` и `build_runner` (проект использует mocktail, генерируемых файлов нет)

### Changed
- Исправлена типизация `_handleWebMessage(dynamic)` → `_handleWebMessage(Object?)` в VGMaps панели
- Обновлён doc-комментарий в `CollectedItemInfo` — убрана ссылка на legacy-таблицу `collection_games`
- Добавлена таблица `tmdb_genres` в БД (миграция v12→v13) — кэш жанров TMDB (id, type, name)
- Добавлены методы `cacheTmdbGenres()` и `getTmdbGenreMap()` в `DatabaseService`
- Добавлены провайдеры `movieGenreMapProvider` и `tvGenreMapProvider` для быстрого маппинга ID→имя жанров
- Добавлена предзагрузка жанров TMDB при старте приложения (`_preloadTmdbGenres()` в `SettingsNotifier`)
- Добавлен авторезолвинг числовых genre_ids при загрузке элементов коллекции из БД (`_resolveGenresIfNeeded<T>()`)
- Добавлены изображения (постеры/обложки) в bottom sheets деталей фильмов и сериалов в поиске

### Changed
- Изменён `HomeScreen` — применена тёмная тема с `AppColors`, `SectionHeader`, `PosterCard` вместо `CollectionTile`
- Изменён `CollectionScreen` — применена тёмная тема: AppBar → SliverAppBar, статистика в виде цветных чипов, `PosterCard` grid для элементов
- Изменён `SearchScreen` — применена тёмная тема: AppBar, TabBar, SearchField, карточки результатов
- Изменены detail screens (Game, Movie, TvShow) — применена тёмная тема: SliverAppBar, секции, чипы
- Изменён `SettingsScreen` — применена тёмная тема: секции с бордерами, кнопки, диалоги
- Изменён `MediaCard` — переработан с `Card` на `Material` + `Container` + `InkWell` с `AppColors`/`AppTypography`
- Изменён `CollectionTile` — стилизация через `AppColors`
- Изменён `CreateCollectionDialog` — стилизация через `AppColors`
- Изменён `CachedImage` — стилизация placeholder/error через `AppColors`
- Изменены search widgets (`GameCard`, `MovieCard`, `TvShowCard`) — стилизация через `AppColors`
- Изменены filter/sort widgets (`PlatformFilterSheet`, `MediaFilterSheet`, `SortSelector`) — тёмная тема
- Изменён `genre_provider.dart` — DB-first стратегия загрузки жанров (БД → API → сохранение в БД)
- Изменён `media_search_provider.dart` — жанры резолвятся в имена ПЕРЕД сохранением в БД
- Изменён `app.dart` — корневой виджет оборачивает в `NavigationShell`
- Изменена версия БД: 12 → 13

### Fixed
- Исправлено отображение числовых ID вместо имён жанров в карточках фильмов и сериалов (TMDB Search API возвращает genre_ids)
- Исправлен потенциальный `FormatException` в `genre_provider.dart` — замена `int.parse` на `int.tryParse` с фильтрацией
- Исправлено мерцание canvas-изображений при перетаскивании (canvas_view.dart)

---

### Added
- Добавлена система дат активности элементов коллекции: `started_at`, `completed_at`, `last_activity_at` — для отслеживания прогресса и истории взаимодействия с играми, фильмами и сериалами
- Добавлена миграция БД v11→v12: три новых колонки в `collection_items`, инициализация `last_activity_at` из `added_at` для существующих записей
- Добавлен виджет `ActivityDatesSection` (`lib/features/collections/widgets/activity_dates_section.dart`) — секция с 4 строками: Added (readonly), Started (editable), Completed (editable), Last Activity (readonly). DatePicker для ручного редактирования дат
- Добавлен метод `updateItemActivityDates` в `DatabaseService` и `CollectionRepository` — ручное обновление дат через DatePicker
- Добавлены методы `updateActivityDates` в `CollectionGamesNotifier` и `CollectionItemsNotifier` — оптимистичное обновление дат в UI
- Добавлена автоматическая установка дат при смене статуса: `last_activity_at` обновляется всегда, `started_at` устанавливается при переходе в inProgress/Playing (если null), `completed_at` устанавливается при переходе в Completed
- Добавлено отображение даты просмотра (`watched_at`) в каждом эпизоде трекера сериалов

### Changed
- Изменён `updateItemStatus` в `DatabaseService` — теперь автоматически устанавливает даты активности при смене статуса (SELECT + UPDATE в одном вызове)
- Изменены модели `CollectionItem` и `CollectionGame` — добавлены поля `startedAt`, `completedAt`, `lastActivityAt`, обновлены `fromDb`, `toDb`, `copyWith`, `fromCollectionItem`, `toCollectionItem`
- Изменён `EpisodeTrackerState` — `watchedEpisodes` изменён с `Set<(int, int)>` на `Map<(int, int), DateTime?>` для хранения дат просмотра
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — добавлена секция `ActivityDatesSection` в `extraSections`
- Изменён `_EpisodeTile` в `TvShowDetailScreen` — отображает дату просмотра эпизода в subtitle

### Fixed
- Исправлена рассинхронизация статусов при возврате из `GameDetailScreen` в список коллекции: `CollectionGamesNotifier` теперь инвалидирует `collectionItemsNotifierProvider` при обновлении статуса, дат, комментариев — обеспечивая синхронизацию между двумя провайдерами

---

### Added
- Добавлена поддержка Android (Lite версия без Canvas)
- Добавлена Android конфигурация: `build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt`, иконки, стили
- Добавлен файл платформенных флагов `platform_features.dart` (`kCanvasEnabled`, `kVgMapsEnabled`, `kScreenshotEnabled`) — условное отключение Canvas, VGMaps, Screenshot на мобильных платформах
- Добавлена зависимость `sqflite: ^2.4.0` для нативной работы SQLite на Android

### Changed
- Изменён `database_service.dart` — `databaseFactoryFfi.openDatabase()` заменён на `databaseFactory.openDatabase()` для кроссплатформенной работы (FFI на desktop, нативный плагин на Android)
- Изменены `CollectionScreen`, `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — переключатель List/Canvas и вкладка Canvas скрыты на Android через `kCanvasEnabled`
- Обновлён `file_picker` с 6.2.1 до 10.3.10 — исправлена несовместимость v1 Android embedding с новыми версиями Flutter
- Обновлены транзитивные зависимости: `build_runner` 2.11.0, `hooks` 1.0.1, `objective_c` 9.3.0, `source_span` 1.10.2, `url_launcher_ios` 6.4.0

---

### Added
- Добавлен режим сортировки коллекции (`CollectionSortMode`): Date Added (по умолчанию), Status (активные первыми), Name (A-Z), Manual (ручной порядок). Режим сохраняется в SharedPreferences per collection
- Добавлен `CollectionSortNotifier` — провайдер режима сортировки с персистентным хранением в SharedPreferences
- Добавлен getter `statusSortPriority` в `ItemStatus` — приоритет для сортировки: inProgress(0) → planned(1) → notStarted(2) → onHold(3) → completed(4) → dropped(5)
- Добавлен UI-селектор сортировки (`_buildSortSelector`) между статистикой и списком элементов коллекции — компактный `PopupMenuButton` с иконкой, текущим режимом и dropdown меню
- Добавлено поле `sort_order` в таблицу `collection_items` (миграция БД v10→v11) для ручной сортировки drag-and-drop
- Добавлен `ReorderableListView` с drag handle в режиме Manual sort — элементы коллекции можно перетаскивать вверх/вниз
- Добавлены методы `getNextSortOrder()` и `reorderItems()` в `DatabaseService` для управления порядком элементов
- Добавлен метод `reorderItem()` в `CollectionItemsNotifier` — оптимистичное обновление UI + batch update sort_order в БД

### Changed
- Изменён `_CollectionItemTile` — маленький цветной бейдж типа медиа убран из обложки, вместо него добавлена наклонённая полупрозрачная фоновая иконка (200px, -0.3 rad, opacity 0.06) по центру карточки через `Stack` + `Positioned.fill` + `Transform.rotate`. Иконка обрезается `Clip.antiAlias` — виден только фрагмент как водяной знак. Cover упрощён с `Stack` до тернарного оператора
- Изменён `CollectionItemsNotifier` — добавлена реактивная сортировка через `ref.watch(collectionSortProvider)`, метод `_applySortMode()` применяет выбранный режим при загрузке и обновлении элементов
- Изменён `CollectionItem` — добавлено поле `sortOrder` (default 0), обновлены `fromDb`, `toDb`, `copyWith`, `internalDbFields`
- Изменён `_buildItemsList` — при Manual sort mode используется `ReorderableListView.builder` с кастомным drag handle вместо `ListView.builder`

### Added
- Добавлен формат экспорта v2: `.xcoll` (лёгкий — метаданные + ID элементов) и `.xcollx` (полный — + canvas + base64 обложки). Старый `.rcoll` поддерживается как legacy v1 (только импорт)
- Добавлен миксин `Exportable` (`lib/shared/models/exportable.dart`) — контракт `toExport()`, `internalDbFields`, `dbToExportKeyMapping`. Применён к `CanvasItem`, `CanvasConnection`, `CanvasViewport`, `Collection`, `CollectionItem`
- Добавлена модель `XcollFile` (`lib/core/services/xcoll_file.dart`) — контейнер файла экспорта/импорта с поддержкой v1 (games) и v2 (items, canvas, images). Вспомогательные классы: `ExportFormat`, `ExportCanvas`, `RcollGame`
- Добавлены методы `readImageBytes()` и `saveImageBytes()` в `ImageCacheService` — прямой доступ к байтам для экспорта/импорта обложек
- Добавлено встраивание кэшированных обложек в full export (`.xcollx`): `ExportService._collectCachedImages()` собирает base64-обложки всех элементов, `ImportService._restoreImages()` восстанавливает обложки в локальный кэш при импорте
- Добавлена стадия `ImportStage.importingImages` в enum для отслеживания прогресса восстановления обложек
- Добавлен `ImageType.canvasImage('canvas_images')` в enum `ImageType` — кэширование URL-изображений с канваса
- Добавлены тесты: `xcoll_file_test.dart`, обновлены `export_service_test.dart` (+24 тестов v2 + images), `import_service_test.dart` (+56 тестов v2 + per-item canvas + images), `canvas_image_item_test.dart` (+10 тестов)

### Changed
- Изменён `ExportService` — полная переработка: добавлены `createLightExport()`, `createFullExport()`, `exportToFile()` с диалогом сохранения. Зависимости: `CanvasRepository`, `ImageCacheService`. Сбор canvas-данных и per-item canvas при full export
- Изменён `ImportService` — полная переработка: добавлен `_importV2()` с поддержкой items, canvas (viewport + items + connections), per-item canvas, восстановление обложек. `_importV1()` для legacy .rcoll
- Изменён `CanvasImageItem` — переведён с `StatelessWidget` на `ConsumerWidget`, URL-изображения используют `CachedImage` с `ImageType.canvasImage` вместо `CachedNetworkImage` для диск-кэширования. Добавлена функция `urlToImageId()` (FNV-1a хэш для стабильных cache-ключей)
- Изменены модели: `Collection`, `CollectionItem`, `CanvasItem`, `CanvasConnection`, `CanvasViewport` — добавлены методы `toExport()` через миксин `Exportable`
- Изменён `HomeScreen` — import использует `.xcoll`, `.xcollx`, `.rcoll` расширения

- Добавлено локальное кэширование изображений (Task #13): обложки игр, постеры фильмов и сериалов скачиваются в локальное хранилище для оффлайн-работы
- Добавлены значения `moviePoster` и `tvShowPoster` в enum `ImageType` (`image_cache_service.dart`) для кэширования постеров фильмов и сериалов
- Добавлены параметры `memCacheWidth`, `memCacheHeight`, `autoDownload` в виджет `CachedImage` — pass-through для `CachedNetworkImage`, автоматическое скачивание в кэш при отсутствии локального файла
- Добавлены параметры `cacheImageType` и `cacheImageId` в `MediaCard` и `MediaDetailView` — при наличии используется `CachedImage` вместо `CachedNetworkImage`
- Добавлен метод `_getImageTypeForCache()` в `CollectionScreen._CollectionItemTile` — маппинг `MediaType` → `ImageType`

### Changed
- Изменён `CachedImage` — полностью переработана логика: при cache enabled + файл отсутствует показывается изображение из сети (fallback на remoteUrl) вместо иконки ошибки, с фоновой загрузкой в кэш через `addPostFrameCallback`
- Изменён `getImageUri` (`ImageCacheService`) — при cache enabled + файл отсутствует возвращает `ImageResult(uri: remoteUrl, isLocal: false, isMissing: true)` вместо `ImageResult(uri: null, isMissing: true)`
- Изменены `CanvasGameCard` и `CanvasMediaCard` — переведены с `StatelessWidget` на `ConsumerWidget`, используют `CachedImage` вместо `CachedNetworkImage`
- Изменён `CollectionScreen` — thumbnails коллекции используют `CachedImage` вместо `CachedNetworkImage`
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — передают `cacheImageType`/`cacheImageId` в `MediaDetailView`
- Изменён `SettingsScreen` — `FutureBuilder<List<dynamic>>` заменён на типизированный `FutureBuilder<(int, int)>` с Dart record для статистики кэша
- Обновлены тесты: `cached_image_test.dart` (13), `canvas_game_card_test.dart`, `canvas_media_card_test.dart` — добавлены ProviderScope, MockImageCacheService, тесты новых ImageType

---

### Added
- Добавлен `ConfigService` (`lib/core/services/config_service.dart`) — сервис экспорта/импорта конфигурации. Класс `ConfigResult` (success/failure/cancelled). Экспорт 7 ключей SharedPreferences в JSON через FilePicker, импорт с валидацией версии и типов
- Добавлен метод `DatabaseService.clearAllData()` — очистка всех 14 таблиц SQLite в одной транзакции с соблюдением порядка FK
- Добавлены методы `SettingsNotifier`: `exportConfig()`, `importConfig()`, `flushDatabase()` — делегирование ConfigService и DatabaseService с обновлением state
- Добавлена секция Configuration в `SettingsScreen` — кнопки Export Config и Import Config для выгрузки/загрузки API ключей
- Добавлена секция Danger Zone в `SettingsScreen` — кнопка Reset Database с диалогом подтверждения, очистка всех данных с сохранением настроек
- Добавлены тесты: `config_service_test.dart` (27), `settings_provider_flush_test.dart` (11), `settings_screen_config_test.dart` (15)

- Добавлена модель `TvEpisode` (`lib/shared/models/tv_episode.dart`) — эпизод сериала из TMDB с полями: tmdbShowId, seasonNumber, episodeNumber, name, overview, airDate, stillUrl, runtime. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`. Equality по (tmdbShowId, seasonNumber, episodeNumber)
- Добавлена миграция БД v9→v10: таблицы `tv_episodes_cache` (кэш эпизодов TMDB) и `watched_episodes` (трекинг просмотренных эпизодов по коллекциям, FK CASCADE на collections)
- Добавлены методы в `DatabaseService`: `getEpisodesByShowAndSeason`, `upsertEpisodes`, `clearEpisodesByShow`, `getWatchedEpisodes`, `markEpisodeWatched`, `markEpisodeUnwatched`, `getWatchedEpisodeCount`, `markSeasonWatched`, `unmarkSeasonWatched`
- Добавлен метод `TmdbApi.getSeasonEpisodes(int tmdbShowId, int seasonNumber)` — загрузка списка эпизодов сезона из TMDB API (`GET /tv/{id}/season/{number}`)
- Добавлен провайдер `EpisodeTrackerNotifier` (`lib/features/collections/providers/episode_tracker_provider.dart`) — NotifierProvider.family по ключу `({collectionId, showId})`. State: episodesBySeason, watchedEpisodes (Set<(int,int)>), loadingSeasons, error. Cache-first стратегия: БД → API → кэш. Автоматический статус Completed при просмотре всех эпизодов (сравнение с tvShow.totalEpisodes из метаданных)
- Добавлена секция Episode Progress в `TvShowDetailScreen`: LinearProgressIndicator с общим прогрессом, ExpansionTile для каждого сезона с ленивой загрузкой эпизодов, CheckboxListTile для отметки просмотра, кнопка Mark all / Unmark all для сезонов
- Добавлена кнопка Refresh в секции сезонов — принудительное обновление данных из TMDB API (новые сезоны/эпизоды добавляются, метаданные обновляются, watched-статусы сохраняются)
- Добавлен метод `EpisodeTrackerNotifier.refreshSeason()` — принудительная загрузка эпизодов сезона из API, минуя кэш
- Добавлен fallback при загрузке сезонов: если кэш БД пуст — автоматическая загрузка из TMDB API с кэшированием
- Добавлены тесты: `tv_episode_test.dart` (46), `episode_tracker_provider_test.dart` (36), обновлены `tmdb_api_test.dart` (+6 тестов getSeasonEpisodes), обновлены `tv_show_detail_screen_test.dart` (MockDatabaseService, MockTmdbApi, новые тесты Episode Progress)

### Changed
- Изменён `TvShowDetailScreen` — секция прогресса заменена с простых +/- кнопок (currentSeason/currentEpisode) на полноценный трекер эпизодов с ExpansionTile по сезонам, чекбоксами и автоматическим статусом Completed. Добавлены виджеты `_SeasonsListWidget`, `_SeasonExpansionTile`, `_EpisodeTile`

---

### Added
- Добавлен персональный Canvas для каждого элемента коллекции (per-item canvas): каждая игра, фильм или сериал имеет собственный холст, доступный через вкладку Canvas на экране деталей
- Добавлен `GameCanvasNotifier` (`lib/features/collections/providers/canvas_provider.dart`) — NotifierProvider.family по ключу `({collectionId, collectionItemId})`. Автоинициализация одним медиа-элементом, поддержка всех типов canvas-элементов (game/movie/tvShow/text/image/link)
- Добавлена миграция БД v8→v9: колонка `collection_item_id` в таблицах `canvas_items` и `canvas_connections`, индексы, таблица `game_canvas_viewport`
- Добавлены методы в `DatabaseService`: `getGameCanvasItems`, `getGameCanvasItemCount`, `getGameCanvasConnections`, `getGameCanvasViewport`, `upsertGameCanvasViewport`, `deleteGameCanvasItems`, `deleteGameCanvasConnections`, `deleteGameCanvasViewport`
- Добавлены методы в `CanvasRepository`: `getGameCanvasItems`, `getGameCanvasItemsWithData`, `hasGameCanvasItems`, `getGameCanvasViewport`, `saveGameCanvasViewport`, `getGameCanvasConnections`
- Добавлено поле `collectionItemId: int?` в модели `CanvasItem` и `CanvasConnection` (null для коллекционного canvas, значение для per-item)
- Добавлена сортировка результатов поиска: `SearchSort` с полями relevance/date/rating и направлением asc/desc. Виджет `SortSelector` с визуальным индикатором направления
- Добавлена фильтрация поиска TMDB: фильтр по году выпуска и жанрам. Виджет `MediaFilterSheet` (BottomSheet с DraggableScrollableSheet, FilterChip для жанров)
- Добавлены провайдеры жанров: `movieGenresProvider`, `tvGenresProvider` — кэширование списков жанров из TMDB API
- Добавлены параметры `year` и `firstAirDateYear` в методы `TmdbApi.searchMovies()` и `TmdbApi.searchTvShows()`
- Добавлены боковые панели SteamGridDB и VGMaps в экраны деталей (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`) — теперь панели доступны на per-item canvas, а не только на основном canvas коллекции
- Добавлены тесты: `search_sort_test.dart`, `sort_selector_test.dart`, `media_filter_sheet_test.dart`, `genre_provider_test.dart`, обновлены `game_search_provider_test.dart`, `media_search_provider_test.dart`, `tmdb_api_test.dart`, `canvas_item_test.dart`, `canvas_connection_test.dart`, `canvas_repository_test.dart`, `game_detail_screen_test.dart`, `movie_detail_screen_test.dart`, `tv_show_detail_screen_test.dart`

### Changed
- Изменены `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` — добавлен `TabBar` с вкладками Details и Canvas. Вкладка Details использует `MediaDetailView(embedded: true)`, вкладка Canvas содержит `CanvasView` с боковыми панелями SteamGridDB (320px) и VGMaps (500px)
- Изменён `MediaDetailView` — добавлен параметр `embedded: bool` (true = только контент без Scaffold, false = полный экран)
- Изменён `CanvasView` — принимает необязательный `collectionItemId` для работы с per-item canvas
- Изменён `SearchScreen` — добавлены `SortSelector` и `MediaFilterSheet` для сортировки и фильтрации результатов поиска
- Изменён `GameSearchNotifier` — добавлены методы `setSort()`, `_applySort()` с сортировкой по релевантности (exact match/startsWith/contains), дате и рейтингу
- Изменён `MediaSearchNotifier` — добавлены методы `setSort()`, `setYearFilter()`, `setGenreFilter()` с локальной фильтрацией по жанрам и серверной фильтрацией по году
- Изменён `CanvasRepository` — выделен приватный метод `_enrichItemsWithMediaData()` для переиспользования при обогащении данными Game/Movie/TvShow

### Fixed
- Исправлена утечка данных между per-item canvas и основным canvas коллекции: добавлен фильтр `AND collection_item_id IS NULL` в 6 SQL-методов `DatabaseService` (`getCanvasItems`, `deleteCanvasItemByRef`, `deleteCanvasItemsByCollection`, `getCanvasItemCount`, `getCanvasConnections`, `deleteCanvasConnectionsByCollection`)
- Исправлена проблема: боковые панели SteamGridDB и VGMaps не открывались на per-item canvas (виджеты панелей отсутствовали в widget tree detail-экранов)

---

### Added
- Добавлен виджет `SourceBadge` (`lib/shared/widgets/source_badge.dart`) — бейдж источника данных (IGDB, TMDB, SteamGridDB, VGMaps) с цветовой маркировкой и текстовой меткой. Размеры: small, medium, large
- Добавлен виджет `MediaCard` (`lib/shared/widgets/media_card.dart`) — базовый виджет карточки результата поиска: постер 60x80, название, subtitle, metadata, trailing-виджет. GameCard, MovieCard, TvShowCard переписаны как тонкие обёртки
- Добавлен виджет `MediaDetailView` (`lib/shared/widgets/media_detail_view.dart`) — базовый виджет экрана деталей медиа: постер 80x120, SourceBadge, info chips, описание, секция статуса, комментарии, заметки, диалог редактирования. GameDetailScreen, MovieDetailScreen, TvShowDetailScreen переписаны как тонкие обёртки
- Добавлена модель `MediaDetailChip` — чип с иконкой и текстом для отображения метаинформации (год, рейтинг, жанры и т.д.)
- Добавлен виджет `MediaTypeBadge` (`lib/shared/widgets/media_type_badge.dart`) — бейдж типа медиа с цветной иконкой (игра — синий, фильм — красный, сериал — зелёный)
- Добавлены константы `MediaTypeTheme` (`lib/shared/constants/media_type_theme.dart`) — цвета и иконки для визуального разделения типов медиа
- Добавлены тесты: `source_badge_test.dart`, `media_card_test.dart`, `media_detail_view_test.dart`, `media_type_badge_test.dart`, `media_type_theme_test.dart`
- Добавлено отображение фильмов и сериалов в коллекциях, деталях и канвасе (Stage 18)
- Добавлен виджет `ItemStatusDropdown` (`lib/features/collections/widgets/item_status_dropdown.dart`) — универсальный dropdown статуса с контекстными лейблами: "Playing"/"Watching" в зависимости от `MediaType`. Включает `ItemStatusChip` для read-only отображения. Полный и компактный режимы. Для сериалов включает статус `onHold`
- Добавлен виджет `CanvasMediaCard` (`lib/features/collections/widgets/canvas_media_card.dart`) — карточка фильма/сериала на канвасе по паттерну `CanvasGameCard`: постер, название, placeholder icon
- Добавлен экран `MovieDetailScreen` (`lib/features/collections/screens/movie_detail_screen.dart`) — тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+Movie на параметры виджета, info chips (год, runtime, жанры, рейтинг), статус через `ItemStatusDropdown`
- Добавлен экран `TvShowDetailScreen` (`lib/features/collections/screens/tv_show_detail_screen.dart`) — тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+TvShow на параметры виджета, info chips (год, сезоны, эпизоды, жанры, рейтинг, статус шоу), секция прогресса через `extraSections`
- Добавлены значения `movie` и `tvShow` в enum `CanvasItemType`, joined поля `Movie? movie` и `TvShow? tvShow` в модели `CanvasItem`, статический метод `CanvasItemType.fromMediaType()`, геттер `isMediaItem`
- Добавлен метод `deleteMediaItem(collectionId, CanvasItemType, refId)` в `CanvasRepository` для generic удаления по типу медиа
- Добавлен метод `removeMediaItem(MediaType, externalId)` в `CanvasNotifier` для generic удаления медиа из канваса
- Добавлены тесты: `item_status_dropdown_test.dart` (95), `canvas_media_card_test.dart` (19), `movie_detail_screen_test.dart` (38), `tv_show_detail_screen_test.dart` (39) — всего 191 новый тест Stage 18

### Changed
- Рефакторинг карточек поиска: `GameCard`, `MovieCard`, `TvShowCard` переписаны как тонкие обёртки над базовым `MediaCard` — удалено ~700 строк дублированного UI кода
- Рефакторинг экранов деталей: `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` переписаны как тонкие обёртки над базовым `MediaDetailView` — удалено ~1300 строк дублированного UI кода. Единый layout: постер 80x120 + SourceBadge + info chips + описание inline + статус + комментарии
- Добавлены бейджи `SourceBadge` в карточки поиска и экраны деталей для отображения источника данных (IGDB/TMDB)
- Добавлены цветные бордеры `MediaTypeBadge` на канвас-карточки (`CanvasGameCard`, `CanvasMediaCard`) для визуального разделения типов медиа
- Добавлены логотипы источников данных (IGDB, TMDB, SteamGridDB) на экран настроек рядом с полями API ключей
- Изменён `CollectionScreen` — полный переход с `CollectionGame`/`collectionGamesNotifierProvider` на `CollectionItem`/`collectionItemsNotifierProvider`: универсальная плитка `_CollectionItemTile` с иконкой типа медиа, контекстные подзаголовки (платформа/год+runtime/год+сезоны), навигация к `MovieDetailScreen`/`TvShowDetailScreen` по типу, `ItemStatusDropdown` вместо `StatusDropdown`
- Изменён `CanvasView` — добавлены switch cases для `CanvasItemType.movie` и `CanvasItemType.tvShow` с рендерингом `CanvasMediaCard`, типоспецифичные размеры (160x240 для movie/tvShow)
- Изменён `CanvasContextMenu` — флаг `showEdit` использует `!itemType.isMediaItem` для скрытия Edit у movie/tvShow (как у game)
- Изменён `CanvasRepository.getItemsWithData()` — загрузка и join Movie/TvShow данных из кэша помимо Game
- Изменён `CanvasRepository.initializeCanvas()` — определение `CanvasItemType` из `CollectionItem.mediaType` для всех типов медиа
- Изменён `CanvasNotifier._initializeFromItems()` — убран фильтр game-only, передаются все элементы коллекции
- Изменён `CanvasNotifier._syncCanvasWithItems()` — синхронизация всех типов медиа с маппингом `MediaType` → `CanvasItemType`
- Изменён `DatabaseService.deleteCanvasItemByRef()` — принимает параметр `itemType` вместо хардкода `'game'`

---

### Added
- Добавлен универсальный поиск с табами Games / Movies / TV Shows (Stage 17)
- Добавлен провайдер `MediaSearchNotifier` (`lib/features/search/providers/media_search_provider.dart`) — поиск фильмов и сериалов через TMDB API с debounce 400ms, переключение табов, кэширование результатов в БД
- Добавлен enum `MediaSearchTab` (movies, tvShows) и state `MediaSearchState` с copyWith, equality
- Добавлен виджет `MovieCard` (`lib/features/search/widgets/movie_card.dart`) — горизонтальная карточка фильма: постер 60x80, название, год, рейтинг, runtime, жанры
- Добавлен виджет `TvShowCard` (`lib/features/search/widgets/tv_show_card.dart`) — горизонтальная карточка сериала: постер 60x80, название, год, рейтинг, жанры, количество сезонов/эпизодов, статус
- Добавлены тесты: `media_search_provider_test.dart`, `movie_card_test.dart`, `tv_show_card_test.dart`

### Changed
- Изменён `SearchScreen` — добавлены TabBar/TabBarView с 3 табами (Games / Movies / TV Shows), общее поле поиска, фильтр платформ только для Games, bottom sheet деталей для фильмов/сериалов, добавление фильмов/сериалов в коллекцию через `collectionItemsNotifierProvider.addItem()` с кэшированием через `upsertMovies()`/`upsertTvShows()`
- Изменён `CollectionScreen` — "Add Game" → "Add Items", "No Games Yet" → "No Items Yet", "Add games to start..." → "Add items to start..." для соответствия универсальным коллекциям
- Изменён `CanvasView` — "Add games to the collection first" → "Add items to the collection first"

### Fixed
- Исправлен баг: подсказка в поле поиска не обновлялась при переключении табов (добавлен `setState` в `_onTabChanged()`)

---

### Added
- Добавлены универсальные коллекции с поддержкой фильмов и сериалов (Stage 16)
- Добавлена модель `CollectionItem` (`lib/shared/models/collection_item.dart`) — универсальный элемент коллекции с MediaType, ItemStatus, заменяет привязку к играм
- Добавлен enum `MediaType` (`lib/shared/models/media_type.dart`) — game, movie, tvShow с отображаемыми названиями
- Добавлен enum `ItemStatus` (`lib/shared/models/item_status.dart`) — notStarted, inProgress, completed, dropped, planned с label, emoji и цветом
- Добавлен `CollectionItemsNotifier` в `collections_provider.dart` — CRUD для универсальных элементов коллекции
- Добавлена миграция БД v7→v8: таблица `collection_items` с FK CASCADE, индексы по collection_id и media_type
- Добавлены методы в `DatabaseService`: `getCollectionItems`, `insertCollectionItem`, `updateCollectionItem`, `deleteCollectionItem`, `getCollectionItemCount`, `getCollectionItemsByType`
- Добавлены методы в `CollectionRepository`: `getItems`, `addItem`, `updateItemStatus`, `deleteItem`, `getItemCount`
- Добавлена обратная совместимость: `CollectionGame.fromCollectionItem()` адаптер, `canvasNotifierProvider` работает с обоими провайдерами
- Добавлены тесты: `collection_item_test.dart`, `media_type_test.dart`, `item_status_test.dart`, `collection_game_test.dart` (обновлён)

### Changed
- Изменён `CanvasNotifier` — слушает `collectionItemsNotifierProvider` для синхронизации канваса с универсальными коллекциями
- Изменён `CollectionGamesNotifier.refresh()` — инвалидирует `collectionItemsNotifierProvider` для двусторонней синхронизации
- Изменён `ExportService` / `ImportService` — поддержка универсальных элементов при экспорте/импорте

---

### Added
- Добавлена интеграция TMDB API для фильмов и сериалов (Stage 15)
- Добавлен API клиент `TmdbApi` (`lib/core/api/tmdb_api.dart`) — поиск фильмов/сериалов, детали, популярные, мультипоиск, списки жанров. OAuth через API key (Bearer token)
- Добавлена модель `Movie` (`lib/shared/models/movie.dart`) — фильм с полями: id, title, overview, posterPath, releaseDate, rating, genres, runtime и др. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена модель `TvShow` (`lib/shared/models/tv_show.dart`) — сериал с полями: id, title, overview, posterPath, firstAirDate, rating, genres, seasons, episodes, status. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена модель `TvSeason` (`lib/shared/models/tv_season.dart`) — сезон сериала. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()`
- Добавлена миграция БД до версии 7: таблицы `movies_cache`, `tv_shows_cache`, `tv_seasons_cache`
- Добавлена секция TMDB API Key в экран настроек для ввода и сохранения ключа
- Добавлено поле `tmdbApiKey` в `SettingsState` и метод `setTmdbApiKey()` в `SettingsNotifier`
- Добавлены тесты: `movie_test.dart` (105), `tv_show_test.dart`, `tv_season_test.dart`, `tmdb_api_test.dart` (81), обновлены `settings_provider_test.dart`, `settings_state_test.dart`

### Changed
- Изменён `DatabaseService` — версия БД увеличена до 7, добавлены 3 таблицы кэша
- Изменён `SettingsNotifier.build()` — инициализация TMDB API клиента
- Изменён `settings_screen.dart` — добавлена секция TMDB API key

---

### Added
- Добавлена боковая панель VGMaps Browser для канваса (Stage 12): встроенный WebView-браузер vgmaps.com для поиска и добавления карт уровней на канвас
- Добавлен провайдер `VgMapsPanelNotifier` (`lib/features/collections/providers/vgmaps_panel_provider.dart`) — NotifierProvider.family по collectionId. State: isOpen, currentUrl, canGoBack, canGoForward, isLoading, capturedImageUrl/Width/Height, error
- Добавлен виджет `VgMapsPanel` (`lib/features/collections/widgets/vgmaps_panel.dart`) — боковая панель 500px: заголовок, навигация (back/forward/home/reload), поиск по имени игры, WebView2 через `webview_windows`, JS injection для перехвата ПКМ на изображениях, bottom bar с превью и кнопкой "Add to Canvas"
- Добавлена кнопка FAB "VGMaps Browser" на тулбар канваса (иконка map, только в режиме редактирования)
- Добавлен пункт "Browse maps..." в контекстное меню пустого места канваса
- Добавлена зависимость `webview_windows: ^0.4.0` — нативный Edge WebView2 для Windows
- Добавлено взаимоисключение панелей: открытие VGMaps закрывает SteamGridDB и наоборот
- Добавлены тесты: `vgmaps_panel_provider_test.dart` (24), `vgmaps_panel_test.dart` (23), обновлены `canvas_view_test.dart` (+2), `canvas_context_menu_test.dart` (+3) — всего 52 теста Stage 12

### Changed
- Изменён `CollectionScreen` — добавлена вторая боковая панель VGMaps с AnimatedContainer (500px). Метод `_addVgMapsImage()` масштабирует карту до max 400px по ширине
- Изменён `CanvasView` — добавлена кнопка FAB VGMaps Browser, взаимоисключение панелей при toggle, `onBrowseMaps` callback в контекстное меню
- Изменён `CanvasContextMenu.showCanvasMenu()` — добавлен необязательный параметр `onBrowseMaps` и пункт "Browse maps..." с Icons.map

---

### Added
- Добавлена боковая панель SteamGridDB для канваса (Stage 10): поиск игр и добавление изображений (grids, heroes, logos, icons) прямо на канвас
- Добавлен провайдер `SteamGridDbPanelNotifier` (`lib/features/collections/providers/steamgriddb_panel_provider.dart`) — NotifierProvider.family по collectionId. Управление поиском игр, выбором типа изображений, in-memory кэш результатов API по ключу `gameId:imageType`
- Добавлен enum `SteamGridDbImageType` (grids/heroes/logos/icons) с отображаемыми лейблами
- Добавлен виджет `SteamGridDbPanel` (`lib/features/collections/widgets/steamgriddb_panel.dart`) — боковая панель 320px: заголовок, поле поиска (автозаполнение из названия коллекции), предупреждение об отсутствии API ключа, результаты поиска (ListView.builder с verified иконкой), SegmentedButton выбора типа, сетка thumbnail-ов (GridView.builder + CachedNetworkImage). Клик на изображение добавляет его на канвас
- Добавлена кнопка FAB "SteamGridDB Images" на тулбар канваса (иконка image_search, только в режиме редактирования)
- Добавлен пункт "Find images..." в контекстное меню пустого места канваса (с разделителем, только в режиме редактирования)
- Добавлены тесты: `steamgriddb_panel_provider_test.dart` (29), `steamgriddb_panel_test.dart` (28), обновлены `canvas_view_test.dart` (+4), `canvas_context_menu_test.dart` (+3) — всего 64 теста Stage 10

### Changed
- Изменён `CollectionScreen` — канвас обёрнут в Row с AnimatedContainer (200ms, easeInOut) для анимированного открытия/закрытия панели, `.select((s) => s.isOpen)` для минимизации rebuild. Метод `_addSteamGridDbImage()` масштабирует изображение до max 300px по ширине с сохранением пропорций
- Изменён `CanvasView` — добавлена кнопка FAB SteamGridDB перед существующими Center view и Reset positions, передаётся `onFindImages` callback в контекстное меню
- Изменён `CanvasContextMenu.showCanvasMenu()` — добавлен необязательный параметр `onFindImages` и пункт "Find images..." с PopupMenuDivider

---

### Added
- Добавлены связи Canvas (Stage 9): визуальные линии между элементами канваса с тремя стилями (solid, dashed, arrow), настраиваемым цветом и лейблами
- Добавлена модель `CanvasConnection` (`lib/shared/models/canvas_connection.dart`) — связь между двумя элементами канваса с полями: id, collectionId, fromItemId, toItemId, label, color (hex), style, createdAt
- Добавлен enum `ConnectionStyle` (solid/dashed/arrow) с `fromString()` конвертером
- Добавлен `CanvasConnectionPainter` (`lib/features/collections/widgets/canvas_connection_painter.dart`) — CustomPainter для рендеринга связей: solid (drawLine), dashed (PathMetrics), arrow (solid + треугольник). Hit-test на линии для контекстного меню
- Добавлен `EditConnectionDialog` (`lib/features/collections/widgets/dialogs/edit_connection_dialog.dart`) — диалог редактирования связи: TextField для label, 8 цветных кнопок, SegmentedButton для стиля (Solid/Dashed/Arrow)
- Добавлена миграция БД до версии 6: таблица `canvas_connections` с FK CASCADE на canvas_items (автоудаление при удалении элемента)
- Добавлены CRUD методы в `DatabaseService`: `getCanvasConnections`, `insertCanvasConnection`, `updateCanvasConnection`, `deleteCanvasConnection`, `deleteCanvasConnectionsByCollection`
- Добавлены методы в `CanvasRepository`: `getConnections`, `createConnection`, `updateConnection`, `deleteConnection`
- Добавлены методы в `CanvasNotifier`: `startConnection`, `completeConnection`, `cancelConnection`, `deleteConnection`, `updateConnection`
- Добавлен пункт "Connect" в контекстное меню элемента канваса — запускает режим создания связи
- Добавлено контекстное меню связей (ПКМ на линии) — Edit / Delete
- Добавлены тесты: `canvas_connection_test.dart` (25), `canvas_repository_connections_test.dart`, `canvas_provider_connections_test.dart`, `canvas_connection_painter_test.dart` (18), `edit_connection_dialog_test.dart`, `canvas_context_menu_connect_test.dart` (7)

### Changed
- Изменён `CanvasView` — добавлен слой CustomPaint для отрисовки связей под элементами, режим создания связи (курсор cell, временная пунктирная линия к курсору, баннер-индикатор, Escape для отмены), hit-test на линии для контекстного меню
- Изменён `CanvasNotifier` — поля `connections` и `connectingFromId` в `CanvasState`, параллельная загрузка connections через `Future.wait`, фильтрация connections при удалении элемента
- Изменён `CanvasContextMenu` — добавлен пункт Connect и метод `showConnectionMenu` для Edit/Delete связей
- Изменён `CanvasRepository` — добавлены 4 метода для CRUD связей
- Изменена `DatabaseService` — версия БД увеличена до 6, добавлена таблица canvas_connections с индексом

---

### Added
- Добавлены элементы Canvas (Stage 8): текстовые блоки, изображения, ссылки, контекстное меню, resize
- Добавлен `CanvasContextMenu` (`lib/features/collections/widgets/canvas_context_menu.dart`) — контекстное меню ПКМ: Add Text/Image/Link на пустом месте; Edit/Delete/Bring to Front/Send to Back на элементе
- Добавлен `CanvasTextItem` (`lib/features/collections/widgets/canvas_text_item.dart`) — текстовый блок с настраиваемым размером шрифта (Small 12/Medium 16/Large 24/Title 32)
- Добавлен `CanvasImageItem` (`lib/features/collections/widgets/canvas_image_item.dart`) — изображение по URL (CachedNetworkImage) или из файла (base64)
- Добавлен `CanvasLinkItem` (`lib/features/collections/widgets/canvas_link_item.dart`) — ссылка с иконкой, double-click открывает в браузере через url_launcher
- Добавлен `AddTextDialog` (`lib/features/collections/widgets/dialogs/add_text_dialog.dart`) — диалог создания/редактирования текста
- Добавлен `AddImageDialog` (`lib/features/collections/widgets/dialogs/add_image_dialog.dart`) — диалог добавления изображения (URL/файл)
- Добавлен `AddLinkDialog` (`lib/features/collections/widgets/dialogs/add_link_dialog.dart`) — диалог добавления/редактирования ссылки
- Добавлен resize handle для всех элементов канваса (14x14, правый нижний угол, мин. 50x50, макс. 2000x2000)
- Добавлены методы `addTextItem`, `addImageItem`, `addLinkItem`, `updateItemData`, `updateItemSize` в `CanvasNotifier`
- Добавлен метод `updateItemData` в `CanvasRepository` для обновления JSON data элемента
- Добавлена зависимость `url_launcher: ^6.2.0`
- Добавлены тесты: `canvas_context_menu_test.dart` (10), `canvas_text_item_test.dart` (8), `canvas_image_item_test.dart` (8), `canvas_link_item_test.dart` (9), `add_text_dialog_test.dart` (9), `add_link_dialog_test.dart` (11), `add_image_dialog_test.dart` (14), + 16 тестов для новых методов canvas_provider + 2 теста updateItemData в canvas_repository — всего 87 тестов Stage 8

### Changed
- Изменён `CanvasView` — добавлено контекстное меню (ПКМ), resize handle, рендеринг text/image/link элементов вместо SizedBox.shrink()
- Изменён `CanvasNotifier` — добавлены 5 методов для управления текстом, изображениями, ссылками и размерами
- Изменён `CanvasRepository` — добавлен метод `updateItemData` для обновления JSON-данных элемента

### Fixed
- Исправлен баг визуальной обратной связи при перетаскивании: элементы теперь двигаются в реальном времени вместо прыжка при отпускании мыши (замена `ValueNotifier + Transform.translate` на `setState + Positioned`)
- Исправлен баг визуальной обратной связи при ресайзе: размер элемента обновляется в реальном времени при перетаскивании handle
- Текстовые блоки на канвасе отображаются без фона — убран Container с цветом и бордером
- Добавлены типоспецифичные размеры по умолчанию: text 200x100, image 200x200, link 200x48 (ранее все типы использовали 150x200)
- Виджеты `CanvasImageItem`, `CanvasLinkItem` заменили фиксированные SizedBox на `SizedBox.expand()` для корректного ресайза

---

- Добавлен базовый Canvas — визуальный холст для свободного размещения элементов коллекции (Stage 7)
- Добавлена миграция БД до версии 5: таблицы `canvas_items` и `canvas_viewport` с FK CASCADE и индексами
- Добавлена модель `CanvasItem` (`lib/shared/models/canvas_item.dart`) с enum `CanvasItemType` (game/text/image/link)
- Добавлена модель `CanvasViewport` (`lib/shared/models/canvas_viewport.dart`) — хранение зума и позиции камеры
- Добавлен `CanvasRepository` (`lib/data/repositories/canvas_repository.dart`) — CRUD для canvas_items и viewport, инициализация сеткой
- Добавлен `CanvasNotifier` (`lib/features/collections/providers/canvas_provider.dart`) — state management канваса с debounced save (300ms position, 500ms viewport), двусторонняя синхронизация с коллекцией (реактивная через `ref.listen`)
- Добавлен `CanvasView` (`lib/features/collections/widgets/canvas_view.dart`) — InteractiveViewer с зумом 0.3–3.0x, drag-and-drop с абсолютным отслеживанием позиции, фоновая сетка, автоцентрирование
- Добавлен `CanvasGameCard` (`lib/features/collections/widgets/canvas_game_card.dart`) — компактная карточка игры с обложкой и названием
- Добавлен переключатель List/Canvas в `CollectionScreen` через `SegmentedButton`
- Добавлены CRUD методы в `DatabaseService`: `getCanvasItems`, `insertCanvasItem`, `updateCanvasItem`, `deleteCanvasItem`, `deleteCanvasItemByRef`, `deleteCanvasItemsByCollection`, `getCanvasItemCount`, `getCanvasViewport`, `upsertCanvasViewport`
- Добавлены тесты: `canvas_item_test.dart` (24), `canvas_viewport_test.dart` (17), `canvas_repository_test.dart` (27), `canvas_provider_test.dart` (45), `canvas_game_card_test.dart` (6), `canvas_view_test.dart` (30) — всего 149 тестов для Stage 7

### Changed
- Изменён `DatabaseService` — версия БД увеличена до 5, добавлены таблицы canvas_items и canvas_viewport
- Изменён `CollectionScreen` — добавлен SegmentedButton для переключения между List и Canvas режимами, синхронизация удаления игр с канвасом
- Оптимизирован `CanvasView` — кеширование `Theme.of(context)`, параллельная загрузка items и viewport

### Fixed
- Исправлен баг drag-and-drop: карточки двигались быстрее курсора из-за конфликта жестов InteractiveViewer и GestureDetector (переход на абсолютное отслеживание через `globalPosition`, блокировка `panEnabled` при drag)

---

- Добавлен API клиент SteamGridDB (`lib/core/api/steamgriddb_api.dart`): поиск игр, загрузка grids, heroes, logos, icons с Bearer token авторизацией
- Добавлена модель `SteamGridDbGame` (`lib/shared/models/steamgriddb_game.dart`) — результат поиска игры в SteamGridDB
- Добавлена модель `SteamGridDbImage` (`lib/shared/models/steamgriddb_image.dart`) — изображение из SteamGridDB (grids, heroes, logos, icons)
- Добавлен debug-экран SteamGridDB (`lib/features/settings/screens/steamgriddb_debug_screen.dart`) с 5 табами: Search, Grids, Heroes, Logos, Icons
- Добавлена секция SteamGridDB API Key в экран настроек для ввода и сохранения ключа
- Добавлена секция Developer Tools в настройках с навигацией на debug-экран (скрыта в release сборке через `kDebugMode`)
- Добавлен скилл `changelog-docs` для документирования изменений и актуализации docs
- Добавлен `steamGridDbApiProvider` — Riverpod провайдер для SteamGridDB API клиента
- Добавлено поле `steamGridDbApiKey` в `SettingsState` и метод `setSteamGridDbApiKey()` в `SettingsNotifier`
- Добавлены тесты: `steamgriddb_game_test.dart`, `steamgriddb_image_test.dart`, `steamgriddb_api_test.dart`

### Changed
- Изменён `SettingsKeys` — добавлен ключ `steamGridDbApiKey`
- Изменён `SettingsNotifier.build()` — теперь также инициализирует SteamGridDB API клиент
- Изменён `SettingsNotifier.clearSettings()` — очищает также SteamGridDB API ключ
- Изменён `settings_screen.dart` — добавлены секции SteamGridDB API и Developer Tools
- Обновлены тесты `settings_state_test.dart` и `settings_screen_test.dart` для покрытия новых полей

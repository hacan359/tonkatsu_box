# Архитектура Tonkatsu Box

## Обзор

Tonkatsu Box — кроссплатформенное приложение на Flutter для управления коллекциями ретро-игр, фильмов и сериалов с интеграцией IGDB, TMDB и SteamGridDB API.

| Слой | Технология |
|------|------------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Database | SQLite (sqflite_ffi на desktop, sqflite на Android) |
| API | IGDB (Twitch OAuth), TMDB (Bearer token), SteamGridDB (Bearer token) |
| Platform | Windows Desktop, Android (VGMaps недоступен) |

---

## Структура проекта

```
lib/
├── main.dart                 # Точка входа
├── app.dart                  # Корневой виджет
├── core/                     # Ядро (API, БД)
├── data/                     # Репозитории
├── features/                 # Фичи (экраны, виджеты)
└── shared/                   # Общие модели
```

---

## Файлы и их назначение

### Точка входа

| Файл | Назначение |
|------|------------|
| `lib/main.dart` | Инициализация Flutter, SQLite, SharedPreferences. Запуск приложения через `ProviderScope` |
| `lib/app.dart` | Корневой виджет `TonkatsuBoxApp`. Настройка темы (Material 3), роутинг на основе состояния API |

---

### Core (Ядро)

| Файл | Назначение |
|------|------------|
| `lib/core/api/igdb_api.dart` | **IGDB API клиент**. OAuth через Twitch, поиск игр, загрузка платформ. Методы: `getAccessToken()`, `searchGames()`, `fetchPlatforms()` |
| `lib/core/api/steamgriddb_api.dart` | **SteamGridDB API клиент**. Bearer token авторизация. Методы: `searchGames()`, `getGrids()`, `getHeroes()`, `getLogos()`, `getIcons()` |
| `lib/core/api/tmdb_api.dart` | **TMDB API клиент**. Bearer token авторизация. Методы: `searchMovies(query, {year})`, `searchTvShows(query, {firstAirDateYear})`, `multiSearch()`, `getMovieDetails()`, `getTvShowDetails()`, `getPopularMovies()`, `getPopularTvShows()`, `getMovieGenres()`, `getTvGenres()`, `getSeasonEpisodes(tmdbShowId, seasonNumber)` |
| `lib/shared/constants/platform_features.dart` | **Флаги платформы**. `kCanvasEnabled` (true на всех платформах), `kVgMapsEnabled` (только Windows), `kScreenshotEnabled` (только Windows). VGMaps скрыт на не-Windows платформах |
| `lib/core/database/database_service.dart` | **SQLite сервис**. Создание таблиц, миграции (версия 14), CRUD для всех сущностей. Использует `databaseFactory.openDatabase()` — кроссплатформенный вызов (FFI на desktop, нативный плагин на Android). Таблицы: `platforms`, `games`, `collections`, `collection_items`, `canvas_items`, `canvas_viewport`, `canvas_connections`, `game_canvas_viewport`, `movies_cache`, `tv_shows_cache`, `tv_seasons_cache`, `tv_episodes_cache`, `watched_episodes`, `tmdb_genres`. Миграция v14: `UPDATE collection_items SET status='in_progress' WHERE status='playing'`. Методы кэша жанров: `cacheTmdbGenres()`, `getTmdbGenreMap()`. Авторезолвинг числовых genre_ids при загрузке коллекций: `_resolveGenresIfNeeded<T>()`. `updateItemStatus` автоматически устанавливает даты активности при смене статуса. `updateItemActivityDates` для ручного обновления дат. Методы per-item canvas: `getGameCanvasItems`, `getGameCanvasConnections`, `getGameCanvasViewport`, `upsertGameCanvasViewport`. Методы эпизодов: `getEpisodesByShowAndSeason`, `upsertEpisodes`, `clearEpisodesByShow`, `getWatchedEpisodes` (возвращает `Map<(int, int), DateTime?>` с датами просмотра), `markEpisodeWatched`, `markEpisodeUnwatched`, `getWatchedEpisodeCount`, `markSeasonWatched`, `unmarkSeasonWatched`. Изоляция данных: коллекционные методы фильтруют `collection_item_id IS NULL`. Метод `clearAllData()` — очистка всех 15 таблиц в транзакции |
| `lib/core/services/config_service.dart` | **Сервис конфигурации**. Экспорт/импорт 7 ключей SharedPreferences в JSON файл. Класс `ConfigResult` (success/failure/cancelled). Методы: `collectSettings()`, `applySettings()`, `exportToFile()`, `importFromFile()` |
| `lib/core/services/image_cache_service.dart` | **Сервис кэширования изображений**. Enum `ImageType` (platformLogo, gameCover, moviePoster, tvShowPoster, canvasImage). Локальное хранение изображений в папках по типу. SharedPreferences для enable/disable и custom path. Валидация magic bytes (JPEG/PNG/WebP) при скачивании и при чтении из кэша. Безопасное удаление файлов (`_tryDelete`) при Windows file lock. Методы: `getImageUri()` (cache-first с fallback на remoteUrl + magic bytes проверка), `downloadImage()` (+ валидация), `downloadImages()`, `readImageBytes()`, `saveImageBytes()`, `clearCache()`, `getCacheSize()`, `getCachedCount()`. Провайдер `imageCacheServiceProvider` |
| `lib/core/services/xcoll_file.dart` | **Модель файла экспорта/импорта**. Формат v2 (.xcoll/.xcollx, items + canvas + images). Классы: `XcollFile`, `ExportFormat` (light/full), `ExportCanvas`. Файлы v1 выбрасывают `FormatException` |
| `lib/core/services/export_service.dart` | **Сервис экспорта**. Создаёт XcollFile из коллекции. Режимы: v2 light (.xcoll — ID элементов), v2 full (.xcollx — + canvas + per-item canvas + base64 обложки). Зависимости: `CanvasRepository`, `ImageCacheService`. Методы: `createLightExport()`, `createFullExport()`, `exportToFile()` |
| `lib/core/services/import_service.dart` | **Сервис импорта**. Импортирует XcollFile в коллекцию. items + canvas (viewport/items/connections) + per-item canvas + восстановление обложек из base64. Прогресс через `ImportStage` enum и `ImportProgressCallback`. Зависимости: `DatabaseService`, `CanvasRepository`, `GameRepository`, `ImageCacheService` |

---

### Models (Модели данных)

| Файл | Назначение |
|------|------------|
| `lib/shared/models/game.dart` | **Модель игры**. Поля: id, name, summary, coverUrl, releaseDate, rating, genres, platformIds. Методы: `fromJson()`, `fromDb()`, `toDb()` |
| `lib/shared/models/platform.dart` | **Модель платформы**. Поля: id, name, abbreviation. Свойство `displayName` возвращает сокращение или полное имя |
| `lib/shared/models/collection.dart` | **Модель коллекции**. Типы: `own`, `imported`, `fork`. Поля для форков: `originalSnapshot`, `forkedFromAuthor` |
| ~~`lib/shared/models/collection_game.dart`~~ | **Удалён**. Заменён на `CollectionItem` с `MediaType` и `ItemStatus` |
| `lib/shared/models/steamgriddb_game.dart` | **Модель SteamGridDB игры**. Поля: id, name, types, verified. Метод: `fromJson()` |
| `lib/shared/models/steamgriddb_image.dart` | **Модель SteamGridDB изображения**. Поля: id, score, style, url, thumb, width, height, mime, author. Свойство `dimensions` |
| `lib/shared/models/collection_item.dart` | **Модель универсального элемента коллекции**. Поля: id, collectionId, mediaType, externalId, platformId, sortOrder, status, authorComment, userComment, addedAt, startedAt, completedAt, lastActivityAt. Методы: `fromDb()`, `toDb()`, `copyWith()`. `sortOrder` используется для ручной сортировки drag-and-drop. Даты хранятся как Unix seconds |
| `lib/shared/models/media_type.dart` | **Enum типа медиа**. Значения: `game`, `movie`, `tvShow`, `animation`. `AnimationSource` — abstract final class с константами `movie = 0`, `tvShow = 1` для дискриминации источника анимации через `platform_id`. Свойства: `label`, `icon`. Методы: `fromString()` |
| `lib/shared/models/item_status.dart` | **Enum статуса элемента**. Значения: `notStarted`, `inProgress`, `completed`, `dropped`, `planned`, `onHold`. Свойства: `label`, `emoji`, `color`, `statusSortPriority`. Методы: `fromString()`, `displayLabel()` |
| `lib/shared/models/collection_sort_mode.dart` | **Enum режима сортировки коллекции**. Значения: `manual`, `addedDate`, `status`, `name`. Свойства: `value`, `displayLabel`, `description`. Метод: `fromString()`. Хранится в SharedPreferences per collection |
| `lib/shared/models/movie.dart` | **Модель фильма**. Поля: id, title, overview, posterPath, releaseDate, rating, genres, runtime и др. Свойства: `posterUrl`, `releaseYear`, `ratingString`, `genresString`. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/tv_show.dart` | **Модель сериала**. Поля: id, title, overview, posterPath, firstAirDate, rating, genres, seasons, episodes, status. Свойства: `posterUrl`, `releaseYear`, `ratingString`, `genresString`. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/tv_season.dart` | **Модель сезона сериала**. Поля: id, tvShowId, seasonNumber, name, overview, posterPath, airDate, episodeCount. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/tv_episode.dart` | **Модель эпизода сериала**. Поля: tmdbShowId, seasonNumber, episodeNumber, name, overview, airDate, stillUrl, runtime. Equality по (tmdbShowId, seasonNumber, episodeNumber). Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/canvas_item.dart` | **Модель элемента канваса**. Enum `CanvasItemType` (game/movie/tvShow/animation/text/image/link). Поля: id, collectionId, collectionItemId (null для коллекционного canvas, int для per-item), itemType, itemRefId, x, y, width, height, zIndex, data (JSON). Joined поля: `game: Game?`, `movie: Movie?`, `tvShow: TvShow?`. Статический метод `CanvasItemType.fromMediaType()`, геттер `isMediaItem` |
| `lib/shared/models/canvas_viewport.dart` | **Модель viewport канваса**. Поля: collectionId, scale, offsetX, offsetY. Хранит зум и позицию камеры |
| `lib/shared/models/canvas_connection.dart` | **Модель связи канваса**. Enum `ConnectionStyle` (solid/dashed/arrow). Поля: id, collectionId, collectionItemId (null для коллекционного canvas, int для per-item), fromItemId, toItemId, label, color (hex), style, createdAt |

---

### Features: Collections (Коллекции)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/collections/screens/home_screen.dart` | **Главный экран**. Список коллекций с группировкой (My/Forked/Imported). AppBar с кнопкой "+" для создания и Import. Меню: rename, fork, delete |
| `lib/features/collections/screens/collection_screen.dart` | **Экран коллекции**. Заголовок со статистикой (прогресс-бар), список элементов. Кнопка "Add Items" открывает SearchScreen. Поддержка игр, фильмов, сериалов и анимации через `CollectionItem`/`collectionItemsNotifierProvider`. Навигация к `GameDetailScreen`/`MovieDetailScreen`/`TvShowDetailScreen`/`AnimeDetailScreen` по типу. Filter chips: All/Games/Movies/TV Shows/Animation. `_CollectionItemTile` — карточка с большой полупрозрачной фоновой иконкой типа медиа (Stack + Positioned) |
| `lib/features/collections/screens/game_detail_screen.dart` | **Экран деталей игры**. TabBar с 2 вкладками: Details (`MediaDetailView(embedded: true)` с info chips, StatusChipRow) и Canvas (CanvasView + боковые панели SteamGridDB/VGMaps). Использует `gameCanvasNotifierProvider` для per-item canvas |
| `lib/features/collections/screens/movie_detail_screen.dart` | **Экран деталей фильма**. TabBar с 2 вкладками: Details (`MediaDetailView(embedded: true)` с info chips, StatusChipRow) и Canvas (CanvasView + боковые панели SteamGridDB/VGMaps). Использует `gameCanvasNotifierProvider` для per-item canvas |
| `lib/features/collections/screens/tv_show_detail_screen.dart` | **Экран деталей сериала**. TabBar с 2 вкладками: Details (`MediaDetailView(embedded: true)` с info chips, Episode Progress с трекером эпизодов по сезонам, StatusChipRow) и Canvas (CanvasView + боковые панели SteamGridDB/VGMaps). Виджеты `_SeasonsListWidget`, `_SeasonExpansionTile`, `_EpisodeTile` — ExpansionTile по сезонам с lazy-loading эпизодов и чекбоксами просмотра. Использует `episodeTrackerNotifierProvider` и `gameCanvasNotifierProvider` для per-item canvas |
| `lib/features/collections/screens/anime_detail_screen.dart` | **Экран деталей анимации**. Адаптивный: movie-like layout для `AnimationSource.movie` (runtime, без episode tracker), tvShow-like layout для `AnimationSource.tvShow` (episode tracker по сезонам с чекбоксами). Accent color: `AppColors.animationAccent` (фиолетовый). TabBar: Details + Canvas (если kCanvasEnabled). Приватные виджеты: `_AnimeSeasonsListWidget`, `_AnimeSeasonExpansionTile`, `_AnimeEpisodeTile`. Использует `episodeTrackerNotifierProvider` и `gameCanvasNotifierProvider` |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/collections/widgets/activity_dates_section.dart` | **Секция дат активности**. StatelessWidget: Added (readonly), Started (editable), Completed (editable), Last Activity (readonly). DatePicker для ручного редактирования. `_DateRow` — приватный виджет строки с иконкой, меткой и датой. `OnDateChanged` typedef для callback |
| `lib/features/collections/widgets/collection_tile.dart` | **Плитка коллекции**. Показывает имя, автора, тип, количество игр. Иконка удаления |
| `lib/features/collections/widgets/create_collection_dialog.dart` | **Диалоги**. Создание, переименование, удаление коллекции |
| `lib/features/collections/widgets/status_chip_row.dart` | **Ряд чипов выбора статуса**. Горизонтальный `Wrap` с кастомными chip-кнопками. Выбранный чип: цветной фон, жирный текст, цветная рамка. `onHold` только для сериалов. Используется на detail-экранах |
| `lib/features/collections/widgets/status_ribbon.dart` | **Диагональная ленточка статуса**. Display-only `Positioned` + `Transform.rotate(-45°)` в верхнем левом углу list-карточек. Emoji + метка, цвет = `status.color`. Не показывается для `notStarted` |
| `lib/features/collections/widgets/canvas_media_card.dart` | **Карточка фильма/сериала на канвасе**. ConsumerWidget. Постер через CachedImage (moviePoster/tvShowPoster), название, placeholder icon (movie/tv). По паттерну CanvasGameCard |
| `lib/features/collections/widgets/canvas_view.dart` | **Canvas View**. InteractiveViewer с зумом 0.3–3.0x, панорамированием, drag-and-drop (абсолютное отслеживание позиции). Фоновая сетка (CustomPainter), автоцентрирование |
| `lib/features/collections/widgets/canvas_game_card.dart` | **Карточка игры на канвасе**. ConsumerWidget. Компактная карточка 160x220px с обложкой через CachedImage (gameCover) и названием |
| `lib/features/collections/widgets/canvas_context_menu.dart` | **Контекстное меню канваса**. ПКМ на пустом месте: Add Text/Image/Link. ПКМ на элементе: Edit/Delete/Bring to Front/Send to Back/Connect. ПКМ на связи: Edit/Delete. Delete с диалогом подтверждения |
| `lib/features/collections/widgets/canvas_connection_painter.dart` | **CustomPainter для связей**. Рисует solid/dashed/arrow линии между центрами элементов. Лейблы с фоном в середине линии. Hit-test для определения клика на линии. Временная пунктирная линия при создании связи |
| `lib/features/collections/widgets/canvas_text_item.dart` | **Текстовый блок на канвасе**. Настраиваемый fontSize (12/16/24/32). Container с padding, фоном surfaceContainerLow |
| `lib/features/collections/widgets/canvas_image_item.dart` | **Изображение на канвасе**. ConsumerWidget. URL (CachedImage с ImageType.canvasImage, FNV-1a хэш URL как imageId) или base64 (Image.memory). Card с Clip.antiAlias, размер по умолчанию 200x200. Функция `urlToImageId()` для стабильных cache-ключей |
| `lib/features/collections/widgets/canvas_link_item.dart` | **Ссылка на канвасе**. Card с иконкой и подчёркнутым текстом. Double-tap → url_launcher. Размер по умолчанию 200x48 |
| `lib/features/collections/widgets/steamgriddb_panel.dart` | **Боковая панель SteamGridDB**. Поиск игр, выбор типа изображений (SegmentedButton), сетка thumbnail-ов (GridView.builder + CachedNetworkImage). Автозаполнение поиска из названия коллекции. Клик на изображение → добавление на канвас |
| `lib/features/collections/widgets/vgmaps_panel.dart` | **Боковая панель VGMaps Browser**. WebView2 (webview_windows) для просмотра vgmaps.de. Навигация (back/forward/home/reload), поиск по имени игры, JS injection для перехвата ПКМ на `<img>`, bottom bar с превью и "Add to Board". Ширина 500px. Взаимоисключение с SteamGridDB панелью. Доступен только на Windows (`kVgMapsEnabled`) |

#### Диалоги

| Файл | Назначение |
|------|------------|
| `lib/features/collections/widgets/dialogs/add_text_dialog.dart` | **Диалог текста**. TextField (multiline) + DropdownButtonFormField (Small/Medium/Large/Title). Возвращает {content, fontSize} |
| `lib/features/collections/widgets/dialogs/add_image_dialog.dart` | **Диалог изображения**. SegmentedButton (URL/File). URL: TextField + CachedNetworkImage preview. File: FilePicker + base64. Возвращает {url} или {base64, mimeType} |
| `lib/features/collections/widgets/dialogs/add_link_dialog.dart` | **Диалог ссылки**. TextField URL (валидация http/https) + Label (optional). Возвращает {url, label} |
| `lib/features/collections/widgets/dialogs/edit_connection_dialog.dart` | **Диалог редактирования связи**. TextField для label, Wrap из 8 цветных кнопок (серый, красный, оранжевый, жёлтый, зелёный, синий, фиолетовый, чёрный), SegmentedButton для стиля (Solid/Dashed/Arrow). Возвращает {label, color, style} |

#### Провайдеры

| Файл | Назначение |
|------|------------|
| `lib/features/collections/providers/collections_provider.dart` | **State management коллекций**. `collectionsProvider` — список. `collectionItemsNotifierProvider` — универсальные элементы коллекции (games/movies/tvShows/animation) с CRUD, реактивной сортировкой и оптимистичным обновлением дат активности. `collectionSortProvider` — режим сортировки per collection (SharedPreferences) |
| `lib/features/collections/providers/steamgriddb_panel_provider.dart` | **State management панели SteamGridDB**. `steamGridDbPanelProvider` — NotifierProvider.family по collectionId. Enum `SteamGridDbImageType` (grids/heroes/logos/icons). State: isOpen, searchTerm, searchResults, selectedGame, selectedImageType, images, isSearching, isLoadingImages, searchError, imageError, imageCache. Методы: togglePanel, openPanel, closePanel, searchGames, selectGame, clearGameSelection, selectImageType. In-memory кэш по ключу `gameId:imageType` |
| `lib/features/collections/providers/vgmaps_panel_provider.dart` | **State management панели VGMaps**. `vgMapsPanelProvider` — NotifierProvider.family по collectionId. State: isOpen, currentUrl, canGoBack, canGoForward, isLoading, capturedImageUrl/Width/Height, error. Методы: togglePanel, openPanel, closePanel, setCurrentUrl, setNavigationState, setLoading, captureImage, clearCapturedImage, setError, clearError |
| `lib/features/collections/providers/episode_tracker_provider.dart` | **State management трекера эпизодов**. `episodeTrackerNotifierProvider` — NotifierProvider.family по `({collectionId, showId})`. State: episodesBySeason (Map<int, List<TvEpisode>>), watchedEpisodes (Map<(int,int), DateTime?>), loadingSeasons, error. Методы: loadSeason (cache-first: DB → API → DB), toggleEpisode, toggleSeason, isEpisodeWatched, watchedCountForSeason, totalWatchedCount, getWatchedAt. Автоматический переход в Completed при просмотре всех эпизодов (сравнение с tvShow.totalEpisodes) |
| `lib/features/collections/providers/canvas_provider.dart` | **State management канваса**. `canvasNotifierProvider` — NotifierProvider.family по collectionId (коллекционный canvas). `gameCanvasNotifierProvider` — NotifierProvider.family по `({collectionId, collectionItemId})` (per-item canvas). Оба реализуют общий интерфейс методов: moveItem, updateViewport, addItem, deleteItem, bringToFront, sendToBack, removeMediaItem, addTextItem, addImageItem, addLinkItem, updateItemData, updateItemSize, startConnection, completeConnection, cancelConnection, deleteConnection, updateConnection. Debounced save (300ms position, 500ms viewport). Коллекционный canvas синхронизируется с коллекцией через `ref.listen`. Per-item canvas автоинициализируется одним медиа-элементом |

---

### Features: Search (Поиск)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/search/screens/search_screen.dart` | **Экран поиска**. TabBar с 4 табами: Games / Movies / TV Shows / Animation. Общее поле ввода с debounce, фильтр платформ (только Games), сортировка (SortSelector), фильтры медиа (год, жанры через MediaFilterSheet). Animation tab объединяет animated movies + TV shows (genre_id=16), исключая их из Movies/TV Shows табов. При `collectionId` — добавляет игры/фильмы/сериалы/анимацию в коллекцию через `collectionItemsNotifierProvider`. Bottom sheet с деталями |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/search/widgets/game_card.dart` | **Карточка игры**. Тонкая обёртка над `MediaCard`: маппинг Game на параметры виджета, SourceBadge IGDB, subtitle (год, рейтинг), metadata (жанры, платформы) |
| `lib/features/search/widgets/movie_card.dart` | **Карточка фильма**. Тонкая обёртка над `MediaCard`: маппинг Movie на параметры виджета, SourceBadge TMDB, subtitle (год, рейтинг, runtime), metadata (жанры) |
| `lib/features/search/widgets/tv_show_card.dart` | **Карточка сериала**. Тонкая обёртка над `MediaCard`: маппинг TvShow на параметры виджета, SourceBadge TMDB, subtitle (год, рейтинг, сезоны), metadata (жанры, статус) |
| `lib/features/search/widgets/animation_card.dart` | **Карточка анимации**. Обёртка над `MediaCard`: принимает `Movie?` или `TvShow?` + флаг `isMovie`. SourceBadge TMDB, бейдж "Movie"/"Series", subtitle (год, рейтинг, runtime или seasons) |
| `lib/features/search/widgets/platform_filter_sheet.dart` | **Bottom sheet фильтра платформ**. Мультивыбор платформ с поиском. Кнопки Clear All / Apply |
| `lib/features/search/widgets/sort_selector.dart` | **Селектор сортировки**. SegmentedButton с 3 опциями (Relevance, Date, Rating). Переключение направления при клике на активный сегмент. Визуальный индикатор ↑↓ |
| `lib/features/search/widgets/media_filter_sheet.dart` | **Bottom sheet фильтров медиа**. DraggableScrollableSheet с фильтрами: Release Year (TextField), Genres (FilterChip). Кнопка Clear All |

#### Провайдеры

| Файл | Назначение |
|------|------------|
| `lib/features/search/providers/game_search_provider.dart` | **State поиска игр**. Debounce 400ms, минимум 2 символа. Фильтр по платформам. Сортировка (relevance/date/rating). Состояние: query, results, isLoading, error, currentSort |
| `lib/features/search/providers/media_search_provider.dart` | **State поиска фильмов/сериалов/анимации**. Debounce 400ms через TMDB API. Enum `MediaSearchTab` (movies, tvShows, animation). Animation tab: `Future.wait([searchMovies, searchTvShows])` → фильтрация по genre_id=16. Movies/TV Shows табы исключают анимацию. Состояние: query, movieResults, tvShowResults, animationMovieResults, animationTvShowResults, isLoading, error, activeTab, currentSort, selectedYear, selectedGenreIds. Кэширование через `upsertMovies()`/`upsertTvShows()` |
| `lib/features/search/providers/genre_provider.dart` | **Провайдеры жанров**. `movieGenresProvider`, `tvGenresProvider` — FutureProvider для кэширования списков жанров из TMDB API. `movieGenreMapProvider`, `tvGenreMapProvider` — маппинг ID→имя для быстрого резолвинга genre_ids. DB-first стратегия: загрузка из таблицы `tmdb_genres`, при пустом кэше — запрос к API и сохранение |

---

### Shared (Общие виджеты, тема и константы)

#### Тема

| Файл | Назначение |
|------|------------|
| `lib/shared/theme/app_colors.dart` | **Цвета тёмной темы**. Статические константы: background (#0A0A0A), surface (#141414), surfaceLight, surfaceBorder, textPrimary (#FFFFFF), textSecondary, textTertiary, gameAccent, movieAccent, tvShowAccent, animationAccent (#CE93D8), ratingHigh/Medium/Low, statusInProgress/Completed/OnHold/Dropped/Planned |
| `lib/shared/theme/app_spacing.dart` | **Отступы и радиусы**. Отступы: xs(4), sm(8), md(16), lg(24), xl(32). Радиусы: radiusXs(4), radiusSm(8), radiusMd(12), radiusLg(16), radiusXl(20). Сетка: posterAspectRatio(2:3), gridColumnsDesktop(4)/Tablet(3)/Mobile(2) |
| `lib/shared/theme/app_typography.dart` | **Типографика (Inter)**. TextStyle: h1(28 bold, -0.5ls), h2(20 w600, -0.2ls), h3(16 w600), body(14), bodySmall(12), caption(11), posterTitle(14 w600), posterSubtitle(11). fontFamily: 'Inter' |
| `lib/shared/theme/app_theme.dart` | **Централизованная тёмная тема**. ThemeData с Brightness.dark принудительно, ColorScheme.dark из AppColors, стилизация AppBar/Card/Input/Dialog/BottomSheet/Chip/Button/NavigationRail/NavigationBar/TabBar |

#### Навигация

| Файл | Назначение |
|------|------------|
| `lib/shared/navigation/navigation_shell.dart` | **NavigationShell**. Адаптивная навигация: `NavigationRail` (боковая панель) при ширине ≥800px, `BottomNavigationBar` при <800px. Табы: Home, Search, Settings. IndexedStack для сохранения состояния |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/shared/widgets/section_header.dart` | **SectionHeader**. Заголовок секции с опциональной кнопкой действия справа |
| `lib/shared/widgets/cached_image.dart` | **Виджет кэшированного изображения**. ConsumerWidget с FutureBuilder. Логика: cache disabled → CachedNetworkImage, cache enabled + file → Image.file, cache enabled + no file → CachedNetworkImage + фоновый download через addPostFrameCallback. Параметры: imageType, imageId, remoteUrl, memCacheWidth/Height, autoDownload, placeholder, errorWidget |
| `lib/shared/widgets/rating_badge.dart` | **Бейдж рейтинга**. Цветной бейдж 28×20: зелёный (≥8.0), жёлтый (≥6.0), красный (<6.0). Текст белый bold 12px |
| `lib/shared/widgets/shimmer_loading.dart` | **Shimmer-загрузка**. `ShimmerBox` (базовый блок), `ShimmerPosterCard` (заглушка для PosterCard), `ShimmerListTile` (заглушка для списка). Анимированный линейный градиент surfaceLight↔surface |
| `lib/shared/widgets/poster_card.dart` | **Вертикальная постерная карточка**. StatefulWidget с hover-анимацией (scale 1.04x). Постер 2:3 через CachedImage, RatingBadge (top-left), отметка коллекции (top-right), название и подзаголовок. Используется в SearchScreen и CollectionScreen grid mode |
| `lib/shared/widgets/hero_collection_card.dart` | **Большая карточка коллекции**. Градиентный фон с иконкой типа медиа, название коллекции, статистика (items, completion %), прогресс-бар. Используется в HomeScreen |
| `lib/shared/widgets/media_card.dart` | **Базовый виджет карточки поиска**. Постер 64x96 (CachedNetworkImage или CachedImage при заданных cacheImageType/cacheImageId), название, subtitle, metadata, trailing. `GameCard`, `MovieCard`, `TvShowCard` являются тонкими обёртками |
| `lib/shared/widgets/media_detail_view.dart` | **Базовый виджет экрана деталей**. Постер 100x150 (CachedNetworkImage или CachedImage), SourceBadge, info chips (`MediaDetailChip`), описание inline, секция статуса, `accentColor` для per-media окрашивания, дополнительные секции (`extraSections`), комментарии автора, личные заметки, диалог редактирования. `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` являются тонкими обёртками |
| `lib/shared/widgets/source_badge.dart` | **Бейдж источника данных**. Enum `DataSource` (igdb, tmdb, steamGridDb, vgMaps). Размеры: small, medium, large. Цветовая маркировка и текстовая метка |
| `lib/shared/widgets/media_type_badge.dart` | **Бейдж типа медиа**. Цветная иконка по `MediaType`: синий (игры), красный (фильмы), зелёный (сериалы) |

#### Константы

| Файл | Назначение |
|------|------------|
| `lib/shared/constants/media_type_theme.dart` | **Тема типов медиа**. Цвета и иконки для визуального разделения: `colorFor(MediaType)`, `iconFor(MediaType)`. Статические константы `gameColor`, `movieColor`, `tvShowColor`, `animationColor` (фиолетовый) |

---

### Features: Settings (Настройки)

| Файл | Назначение |
|------|------------|
| `lib/features/settings/screens/settings_screen.dart` | **Экран настроек**. Ввод IGDB Client ID/Secret, SteamGridDB API key, TMDB API key. Кнопки Verify/Refresh Platforms. Секция Configuration (Export/Import Config). Секция Danger Zone (Reset Database с диалогом подтверждения). Debug Panel (только в debug) |
| `lib/features/settings/screens/steamgriddb_debug_screen.dart` | **Debug-экран SteamGridDB**. 5 табов: Search, Grids, Heroes, Logos, Icons. Тестирование всех API эндпоинтов |
| `lib/features/settings/providers/settings_provider.dart` | **State настроек**. Хранение IGDB, SteamGridDB, TMDB credentials в SharedPreferences, валидация токена, синхронизация платформ. Методы: `exportConfig()`, `importConfig()`, `flushDatabase()` |

---

### Repositories (Репозитории)

| Файл | Назначение |
|------|------------|
| `lib/data/repositories/collection_repository.dart` | **Репозиторий коллекций**. CRUD коллекций и игр. Форки с snapshot. Статистика (CollectionStats) |
| `lib/data/repositories/game_repository.dart` | **Репозиторий игр**. Поиск через API + кеширование в SQLite |
| `lib/data/repositories/canvas_repository.dart` | **Репозиторий канваса**. CRUD для canvas_items, viewport и connections. Коллекционные методы: getItems, getItemsWithData (с joined Game/Movie/TvShow), createItem, updateItem, updateItemPosition, updateItemSize, updateItemData, updateItemZIndex, deleteItem, deleteMediaItem, hasCanvasItems, initializeCanvas, getConnections, createConnection, updateConnection, deleteConnection. Per-item методы: getGameCanvasItems, getGameCanvasItemsWithData, hasGameCanvasItems, getGameCanvasViewport, saveGameCanvasViewport, getGameCanvasConnections |

---

## Потоки данных

### 1. Поиск игры

```
Пользователь вводит текст
       ↓
SearchScreen._onSearchChanged()
       ↓
gameSearchProvider.search() [debounce 400ms]
       ↓
GameRepository.searchGames()
       ↓
IgdbApi.searchGames() → API запрос
       ↓
Результаты кешируются в SQLite
       ↓
UI обновляется через ref.watch()
```

### 2. Добавление игры в коллекцию

```
Тап на игру в SearchScreen (таб Games)
       ↓
_addGameToCollection()
       ↓
Диалог выбора платформы (если несколько)
       ↓
collectionItemsNotifierProvider.addItem(mediaType: MediaType.game, ...)
       ↓
CollectionRepository.addItem()
       ↓
DatabaseService.addItemToCollection()
       ↓
SnackBar "Game added to collection"
```

### 2a. Поиск фильмов/сериалов

```
Пользователь вводит текст (таб Movies или TV Shows)
       ↓
SearchScreen._onSearchChanged()
       ↓
mediaSearchProvider.search() [debounce 400ms]
       ↓
TmdbApi.searchMovies() / searchTvShows() → API запрос
       ↓
Результаты кешируются через upsertMovies() / upsertTvShows()
       ↓
UI обновляется через ref.watch()
```

### 2b. Добавление фильма/сериала в коллекцию

```
Тап на фильм/сериал в SearchScreen
       ↓
_showCollectionSelectionDialog() [если нет collectionId]
       ↓
collectionItemsNotifierProvider.addItem(
  mediaType: MediaType.movie / .tvShow,
  externalId: tmdbId
)
       ↓
CollectionRepository.addItem()
       ↓
DatabaseService.insertCollectionItem()
       ↓
SnackBar "Movie/TV show added to collection"
```

### 3. Canvas (визуальный холст)

```
Переключение List → Canvas
       ↓
CanvasView (ConsumerStatefulWidget)
       ↓
canvasNotifierProvider(collectionId).build()
       ↓
CanvasRepository.getItemsWithData()  [items + joined Game]
CanvasRepository.getViewport()       [zoom + offset]
       ↓
Если пусто → initializeCanvas() [раскладка игр сеткой]
       ↓
InteractiveViewer (zoom 0.3–3.0x, pan)
       ↓
Drag карточки → moveItem() [debounce 300ms → updateItemPosition]
Zoom/Pan → updateViewport() [debounce 500ms → saveViewport]
```

### 4. Создание связи на канвасе

```
ПКМ на элементе → Connect
       ↓
CanvasNotifier.startConnection(fromItemId)
       ↓
Курсор → cell, временная пунктирная линия к курсору
       ↓
Клик на другой элемент → completeConnection(toItemId)
       ↓
CanvasRepository.createConnection()
       ↓
DatabaseService.insertCanvasConnection()
       ↓
State обновляется, связь рисуется CanvasConnectionPainter
```

### 5. Добавление SteamGridDB-изображения на канвас

```
Клик кнопки SteamGridDB / ПКМ → Find images...
       ↓
SteamGridDbPanelNotifier.togglePanel() / openPanel()
       ↓
Ввод запроса → searchGames(term)
       ↓
SteamGridDbApi.searchGames() → список SteamGridDbGame
       ↓
Клик на игру → selectGame(game)
       ↓
_loadImages() → api.getGrids(gameId) [кэш по gameId:imageType]
       ↓
GridView.builder с CachedNetworkImage thumbnails
       ↓
Клик на thumbnail → onAddImage(SteamGridDbImage)
       ↓
CollectionScreen._addSteamGridDbImage()
       ↓
canvasNotifierProvider.addImageItem(centerX, centerY, {url})
       ↓
SnackBar "Image added to canvas"
```

### 6. Изменение статуса

```
Тап на StatusChipRow (detail-экран)
       ↓
collectionItemsNotifierProvider.updateStatus()  [все типы медиа]
       ↓
DatabaseService.updateItemStatus()
  → last_activity_at = now (всегда)
  → started_at = now (при inProgress, если null)
  → completed_at = now (при completed)
       ↓
Оптимистичное обновление state (с датами)
       ↓
Инвалидация collectionStatsProvider
Инвалидация collectionItemsNotifierProvider [только для games]
```

---

## База данных

### Таблицы

```sql
-- Платформы из IGDB (кеш)
CREATE TABLE platforms (
  id INTEGER PRIMARY KEY,     -- IGDB ID
  name TEXT NOT NULL,
  abbreviation TEXT,
  synced_at INTEGER
);

-- Игры из IGDB (кеш)
CREATE TABLE games (
  id INTEGER PRIMARY KEY,     -- IGDB ID
  name TEXT NOT NULL,
  summary TEXT,
  cover_url TEXT,
  release_date INTEGER,
  rating REAL,
  rating_count INTEGER,
  genres TEXT,                -- pipe-separated
  platform_ids TEXT,          -- comma-separated
  cached_at INTEGER
);

-- Коллекции пользователя
CREATE TABLE collections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  author TEXT NOT NULL,
  type TEXT DEFAULT 'own',    -- own/imported/fork
  created_at INTEGER NOT NULL,
  original_snapshot TEXT,     -- JSON для форков
  forked_from_author TEXT,
  forked_from_name TEXT
);

-- Универсальные элементы коллекций (Stage 16, updated v12, v14)
CREATE TABLE collection_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'game',  -- game/movie/tvShow
  external_id INTEGER NOT NULL,
  platform_id INTEGER,
  current_season INTEGER DEFAULT 0,
  current_episode INTEGER DEFAULT 0,
  status TEXT DEFAULT 'not_started',
  author_comment TEXT,
  user_comment TEXT,
  added_at INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  started_at INTEGER,            -- auto-set on inProgress, editable
  completed_at INTEGER,          -- auto-set on completed, editable
  last_activity_at INTEGER,      -- auto-set on any status change
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
  UNIQUE(collection_id, media_type, external_id, platform_id)
);

-- Кэш фильмов из TMDB (Stage 15)
CREATE TABLE movies_cache (
  id INTEGER PRIMARY KEY,      -- TMDB ID
  title TEXT NOT NULL,
  overview TEXT,
  poster_path TEXT,
  release_date TEXT,
  rating REAL,
  rating_count INTEGER,
  genres TEXT,                  -- pipe-separated
  runtime INTEGER,
  cached_at INTEGER
);

-- Кэш сериалов из TMDB (Stage 15)
CREATE TABLE tv_shows_cache (
  id INTEGER PRIMARY KEY,      -- TMDB ID
  title TEXT NOT NULL,
  overview TEXT,
  poster_path TEXT,
  first_air_date TEXT,
  rating REAL,
  rating_count INTEGER,
  genres TEXT,                  -- pipe-separated
  number_of_seasons INTEGER,
  number_of_episodes INTEGER,
  status TEXT,
  cached_at INTEGER
);

-- Кэш сезонов сериалов из TMDB (Stage 15)
CREATE TABLE tv_seasons_cache (
  id INTEGER PRIMARY KEY,
  tv_show_id INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  name TEXT,
  overview TEXT,
  poster_path TEXT,
  air_date TEXT,
  episode_count INTEGER,
  cached_at INTEGER,
  FOREIGN KEY (tv_show_id) REFERENCES tv_shows_cache(id) ON DELETE CASCADE
);

-- Кэш эпизодов сериалов из TMDB (Task #11)
CREATE TABLE tv_episodes_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tmdb_show_id INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  episode_number INTEGER NOT NULL,
  name TEXT,
  overview TEXT,
  air_date TEXT,
  still_url TEXT,
  runtime INTEGER,
  cached_at INTEGER,
  UNIQUE(tmdb_show_id, season_number, episode_number)
);

-- Просмотренные эпизоды (Task #12)
CREATE TABLE watched_episodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  show_id INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  episode_number INTEGER NOT NULL,
  watched_at INTEGER,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
  UNIQUE(collection_id, show_id, season_number, episode_number)
);

-- Кэш жанров TMDB (v13)
CREATE TABLE tmdb_genres (
  id INTEGER NOT NULL,
  type TEXT NOT NULL,        -- 'movie' или 'tv'
  name TEXT NOT NULL,
  PRIMARY KEY (id, type)
);

-- Элементы канваса (Stage 7, updated Stage 9+)
CREATE TABLE canvas_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  collection_item_id INTEGER,  -- NULL для коллекционного canvas, int для per-item
  item_type TEXT NOT NULL DEFAULT 'game',
  item_ref_id INTEGER,
  x REAL NOT NULL DEFAULT 0.0,
  y REAL NOT NULL DEFAULT 0.0,
  width REAL,
  height REAL,
  z_index INTEGER NOT NULL DEFAULT 0,
  data TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
);

-- Viewport канваса (Stage 7)
CREATE TABLE canvas_viewport (
  collection_id INTEGER PRIMARY KEY,
  scale REAL NOT NULL DEFAULT 1.0,
  offset_x REAL NOT NULL DEFAULT 0.0,
  offset_y REAL NOT NULL DEFAULT 0.0,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
);

-- Связи канваса (Stage 9, updated Stage 9+)
CREATE TABLE canvas_connections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  collection_item_id INTEGER,  -- NULL для коллекционного canvas, int для per-item
  from_item_id INTEGER NOT NULL,
  to_item_id INTEGER NOT NULL,
  label TEXT,
  color TEXT DEFAULT '#666666',
  style TEXT DEFAULT 'solid',
  created_at INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
  FOREIGN KEY (from_item_id) REFERENCES canvas_items(id) ON DELETE CASCADE,
  FOREIGN KEY (to_item_id) REFERENCES canvas_items(id) ON DELETE CASCADE
);

-- Viewport per-item канваса (Stage 9+)
CREATE TABLE game_canvas_viewport (
  collection_item_id INTEGER PRIMARY KEY,
  scale REAL NOT NULL DEFAULT 1.0,
  offset_x REAL NOT NULL DEFAULT 0.0,
  offset_y REAL NOT NULL DEFAULT 0.0
);
```

---

## Riverpod провайдеры

| Провайдер | Тип | Назначение |
|-----------|-----|------------|
| `databaseServiceProvider` | Provider | Синглтон DatabaseService |
| `igdbApiProvider` | Provider | Синглтон IgdbApi |
| `steamGridDbApiProvider` | Provider | Синглтон SteamGridDbApi |
| `imageCacheServiceProvider` | Provider | Синглтон ImageCacheService |
| `sharedPreferencesProvider` | Provider | SharedPreferences (override в main) |
| `settingsNotifierProvider` | NotifierProvider | Настройки IGDB, токены |
| `hasValidApiKeyProvider` | Provider | bool — готов ли API |
| `collectionsProvider` | AsyncNotifierProvider | Список коллекций |
| `collectionItemsNotifierProvider` | NotifierProvider.family | Элементы коллекции (по collectionId) |
| `collectionStatsProvider` | FutureProvider.family | Статистика коллекции |
| `tmdbApiProvider` | Provider | Синглтон TmdbApi |
| `gameSearchProvider` | NotifierProvider | Состояние поиска игр |
| `mediaSearchProvider` | NotifierProvider | Состояние поиска фильмов/сериалов |
| `collectionItemsNotifierProvider` | NotifierProvider.family | Универсальные элементы коллекции (по collectionId) |
| `gameRepositoryProvider` | Provider | Репозиторий игр |
| `collectionRepositoryProvider` | Provider | Репозиторий коллекций |
| `canvasRepositoryProvider` | Provider | Репозиторий канваса |
| `canvasNotifierProvider` | NotifierProvider.family | Состояние коллекционного канваса (по collectionId) |
| `gameCanvasNotifierProvider` | NotifierProvider.family | Состояние per-item канваса (по `({collectionId, collectionItemId})`) |
| `episodeTrackerNotifierProvider` | NotifierProvider.family | Трекер просмотренных эпизодов (по `({collectionId, showId})`) |
| `steamGridDbPanelProvider` | NotifierProvider.family | Состояние панели SteamGridDB (по collectionId) |
| `movieGenresProvider` | FutureProvider | Список жанров фильмов из TMDB (DB-first cache) |
| `tvGenresProvider` | FutureProvider | Список жанров сериалов из TMDB (DB-first cache) |
| `movieGenreMapProvider` | FutureProvider | Маппинг ID→имя жанров фильмов |
| `tvGenreMapProvider` | FutureProvider | Маппинг ID→имя жанров сериалов |

---

## Навигация

```
Запуск → _AppRouter
         │
         ├─[Нет API ключа]→ SettingsScreen(isInitialSetup: true)
         │
         └─[Есть API ключ]→ NavigationShell (NavigationRail sidebar)
                              ├─ Tab 0: HomeScreen
                              │  ├→ CollectionScreen(collectionId)
                              │  │  ├→ GameDetailScreen(collectionId, itemId)
                              │  │  ├→ MovieDetailScreen(collectionId, itemId)
                              │  │  ├→ TvShowDetailScreen(collectionId, itemId)
                              │  │  ├→ AnimeDetailScreen(collectionId, itemId)
                              │  │  └→ SearchScreen(collectionId)
                              │  │      [добавление игр/фильмов/сериалов]
                              │  │
                              ├─ Tab 1: SearchScreen()
                              │   [просмотр игр/фильмов/сериалов]
                              │
                              └─ Tab 2: SettingsScreen()
                                  [настройки]
                                  └→ SteamGridDbDebugScreen()
                                      [debug, только в debug сборке]
```

---

## Ключевые паттерны

### 1. Immutable Models
Все модели используют `final` поля и метод `copyWith()` для создания изменённых копий.

### 2. Factory Constructors
- `fromJson()` — парсинг API ответа
- `fromDb()` — парсинг записи SQLite
- `toDb()` — сериализация для БД

### 3. Riverpod Family
Для данных, зависящих от ID (элементы коллекции, статистика):
```dart
final collectionItemsNotifierProvider = NotifierProvider.family<..., int>
ref.watch(collectionItemsNotifierProvider(collectionId))
```

### 4. Optimistic Updates
При изменении статуса сначала обновляется локальный state, затем база данных.

### 5. Debounce
Поиск использует 400ms debounce для снижения нагрузки на API.

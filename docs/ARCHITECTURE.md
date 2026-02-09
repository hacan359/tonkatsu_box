# Архитектура xeRAbora

## Обзор

xeRAbora — Windows desktop приложение на Flutter для управления коллекциями ретро-игр, фильмов и сериалов с интеграцией IGDB, TMDB и SteamGridDB API.

| Слой | Технология |
|------|------------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Database | SQLite (sqflite_ffi) |
| API | IGDB (Twitch OAuth), TMDB (Bearer token), SteamGridDB (Bearer token) |
| Platform | Windows Desktop |

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
| `lib/app.dart` | Корневой виджет `XeraboraApp`. Настройка темы (Material 3), роутинг на основе состояния API |

---

### Core (Ядро)

| Файл | Назначение |
|------|------------|
| `lib/core/api/igdb_api.dart` | **IGDB API клиент**. OAuth через Twitch, поиск игр, загрузка платформ. Методы: `getAccessToken()`, `searchGames()`, `fetchPlatforms()` |
| `lib/core/api/steamgriddb_api.dart` | **SteamGridDB API клиент**. Bearer token авторизация. Методы: `searchGames()`, `getGrids()`, `getHeroes()`, `getLogos()`, `getIcons()` |
| `lib/core/api/tmdb_api.dart` | **TMDB API клиент**. Bearer token авторизация. Методы: `searchMovies()`, `searchTvShows()`, `multiSearch()`, `getMovieDetails()`, `getTvShowDetails()`, `getPopularMovies()`, `getPopularTvShows()`, `getMovieGenres()`, `getTvGenres()` |
| `lib/core/database/database_service.dart` | **SQLite сервис**. Создание таблиц, миграции (версия 8), CRUD для всех сущностей. Таблицы: `platforms`, `games`, `collections`, `collection_games`, `collection_items`, `canvas_items`, `canvas_viewport`, `canvas_connections`, `movies_cache`, `tv_shows_cache`, `tv_seasons_cache` |

---

### Models (Модели данных)

| Файл | Назначение |
|------|------------|
| `lib/shared/models/game.dart` | **Модель игры**. Поля: id, name, summary, coverUrl, releaseDate, rating, genres, platformIds. Методы: `fromJson()`, `fromDb()`, `toDb()` |
| `lib/shared/models/platform.dart` | **Модель платформы**. Поля: id, name, abbreviation. Свойство `displayName` возвращает сокращение или полное имя |
| `lib/shared/models/collection.dart` | **Модель коллекции**. Типы: `own`, `imported`, `fork`. Поля для форков: `originalSnapshot`, `forkedFromAuthor` |
| `lib/shared/models/collection_game.dart` | **Игра в коллекции**. Связь коллекции с игрой. Статусы: `notStarted`, `playing`, `completed`, `dropped`, `planned`. Комментарии автора и пользователя |
| `lib/shared/models/steamgriddb_game.dart` | **Модель SteamGridDB игры**. Поля: id, name, types, verified. Метод: `fromJson()` |
| `lib/shared/models/steamgriddb_image.dart` | **Модель SteamGridDB изображения**. Поля: id, score, style, url, thumb, width, height, mime, author. Свойство `dimensions` |
| `lib/shared/models/collection_item.dart` | **Модель универсального элемента коллекции**. Поля: id, collectionId, mediaType, externalId, platformId, status, authorComment, userComment, addedAt. Методы: `fromDb()`, `toDb()`, `copyWith()`. Заменяет привязку только к играм |
| `lib/shared/models/media_type.dart` | **Enum типа медиа**. Значения: `game`, `movie`, `tvShow`. Свойства: `label`, `icon`. Методы: `fromString()` |
| `lib/shared/models/item_status.dart` | **Enum статуса элемента**. Значения: `notStarted`, `inProgress`, `completed`, `dropped`, `planned`. Свойства: `label`, `emoji`, `color`. Методы: `fromString()` |
| `lib/shared/models/movie.dart` | **Модель фильма**. Поля: id, title, overview, posterPath, releaseDate, rating, genres, runtime и др. Свойства: `posterUrl`, `releaseYear`, `ratingString`, `genresString`. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/tv_show.dart` | **Модель сериала**. Поля: id, title, overview, posterPath, firstAirDate, rating, genres, seasons, episodes, status. Свойства: `posterUrl`, `releaseYear`, `ratingString`, `genresString`. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/tv_season.dart` | **Модель сезона сериала**. Поля: id, tvShowId, seasonNumber, name, overview, posterPath, airDate, episodeCount. Методы: `fromJson()`, `fromDb()`, `toDb()`, `copyWith()` |
| `lib/shared/models/canvas_item.dart` | **Модель элемента канваса**. Enum `CanvasItemType` (game/movie/tvShow/text/image/link). Поля: id, collectionId, itemType, itemRefId, x, y, width, height, zIndex, data (JSON). Joined поля: `game: Game?`, `movie: Movie?`, `tvShow: TvShow?`. Статический метод `CanvasItemType.fromMediaType()`, геттер `isMediaItem` |
| `lib/shared/models/canvas_viewport.dart` | **Модель viewport канваса**. Поля: collectionId, scale, offsetX, offsetY. Хранит зум и позицию камеры |
| `lib/shared/models/canvas_connection.dart` | **Модель связи канваса**. Enum `ConnectionStyle` (solid/dashed/arrow). Поля: id, collectionId, fromItemId, toItemId, label, color (hex), style, createdAt |

---

### Features: Collections (Коллекции)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/collections/screens/home_screen.dart` | **Главный экран**. Список коллекций с группировкой (My/Forked/Imported). FAB для создания. Меню: rename, fork, delete |
| `lib/features/collections/screens/collection_screen.dart` | **Экран коллекции**. Заголовок со статистикой (прогресс-бар), список элементов. Кнопка "Add Items" открывает SearchScreen. Поддержка игр, фильмов и сериалов через `CollectionItem`/`collectionItemsNotifierProvider`. Навигация к `GameDetailScreen`/`MovieDetailScreen`/`TvShowDetailScreen` по типу |
| `lib/features/collections/screens/game_detail_screen.dart` | **Экран деталей игры**. Тонкая обёртка над `MediaDetailView`: маппинг CollectionGame на параметры виджета, info chips (год, рейтинг, жанры), `StatusDropdown` |
| `lib/features/collections/screens/movie_detail_screen.dart` | **Экран деталей фильма**. Тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+Movie на параметры виджета, info chips (год, runtime, жанры, рейтинг), `ItemStatusDropdown` |
| `lib/features/collections/screens/tv_show_detail_screen.dart` | **Экран деталей сериала**. Тонкая обёртка над `MediaDetailView`: маппинг CollectionItem+TvShow на параметры виджета, info chips (год, сезоны, эпизоды, жанры, рейтинг, статус шоу), секция прогресса через `extraSections` |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/collections/widgets/collection_tile.dart` | **Плитка коллекции**. Показывает имя, автора, тип, количество игр. Иконка удаления |
| `lib/features/collections/widgets/create_collection_dialog.dart` | **Диалоги**. Создание, переименование, удаление коллекции |
| `lib/features/collections/widgets/status_dropdown.dart` | **Выпадающий список статусов** (legacy, для GameDetailScreen). Компактный и полный режим |
| `lib/features/collections/widgets/item_status_dropdown.dart` | **Универсальный dropdown статуса**. Контекстные лейблы по `MediaType` ("Playing"/"Watching"). `ItemStatusChip` для read-only. Полный/компактный режим. `onHold` только для сериалов |
| `lib/features/collections/widgets/canvas_media_card.dart` | **Карточка фильма/сериала на канвасе**. Постер (CachedNetworkImage), название, placeholder icon (movie/tv). По паттерну CanvasGameCard |
| `lib/features/collections/widgets/canvas_view.dart` | **Canvas View**. InteractiveViewer с зумом 0.3–3.0x, панорамированием, drag-and-drop (абсолютное отслеживание позиции). Фоновая сетка (CustomPainter), автоцентрирование |
| `lib/features/collections/widgets/canvas_game_card.dart` | **Карточка игры на канвасе**. Компактная карточка 160x220px с обложкой и названием. RepaintBoundary для оптимизации |
| `lib/features/collections/widgets/canvas_context_menu.dart` | **Контекстное меню канваса**. ПКМ на пустом месте: Add Text/Image/Link. ПКМ на элементе: Edit/Delete/Bring to Front/Send to Back/Connect. ПКМ на связи: Edit/Delete. Delete с диалогом подтверждения |
| `lib/features/collections/widgets/canvas_connection_painter.dart` | **CustomPainter для связей**. Рисует solid/dashed/arrow линии между центрами элементов. Лейблы с фоном в середине линии. Hit-test для определения клика на линии. Временная пунктирная линия при создании связи |
| `lib/features/collections/widgets/canvas_text_item.dart` | **Текстовый блок на канвасе**. Настраиваемый fontSize (12/16/24/32). Container с padding, фоном surfaceContainerLow |
| `lib/features/collections/widgets/canvas_image_item.dart` | **Изображение на канвасе**. URL (CachedNetworkImage) или base64 (Image.memory). Card с Clip.antiAlias, размер по умолчанию 200x200 |
| `lib/features/collections/widgets/canvas_link_item.dart` | **Ссылка на канвасе**. Card с иконкой и подчёркнутым текстом. Double-tap → url_launcher. Размер по умолчанию 200x48 |
| `lib/features/collections/widgets/steamgriddb_panel.dart` | **Боковая панель SteamGridDB**. Поиск игр, выбор типа изображений (SegmentedButton), сетка thumbnail-ов (GridView.builder + CachedNetworkImage). Автозаполнение поиска из названия коллекции. Клик на изображение → добавление на канвас |
| `lib/features/collections/widgets/vgmaps_panel.dart` | **Боковая панель VGMaps Browser**. WebView2 (webview_windows) для просмотра vgmaps.com. Навигация (back/forward/home/reload), поиск по имени игры, JS injection для перехвата ПКМ на `<img>`, bottom bar с превью и "Add to Canvas". Ширина 500px. Взаимоисключение с SteamGridDB панелью |

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
| `lib/features/collections/providers/collections_provider.dart` | **State management коллекций**. `collectionsProvider` — список. `collectionGamesNotifierProvider` — игры в коллекции с CRUD (legacy). `collectionItemsNotifierProvider` — универсальные элементы коллекции (games/movies/tvShows) с CRUD. Двусторонняя синхронизация между games и items провайдерами |
| `lib/features/collections/providers/steamgriddb_panel_provider.dart` | **State management панели SteamGridDB**. `steamGridDbPanelProvider` — NotifierProvider.family по collectionId. Enum `SteamGridDbImageType` (grids/heroes/logos/icons). State: isOpen, searchTerm, searchResults, selectedGame, selectedImageType, images, isSearching, isLoadingImages, searchError, imageError, imageCache. Методы: togglePanel, openPanel, closePanel, searchGames, selectGame, clearGameSelection, selectImageType. In-memory кэш по ключу `gameId:imageType` |
| `lib/features/collections/providers/vgmaps_panel_provider.dart` | **State management панели VGMaps**. `vgMapsPanelProvider` — NotifierProvider.family по collectionId. State: isOpen, currentUrl, canGoBack, canGoForward, isLoading, capturedImageUrl/Width/Height, error. Методы: togglePanel, openPanel, closePanel, setCurrentUrl, setNavigationState, setLoading, captureImage, clearCapturedImage, setError, clearError |
| `lib/features/collections/providers/canvas_provider.dart` | **State management канваса**. `canvasNotifierProvider` — NotifierProvider.family по collectionId. Методы: moveItem, updateViewport, addItem, deleteItem, bringToFront, sendToBack, removeMediaItem (generic по MediaType), removeGameItem (delegates to removeMediaItem), addTextItem, addImageItem, addLinkItem, updateItemData, updateItemSize, startConnection, completeConnection, cancelConnection, deleteConnection, updateConnection. Debounced save (300ms position, 500ms viewport). Двусторонняя синхронизация с коллекцией (все типы медиа) через `ref.listen`. Параллельная загрузка items, viewport и connections через `Future.wait` |

---

### Features: Search (Поиск)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/search/screens/search_screen.dart` | **Экран поиска**. TabBar с 3 табами: Games / Movies / TV Shows. Общее поле ввода с debounce, фильтр платформ (только Games). При `collectionId` — добавляет игры/фильмы/сериалы в коллекцию через `collectionItemsNotifierProvider`. Bottom sheet с деталями фильма/сериала |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/search/widgets/game_card.dart` | **Карточка игры**. Тонкая обёртка над `MediaCard`: маппинг Game на параметры виджета, SourceBadge IGDB, subtitle (год, рейтинг), metadata (жанры, платформы) |
| `lib/features/search/widgets/movie_card.dart` | **Карточка фильма**. Тонкая обёртка над `MediaCard`: маппинг Movie на параметры виджета, SourceBadge TMDB, subtitle (год, рейтинг, runtime), metadata (жанры) |
| `lib/features/search/widgets/tv_show_card.dart` | **Карточка сериала**. Тонкая обёртка над `MediaCard`: маппинг TvShow на параметры виджета, SourceBadge TMDB, subtitle (год, рейтинг, сезоны), metadata (жанры, статус) |
| `lib/features/search/widgets/platform_filter_sheet.dart` | **Bottom sheet фильтра**. Мультивыбор платформ с поиском. Кнопки Clear All / Apply |

#### Провайдеры

| Файл | Назначение |
|------|------------|
| `lib/features/search/providers/game_search_provider.dart` | **State поиска игр**. Debounce 400ms, минимум 2 символа. Фильтр по платформам. Состояние: query, results, isLoading, error |
| `lib/features/search/providers/media_search_provider.dart` | **State поиска фильмов/сериалов**. Debounce 400ms через TMDB API. Enum `MediaSearchTab` (movies, tvShows). Состояние: query, movieResults, tvShowResults, isLoading, error, activeTab. Кэширование через `upsertMovies()`/`upsertTvShows()` |

---

### Shared (Общие виджеты и константы)

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/shared/widgets/media_card.dart` | **Базовый виджет карточки поиска**. Постер 60x80 (CachedNetworkImage), название, subtitle, metadata, trailing. `GameCard`, `MovieCard`, `TvShowCard` являются тонкими обёртками |
| `lib/shared/widgets/media_detail_view.dart` | **Базовый виджет экрана деталей**. Постер 80x120, SourceBadge, info chips (`MediaDetailChip`), описание inline, секция статуса, дополнительные секции (`extraSections`), комментарии автора, личные заметки, диалог редактирования. `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen` являются тонкими обёртками |
| `lib/shared/widgets/source_badge.dart` | **Бейдж источника данных**. Enum `DataSource` (igdb, tmdb, steamGridDb, vgMaps). Размеры: small, medium, large. Цветовая маркировка и текстовая метка |
| `lib/shared/widgets/media_type_badge.dart` | **Бейдж типа медиа**. Цветная иконка по `MediaType`: синий (игры), красный (фильмы), зелёный (сериалы) |

#### Константы

| Файл | Назначение |
|------|------------|
| `lib/shared/constants/media_type_theme.dart` | **Тема типов медиа**. Цвета и иконки для визуального разделения: `colorFor(MediaType)`, `iconFor(MediaType)`. Статические константы `gameColor`, `movieColor`, `tvShowColor` |

---

### Features: Settings (Настройки)

| Файл | Назначение |
|------|------------|
| `lib/features/settings/screens/settings_screen.dart` | **Экран настроек**. Ввод IGDB Client ID/Secret, SteamGridDB API key, кнопки Verify/Refresh Platforms, ссылка на Debug Panel (только в debug) |
| `lib/features/settings/screens/steamgriddb_debug_screen.dart` | **Debug-экран SteamGridDB**. 5 табов: Search, Grids, Heroes, Logos, Icons. Тестирование всех API эндпоинтов |
| `lib/features/settings/providers/settings_provider.dart` | **State настроек**. Хранение IGDB и SteamGridDB credentials в SharedPreferences, валидация токена, синхронизация платформ |

---

### Repositories (Репозитории)

| Файл | Назначение |
|------|------------|
| `lib/data/repositories/collection_repository.dart` | **Репозиторий коллекций**. CRUD коллекций и игр. Форки с snapshot. Статистика (CollectionStats) |
| `lib/data/repositories/game_repository.dart` | **Репозиторий игр**. Поиск через API + кеширование в SQLite |
| `lib/data/repositories/canvas_repository.dart` | **Репозиторий канваса**. CRUD для canvas_items, viewport и connections. Методы: getItems, getItemsWithData (с joined Game/Movie/TvShow), createItem, updateItem, updateItemPosition, updateItemSize, updateItemData, updateItemZIndex, deleteItem, deleteMediaItem (generic по CanvasItemType), hasCanvasItems, initializeCanvas (раскладка сеткой для всех типов медиа), getConnections, createConnection, updateConnection, deleteConnection |

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
collectionGamesNotifierProvider.addGame()
       ↓
CollectionRepository.addGame()
       ↓
DatabaseService.addGameToCollection()
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
Клик FAB SteamGridDB / ПКМ → Find images...
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
Тап на StatusDropdown
       ↓
collectionGamesNotifierProvider.updateStatus()
       ↓
Локальное обновление state (мгновенный UI)
       ↓
DatabaseService.updateGameStatus()
       ↓
Инвалидация collectionStatsProvider
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

-- Игры в коллекциях
CREATE TABLE collection_games (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  igdb_id INTEGER NOT NULL,
  platform_id INTEGER NOT NULL,
  author_comment TEXT,
  user_comment TEXT,
  status TEXT DEFAULT 'not_started',
  added_at INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
  UNIQUE(collection_id, igdb_id, platform_id)
);

-- Универсальные элементы коллекций (Stage 16)
CREATE TABLE collection_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'game',  -- game/movie/tvShow
  external_id INTEGER NOT NULL,
  platform_id INTEGER,
  status TEXT DEFAULT 'not_started',
  author_comment TEXT,
  user_comment TEXT,
  added_at INTEGER NOT NULL,
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

-- Элементы канваса (Stage 7)
CREATE TABLE canvas_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
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

-- Связи канваса (Stage 9)
CREATE TABLE canvas_connections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
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
```

---

## Riverpod провайдеры

| Провайдер | Тип | Назначение |
|-----------|-----|------------|
| `databaseServiceProvider` | Provider | Синглтон DatabaseService |
| `igdbApiProvider` | Provider | Синглтон IgdbApi |
| `steamGridDbApiProvider` | Provider | Синглтон SteamGridDbApi |
| `sharedPreferencesProvider` | Provider | SharedPreferences (override в main) |
| `settingsNotifierProvider` | NotifierProvider | Настройки IGDB, токены |
| `hasValidApiKeyProvider` | Provider | bool — готов ли API |
| `collectionsProvider` | AsyncNotifierProvider | Список коллекций |
| `collectionGamesNotifierProvider` | NotifierProvider.family | Игры в коллекции (по collectionId) |
| `collectionStatsProvider` | FutureProvider.family | Статистика коллекции |
| `tmdbApiProvider` | Provider | Синглтон TmdbApi |
| `gameSearchProvider` | NotifierProvider | Состояние поиска игр |
| `mediaSearchProvider` | NotifierProvider | Состояние поиска фильмов/сериалов |
| `collectionItemsNotifierProvider` | NotifierProvider.family | Универсальные элементы коллекции (по collectionId) |
| `gameRepositoryProvider` | Provider | Репозиторий игр |
| `collectionRepositoryProvider` | Provider | Репозиторий коллекций |
| `canvasRepositoryProvider` | Provider | Репозиторий канваса |
| `canvasNotifierProvider` | NotifierProvider.family | Состояние канваса (по collectionId) |
| `steamGridDbPanelProvider` | NotifierProvider.family | Состояние панели SteamGridDB (по collectionId) |

---

## Навигация

```
Запуск → _AppRouter
         │
         ├─[Нет API ключа]→ SettingsScreen(isInitialSetup: true)
         │
         └─[Есть API ключ]→ HomeScreen
                            │
                            ├→ CollectionScreen(collectionId)
                            │  │
                            │  ├→ GameDetailScreen(collectionId, itemId)
                            │  ├→ MovieDetailScreen(collectionId, itemId)
                            │  ├→ TvShowDetailScreen(collectionId, itemId)
                            │  │
                            │  └→ SearchScreen(collectionId)
                            │      [добавление игр/фильмов/сериалов]
                            │
                            ├→ SearchScreen()
                            │   [просмотр игр]
                            │
                            └→ SettingsScreen()
                                [настройки]
                                │
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
Для данных, зависящих от ID (игры коллекции, статистика):
```dart
final collectionGamesNotifierProvider = NotifierProvider.family<..., int>
ref.watch(collectionGamesNotifierProvider(collectionId))
```

### 4. Optimistic Updates
При изменении статуса сначала обновляется локальный state, затем база данных.

### 5. Debounce
Поиск использует 400ms debounce для снижения нагрузки на API.

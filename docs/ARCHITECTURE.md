# Архитектура xeRAbora

## Обзор

xeRAbora — Windows desktop приложение на Flutter для управления коллекциями ретро-игр с интеграцией IGDB API.

| Слой | Технология |
|------|------------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Database | SQLite (sqflite_ffi) |
| API | IGDB через Twitch OAuth, SteamGridDB (Bearer token) |
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
| `lib/core/database/database_service.dart` | **SQLite сервис**. Создание таблиц, миграции (версия 6), CRUD для всех сущностей. Таблицы: `platforms`, `games`, `collections`, `collection_games`, `canvas_items`, `canvas_viewport`, `canvas_connections` |

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
| `lib/shared/models/canvas_item.dart` | **Модель элемента канваса**. Enum `CanvasItemType` (game/text/image/link). Поля: id, collectionId, itemType, itemRefId, x, y, width, height, zIndex, data (JSON). Joined поле `game: Game?` |
| `lib/shared/models/canvas_viewport.dart` | **Модель viewport канваса**. Поля: collectionId, scale, offsetX, offsetY. Хранит зум и позицию камеры |
| `lib/shared/models/canvas_connection.dart` | **Модель связи канваса**. Enum `ConnectionStyle` (solid/dashed/arrow). Поля: id, collectionId, fromItemId, toItemId, label, color (hex), style, createdAt |

---

### Features: Collections (Коллекции)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/collections/screens/home_screen.dart` | **Главный экран**. Список коллекций с группировкой (My/Forked/Imported). FAB для создания. Меню: rename, fork, delete |
| `lib/features/collections/screens/collection_screen.dart` | **Экран коллекции**. Заголовок со статистикой (прогресс-бар), список игр. Кнопка "Add Game" открывает SearchScreen |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/collections/widgets/collection_tile.dart` | **Плитка коллекции**. Показывает имя, автора, тип, количество игр. Иконка удаления |
| `lib/features/collections/widgets/create_collection_dialog.dart` | **Диалоги**. Создание, переименование, удаление коллекции |
| `lib/features/collections/widgets/status_dropdown.dart` | **Выпадающий список статусов**. Компактный и полный режим |
| `lib/features/collections/widgets/canvas_view.dart` | **Canvas View**. InteractiveViewer с зумом 0.3–3.0x, панорамированием, drag-and-drop (абсолютное отслеживание позиции). Фоновая сетка (CustomPainter), автоцентрирование |
| `lib/features/collections/widgets/canvas_game_card.dart` | **Карточка игры на канвасе**. Компактная карточка 160x220px с обложкой и названием. RepaintBoundary для оптимизации |
| `lib/features/collections/widgets/canvas_context_menu.dart` | **Контекстное меню канваса**. ПКМ на пустом месте: Add Text/Image/Link. ПКМ на элементе: Edit/Delete/Bring to Front/Send to Back/Connect. ПКМ на связи: Edit/Delete. Delete с диалогом подтверждения |
| `lib/features/collections/widgets/canvas_connection_painter.dart` | **CustomPainter для связей**. Рисует solid/dashed/arrow линии между центрами элементов. Лейблы с фоном в середине линии. Hit-test для определения клика на линии. Временная пунктирная линия при создании связи |
| `lib/features/collections/widgets/canvas_text_item.dart` | **Текстовый блок на канвасе**. Настраиваемый fontSize (12/16/24/32). Container с padding, фоном surfaceContainerLow |
| `lib/features/collections/widgets/canvas_image_item.dart` | **Изображение на канвасе**. URL (CachedNetworkImage) или base64 (Image.memory). Card с Clip.antiAlias, размер по умолчанию 200x200 |
| `lib/features/collections/widgets/canvas_link_item.dart` | **Ссылка на канвасе**. Card с иконкой и подчёркнутым текстом. Double-tap → url_launcher. Размер по умолчанию 200x48 |
| `lib/features/collections/widgets/steamgriddb_panel.dart` | **Боковая панель SteamGridDB**. Поиск игр, выбор типа изображений (SegmentedButton), сетка thumbnail-ов (GridView.builder + CachedNetworkImage). Автозаполнение поиска из названия коллекции. Клик на изображение → добавление на канвас |

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
| `lib/features/collections/providers/collections_provider.dart` | **State management коллекций**. `collectionsProvider` — список. `collectionGamesNotifierProvider` — игры в коллекции с CRUD |
| `lib/features/collections/providers/steamgriddb_panel_provider.dart` | **State management панели SteamGridDB**. `steamGridDbPanelProvider` — NotifierProvider.family по collectionId. Enum `SteamGridDbImageType` (grids/heroes/logos/icons). State: isOpen, searchTerm, searchResults, selectedGame, selectedImageType, images, isSearching, isLoadingImages, searchError, imageError, imageCache. Методы: togglePanel, openPanel, closePanel, searchGames, selectGame, clearGameSelection, selectImageType. In-memory кэш по ключу `gameId:imageType` |
| `lib/features/collections/providers/canvas_provider.dart` | **State management канваса**. `canvasNotifierProvider` — NotifierProvider.family по collectionId. Методы: moveItem, updateViewport, addItem, deleteItem, bringToFront, sendToBack, removeGameItem, addTextItem, addImageItem, addLinkItem, updateItemData, updateItemSize, startConnection, completeConnection, cancelConnection, deleteConnection, updateConnection. Debounced save (300ms position, 500ms viewport). Двусторонняя синхронизация с коллекцией через `ref.listen`. Параллельная загрузка items, viewport и connections через `Future.wait` |

---

### Features: Search (Поиск)

#### Экраны

| Файл | Назначение |
|------|------------|
| `lib/features/search/screens/search_screen.dart` | **Экран поиска**. Поле ввода с debounce, фильтр платформ, результаты. При `collectionId` — добавляет игры в коллекцию |

#### Виджеты

| Файл | Назначение |
|------|------------|
| `lib/features/search/widgets/game_card.dart` | **Карточка игры**. Обложка (CachedNetworkImage), название, год, рейтинг, жанры, платформы |
| `lib/features/search/widgets/platform_filter_sheet.dart` | **Bottom sheet фильтра**. Мультивыбор платформ с поиском. Кнопки Clear All / Apply |

#### Провайдеры

| Файл | Назначение |
|------|------------|
| `lib/features/search/providers/game_search_provider.dart` | **State поиска**. Debounce 400ms, минимум 2 символа. Фильтр по платформам. Состояние: query, results, isLoading, error |

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
| `lib/data/repositories/canvas_repository.dart` | **Репозиторий канваса**. CRUD для canvas_items, viewport и connections. Методы: getItems, getItemsWithData (с joined Game), createItem, updateItem, updateItemPosition, updateItemSize, updateItemData, updateItemZIndex, deleteItem, hasCanvasItems, initializeCanvas (раскладка сеткой), getConnections, createConnection, updateConnection, deleteConnection |

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
Тап на игру в SearchScreen
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
| `gameSearchProvider` | NotifierProvider | Состояние поиска |
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
                            │  └→ SearchScreen(collectionId)
                            │      [добавление игры]
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

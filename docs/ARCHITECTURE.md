# Архитектура xeRAbora

## Обзор

xeRAbora — Windows desktop приложение на Flutter для управления коллекциями ретро-игр с интеграцией IGDB API.

| Слой | Технология |
|------|------------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Database | SQLite (sqflite_ffi) |
| API | IGDB через Twitch OAuth |
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
| `lib/core/database/database_service.dart` | **SQLite сервис**. Создание таблиц, миграции, CRUD для всех сущностей. Таблицы: `platforms`, `games`, `collections`, `collection_games` |

---

### Models (Модели данных)

| Файл | Назначение |
|------|------------|
| `lib/shared/models/game.dart` | **Модель игры**. Поля: id, name, summary, coverUrl, releaseDate, rating, genres, platformIds. Методы: `fromJson()`, `fromDb()`, `toDb()` |
| `lib/shared/models/platform.dart` | **Модель платформы**. Поля: id, name, abbreviation. Свойство `displayName` возвращает сокращение или полное имя |
| `lib/shared/models/collection.dart` | **Модель коллекции**. Типы: `own`, `imported`, `fork`. Поля для форков: `originalSnapshot`, `forkedFromAuthor` |
| `lib/shared/models/collection_game.dart` | **Игра в коллекции**. Связь коллекции с игрой. Статусы: `notStarted`, `playing`, `completed`, `dropped`, `planned`. Комментарии автора и пользователя |

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

#### Провайдеры

| Файл | Назначение |
|------|------------|
| `lib/features/collections/providers/collections_provider.dart` | **State management коллекций**. `collectionsProvider` — список. `collectionGamesNotifierProvider` — игры в коллекции с CRUD |

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
| `lib/features/settings/screens/settings_screen.dart` | **Экран настроек**. Ввод Client ID/Secret, кнопки Verify/Refresh Platforms |
| `lib/features/settings/providers/settings_provider.dart` | **State настроек**. Хранение credentials в SharedPreferences, валидация токена, синхронизация платформ |

---

### Repositories (Репозитории)

| Файл | Назначение |
|------|------------|
| `lib/data/repositories/collection_repository.dart` | **Репозиторий коллекций**. CRUD коллекций и игр. Форки с snapshot. Статистика (CollectionStats) |
| `lib/data/repositories/game_repository.dart` | **Репозиторий игр**. Поиск через API + кеширование в SQLite |

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

### 3. Изменение статуса

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
```

---

## Riverpod провайдеры

| Провайдер | Тип | Назначение |
|-----------|-----|------------|
| `databaseServiceProvider` | Provider | Синглтон DatabaseService |
| `igdbApiProvider` | Provider | Синглтон IgdbApi |
| `sharedPreferencesProvider` | Provider | SharedPreferences (override в main) |
| `settingsNotifierProvider` | NotifierProvider | Настройки IGDB, токены |
| `hasValidApiKeyProvider` | Provider | bool — готов ли API |
| `collectionsProvider` | AsyncNotifierProvider | Список коллекций |
| `collectionGamesNotifierProvider` | NotifierProvider.family | Игры в коллекции (по collectionId) |
| `collectionStatsProvider` | FutureProvider.family | Статистика коллекции |
| `gameSearchProvider` | NotifierProvider | Состояние поиска |
| `gameRepositoryProvider` | Provider | Репозиторий игр |
| `collectionRepositoryProvider` | Provider | Репозиторий коллекций |

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

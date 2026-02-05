# xeRAbora — Development Plan

Внутренний документ с детальным планом разработки.

---

## Stage 1: Project Setup & IGDB Connection

**Цель:** Приложение запускается, принимает API ключи, синхронизирует платформы.

### 1.1 Flutter Project Init

```bash
flutter create . --platforms=windows --org=com.xerabora
```

### 1.2 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite_common_ffi: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1
  dio: ^5.4.0
  flutter_riverpod: ^2.4.9
  shared_preferences: ^2.2.2
  file_picker: ^6.1.1
  cached_network_image: ^3.3.1
```

### 1.3 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   │   └── database_service.dart
│   └── api/
│       └── igdb_api.dart
├── features/
│   ├── settings/
│   │   ├── screens/
│   │   │   └── settings_screen.dart
│   │   └── providers/
│   │       └── settings_provider.dart
│   └── collections/
│       └── screens/
│           └── home_screen.dart
└── shared/
    └── models/
        └── platform.dart
```

### 1.4 Database Schema

```sql
CREATE TABLE platforms (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  abbreviation TEXT,
  synced_at INTEGER
);
```

### 1.5 IGDB API Client

**Файл:** `lib/core/api/igdb_api.dart`

**Методы:**
- `getAccessToken(clientId, clientSecret)` → Bearer token
- `validateCredentials()` → bool
- `fetchPlatforms()` → List<Platform>

**Auth flow:**
```
POST https://id.twitch.tv/oauth2/token
  client_id, client_secret, grant_type=client_credentials
→ access_token (expires in ~60 days)
```

**Platforms request:**
```
POST https://api.igdb.com/v4/platforms
Headers: Client-ID, Authorization: Bearer
Body: fields id,name,abbreviation; limit 500;
```

### 1.6 Settings Provider

**Файл:** `lib/features/settings/providers/settings_provider.dart`

**Storage (SharedPreferences):**
- `igdb_client_id`
- `igdb_client_secret`
- `igdb_access_token`
- `igdb_token_expires`

**Providers:**
- `hasValidApiKeyProvider` → bool
- `settingsNotifierProvider` → AsyncNotifier

### 1.7 Settings Screen

**Файл:** `lib/features/settings/screens/settings_screen.dart`

**UI:**
```
┌─────────────────────────────────────────┐
│ IGDB API Setup                          │
├─────────────────────────────────────────┤
│ Client ID                               │
│ [____________________________________]  │
│                                         │
│ Client Secret                           │
│ [____________________________________]  │
│                                         │
│ [Verify Connection]                     │
│                                         │
│ Status: ✓ Connected / ✗ Invalid         │
│ Platforms synced: 187                   │
│ Last sync: 2025-02-02                   │
│                                         │
│ [Refresh Platforms]                     │
└─────────────────────────────────────────┘
```

### 1.8 App Router

**Файл:** `lib/app.dart`

```dart
hasValidApiKey?
  → false: SettingsScreen(isInitialSetup: true)
  → true: HomeScreen()
```

### Checklist Stage 1

- [ ] Flutter project created
- [ ] Dependencies installed
- [ ] SQLite initialized, platforms table created
- [ ] IGDB API client with auth
- [ ] Settings screen with key input
- [ ] Key validation works
- [ ] Platforms sync to DB
- [ ] Router redirects based on key presence

---

## Stage 2: Game Search

**Цель:** Поиск игр в IGDB с отображением результатов.

### 2.1 Database

```sql
CREATE TABLE games_cache (
  igdb_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  cover_url TEXT,
  genres TEXT,  -- JSON array
  summary TEXT,
  cached_at INTEGER
);
```

### 2.2 Models

**Файл:** `lib/shared/models/game.dart`

```dart
class Game {
  final int igdbId;
  final String name;
  final String? coverUrl;
  final List<String> genres;
  final String? summary;
  final List<int> platformIds;
}
```

### 2.3 IGDB API — Search

**Добавить в** `igdb_api.dart`:

```dart
Future<List<Game>> searchGames(String query);
Future<List<Game>> getGamesByIds(List<int> ids);
```

**Search request:**
```
POST https://api.igdb.com/v4/games
Body:
  search "query";
  fields id,name,cover.url,genres.name,platforms.id,summary;
  limit 20;
```

### 2.4 Search Provider

**Файл:** `lib/features/search/providers/search_provider.dart`

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = FutureProvider<List<Game>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(igdbApiProvider).searchGames(query);
});
```

### 2.5 Search Screen

**Файл:** `lib/features/search/screens/search_screen.dart`

**UI:**
```
┌─────────────────────────────────────────┐
│ ← Search Games                          │
├─────────────────────────────────────────┤
│ [🔍 Search games...___________________] │
├─────────────────────────────────────────┤
│ ┌─────┐ Chrono Trigger                  │
│ │cover│ RPG • SNES, PS1, DS             │
│ └─────┘                          [Add]  │
│                                         │
│ ┌─────┐ Chrono Cross                    │
│ │cover│ RPG • PS1                       │
│ └─────┘                          [Add]  │
└─────────────────────────────────────────┘
```

### 2.6 Platform Selection Dialog

При нажатии [Add]:
```
┌─────────────────────────────┐
│ Select Platform             │
├─────────────────────────────┤
│ ○ SNES                      │
│ ○ PlayStation               │
│ ○ Nintendo DS               │
├─────────────────────────────┤
│ [Cancel]           [Add]    │
└─────────────────────────────┘
```

### Checklist Stage 2

- [ ] games_cache table created
- [ ] Game model
- [ ] IGDB search method
- [ ] Search provider with debounce
- [ ] Search screen UI
- [ ] Results with covers (cached_network_image)
- [ ] Platform selection dialog
- [ ] Games cache in SQLite

---

## Stage 3: Collections CRUD

**Цель:** Создание коллекций, добавление/удаление игр.

### 3.1 Database

```sql
CREATE TABLE collections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  author TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'own',
  created_at INTEGER NOT NULL,
  original_snapshot TEXT,
  forked_from_author TEXT,
  forked_from_name TEXT
);

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

### 3.2 Models

**Файл:** `lib/shared/models/collection.dart`

```dart
class Collection {
  final int id;
  final String name;
  final String author;
  final CollectionType type; // own, imported, fork
  final DateTime createdAt;
  final String? originalSnapshot;
  final String? forkedFromAuthor;
  final String? forkedFromName;
}
```

**Файл:** `lib/shared/models/collection_game.dart`

```dart
enum GameStatus { notStarted, playing, completed, dropped, planned }

class CollectionGame {
  final int id;
  final int collectionId;
  final int igdbId;
  final int platformId;
  final String? authorComment;
  final String? userComment;
  final GameStatus status;
  final DateTime addedAt;
  
  // Joined data
  final Game? game;
  final Platform? platform;
}
```

### 3.3 Repository

**Файл:** `lib/core/database/collection_repository.dart`

```dart
class CollectionRepository {
  // Collections
  Future<List<Collection>> getAll();
  Future<Collection> create(String name, String author);
  Future<void> delete(int id);
  Future<void> update(int id, {String? name});
  
  // Games in collection
  Future<List<CollectionGame>> getGames(int collectionId);
  Future<void> addGame(int collectionId, int igdbId, int platformId);
  Future<void> removeGame(int id);
  Future<void> updateGameStatus(int id, GameStatus status);
}
```

### 3.4 Collections Provider

**Файл:** `lib/features/collections/providers/collections_provider.dart`

```dart
final collectionsProvider = AsyncNotifierProvider<CollectionsNotifier, List<Collection>>;
final collectionGamesProvider = FutureProvider.family<List<CollectionGame>, int>;
final collectionStatsProvider = Provider.family<CollectionStats, int>;
```

### 3.5 Home Screen

**Файл:** `lib/features/collections/screens/home_screen.dart`

**UI:**
```
┌─────────────────────────────────────────┐
│ xeRAbora                      [⚙️]      │
├─────────────────────────────────────────┤
│ My Collections                          │
│ ┌─────────────────────────────────────┐ │
│ │ 📁 SNES Classics                    │ │
│ │    25 games • 48% completed         │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 📁 Backlog 2025                     │ │
│ │    12 games • 0% completed          │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Imported                                │
│ ┌─────────────────────────────────────┐ │
│ │ 📥 Top RPGs by retro_fan            │ │
│ │    50 games                         │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [+ New Collection]    [📂 Import]       │
└─────────────────────────────────────────┘
```

### 3.6 Collection Detail Screen

**Файл:** `lib/features/collections/screens/collection_screen.dart`

**UI:**
```
┌─────────────────────────────────────────┐
│ ← SNES Classics              [Export]   │
│ 25 games • 12 completed                 │
│ [▓▓▓▓▓▓▓▓░░░░░░░] 48%                   │
├─────────────────────────────────────────┤
│ ┌─────┐ Chrono Trigger        [✅ ▼]   │
│ │cover│ RPG • SNES                      │
│ └─────┘ 💬 "Best RPG ever"              │
│                                         │
│ ┌─────┐ Super Metroid         [🎮 ▼]   │
│ │cover│ Action • SNES                   │
│ └─────┘                                 │
│                                         │
│ ┌─────┐ Final Fantasy VI      [⬜ ▼]   │
│ │cover│ RPG • SNES                      │
│ └─────┘                                 │
├─────────────────────────────────────────┤
│           [+ Add Game]                  │
└─────────────────────────────────────────┘
```

### 3.7 Status Dropdown

```dart
enum GameStatus {
  notStarted('Not Started', '⬜'),
  playing('Playing', '🎮'),
  completed('Completed', '✅'),
  dropped('Dropped', '⏸️'),
  planned('Planned', '📋');
}
```

### Checklist Stage 3

- [x] collections table
- [x] collection_games table
- [x] Collection model
- [x] CollectionGame model
- [x] CollectionRepository
- [x] Collections provider
- [x] Home screen with list
- [x] Create collection dialog
- [x] Collection detail screen
- [x] Add game flow (search → select → add)
- [x] Remove game (swipe or button)
- [x] Status dropdown
- [x] Collection stats (progress bar)
- [x] Platform filter fix (IGDB query order)
- [x] Platform names in selection dialog
- [x] Status update in game detail sheet (reactive)
- [x] Auto-focus in platform filter sheet
- [x] Delete button on collection tile

---

## Stage 4: Export / Import

**Цель:** Шаринг коллекций через .rcoll файлы.

### 4.1 Export Service

**Файл:** `lib/core/services/export_service.dart`

```dart
class ExportService {
  Future<String> exportToJson(Collection collection, List<CollectionGame> games);
  Future<File> saveToFile(String json, String filename);
}
```

**Format:**
```json
{
  "version": 1,
  "name": "Collection Name",
  "author": "username",
  "created": "2025-02-02T12:00:00Z",
  "description": null,
  "games": [
    {"igdb_id": 1234, "platform_id": 19, "comment": "..."}
  ]
}
```

### 4.2 Import Service

**Файл:** `lib/core/services/import_service.dart`

```dart
class ImportService {
  Future<RcollFile> parseFile(File file);
  Future<Collection> import(RcollFile rcoll);
}
```

**Flow:**
1. Parse JSON
2. Extract igdb_ids
3. Batch request to IGDB: `where id = (1,2,3...)`
4. Cache games in games_cache
5. Create collection with type='imported'
6. Create collection_games entries

### 4.3 UI

**Export:**
- Button on CollectionScreen
- FilePicker.saveFile()
- Success snackbar

**Import:**
- Button on HomeScreen
- FilePicker.pickFiles(allowedExtensions: ['rcoll'])
- Loading indicator during IGDB fetch
- Success → navigate to new collection

### Checklist Stage 4

- [ ] ExportService
- [ ] ImportService
- [ ] .rcoll JSON serialization
- [ ] Batch IGDB fetch on import
- [ ] Export button + file picker
- [ ] Import button + file picker
- [ ] Loading state during import
- [ ] Imported collections marked as read-only

---

## Stage 5: Forks & Revert

**Цель:** Копирование и откат коллекций.

### 5.1 Fork Logic

**В CollectionRepository:**

```dart
Future<Collection> fork(int collectionId) async {
  final original = await getById(collectionId);
  final games = await getGames(collectionId);
  
  // Serialize original state
  final snapshot = jsonEncode({
    'name': original.name,
    'author': original.author,
    'games': games.map((g) => {
      'igdb_id': g.igdbId,
      'platform_id': g.platformId,
      'author_comment': g.authorComment,
    }).toList(),
  });
  
  // Create fork
  final fork = await create(
    name: '${original.name} (copy)',
    author: currentUser,
    type: CollectionType.fork,
    originalSnapshot: snapshot,
    forkedFromAuthor: original.author,
    forkedFromName: original.name,
  );
  
  // Copy games
  for (final game in games) {
    await addGame(fork.id, game.igdbId, game.platformId, 
      authorComment: game.authorComment);
  }
  
  return fork;
}
```

### 5.2 Revert Logic

```dart
Future<void> revertToOriginal(int collectionId) async {
  final collection = await getById(collectionId);
  final snapshot = jsonDecode(collection.originalSnapshot!);
  
  // Clear current games
  await clearGames(collectionId);
  
  // Restore from snapshot
  for (final game in snapshot['games']) {
    await addGame(collectionId, game['igdb_id'], game['platform_id'],
      authorComment: game['author_comment']);
  }
}
```

### 5.3 UI

**Imported collection:**
```
[Create Copy] button → creates fork
```

**Fork collection:**
```
Header: "Forked from: retro_fan / Top RPGs"
[Revert to Original] button → confirmation dialog → revert
```

### Checklist Stage 5

- [ ] Fork method in repository
- [ ] original_snapshot serialization
- [ ] Revert method
- [ ] "Create Copy" button for imported
- [ ] Fork header showing origin
- [ ] "Revert to Original" with confirmation
- [ ] Fork becomes editable (type=fork)

---

## Stage 6: Comments

**Цель:** Система комментариев.

### 6.1 Author Comment

- Editable only in own/fork collections
- Saved in collection_games.author_comment
- Exported in .rcoll
- Shown as "💬 Author: ..." in UI

### 6.2 User Comment

- Editable everywhere
- Saved in collection_games.user_comment
- NOT exported
- Shown as "📝 My note: ..." in UI

### 6.3 Game Detail Screen

**Файл:** `lib/features/collections/screens/game_detail_screen.dart`

**UI:**
```
┌─────────────────────────────────────────┐
│ ← Chrono Trigger                        │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │           [Cover Image]             │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Platform: SNES                          │
│ Genres: RPG                             │
│ Status: [✅ Completed ▼]                │
│                                         │
│ Summary                                 │
│ A group of adventurers travel through   │
│ time to prevent a global catastrophe... │
│                                         │
│ Author's Comment                        │
│ ┌─────────────────────────────────────┐ │
│ │ Best RPG of all time. The music,    │ │
│ │ the story, everything is perfect.   │ │
│ └─────────────────────────────────────┘ │
│ [Edit] (only if own/fork)               │
│                                         │
│ My Notes                                │
│ ┌─────────────────────────────────────┐ │
│ │ Finished all endings. Need to try   │ │
│ │ the DS version next.                │ │
│ └─────────────────────────────────────┘ │
│ [Edit]                                  │
└─────────────────────────────────────────┘
```

### Checklist Stage 6

- [ ] Game detail screen
- [ ] Author comment display
- [ ] Author comment edit (own/fork only)
- [ ] User comment display
- [ ] User comment edit (always)
- [ ] Comments shown on game cards
- [ ] Author comment in export

---

## Database Schema (Complete)

```sql
-- Platforms (from IGDB)
CREATE TABLE platforms (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  abbreviation TEXT,
  synced_at INTEGER
);

-- Games cache (from IGDB)
CREATE TABLE games_cache (
  igdb_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  cover_url TEXT,
  genres TEXT,
  summary TEXT,
  cached_at INTEGER
);

-- Collections
CREATE TABLE collections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  author TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'own',
  created_at INTEGER NOT NULL,
  original_snapshot TEXT,
  forked_from_author TEXT,
  forked_from_name TEXT
);

-- Collection games
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

-- Indexes
CREATE INDEX idx_collection_games_collection ON collection_games(collection_id);
CREATE INDEX idx_collection_games_igdb ON collection_games(igdb_id);
```

---

## File Structure (Complete)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   │   ├── database_service.dart
│   │   └── collection_repository.dart
│   ├── api/
│   │   └── igdb_api.dart
│   └── services/
│       ├── export_service.dart
│       └── import_service.dart
├── features/
│   ├── settings/
│   │   ├── screens/
│   │   │   └── settings_screen.dart
│   │   └── providers/
│   │       └── settings_provider.dart
│   ├── search/
│   │   ├── screens/
│   │   │   └── search_screen.dart
│   │   └── providers/
│   │       └── search_provider.dart
│   └── collections/
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── collection_screen.dart
│       │   └── game_detail_screen.dart
│       ├── providers/
│       │   └── collections_provider.dart
│       └── widgets/
│           ├── collection_tile.dart
│           └── game_card.dart
└── shared/
    ├── models/
    │   ├── platform.dart
    │   ├── game.dart
    │   ├── collection.dart
    │   └── collection_game.dart
    └── widgets/
        └── status_dropdown.dart
```

---

# Журнал изменений разработки

Этот раздел документирует решения, принятые во время разработки, которые отличаются от первоначального плана или содержат важные архитектурные решения.

---

## Stage 4: Progress Tracking (2026-02-05)

### Изменение: Полноэкранный GameDetailScreen вместо BottomSheet

**План:** Согласно dev.md (Stage 6 - Комментарии), предполагалось использовать BottomSheet для просмотра деталей игры.

**Решение:** Реализован полноэкранный `GameDetailScreen` вместо `_GameDetailSheet`.

**Причины:**
1. **UX улучшение** - полноэкранный просмотр позволяет показать больше информации без прокрутки
2. **Обложка игры** - SliverAppBar с FlexibleSpaceBar позволяет красиво отображать обложку с эффектом параллакса при скролле
3. **Редактирование** - диалоги редактирования комментариев лучше работают в контексте полноэкранного экрана
4. **Консистентность** - навигация через `Navigator.push()` соответствует паттерну остального приложения

**Код:**
```dart
// Было (BottomSheet):
showModalBottomSheet<void>(
  context: context,
  builder: (BuildContext context) => _GameDetailSheet(...),
);

// Стало (полноэкранный):
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (BuildContext context) => GameDetailScreen(
      collectionId: widget.collectionId,
      gameId: game.id,
      isEditable: _collection!.isEditable,
    ),
  ),
);
```

### Изменение: Использование CachedNetworkImage для обложек

**Решение:** Используется `cached_network_image` пакет для кэширования обложек игр.

**Причины:**
1. **Производительность** - изображения кэшируются локально, не загружаются повторно
2. **UX** - placeholder при загрузке, graceful fallback при ошибках
3. **Оффлайн** - кэшированные изображения доступны без интернета

### Архитектурное решение: Передача isEditable через конструктор

**Решение:** `GameDetailScreen` получает `isEditable` через конструктор, а не вычисляет его из коллекции.

**Причины:**
1. **Производительность** - не требуется дополнительный запрос коллекции
2. **Single Source of Truth** - родительский экран уже знает состояние коллекции
3. **Тестируемость** - легко мокать в тестах

### Тестирование: Override collectionRepositoryProvider вместо NotifierProvider

**Проблема:** `collectionGamesNotifierProvider` не поддерживает прямой `overrideWith` в тестах.

**Решение:** Мокаем `collectionRepositoryProvider`, от которого зависит NotifierProvider.

```dart
// Было (не работает):
collectionGamesNotifierProvider(1).overrideWith(...)

// Стало:
collectionRepositoryProvider.overrideWithValue(mockRepo)
```

**Причина:** Riverpod `AsyncNotifierProvider.family` не имеет метода `overrideWith` для семейных провайдеров. Мокирование репозитория - более чистый подход.

---

## Общие решения

### Локализация UI текстов

**Текущее состояние:** UI тексты захардкожены на английском.

**Причина:** Приоритет на функциональность. Локализация запланирована отдельным этапом.

**Тексты для локализации:**
- "Status", "Description", "Author's Comment", "My Notes"
- "Edit", "Save", "Cancel"
- "No comment yet. Tap Edit to add one."
- "No comment from the author."
- "Game not found"

### Тестирование: 16 widget тестов для GameDetailScreen

**Покрытие:**
- Отображение названия игры
- Отображение платформы (abbreviation если есть)
- Статус dropdown
- Описание игры (summary)
- Комментарий автора
- Личные заметки
- Кнопки Edit в зависимости от isEditable
- Жанры
- Год релиза
- Рейтинг (форматирование X.X/10)
- Placeholder для пустых комментариев
- Readonly сообщения
- Game not found
- Открытие/закрытие диалога редактирования

---

## Ветки и PR

| Этап | Ветка | PR | Статус |
|------|-------|-----|--------|
| Stage 1 | - | - | Merged в main |
| Stage 2 | stage-2-game-search | #2 | Merged |
| Stage 3 | feature/stage-3-collections | #3 | Merged |
| Stage 4 | feature/stage-4-progress-tracking | #4 | В разработке |

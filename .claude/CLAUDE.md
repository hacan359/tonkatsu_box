# Правила проекта xerabora

## Язык общения
Всегда отвечай на русском языке.

## Технологии
- Flutter 3.38+ / Dart 3.10+
- Платформы: Windows desktop (полная версия) + Android (без VGMaps/WebView)
- State management: **Riverpod** (NotifierProvider, AsyncNotifierProvider)
- База данных: SQLite (sqflite_common_ffi на desktop, sqflite на Android)
- API: IGDB (Twitch OAuth), TMDB (Bearer token), SteamGridDB (Bearer token)
- HTTP: Dio
- Тесты: flutter_test + mocktail

## Среда выполнения
**ВАЖНО:** Flutter SDK установлен только на Windows, не в WSL!

```bash
powershell.exe -Command "cd D:\CODE\xerabora; flutter analyze"
powershell.exe -Command "cd D:\CODE\xerabora; flutter test"
powershell.exe -Command "cd D:\CODE\xerabora; flutter run -d windows"
```

## Архитектура и структура

### Реальная структура проекта:
```
lib/
├── main.dart              # Точка входа, SQLite init, ProviderScope
├── app.dart               # TonkatsuBoxApp — MaterialApp, dark theme, SplashScreen
├── core/
│   ├── api/               # API клиенты: igdb_api, tmdb_api, steamgriddb_api
│   ├── database/          # DatabaseService — SQLite, 15 таблиц, миграции
│   └── services/          # export/import (.xcoll/.xcollx), image_cache, config
├── data/
│   └── repositories/      # canvas_repository, collection_repository, game_repository
├── features/
│   ├── collections/       # Главная фича: коллекции, canvas (Board), детали
│   │   ├── providers/     # canvas, collections, episode_tracker, steamgriddb/vgmaps panel
│   │   ├── screens/       # home, collection, game/movie/tv_show/anime detail
│   │   └── widgets/       # canvas элементы, панели, диалоги, UI компоненты
│   ├── search/            # Универсальный поиск (4 таба: Games/Movies/TV/Animation)
│   │   ├── providers/     # game_search, media_search, genre
│   │   ├── screens/       # search_screen
│   │   └── widgets/       # карточки, фильтры, сортировка
│   ├── settings/          # Настройки API keys, кэш, debug панели
│   └── splash/            # Splash screen с анимацией логотипа
└── shared/
    ├── constants/          # media_type_theme, platform_features
    ├── models/             # 19 моделей: Game, Movie, TvShow, Collection, CanvasItem...
    ├── navigation/         # NavigationShell (Rail на desktop, BottomBar на mobile)
    ├── theme/              # AppColors, AppTypography, AppSpacing, AppTheme (dark)
    └── widgets/            # CachedImage, PosterCard, RatingBadge, ShimmerLoading...
```

### Принципы:
- **Feature-based** — каждая фича в `features/{name}/screens|providers|widgets/`
- **Single Responsibility** — один класс = одна ответственность
- **Dependency Injection** — через Riverpod провайдеры
- **Immutability** — предпочитать immutable объекты, `copyWith` для изменений
- **Composition over Inheritance** — композиция вместо наследования

## Паттерны проекта

### Модели (`lib/shared/models/`)
Все модели имеют единообразный интерфейс:
```dart
class Game {
  // Именованные конструкторы для разных источников
  factory Game.fromJson(Map<String, dynamic> json);  // из API
  factory Game.fromDb(Map<String, dynamic> row);      // из SQLite
  Map<String, dynamic> toDb();                        // в SQLite
  Game copyWith({String? name, ...});                 // immutable update
}
```
Модели для экспорта реализуют `Exportable` mixin (`toExport()`).

### Riverpod провайдеры
```dart
// Синхронный state
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

// Асинхронный state (загрузка данных)
final collectionItemsProvider = AsyncNotifierProvider
    .family<CollectionItemsNotifier, List<CollectionItem>, int>(
  CollectionItemsNotifier.new,
);

// Простой провайдер зависимости
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
```

### API клиенты (`lib/core/api/`)
- Каждый API — отдельный класс с Dio + Riverpod провайдер
- `IgdbApi` — Twitch OAuth (Client Credentials), провайдер `igdbApiProvider`
- `TmdbApi` — Bearer token, провайдер `tmdbApiProvider`
- `SteamGridDbApi` — Bearer token, провайдер `steamGridDbApiProvider`
- API ключи хранятся в SharedPreferences, читаются через `SettingsNotifier`

### База данных (`lib/core/database/database_service.dart`)
- SQLite через sqflite_common_ffi, 15 таблиц, текущая версия БД: 14
- Миграции в `_onUpgrade()` — инкрементальные (v1 → v2 → ... → v14)
- Провайдер: `databaseServiceProvider`

### Тесты (`test/`)
- Зеркальная структура: `test/` повторяет `lib/`
- Моки через mocktail: `class MockDio extends Mock implements Dio {}`
- Группировка: `group('ClassName', () { group('methodName', () { ... }); });`
- Widget тесты: `ProviderScope` с overrides для моков зависимостей

### Навигация
```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (BuildContext context) => const TargetScreen(),
));
```

## Строгая типизация Dart

### ОБЯЗАТЕЛЬНО:
- **Никогда** не использовать `dynamic` — всегда явные типы
- **Никогда** не использовать `var` для публичных API — только явные типы
- **Всегда** указывать возвращаемый тип функций
- **Всегда** указывать типы параметров
- **Всегда** использовать `final` для неизменяемых переменных
- **Всегда** использовать `const` где возможно (конструкторы, значения)
- **Никогда** не использовать `!` (null assertion) без крайней необходимости
- **Всегда** обрабатывать nullable типы через `?.`, `??`, или проверки

### Пример правильного кода:
```dart
// ХОРОШО
final String userName = 'John';
const int maxRetries = 3;

Future<List<User>> fetchUsers({required int limit}) async {
  final List<User> users = await _api.getUsers(limit: limit);
  return users;
}

// ПЛОХО
var userName = 'John';  // Нет явного типа
dynamic data;           // Использование dynamic
fetchUsers(limit) {}    // Нет типов
```

## Правила написания кода

### Naming conventions:
- `UpperCamelCase` — классы, enum, typedef, расширения
- `lowerCamelCase` — переменные, функции, параметры
- `_privateVariable` — приватные члены начинаются с `_`
- `SCREAMING_CAPS` — только для deprecated констант

### Документация:
- Публичные API должны иметь `///` документацию
- **НЕ** ставить `///` в начале файла без `library` директивы (вызывает `dangling_library_doc_comments`) — использовать `//`
- Сложная логика должна иметь комментарии

### Обработка ошибок:
- Использовать кастомные Exception классы
- Всегда обрабатывать ошибки в try-catch
- Логировать ошибки с контекстом

## ОБЯЗАТЕЛЬНО для каждой задачи

### 1. Тесты (100% coverage)
После написания любого кода:
- Создать unit тесты для каждой функции/метода
- Покрыть все ветви условий (if/else/switch)
- Покрыть граничные случаи (пустые списки, null, границы)
- Покрыть обработку ошибок
- Запустить: `flutter test --coverage`

### 2. Двойное ревью
Перед завершением задачи сделать 2 круга проверки:

**Круг 1 — Функциональность:**
- Логика работает правильно?
- Все edge cases обработаны?
- Нет ли уязвимостей?
- Типизация строгая?

**Круг 2 — Качество:**
- Код читаемый?
- Нет дублирования?
- Производительность оптимальна?
- Соответствует стилю проекта?

### 3. Проверки перед завершением
```bash
flutter analyze    # Без warnings и errors
flutter test       # Все тесты проходят
```

## Запрещено
- `print()` в production коде — использовать логгер
- Хардкод строк UI — использовать локализацию
- Magic numbers — выносить в константы
- Игнорировать lint warnings
- Коммитить закомментированный код
- Использовать `setState` в сложных виджетах — использовать Riverpod

## Flutter лучшие практики

### Widgets:
- Разбивать большие виджеты на мелкие
- Использовать `const` конструкторы
- Выносить стили в отдельные константы (`AppColors`, `AppSpacing`, `AppTypography`)
- Использовать `Key` для списков

### Performance:
- Избегать rebuild всего дерева
- Использовать `const` widgets
- Ленивая загрузка для больших списков (`ListView.builder`)
- Кэшировать тяжелые вычисления

### Платформо-зависимый код:
- Проверять платформу через `platform_features.dart` (`kCanvasEnabled`, `kVgMapsEnabled`)
- VGMaps / WebView2 — только Windows
- Long press контекстное меню — Android, right-click — Windows

## Ключевые файлы для ориентации
| Файл | Описание |
|------|----------|
| `lib/core/database/database_service.dart` | Вся работа с БД (1974 строк) |
| `lib/features/collections/widgets/canvas_view.dart` | Главный виджет Board/Canvas |
| `lib/features/collections/providers/canvas_provider.dart` | State канваса |
| `lib/features/collections/providers/collections_provider.dart` | State коллекций |
| `lib/shared/models/collection_item.dart` | Универсальный элемент коллекции |
| `lib/shared/models/canvas_item.dart` | Элемент канваса (7 типов) |
| `lib/shared/theme/app_theme.dart` | Централизованная тема (dark Material 3) |
| `analysis_options.yaml` | Строгие lint правила |

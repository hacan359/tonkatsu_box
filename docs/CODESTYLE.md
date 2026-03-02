# Tonkatsu Box — Код-стандарт

Обязательные правила для всего кода в проекте Tonkatsu Box. Этот документ — источник истины; `analysis_options.yaml` обеспечивает автоматическую проверку, но не покрывает все соглашения.

## Анализатор

Проект использует максимально строгие настройки. Код не должен генерировать ни одного warning/info:

- `strict-casts: true` — нет неявных приведений
- `strict-inference: true` — нет неявного вывода типов
- `strict-raw-types: true` — нет raw-дженериков
- `always_specify_types: true` — все типы явно
- `avoid_print: true` — print запрещён, использовать `_log`
- `require_trailing_commas: true` — завершающие запятые
- `prefer_single_quotes: true` — одинарные кавычки

## Структура проекта

```
lib/
├── main.dart                 # Точка входа
├── app.dart                  # Корневой виджет
├── core/                     # Ядро (не зависит от features)
│   ├── api/                  #   API-клиенты (Dio)
│   ├── database/             #   DatabaseService, schema, миграции
│   │   └── migrations/       #     Отдельные файлы миграций
│   ├── logging/              #   AppLogger
│   └── services/             #   Export, Import, ImageCache, Config
├── data/                     # Репозитории (мост core ↔ features)
│   └── repositories/
├── features/                 # Фичи (экраны, провайдеры, виджеты)
│   ├── collections/
│   ├── home/
│   ├── search/
│   ├── settings/
│   ├── splash/
│   ├── welcome/
│   └── wishlist/
├── l10n/                     # Локализация (ARB, gen_l10n)
└── shared/                   # Общие модели, виджеты, тема
├── constants/
├── extensions/
├── gamepad/
├── models/
├── navigation/
├── theme/
└── widgets/
```

Направление зависимостей: `features → data → core → shared`. Фичи не импортируют друг друга (кроме навигации).

## Именование файлов и классов

- Файлы: `snake_case.dart`
- Классы: `PascalCase`
- Перечисления: `PascalCase`, значения `camelCase`
- Провайдеры: `camelCaseProvider` (суффикс `Provider`)
- Приватные поля: `_camelCase`
- Константы: `camelCase` (Dart-стиль, не UPPER_SNAKE)

## State Management (Riverpod)

Паттерн провайдеров:

```dart
// Простой провайдер — глобальный final
final Provider<SomeApi> someApiProvider = Provider<SomeApi>((Ref ref) {
  return SomeApi();
});

// AsyncNotifier — для состояния с загрузкой
final AsyncNotifierProvider<SomeNotifier, List<Item>>
    someProvider =
    AsyncNotifierProvider<SomeNotifier, List<Item>>(
  SomeNotifier.new,
);

class SomeNotifier extends AsyncNotifier<List<Item>> {
  late SomeRepository _repository;

  @override
  Future<List<Item>> build() async {
    _repository = ref.watch(someRepositoryProvider);
    return _repository.getAll();
  }
}
```

- Типы провайдеров указываются **явно** в объявлении
- `ref.watch()` — в `build()`, `ref.read()` — в методах-действиях

## Модели данных

Модели — immutable классы с фабричными конструкторами:

```dart
class Game {
  const Game({
    required this.id,
    required this.name,
    this.summary,
  });

  factory Game.fromJson(Map<String, dynamic> json) { ... }
  factory Game.fromDb(Map<String, dynamic> row) { ... }

  final int id;
  final String name;
  final String? summary;

  Map<String, dynamic> toDb() { ... }
  Map<String, dynamic> toJson() { ... }
  Game copyWith({...}) { ... }
}
```

Порядок в классе модели:
1. `const` конструктор
2. Фабричные конструкторы (`fromJson`, `fromDb`)
3. Поля (`final`)
4. Геттеры/computed-свойства
5. Методы (`toDb`, `toJson`, `copyWith`)

## Логирование

### Правила

- `print()` и `debugPrint()` — **запрещены** (`avoid_print: true`)
- Для логирования использовать `package:logging`
- Инициализация: `AppLogger.init()` в `main()` до `runApp()`
- Логи выводятся через `dart:developer` `log()` (видны в Flutter DevTools)

### Уровни логирования

| Уровень | Когда использовать | Пример |
|---------|-------------------|--------|
| `_log.fine()` | Детали для отладки, обычно шумно | `_log.fine('Loaded 42 platforms')` |
| `_log.info()` | Важные события жизненного цикла | `_log.info('Database upgraded to v23')` |
| `_log.warning()` | Ошибки, которые не ломают приложение | `_log.warning('Failed to load genre map', e)` |
| `_log.severe()` | Критические ошибки | `_log.severe('Database creation failed', e, stackTrace)` |

### Размещение логгера

Статическое поле `_log` размещается **первым** в теле класса:

```dart
class IgdbApi {
  static final Logger _log = Logger('IgdbApi');

  // ... остальные поля и методы
}
```

Имя логгера = имя класса.

### Правило catch-блоков

**Запрещено** писать `catch (_)` без логирования (кроме осознанных ситуаций вроде repair-миграции v16). Каждый catch должен либо:
- логировать ошибку: `_log.warning('описание', e)`
- пробрасывать её дальше: `rethrow`
- иметь комментарий, почему ошибка намеренно игнорируется

```dart
// ✅ Правильно
} catch (e) {
  _log.warning('Failed to download image: $imageId', e);
  return false;
}

// ✅ Правильно — осознанное игнорирование с комментарием
} on DatabaseException catch (_) {
  // Колонка уже существует — repair-миграция, безопасно игнорировать.
}

// ❌ Запрещено — молчаливый catch
} catch (_) {
  return false;
}
```

### Где добавлять логгер

Логгер **обязателен** в:
- Всех классах в `lib/core/` (API, Database, Services)
- Всех репозиториях в `lib/data/repositories/`
- Всех Notifier/AsyncNotifier в `lib/features/*/providers/`

Логгер **не нужен** в:
- Моделях (`lib/shared/models/`)
- Статических утилитах без side-effects
- Виджетах (кроме debug-экранов)

## Миграции БД

Каждая миграция — отдельный файл в `lib/core/database/migrations/`:

```dart
class MigrationV24 extends Migration {
  @override
  int get version => 24;

  @override
  String get description => 'Brief description in English';

  @override
  Future<void> migrate(Database db) async {
    // SQL-операции
  }
}
```

Процедура добавления:
1. Создать `migration_v24.dart`
2. Добавить `MigrationV24()` в `MigrationRegistry.all`
3. Обновить `version: 24` в `_initDatabase()`
4. Если нужна новая таблица — добавить метод в `DatabaseSchema` и вызвать из `createAll()`

## Документация

- Doc-комментарии (`///`) — на русском
- На всех публичных классах и методах
- На приватных методах, если логика неочевидна
- Inline-комментарии (`//`) — по ситуации, русский или английский

```dart
/// Сервис для работы с SQLite базой данных.
///
/// Управляет инициализацией базы данных и CRUD операциями.
class DatabaseService {
```

## Импорты

Порядок групп (разделённых пустой строкой):
1. `dart:` стандартная библиотека
2. `package:` внешние пакеты
3. Относительные импорты проекта

```dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/game.dart';
import '../../shared/models/platform.dart';
```

## Тестирование

- Тесты зеркалят структуру `lib/` → `test/`
- Используется `mocktail` для моков
- In-memory SQLite (`sqflite_common_ffi`, `inMemoryDatabasePath`) для тестов БД
- Тест-файлы: `*_test.dart`

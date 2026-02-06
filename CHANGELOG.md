# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [Unreleased]

### Added
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

# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [Unreleased]

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

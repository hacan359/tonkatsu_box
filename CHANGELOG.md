# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [Unreleased]

### Added
- Добавлена фича «Wishlist» — заметки для отложенного поиска контента (5-й таб навигации)
  - Модель `WishlistItem` (`lib/shared/models/wishlist_item.dart`) с `fromDb()`, `toDb()`, `copyWith()`
  - Таблица `wishlist` в SQLite, миграция v18→v19, 8 CRUD методов в `DatabaseService`
  - `WishlistRepository` (`lib/data/repositories/wishlist_repository.dart`) — тонкая обёртка над БД
  - `WishlistNotifier` (`wishlistProvider`) — AsyncNotifier с оптимистичным обновлением state
  - `activeWishlistCountProvider` — счётчик активных (не resolved) элементов для badge
  - `WishlistScreen` — ListView с FAB, popup menu (Search/Edit/Resolve/Delete), фильтр resolved, clear resolved
  - `AddWishlistDialog` — создание/редактирование заметки с опциональным типом медиа (ChoiceChip: Game/Movie/TV/Animation)
  - 5-й таб «Wishlist» в `NavigationShell` с Badge (количество активных заметок)
  - Тап на заметку → переход в `SearchScreen` с предзаполненным запросом
  - Resolved заметки: зачёркнутый текст, opacity 0.5, в конце списка
  - Добавлены тесты: wishlist_item_test (10), database_service_test (+13 Wishlist CRUD), wishlist_repository_test (8), wishlist_provider_test (11), wishlist_screen_test (12), add_wishlist_dialog_test (10), navigation_shell_test (обновлены для 5 табов)
- Добавлен параметр `initialQuery` в `SearchScreen` — предзаполнение поля поиска и автоматический запуск поиска при открытии из Wishlist

### Added
- Добавлен тайловый фон на всех экранах — `background_tile.png` (паттерн геймпада) зациклен через `ImageRepeat.repeat` с `opacity: 0.03` и `scale: 0.667` в `MaterialApp.builder`
  - Путь к ассету в `AppAssets.backgroundTile`
  - `scaffoldBackgroundColor` в теме изменён на `Colors.transparent` для прозрачности Scaffold-ов
  - Удалён явный `backgroundColor: AppColors.background` с 16 экранов (28 Scaffold-ов)
- Обновлены иконки приложения (Android + Windows) через `flutter_launcher_icons`

### Fixed
- Исправлен crash `Null check operator used on a null value` в `CanvasNotifier.removeByCollectionItemId()` и `removeMediaItem()` — добавлен null-guard для `_collectionId`

### Added
- Добавлена поддержка мультиплатформенных игр — одна и та же игра может быть добавлена в коллекцию с разными платформами (SNES, GBA и т.д.) с независимым прогрессом, рейтингом и заметками
  - Миграция БД v17→v18: UNIQUE индексы `collection_items` расширены на `COALESCE(platform_id, -1)` для различения записей по платформе
  - Метод `DatabaseService.getUniquePlatformIds()` — получение уникальных ID платформ из игровых элементов (опционально по коллекции)
  - Метод `DatabaseService.deleteCanvasItemByCollectionItemId()` — удаление канвас-элемента по ID элемента коллекции
  - Метод `CanvasRepository.deleteByCollectionItemId()` — обёртка для удаления канвас-элементов
  - Провайдер `allItemsPlatformsProvider` (`all_items_provider.dart`) — FutureProvider уникальных платформ из игровых элементов
- Добавлен фильтр платформ на экранах Home (AllItemsScreen) и Collection (CollectionScreen)
  - При выборе типа "Games" появляется второй ряд ChoiceChip с платформами (All + список платформ из текущих элементов)
  - Фильтрация работает совместно с фильтром типа медиа
  - Смена типа медиа автоматически сбрасывает выбранную платформу
- Добавлен бейдж платформы на постер-карточках игр — параметр `platformLabel` в `MediaPosterCard`, отображается как subtitle
- Добавлены тесты: `database_service_test.dart` (+11 тестов: multi-platform UNIQUE index, getUniquePlatformIds), `all_items_provider_test.dart` (+5 тестов: allItemsPlatformsProvider), `all_items_screen_test.dart` (+4 теста: платформенный фильтр), `canvas_repository_test.dart` (+2 теста: deleteByCollectionItemId)

### Changed
- Рефакторинг синхронизации канваса (`canvas_provider.dart`) — ключи элементов изменены с `"mediaType:externalId"` на `collectionItemId` (уникальный PK), что позволяет корректно различать одну игру на разных платформах
- Обновлена `_syncCanvasWithItems()` и `removeByCollectionItemId()` в `CanvasNotifier` для работы с `collectionItemId`

### Added
- Добавлена фича «Move to Collection» — перемещение элементов между коллекциями и в/из uncategorized
  - Метод `DatabaseService.updateItemCollectionId()` — обновление `collection_id` и `sort_order` элемента
  - Метод `CollectionRepository.moveItemToCollection()` — перемещение с обработкой UNIQUE constraint
  - Метод `CollectionItemsNotifier.moveItem()` — перемещение с инвалидацией всех связанных провайдеров
  - Shared диалог `collection_picker_dialog.dart` — выбор коллекции с sealed class `CollectionChoice` (`ChosenCollection` / `WithoutCollection`), параметры `excludeCollectionId`, `showUncategorized`
  - `PopupMenuButton` на экранах деталей (Game, Movie, TV Show, Anime) — пункты «Move to Collection» и «Remove» (заменяет одиночную кнопку Remove)
  - `PopupMenuButton` на тайлах `_CollectionItemTile` в `CollectionScreen` — «Move» и «Remove» (заменяет одиночный `IconButton` Remove)
- Добавлены тесты: `anime_detail_screen_test.dart` (31 тест), `collection_picker_dialog_test.dart` (12 тестов), `database_service_test.dart` (тесты updateItemCollectionId), дополнены `collection_repository_test.dart` (moveItemToCollection: success, duplicate, not found)

### Changed
- Рефакторинг `SearchScreen` — sealed class `CollectionChoice` и метод `_showCollectionSelectionDialog()` вынесены в shared `collection_picker_dialog.dart`, удалено ~80 строк дублирующего кода
- Скрыта вкладка Board на экранах деталей для uncategorized-элементов (`collectionId == null`) — геттер `_hasCanvas` на 4 detail screens, `TabController(length: _hasCanvas ? 2 : 1)`
- Инвалидация `uncategorizedItemCountProvider` при добавлении/удалении элементов в `CollectionItemsNotifier.addItem()` и `removeItem()`
- Улучшен сброс базы данных (`DatabaseScreen._resetDatabase`) — добавлена инвалидация 7 провайдеров (`collectionsProvider`, `uncategorizedItemCountProvider`, `allItemsNotifierProvider`, `collectedGameIdsProvider`, `collectedMovieIdsProvider`, `collectedTvShowIdsProvider`, `collectedAnimationIdsProvider`) + навигация `pushReplacement(NavigationShell)` для полного сброса стеков всех табов
- Обновлены провайдеры канваса, SteamGridDB панели, VGMaps панели и трекера эпизодов для поддержки nullable `collectionId`

### Fixed
- Исправлен crash `FileImage._loadAsync: Bad state: File is empty` — добавлен sync guard в `CachedImage` перед `Image.file()`: проверка `existsSync()` и `lengthSync() > 0` с fallback на сетевое изображение
- Исправлена валидация кэша: `ImageCacheService.isImageCached()` теперь проверяет целостность файла через magic bytes (`_isValidImageFile`), а не только существование
- Исправлено сохранение пустых файлов в кэш: `ImageCacheService.saveImageBytes()` отклоняет пустые данные (`bytes.isEmpty`)
- Исправлен сброс БД не обновляющий UI — элементы оставались на экранах до перезапуска приложения

### Added
- Добавлен виджет `BreadcrumbAppBar` (`lib/shared/widgets/breadcrumb_app_bar.dart`) — навигационные хлебные крошки: логотип 20x20 + разделители `›` + кликабельные крошки. Поддержка `bottom` (TabBar), `actions`, горизонтальный скролл. Последняя крошка — жирная (w600), остальные кликабельные (w400)
- Добавлен экран-хаб `SettingsScreen` — 4 карточки навигации: Credentials, Cache, Database, Debug (только kDebugMode). Заменяет монолитный экран настроек (~1118 строк)
- Добавлены подэкраны настроек: `CredentialsScreen` (IGDB/SteamGridDB/TMDB API ключи), `CacheScreen` (кэш изображений), `DatabaseScreen` (export/import/reset), `DebugHubScreen` (3 debug-инструмента)
- Добавлен параметр `collectionName` в экраны деталей (`GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`, `AnimeDetailScreen`) для отображения в хлебных крошках
- Добавлены тесты: `breadcrumb_app_bar_test.dart` (21 тест), `settings_screen_test.dart` (15 тестов, переписан), `credentials_screen_test.dart` (43 теста), `database_screen_test.dart` (11 тестов), `cache_screen_test.dart` (8 тестов), `debug_hub_screen_test.dart` (10 тестов)

### Changed
- Все экраны переведены на `BreadcrumbAppBar` вместо стандартного AppBar: AllItemsScreen, HomeScreen, CollectionScreen, SearchScreen, все detail screens, все debug screens
- Логотип вынесен выше NavigationRail в `NavigationShell` (desktop) — `Column(logo, Expanded(Rail))` вместо `Rail.leading`
- Реструктуризация Settings: монолитный экран (~1118 строк) разбит на хаб + 4 подэкрана с навигацией через `Navigator.push`
- Debug screens (IGDB Media, SteamGridDB, Gamepad) используют `BreadcrumbAppBar` с крошками Settings › Debug › {name}

### Removed
- Удалён монолитный код SettingsScreen (секции credentials, cache, database, danger zone — перенесены в отдельные экраны)
- Удалён `settings_screen_config_test.dart` — покрытие перенесено в `database_screen_test.dart`

### Added
- Добавлен экран All Items (Home tab) — отображает все элементы из всех коллекций в grid-виде с PosterCard, именем коллекции как subtitle. Чипсы фильтрации по типу медиа (All/Games/Movies/TV Shows/Animation) и ActionChip сортировки по рейтингу (toggle asc/desc). Loading, empty, error states. RefreshIndicator
- Добавлена 4-табная навигация: Home (все элементы), Collections, Search, Settings. Ранее было 3 таба: Home (коллекции), Search, Settings
- Добавлены провайдеры `allItemsSortProvider`, `allItemsSortDescProvider`, `allItemsNotifierProvider`, `collectionNamesProvider` (`lib/features/home/providers/all_items_provider.dart`)
- Добавлены методы `DatabaseService.getAllCollectionItems()` и `getAllCollectionItemsWithData()` — загрузка элементов из всех коллекций (с опциональной фильтрацией по типу медиа)
- Добавлен метод `CollectionRepository.getAllItemsWithData()`
- Добавлена утилита `applySortMode()` (`lib/features/collections/providers/sort_utils.dart`) — вынесена общая логика сортировки из `CollectionItemsNotifier`

### Changed
- Изменена навигация `NavigationShell`: `NavTab` enum расширен до 4 значений (home, collections, search, settings), `_tabCount = 4`, `AllItemsScreen` загружается eager, остальные tabs lazy
- Рефакторинг `CollectionItemsNotifier._applySortMode()` → вызывает shared `applySortMode()` из `sort_utils.dart`
- Добавлена инвалидация `allItemsNotifierProvider` при добавлении/удалении элементов в `CollectionItemsNotifier`
- Исправлен баг `_loadFromPrefs()` в sort-нотифайерах: добавлен `await Future<void>.value()` чтобы state не перезаписывался return в build()

### Changed
- Оптимизирован запуск на Android — ленивая инициализация табов в `NavigationShell`: SearchScreen и SettingsScreen строятся только при первом переключении на таб (убирает 4 тяжёлых DB-запроса и загрузку платформ при старте)
- Добавлена платформенная проверка в `GamepadService` — на мобильных (Android/iOS) сервис не запускается и не подписывается на `Gamepads.events`, что снижает нагрузку при старте
- Оптимизирован `SplashScreen` — pre-warming базы данных выполняется параллельно с 2-секундной анимацией логотипа. Навигация происходит только когда И анимация завершена, И DB открыта — это разводит DB-инициализацию и route transition по времени, предотвращая ANR на слабых устройствах
- Уменьшена длительность FadeTransition при переходе с splash на главный экран на мобильных: 200ms вместо 500ms

### Added
- Добавлен виджет `DualRatingBadge` (`lib/shared/widgets/dual_rating_badge.dart`) — двойной рейтинг `★ 8 / 7.5` (пользовательский + API). Режимы: badge (затемнённый фон на постере), compact (уменьшенный), inline (без фона, для list-карточек). Геттеры `hasRating`, `formattedRating`
- Добавлен виджет `MediaPosterCard` (`lib/shared/widgets/media_poster_card.dart`) — единая вертикальная постерная карточка с enum `CardVariant` (grid/compact/canvas). Grid/compact: hover-анимация, DualRatingBadge, отметка коллекции, статус-бейдж, title+subtitle. Canvas: Card с цветной рамкой по типу медиа, без hover/рейтинга
- Добавлены геттеры `CollectionItem.apiRating` (нормализованный 0–10: IGDB/10, TMDB as-is) и `CollectionItem.itemDescription` (game.summary / movie.overview / tvShow.overview) в `lib/shared/models/collection_item.dart`
- Добавлены тесты: `dual_rating_badge_test.dart` (25 тестов), `media_poster_card_test.dart` (46 тестов), дополнены `collection_item_test.dart` (+20 тестов apiRating/itemDescription)

### Changed
- Изменён `collection_screen.dart` — `PosterCard` заменён на `MediaPosterCard(variant: grid/compact)` с двойным рейтингом. `_CollectionItemTile` обогащён: DualRatingBadge inline, описание (1 строка), заметки пользователя (иконка `note_outlined`). Удалён метод `_normalizedRating()`
- Изменён `search_screen.dart` — `PosterCard` заменён на `MediaPosterCard(variant: grid/compact)` с API рейтингом
- Изменён `canvas_view.dart` — `CanvasGameCard`/`CanvasMediaCard` заменены на `MediaPosterCard(variant: canvas)` через единый helper `_buildMediaCard(CanvasItem)`

### Removed
- Удалён `PosterCard` (`lib/shared/widgets/poster_card.dart`) — заменён на `MediaPosterCard(variant: grid/compact)` (~340 строк)
- Удалён `MediaCard` (`lib/shared/widgets/media_card.dart`) — мёртвый код после редизайна SearchScreen (~323 строки)
- Удалены `GameCard`, `MovieCard`, `TvShowCard` (`lib/features/search/widgets/`) — мёртвый код (~361 строка)
- Удалены `CanvasGameCard`, `CanvasMediaCard` (`lib/features/collections/widgets/`) — заменены на `MediaPosterCard(variant: canvas)` (~282 строки)
- Удалены тесты удалённых виджетов: 7 файлов (~2792 строки). Итого: -3604 строки кода

### Added
- Добавлен пользовательский рейтинг (1-10) — новое поле `userRating` в `CollectionItem`, миграция БД v14→v15 (`ALTER TABLE collection_items ADD COLUMN user_rating INTEGER`), метод `DatabaseService.updateItemUserRating()`
- Добавлен виджет `StarRatingBar` (`lib/shared/widgets/star_rating_bar.dart`) — 10 кликабельных звёзд с InkWell (focusable для геймпада), повторный клик на текущий рейтинг сбрасывает оценку
- Добавлена секция "My Rating" на экранах деталей (Game, Movie, TV Show, Anime) — между Status и My Notes, отображает `StarRatingBar` с текущим значением и label "X/10"
- Добавлен режим сортировки `CollectionSortMode.rating` — сортировка по пользовательскому рейтингу (высшие первыми, без оценки — в конце)

### Changed
- Переименована секция "Author's Comment" → "Author's Review" на экранах деталей — добавлена подпись "Visible to others when shared. Your review of this title." для пояснения назначения
- Изменён порядок секций на экранах деталей: Header → Status → My Rating → **My Notes** → **Author's Review** → Activity & Progress (ранее Author's Comment шёл перед My Notes)
- Изменён `CollectionItem.copyWith()` — добавлены sentinel-флаги `clearAuthorComment` и `clearUserComment` для возможности очистки комментариев (установки в `null`)
- Изменён `CollectionItemsNotifier` — методы `updateAuthorComment` и `updateUserComment` используют sentinel-флаги при передаче `null`, добавлен метод `updateUserRating` с валидацией диапазона 1-10
- Дополнительные секции (Activity Dates, Episode Progress) обёрнуты в `ExpansionTile` "Activity & Progress" (свёрнуто по умолчанию)

### Fixed
- Исправлена невозможность очистить комментарий автора и личные заметки — `copyWith` использовал `??` для nullable String-полей, что не позволяло установить `null`

### Added
- Добавлена визуальная доска (Board) на Android — `kCanvasEnabled` теперь возвращает `true` на всех платформах, Board доступен в коллекциях и на экранах деталей (игры, фильмы, сериалы, анимация)
- Добавлено контекстное меню по long press на мобильных устройствах — long press на пустом месте доски открывает меню добавления элементов (текст/изображение/ссылка), long press на элементе — меню редактирования (Edit/Delete/Connect и т.д.)
- Увеличен размер resize handle на мобильных устройствах (24px вместо 14px) для удобства тач-ввода
- Добавлен zoom-to-fit при открытии Board — на мобильных контент автоматически масштабируется, чтобы все элементы помещались в viewport с отступами

### Changed
- Переименован «Canvas» → «Board» во всех пользовательских текстах (28 вхождений): вкладка «Board» в коллекции и на экранах деталей, tooltip замка «Lock/Unlock board», SnackBar «Image/Map added to board», кнопка «Add to Board» в VGMaps, описание формата экспорта, сообщения импорта, описание сброса БД в настройках, пустые состояния доски
- Скрыта кнопка VGMaps Browser и пункт меню «Browse maps...» на не-Windows платформах — VGMaps требует `webview_windows`, доступен только на Windows через `kVgMapsEnabled`
- Упрощена подсказка режима создания связей: «Tap an element to create a connection.» вместо «Click on an element to create a connection. Press Escape to cancel.»

### Added
- Добавлен экспорт canvas-изображений в полный экспорт `.xcollx` — изображения с канваса (`CanvasItemType.image`) теперь включаются в секцию `images` с ключом `canvas_images/{hash}`
- Добавлен полный офлайн-экспорт: секция `media` в `.xcollx` содержит данные Game/Movie/TvShow (через `toDb()` без `cached_at`). При импорте данные восстанавливаются из файла через `fromDb()` — API-вызовы не требуются
- Добавлен этап `ImportStage.restoringMedia` для отслеживания прогресса восстановления медиа-данных
- Добавлено поле `media` в `XcollFile` с поддержкой сериализации/десериализации
- Добавлен метод `ExportService._collectMediaData()` — сбор Game/Movie/TvShow из joined полей элементов с дедупликацией по ID
- Добавлены методы `ImportService._restoreEmbeddedMedia()` и `_fetchMediaFromApi()` — условный импорт: офлайн из файла или онлайн из API
- Добавлена предзагрузка сезонов сериалов при добавлении tvShow/animation-сериала в коллекцию — `_preloadSeasons()` в `SearchScreen` (fire-and-forget, не блокирует UI). Сезоны кэшируются в `tv_seasons_cache` для офлайн-доступа
- Добавлены `tv_seasons` в полный экспорт `.xcollx` — сезоны сериалов собираются из кэша БД и включаются в секцию `media.tv_seasons`. `ExportService._collectMediaData()` стал async, принимает `DatabaseService`
- Добавлено восстановление `tv_seasons` при импорте `.xcollx` — `ImportService._restoreEmbeddedMedia()` парсит `media.tv_seasons` и восстанавливает через `TvSeason.fromDb()` с отслеживанием прогресса
- Добавлены счётчики элементов на filter chips коллекции — каждый чип показывает количество: All (N), Games (N), Movies (N), TV Shows (N), Animation (N)
- Добавлены `tv_episodes` в полный экспорт `.xcollx` — эпизоды всех сезонов сериалов собираются из кэша БД и включаются в секцию `media.tv_episodes`. Метод `DatabaseService.getEpisodesByShowId()` возвращает все эпизоды сериала. Запросы сезонов и эпизодов выполняются параллельно через `Future.wait`
- Добавлено восстановление `tv_episodes` при импорте `.xcollx` — `ImportService._restoreEmbeddedMedia()` парсит `media.tv_episodes` и восстанавливает через `TvEpisode.fromDb()` / `upsertEpisodes()` с отслеживанием прогресса

### Fixed
- Исправлен маппинг `ImageType` для анимации: `_imageTypeFor()` в `CollectionScreen`, `HeroCollectionCard` и `CanvasMediaCard` теперь учитывает `platformId` — анимационные сериалы (`AnimationSource.tvShow`) отображают обложки из `tv_show_posters` вместо `movie_posters`
- Исправлена обработка повреждённых кэшированных изображений: `CachedImage` теперь при ошибке декодирования (`Codec failed to produce an image`) удаляет битый файл из кэша, показывает изображение из сети (fallback) и перекачивает файл в фоне. Добавлен метод `ImageCacheService.deleteImage()`. Флаг `_corruptHandled` предотвращает повторные вызовы при rebuild
- Исправлен диалог экспорта: выбор формата (Light/Full) теперь показывается всегда, а не только при наличии canvas данных

### Changed
- Изменён `_AppRouter` — приложение больше не блокируется без API ключей, только поиск недоступен
- Изменён `SearchScreen` — при отсутствии API ключей показывает заглушку вместо интерфейса поиска
- Увеличена ширина кнопок Save в настройках: 80px → 100px (текст не обрезается на узких экранах)
- Уменьшены размеры шрифтов на 2px для лучшего отображения на Android (h1: 26, h2: 18, h3: 14, body: 12, bodySmall: 11, caption: 10)

### Fixed
- Исправлена валидация API ключей: при пустом поле показывается ошибка вместо ложного успеха

### Removed
- Удалены персональные данные прогресса из экспорта коллекции: `status`, `current_season`, `current_episode` больше не включаются в `.xcoll`/`.xcollx` файлы. При импорте старых файлов с этими полями — обратная совместимость сохранена
- Удалён класс `CollectionGame` и enum `GameStatus` (`lib/shared/models/collection_game.dart`) — полностью заменены на `CollectionItem` и `ItemStatus`
- Удалён `CollectionGamesNotifier` и провайдеры `collectionGamesProvider`, `collectionGamesNotifierProvider` из `collections_provider.dart` (~180 строк)
- Удалён legacy-маппинг статуса `'playing'` — статус `inProgress` теперь единообразен для всех типов медиа. Миграция БД v13→v14 обновляет существующие записи
- Удалён метод `ItemStatus.dbValue(MediaType)` — везде используется `ItemStatus.value`
- Удалён формат v1 (.rcoll): класс `RcollGame`, константа `xcollLegacyVersion`, методы `_parseV1()`, `createXcollFile()`, `exportToLegacyJson()`, `_importV1()`. Файлы v1 при попытке импорта выбрасывают `FormatException`
- Удалены этапы импорта `ImportStage.cachingGames` и `ImportStage.addingGames` (использовались только v1)
- Удалены геттеры `XcollFile.isV1`, `XcollFile.isV2`, `XcollFile.gameIds`, поле `XcollFile.legacyGames`
- Удалены legacy-методы из `DatabaseService`: `getCollectionGames()`, `getCollectionGamesWithData()`, `getCollectionGameById()`, `addGameToCollection()`, `removeGameFromCollection()`, `updateGameStatus()`, `getCollectionGameCount()`, `getCompletedGameCount()`, `getCollectionStats()`, `clearCollectionGames()` и др.
- Удалены legacy-методы из `CollectionRepository`: `getGames()`, `getGamesWithData()`, `addGame()`, `removeGame()`, `updateGameStatus()` и др.
- Удалено поле `CollectionStats.playing` — заменено на `inProgress`
- Удалён файл `test/shared/models/collection_game_test.dart`

### Changed
- Изменён `GameDetailScreen` — рефакторинг с `CollectionGame`/`collectionGamesNotifierProvider` на `CollectionItem`/`collectionItemsNotifierProvider`, параметр `gameId` → `itemId`
- Изменён `SearchScreen` — `addGame()` заменён на `addItem(mediaType: MediaType.game, ...)` через `collectionItemsNotifierProvider`
- Изменён формат fork snapshot — ключ `'games'` заменён на `'items'` с полями `media_type`/`external_id`/`platform_id`
- Изменена версия БД: 13 → 14

### Added
- Добавлена вкладка Animation в универсальном поиске — 4-й таб, объединяющий анимационные фильмы и анимационные сериалы из TMDB (жанр Animation, genre_id=16). Анимация фильтруется клиентски из результатов Movies и TV Shows
- Добавлен `MediaType.animation` в enum `MediaType` с `displayLabel: 'Animation'`, `fromString('animation')`
- Добавлен `AnimationSource` — abstract final class с константами `movie = 0`, `tvShow = 1` для дискриминации источника анимации через `collection_items.platform_id`
- Добавлен `CanvasItemType.animation` с `fromMediaType(MediaType.animation)`, `isMediaItem` возвращает true
- Добавлен экран `AnimeDetailScreen` (`lib/features/collections/screens/anime_detail_screen.dart`) — адаптивный: movie-like layout (runtime, без episode tracker) для `AnimationSource.movie`, tvShow-like layout (episode tracker, seasons) для `AnimationSource.tvShow`. Accent color: `AppColors.animationAccent`
- Добавлен виджет `AnimationCard` (`lib/features/search/widgets/animation_card.dart`) — карточка анимации в поиске с бейджем "Movie"/"Series" для различения типа источника
- Добавлен filter chip `Animation` в `CollectionScreen` для фильтрации элементов коллекции по типу
- Добавлен цвет `animationColor = Color(0xFF9C27B0)` (фиолетовый) в `MediaTypeTheme` и `animationAccent = Color(0xFFCE93D8)` в `AppColors`
- Добавлен провайдер `collectedAnimationIdsProvider` в `collections_provider.dart`
- Добавлены тесты: `animation_source_test.dart`, обновлены `media_type_test.dart`, `canvas_item_test.dart`, `media_type_theme_test.dart`, `collection_item_test.dart`, `media_search_provider_test.dart`

### Changed
- Изменён `MediaSearchNotifier` — добавлен `MediaSearchTab.animation`, фильтрация по genre_id=16: Animation tab показывает только анимацию, Movies/TV Shows табы исключают анимацию
- Изменён `SearchScreen` — `TabController(length: 4)`, 4-й таб Animation с объединённым списком animated movies + TV shows
- Изменён `CollectionScreen` — обновлены все switch expressions (8 штук) для `MediaType.animation`: рейтинг, год, субтитры, imageType, навигация на `AnimeDetailScreen`, иконка `Icons.animation`
- Изменён `CanvasMediaCard` — обновлены все switch expressions (6 штук) для `CanvasItemType.animation`: imageType, imageId, borderColor (фиолетовый), posterUrl, title, placeholderIcon
- Изменён `CanvasView` — обновлены switch expressions (5 штук) для `CanvasItemType.animation`
- Изменён `CanvasRepository._enrichItemsWithMediaData()` — animation items ищутся параллельно в movies и tvShows по refId
- Изменён `DatabaseService._loadJoinedData()` — case `MediaType.animation` по `platformId` добавляет ID в `movieIds` или `tvShowIds`
- Изменён `CollectionStats` — добавлено поле `animationCount`
- Изменён `CollectionItem` — `itemName`, `coverUrl`, `thumbnailUrl` учитывают `MediaType.animation` с проверкой `platformId` для movie/tvShow
- Изменён `HeroCollectionCard` — animation → `ImageType.moviePoster`
- Изменён `ExportService` / `ImportService` — поддержка animation при экспорте/импорте

- Добавлен замок канваса (View Mode Lock) — кнопка-замок в AppBar для блокировки канваса в режим просмотра. Доступен только для собственных/fork коллекций. При блокировке боковые панели (SteamGridDB, VGMaps) закрываются автоматически. Реализован на `CollectionScreen`, `GameDetailScreen`, `MovieDetailScreen`, `TvShowDetailScreen`
- Добавлено сохранение режима отображения коллекции (grid/list) в SharedPreferences — при переключении выбор запоминается per-collection и восстанавливается при следующем открытии. Ключ `SettingsKeys.collectionViewModePrefix` в `settings_provider.dart`

### Added
- Добавлен виджет `StatusChipRow` — горизонтальный ряд chip-кнопок для выбора статуса на detail-экранах (все статусы видны сразу, тап = выбор, AnimatedContainer для плавных переходов)
- Добавлен виджет `StatusRibbon` — диагональная ленточка статуса в верхнем левом углу list-карточек (display only, цвет из `ItemStatus.color`, emoji + метка)
- Добавлен геттер `ItemStatus.color` — единый маппинг статус→цвет, устранено дублирование `_getStatusColor()`
- Добавлен статус-бейдж (цветной кружок с эмодзи) на `PosterCard` в grid-режиме коллекции — новый параметр `ItemStatus? status`
- Добавлен шрифт Inter (Regular, Medium, SemiBold, Bold) в `assets/fonts/`
- Добавлен `AppTheme` (`lib/shared/theme/app_theme.dart`) — централизованная тёмная тема через `AppColors`, стилизация всех Material-компонентов
- Добавлены стили `posterTitle` и `posterSubtitle` в `AppTypography`
- Добавлены константы `radiusLg`, `radiusXl`, `posterAspectRatio`, `gridColumnsDesktop/Tablet/Mobile` в `AppSpacing`
- Добавлен виджет `RatingBadge` (`lib/shared/widgets/rating_badge.dart`) — цветной бейдж рейтинга (зелёный ≥8, жёлтый ≥6, красный <6)
- Добавлены виджеты shimmer-загрузки (`lib/shared/widgets/shimmer_loading.dart`) — `ShimmerBox`, `ShimmerPosterCard`, `ShimmerListTile` с анимированным градиентом
- Добавлен виджет `PosterCard` (`lib/shared/widgets/poster_card.dart`) — вертикальная карточка 2:3 с постером, RatingBadge, hover-анимацией и отметкой коллекции
- Добавлен виджет `HeroCollectionCard` (`lib/shared/widgets/hero_collection_card.dart`) — большая карточка коллекции с градиентным фоном, прогресс-баром и статистикой
- Добавлена адаптивная навигация в `NavigationShell` — `BottomNavigationBar` при ширине <800px, `NavigationRail` при ≥800px
- Добавлен режим сетки в `CollectionScreen` — переключение list/grid, `PosterCard` в `GridView.builder`
- Добавлены фильтры в `CollectionScreen` — фильтр по типу медиа (All/Games/Movies/TV Shows) через `ChoiceChip`, поиск по имени

### Changed
- Заменён `PopupMenuButton` dropdown на `StatusChipRow` (ряд чипов) на detail-экранах (game, movie, tv_show)
- Заменён compact dropdown на `StatusRibbon` (диагональная ленточка) на list-карточках `_CollectionItemTile` — статус теперь display only, смена только на detail-экране
- Перенесена кнопка "New Collection" из FAB в AppBar (IconButton "+") на `HomeScreen`
- Перенесена кнопка "Add Items" из FAB в AppBar (IconButton "+") на `CollectionScreen`
- Мигрирован `game_detail_screen.dart` с legacy `StatusDropdown` (GameStatus) на `StatusChipRow` (ItemStatus) с конвертацией через `toItemStatus()`/`_toGameStatus()`
- Углублена тёмная палитра `AppColors`: background `#121212`→`#0A0A0A`, surface `#1E1E1E`→`#141414`, surfaceLight `#2A2A2A`→`#1E1E1E`, surfaceBorder `#3A3A3A`→`#2A2A2A`, textPrimary `#E0E0E0`→`#FFFFFF`
- Добавлены цвета рейтинга в `AppColors`: `ratingHigh` (#22C55E), `ratingMedium` (#FBBF24), `ratingLow` (#EF4444)
- Добавлен цвет статуса `statusPlanned` (#8B5CF6) в `AppColors`
- Установлен минимальный размер окна 800×600 (`windows/runner/win32_window.cpp`, `WM_GETMINMAXINFO`)
- Изменён `AppTypography` — шрифт Inter (`fontFamily: 'Inter'`), `letterSpacing: -0.5` для h1, `-0.2` для h2
- Изменён `app.dart` — принудительно тёмная тема (`ThemeMode.dark`), удалены `_lightTheme`/`_darkTheme`/`_buildTheme()`, подключён `AppTheme.darkTheme`
- Изменён `HomeScreen` — `CustomScrollView` со Slivers, первые коллекции как `HeroCollectionCard`, shimmer-загрузка
- Изменён `SearchScreen` — результаты поиска в виде сетки `PosterCard` вместо горизонтальных карточек, затемнение постеров
- Изменён `MediaDetailView` — все цвета через `AppColors`/`AppTypography`, постер увеличен 80×120→100×150, добавлен параметр `accentColor` для per-media окрашивания
- Изменены detail screens (Game, Movie, TvShow) — fallback AppBars стилизованы через `AppColors`, добавлены per-media `accentColor` (movieAccent, tvShowAccent)
- Изменён `SettingsScreen` — кнопки Export/Import адаптивные (Row при ≥400px, Column при <400px), `Theme.of(context).colorScheme.error` заменён на `AppColors.error`
- Изменён `MediaCard` — постер увеличен 60×80→64×96
- Изменён `ImageCacheService` — eager-кэширование обложки при добавлении элемента в коллекцию из поиска, валидация magic bytes (JPEG/PNG/WebP) вместо проверки размера, безопасное удаление файлов при блокировке Windows

### Fixed
- Исправлен overflow заголовков секций в `SettingsScreen` — текст в `Row` обёрнут в `Flexible` с `TextOverflow.ellipsis` (7 секций)
- Исправлен overflow `ListTile` с кнопкой очистки кэша в `SettingsScreen` — `TextButton.icon` заменён на `IconButton`
- Исправлен vertical overflow в `SearchScreen` empty/error states — `Column` заменён на `SingleChildScrollView` + `MainAxisSize.min`
- Исправлен crash `PathAccessException` на Windows при удалении занятого файла в `ImageCacheService` (errno 32)
- Исправлена ошибка `Invalid image data` при загрузке битых кэшированных файлов — валидация magic bytes
- Исправлено отображение чужой обложки на карточке в сетке поиска — добавлен `ValueKey` на `PosterCard` в `GridView`
- Исправлен критический баг миграции БД: колонка `collection_item_id` отсутствовала в `CREATE TABLE` для `canvas_items` и `canvas_connections` при свежей установке (Android). Запросы с `WHERE collection_item_id IS NULL` падали с ошибкой `no such column`
- Исправлен overflow 47/128px в `CreateCollectionDialog` при открытии клавиатуры на Android — `Column` обёрнут в `SingleChildScrollView`
- Исправлен overflow 1.6px в `_CollectionItemTile` на Android (text scale > 1.0) — обложка увеличена с 48×64 до 48×72
- Исправлен overflow 38px справа в `HeroCollectionCard` на узком экране — добавлен `maxLines: 1` и `overflow: TextOverflow.ellipsis` к тексту статистики, уменьшена мозаика с 80 до 64px
- Исправлена работа `FilePicker` на Android: `FileType.custom` заменён на `FileType.any` с ручной проверкой расширения (в `ImportService`, `ExportService`, `ConfigService`)
- Исправлена производительность старта на Android (308 пропущенных кадров) — `_preloadTmdbGenres()` и `_loadPlatformCount()` отложены через `Future.microtask()`
- Исправлен overflow 128px в `_buildEmptyState()` и `_buildErrorState()` на Android при открытой клавиатуре — `Padding` заменён на `SingleChildScrollView`

---

### Added
- Добавлена дизайн-система для тёмной темы: `AppColors`, `AppSpacing`, `AppTypography` (`lib/shared/theme/`)
- Добавлен `NavigationShell` с `NavigationRail` — боковая навигация (Home, Search, Settings)
- Добавлены виджеты: `SectionHeader` (заголовок секции с кнопкой действия)

### Removed
- Удалён виджет `ItemStatusDropdown` и `ItemStatusChip` (`item_status_dropdown.dart`) — заменены на `StatusChipRow` и `StatusRibbon`
- Удалён legacy виджет `StatusDropdown` и `StatusChip` (`status_dropdown.dart`) — заменены на `StatusChipRow`
- Удалены FAB-кнопки "New Collection" и "Add Items" — перенесены в AppBar
- Удалена цветная полоска статуса (3px) на `_CollectionItemTile` — заменена на `StatusRibbon`
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

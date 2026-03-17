# UX: Обновление коллекций и элементов

## Исходные задачи

- Добавить clone (copy элемента из одной коллекции в другую)
- Добавить фильтр поиска коллекций, по алфавиту, проверить можно ли добавить фильтр по признаку последний обновленный, сохранять выбранные фильтры.
- На странице поиска, если элемент уже в коллекции, при нажатии добавить кнопку перейти в деталку объекта

---

## Техническое задание

### Задача 1: Клонирование (копирование) элемента между коллекциями

**Цель:** Пользователь может скопировать элемент из одной коллекции в другую, сохраняя оригинал на месте.

**Текущее состояние:**
- Существует только `moveItem` — перемещение (удаляет из источника)
- UNIQUE constraint `(collection_id, media_type, external_id)` запрещает дубли в одной коллекции
- При move в коллекцию, где элемент уже есть — возвращается `false`, показывается info snackbar

**Решение:** Полная копия — все пользовательские данные переносятся в клон.

**Что копируется, а что нет:**

| Поле | В клоне | Почему |
|------|---------|--------|
| `id` | Новый (autoincrement) | Новая запись в БД |
| `collection_id` | Целевая коллекция | Весь смысл clone |
| `media_type` | Копия | Тот же тип медиа |
| `external_id` | Копия | Та же игра/фильм/сериал |
| `platform_id` | Копия | Та же платформа |
| `status` | Копия | Полная копия прогресса |
| `author_comment` | Копия | Комментарий автора сохраняется |
| `user_comment` | Копия | Личный комментарий сохраняется |
| `user_rating` | Копия | Оценка сохраняется |
| `current_season` | Копия | Прогресс сериала сохраняется |
| `current_episode` | Копия | Прогресс сериала сохраняется |
| `started_at` | Копия | Даты активности сохраняются |
| `completed_at` | Копия | Даты активности сохраняются |
| `last_activity_at` | Копия | Даты активности сохраняются |
| `sort_order` | `getNextSortOrder()` | Встаёт в конец целевой коллекции |
| `added_at` | `DateTime.now()` | Дата клонирования, не оригинала |
| **Canvas items** | **НЕ копируются** | Канвас — отдельная раскладка у каждой коллекции, позиции не переносимы |
| **Tier list entries** | **НЕ копируются** | Тир-листы привязаны к конкретной коллекции |

**Защита от дубликатов:** UNIQUE constraint `(collection_id, media_type, external_id)` — если элемент уже есть в целевой коллекции, `DatabaseException.isUniqueConstraintError()` → возвращаем `false`, info snackbar.

**Что нужно сделать:**

#### Этап 1.1: Слой данных (DAO + Repository)
- [ ] В `collection_dao.dart` — новый метод `cloneItemToCollection(int itemId, int targetCollectionId)`:
  - SELECT исходного элемента по `itemId`
  - INSERT новой записи с полной копией полей (см. таблицу выше)
  - `sort_order` = `getNextSortOrder(targetCollectionId)`
  - `added_at` = `DateTime.now()`
  - Обрабатывает UNIQUE constraint — возвращает `null` при дубликате (аналогично `addItemToCollection`)
  - Возвращает `int?` — ID нового элемента или `null`
- [ ] В `collection_repository.dart` — новый метод `cloneItemToCollection(int itemId, int targetCollectionId)` — делегирует в DAO

#### Этап 1.2: Провайдер
- [ ] В `collections_provider.dart` (`CollectionItemsNotifier`) — новый метод `cloneItem`:
  - Принимает `int itemId`, `int targetCollectionId`, `MediaType mediaType`
  - Вызывает `repository.cloneItemToCollection(itemId, targetCollectionId)`
  - При успехе — инвалидирует провайдеры целевой коллекции (`collectionItemsNotifierProvider`, `collectionStatsProvider`, `collectionCoversProvider`)
  - Инвалидирует `collectedIds` провайдеры и `allItemsNotifierProvider`
  - Возвращает `bool` (успех/дубликат)

#### Этап 1.3: UI — контекстное меню элемента
- [ ] В контекстном меню элемента коллекции (long press на Android, right-click на Windows) — добавить пункт "Копировать в коллекцию..." рядом с "Переместить в коллекцию..."
- [ ] Пункт открывает `showCollectionPickerDialog` с `alreadyInCollectionIds`
- [ ] По выбору коллекции — вызывает `cloneItem`, показывает success/info snackbar

#### Этап 1.4: Тесты
- [ ] Unit-тест `cloneItemToCollection` в DAO (успех + проверка скопированных полей, дубликат → `null`, несуществующий item)
- [ ] Unit-тест метода в repository
- [ ] Unit-тест `cloneItem` в provider (успех + инвалидация провайдеров, дубликат, canvas/tier-list не затронуты)
- [ ] Widget-тест: пункт "Копировать в коллекцию" отображается в контекстном меню

---

### Задача 2: Сортировка и переключение вида списка коллекций на Home Screen

**Цель:** Пользователь может сортировать коллекции (по алфавиту, дате создания), переключать вид (grid/list), и все выборы сохраняются между сессиями.

**Текущее состояние:**
- Home screen показывает коллекции в `GridView.builder` с `CollectionCard` (мозаика обложек в стиле iOS-папки)
- Порядок `created_at DESC` (захардкожено в DAO)
- Есть только `TypeToFilterOverlay` — поиск по имени (фильтрация по подстроке)
- Сортировка элементов внутри коллекции уже реализована по паттерну: `CollectionSortNotifier` + `CollectionSortDescNotifier` → `SharedPreferences`, `family` провайдеры
- Сортировка элементов — в памяти (Dart `sort()`), не через SQL — делаем так же

**Решения:**
- **Сортировка** — в памяти (Dart). DAO возвращает список как есть, UI сортирует. Коллекций 10–50, консистентно с `sort_utils.dart`.
- **List-вариант** — простой: название + статистика в строку, без картинок. Дизайн будет дорабатываться позже.
- **Выбор вида** — сохраняется в SharedPreferences.

**Режимы сортировки (первый шаг):**
- **По дате создания** (`createdAt`) — дефолт, текущее поведение
- **По алфавиту** (`name`) — A→Z / Z→A

> **Будущее:** `updatedAt` (миграция БД, автообновление при изменениях) — отдельная задача, когда понадобится.

**Что нужно сделать:**

#### Этап 2.1: Enum сортировки коллекций
- [ ] Новый файл `lib/shared/models/collection_list_sort_mode.dart`
- [ ] Enum `CollectionListSortMode` — `createdDate`, `alphabetical`
- [ ] Поля: `value` (для SharedPreferences), `displayLabel`, `shortLabel`, `description`
- [ ] Локализованные методы (`localizedDisplayLabel(S l)` и т.д.) — по аналогии с `CollectionSortMode`

#### Этап 2.2: Провайдеры (сортировка + вид)
- [ ] В `collections_provider.dart` — новые провайдеры:
  - `collectionListSortProvider` — `NotifierProvider<CollectionListSortNotifier, CollectionListSortMode>`
  - `collectionListSortDescProvider` — `NotifierProvider<CollectionListSortDescNotifier, bool>`
  - `collectionListViewModeProvider` — `NotifierProvider<CollectionListViewModeNotifier, bool>` (true = grid, false = list)
- [ ] Ключи SharedPreferences: `collection_list_sort_mode`, `collection_list_sort_desc`, `collection_list_grid_view`
- [ ] Дефолты: `createdDate`, `descending = false` (новые первыми), `gridView = true` (текущее поведение)

#### Этап 2.3: List-виджет (простой вариант без картинок)
- [ ] Новый виджет `CollectionListTile` в `collection_card.dart` (или отдельный файл):
  - `ListTile` с названием коллекции + статистика ("12 items, 75%") как subtitle
  - `onTap` + `onLongPress` — те же callbacks что у `CollectionCard`
- [ ] `UncategorizedListTile` — аналог `UncategorizedCard` для list-вида

#### Этап 2.4: Применение сортировки и переключение вида в Home Screen
- [ ] В `_buildCollectionsList` — после фильтрации по имени, применить сортировку:
  - `createdDate` + desc=false → `created_at DESC` (новые первыми, дефолт)
  - `createdDate` + desc=true → `created_at ASC` (старые первыми)
  - `alphabetical` + desc=false → `name ASC` (A→Z)
  - `alphabetical` + desc=true → `name DESC` (Z→A)
- [ ] `ref.watch` на провайдеры сортировки и вида — автоматический rebuild
- [ ] Если `gridView = true` → текущий `GridView.builder` с `CollectionCard` / `UncategorizedCard`
- [ ] Если `gridView = false` → `ListView.builder` с `CollectionListTile` / `UncategorizedListTile`

#### Этап 2.5: UI — кнопки в AppBar
- [ ] Кнопка сортировки (`Icons.sort`) → `PopupMenuButton`:
  - По дате создания
  - По алфавиту
  - Разделитель + toggle направления (↑/↓)
  - Визуальная индикация: если не дефолт — иконка подсвечивается `AppColors.brand`
- [ ] Кнопка переключения вида (`Icons.grid_view` / `Icons.view_list`) — toggle между grid и list

#### Этап 2.6: Тесты
- [ ] Unit-тесты `CollectionListSortMode` (fromString, все значения)
- [ ] Unit-тесты `CollectionListSortNotifier` (дефолт, setSortMode, сохранение в SharedPreferences)
- [ ] Unit-тесты `CollectionListSortDescNotifier` (toggle, setDescending)
- [ ] Unit-тесты `CollectionListViewModeNotifier` (toggle, сохранение)
- [ ] Unit-тесты сортировки списка: оба режима × оба направления
- [ ] Widget-тест: кнопки сортировки и вида в AppBar
- [ ] Widget-тест: переключение grid ↔ list отображает правильные виджеты

---

### Задача 3: Кнопка "Открыть в коллекции" на карточках поиска

**Цель:** Если элемент уже есть в коллекции — рядом с кнопкой "Add" показать кнопку "Open in collection", которая навигирует к деталке элемента в коллекции.

**Текущее состояние:**
- На карточках `MediaPosterCard` уже есть бейдж-галочка (`isInCollection`) — визуальная индикация работает
- `_collectedIdsProvider` в `BrowseGrid` собирает `Set<int>` для каждого типа медиа — **но только ID, без `CollectedItemInfo`**
- `collectedGameIdsProvider` и аналоги возвращают `Map<externalId, List<CollectedItemInfo>>` с `recordId`, `collectionId`, `collectionName` — достаточно для навигации
- `ItemDetailScreen` принимает: `collectionId` (int?), `itemId` (int), `isEditable` (bool)
- Текущий тап на карточку: если `collectionId != null` → добавление; если `null` → bottom sheet с деталями
- Ничего не ломаем — кнопка Add и текущий тап остаются как есть

**Поведение новой кнопки "Open in collection":**
- Кнопка появляется **только** когда элемент уже в коллекции(ях)
- Если элемент в **1 коллекции** → сразу navigate к `ItemDetailScreen`
- Если элемент в **нескольких коллекциях** → диалог выбора коллекции → navigate к деталке выбранной
- Работает в обоих режимах SearchScreen (`collectionId != null` и Browse)

**Навигация к деталке:**
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ItemDetailScreen(
    collectionId: info.collectionId,  // из CollectedItemInfo
    itemId: info.recordId,            // из CollectedItemInfo
    isEditable: true,                 // own-коллекции всегда editable
  ),
));
```

**Что нужно сделать:**

#### Этап 3.1: Расширить данные в BrowseGrid
- [ ] `BrowseGrid` сейчас получает только `Set<int>` (ID) для маркировки — нужен доступ к полным `CollectedItemInfo` для навигации
- [ ] Передавать `Map<int, List<CollectedItemInfo>>` вместо `Set<int>` (или дополнительно) — чтобы `BrowseGrid` мог передать callback навигации в карточку
- [ ] Альтернатива: передавать `onOpenInCollection` callback из `SearchScreen` в `BrowseGrid`, аналогично `onItemTap`

#### Этап 3.2: UI — кнопка на карточке MediaPosterCard
- [ ] Новый параметр `onOpenInCollection` (VoidCallback?) в `MediaPosterCard`
- [ ] Если `onOpenInCollection != null` — показать маленькую иконку-кнопку (например `Icons.open_in_new` или `Icons.launch`) рядом с бейджем "в коллекции"
- [ ] Кнопка не должна конфликтовать с основным тапом по карточке

#### Этап 3.3: Логика навигации в SearchScreen
- [ ] Новый метод `_openItemInCollection(int externalId, MediaType mediaType)`:
  - Получает `List<CollectedItemInfo>` из соответствующего `collected*IdsProvider`
  - Если 1 запись → сразу `Navigator.push(ItemDetailScreen(...))`
  - Если несколько → диалог выбора коллекции (простой `SimpleDialog` или `BottomSheet` со списком `collectionName`) → navigate
- [ ] Передать этот метод как callback в `BrowseGrid` → `MediaPosterCard`

#### Этап 3.4: Тесты
- [ ] Unit-тесты: `_openItemInCollection` — 1 коллекция (прямая навигация), несколько коллекций (диалог)
- [ ] Widget-тесты: кнопка "Open in collection" появляется только для элементов в коллекции
- [ ] Widget-тесты: кнопка не появляется для элементов не в коллекции
- [ ] Widget-тесты: навигация к `ItemDetailScreen` с правильными параметрами

---

## Порядок реализации

Задачи независимы друг от друга, можно делать в любом порядке:

1. **Задача 2** — сортировка коллекций (самая простая, не требует миграции БД)
2. **Задача 1** — клонирование элементов (DAO + провайдер + UI)
3. **Задача 3** — навигация к деталке из поиска
4. **Тесты** — писать параллельно с каждым этапом

## Статус выполнения

| Задача | Статус | Дата |
|--------|--------|------|
| 1. Клонирование элементов | Готово | 2026-03-17 |
| 2. Сортировка и вид коллекций | Готово | 2026-03-17 |
| 3. Кнопка "Открыть в коллекции" | Готово | 2026-03-17 |

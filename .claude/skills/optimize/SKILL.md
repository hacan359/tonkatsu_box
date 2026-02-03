---
name: optimize
description: Оптимизация кода по производительности, памяти и читаемости. Используй для улучшения существующего кода.
---

# Оптимизация кода

## Процесс оптимизации

### 1. Профилирование (найти узкие места)

#### Flutter DevTools:
```bash
flutter run --profile
# Открыть DevTools и проанализировать:
# - CPU Profiler
# - Memory
# - Performance overlay
```

#### Метрики для отслеживания:
- Время рендеринга фреймов (< 16ms для 60fps)
- Использование памяти
- Количество rebuild виджетов
- Время запуска приложения

### 2. Оптимизация алгоритмов

#### Сложность:
| Было | Стало | Пример |
|------|-------|--------|
| O(n²) | O(n log n) | Сортировка |
| O(n²) | O(n) | Вложенные циклы → Map/Set |
| O(n) | O(1) | Линейный поиск → HashMap |

#### Примеры:
```dart
// ПЛОХО: O(n²)
for (final item in list1) {
  if (list2.contains(item)) { ... }
}

// ХОРОШО: O(n)
final set2 = list2.toSet();
for (final item in list1) {
  if (set2.contains(item)) { ... }
}
```

### 3. Оптимизация памяти

#### Избегать:
- Создание объектов в циклах
- Копирование больших коллекций
- Удержание ссылок на неиспользуемые объекты
- Утечки через подписки и listeners

#### Решения:
```dart
// Переиспользовать объекты
final _dateFormat = DateFormat('yyyy-MM-dd'); // Один раз

// Использовать const
const _defaultPadding = EdgeInsets.all(16);

// Отписываться в dispose
@override
void dispose() {
  _subscription.cancel();
  _controller.dispose();
  super.dispose();
}
```

### 4. Оптимизация Flutter виджетов

#### Уменьшить rebuild:
```dart
// ПЛОХО: весь список перестраивается
ListView(
  children: items.map((i) => ItemWidget(i)).toList(),
)

// ХОРОШО: только видимые элементы
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

#### Использовать const:
```dart
// ПЛОХО
return Container(
  padding: EdgeInsets.all(16),  // Создаётся каждый build
  child: Text('Hello'),
);

// ХОРОШО
return const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
);
```

#### Разделять виджеты:
```dart
// ПЛОХО: весь виджет перестраивается при изменении counter
class MyWidget extends StatefulWidget {
  Widget build(context) {
    return Column(
      children: [
        Text('Counter: $counter'),  // Меняется
        HeavyWidget(),              // Не меняется, но перестраивается
      ],
    );
  }
}

// ХОРОШО: вынести неизменяемое
class MyWidget extends StatefulWidget {
  Widget build(context) {
    return Column(
      children: [
        CounterText(counter: counter),
        const HeavyWidget(),  // Не перестраивается
      ],
    );
  }
}
```

### 5. Оптимизация async операций

#### Параллельное выполнение:
```dart
// ПЛОХО: последовательно
final users = await fetchUsers();
final posts = await fetchPosts();

// ХОРОШО: параллельно
final results = await Future.wait([
  fetchUsers(),
  fetchPosts(),
]);
```

#### Кэширование:
```dart
class CachedRepository {
  final Map<String, User> _cache = {};

  Future<User> getUser(String id) async {
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }
    final user = await _api.fetchUser(id);
    _cache[id] = user;
    return user;
  }
}
```

#### Debounce для частых вызовов:
```dart
Timer? _debounce;

void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    performSearch(query);
  });
}
```

### 6. Checklist оптимизации

- [ ] Нет O(n²) алгоритмов где можно лучше
- [ ] Нет создания объектов в build()
- [ ] const используется везде где возможно
- [ ] ListView.builder для длинных списков
- [ ] Подписки отменяются в dispose()
- [ ] Тяжёлые вычисления вынесены из UI thread
- [ ] Изображения оптимизированы (размер, кэш)
- [ ] Нет лишних setState/rebuild

### 7. Валидация

После оптимизации:
```bash
# Проверить что ничего не сломалось
flutter test

# Проверить производительность
flutter run --profile
# Использовать Performance overlay (P в консоли)
```

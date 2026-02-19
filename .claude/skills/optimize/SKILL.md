---
name: optimize
description: Code optimization for performance, memory, and readability. Use to improve existing code.
---

# Code Optimization

## Optimization Process

### 1. Profiling (Find Bottlenecks)

#### Flutter DevTools:
```bash
flutter run --profile
# Open DevTools and analyze:
# - CPU Profiler
# - Memory
# - Performance overlay
```

#### Metrics to Track:
- Frame rendering time (< 16ms for 60fps)
- Memory usage
- Widget rebuild count
- App startup time

### 2. Algorithm Optimization

#### Complexity:
| Before | After | Example |
|--------|-------|---------|
| O(n²) | O(n log n) | Sorting |
| O(n²) | O(n) | Nested loops → Map/Set |
| O(n) | O(1) | Linear search → HashMap |

#### Examples:
```dart
// BAD: O(n²)
for (final item in list1) {
  if (list2.contains(item)) { ... }
}

// GOOD: O(n)
final set2 = list2.toSet();
for (final item in list1) {
  if (set2.contains(item)) { ... }
}
```

### 3. Memory Optimization

#### Avoid:
- Creating objects in loops
- Copying large collections
- Holding references to unused objects
- Leaks through subscriptions and listeners

#### Solutions:
```dart
// Reuse objects
final _dateFormat = DateFormat('yyyy-MM-dd'); // Once

// Use const
const _defaultPadding = EdgeInsets.all(16);

// Unsubscribe in dispose
@override
void dispose() {
  _subscription.cancel();
  _controller.dispose();
  super.dispose();
}
```

### 4. Flutter Widget Optimization

#### Reduce Rebuilds:
```dart
// BAD: entire list rebuilds
ListView(
  children: items.map((i) => ItemWidget(i)).toList(),
)

// GOOD: only visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

#### Use const:
```dart
// BAD
return Container(
  padding: EdgeInsets.all(16),  // Created every build
  child: Text('Hello'),
);

// GOOD
return const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
);
```

#### Split Widgets:
```dart
// BAD: entire widget rebuilds when counter changes
class MyWidget extends StatefulWidget {
  Widget build(context) {
    return Column(
      children: [
        Text('Counter: $counter'),  // Changes
        HeavyWidget(),              // Doesn't change but rebuilds
      ],
    );
  }
}

// GOOD: extract immutable parts
class MyWidget extends StatefulWidget {
  Widget build(context) {
    return Column(
      children: [
        CounterText(counter: counter),
        const HeavyWidget(),  // Doesn't rebuild
      ],
    );
  }
}
```

### 5. Async Operations Optimization

#### Parallel Execution:
```dart
// BAD: sequential
final users = await fetchUsers();
final posts = await fetchPosts();

// GOOD: parallel
final results = await Future.wait([
  fetchUsers(),
  fetchPosts(),
]);
```

#### Caching:
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

#### Debounce for Frequent Calls:
```dart
Timer? _debounce;

void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    performSearch(query);
  });
}
```

### 6. Optimization Checklist

- [ ] No O(n²) algorithms where better is possible
- [ ] No object creation in build()
- [ ] const used everywhere possible
- [ ] ListView.builder for long lists
- [ ] Subscriptions cancelled in dispose()
- [ ] Heavy computations moved off UI thread
- [ ] Images optimized (size, cache)
- [ ] No unnecessary setState/rebuild

### 7. Validation

After optimization:
```bash
# Verify nothing is broken
flutter test

# Check performance
flutter run --profile
# Use Performance overlay (P in console)
```

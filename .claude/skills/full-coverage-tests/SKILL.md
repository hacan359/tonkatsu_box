---
name: full-coverage-tests
description: Creates unit tests with 100% code coverage. Use after writing any code or when requested by user.
---

# Creating Tests — Only Logic, No UI

## Scope

**Тестируем ТОЛЬКО логику:**
- Модели (fromJson, fromDb, toDb, copyWith, геттеры, операторы)
- Сервисы и репозитории (CRUD, бизнес-логика, обработка ошибок)
- Провайдеры Riverpod (state transitions, async logic)
- API клиенты (запросы, парсинг, обработка ошибок)
- Утилиты, хелперы, расширения
- Миграции БД (структура данных, seed data)

**НЕ тестируем:**
- Наличие конкретных виджетов/кнопок/текстов в UI (find.text, find.byType для UI элементов)
- Визуальное расположение элементов
- Стили, цвета, размеры
- Навигацию между экранами
- Любые widget tests типа "должен показывать кнопку X" или "должен отображать текст Y"

## Process

### 1. Code Analysis
- Read all the code that needs test coverage
- Identify all public methods and functions
- Find all conditional branches (if/else/switch/try-catch)
- Determine edge cases

### 2. Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassName', () {
    late ClassName sut; // System Under Test

    setUp(() {
      sut = ClassName();
    });

    group('methodName', () {
      test('should return X when Y', () {
        // Arrange
        final input = ...;

        // Act
        final result = sut.methodName(input);

        // Assert
        expect(result, equals(expected));
      });
    });
  });
}
```

### 3. What to Cover (Checklist)

#### For each function/method:
- [ ] Happy path (successful scenario)
- [ ] Empty input (null, [], '')
- [ ] Boundary values (0, -1, maxInt)
- [ ] Invalid input
- [ ] All if/else branches
- [ ] All switch cases
- [ ] Exception handling (try-catch)

#### For async code:
- [ ] Successful execution
- [ ] Timeout
- [ ] Network/API error
- [ ] Operation cancellation

#### For models:
- [ ] fromJson — all fields, missing fields, null fields
- [ ] fromDb — all fields, missing fields
- [ ] toDb — round-trip (fromDb → toDb → fromDb)
- [ ] copyWith — each field individually, no-change copy
- [ ] Computed getters (displayName, urls, etc.)
- [ ] equality / toString if overridden

#### For providers (Riverpod):
- [ ] Initial state
- [ ] State after method calls
- [ ] Error states
- [ ] Dependencies (mock ref.watch/ref.read)

### 4. Mocks and Stubs
```dart
// Use mocktail for mocks
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

// In tests
final MockDatabaseService mockDb = MockDatabaseService();
when(() => mockDb.getAllPlatforms()).thenAnswer((_) async => <Platform>[]);
```

### 5. Coverage Verification
```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (optional)
genhtml coverage/lcov.info -o coverage/html
```

### 6. Completion Criteria
- All tests pass (`flutter test`)
- All logic branches covered
- Edge cases tested
- No missed error handling paths

## Test Naming Convention
```
should [expected result] when [condition]
```

Examples:
- `should return empty list when no data exists`
- `should throw exception when id is invalid`
- `should parse all fields from valid JSON`
- `should fallback to default when abbreviation is null`

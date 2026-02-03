---
name: full-coverage-tests
description: Создаёт unit тесты с 100% покрытием кода. Используй после написания любого кода или по запросу пользователя.
---

# Создание тестов с 100% покрытием

## Процесс

### 1. Анализ кода
- Прочитай весь код который нужно покрыть тестами
- Выдели все публичные методы и функции
- Найди все условные ветви (if/else/switch/try-catch)
- Определи граничные случаи

### 2. Структура тестов
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ИмяКласса', () {
    late ИмяКласса sut; // System Under Test

    setUp(() {
      sut = ИмяКласса();
    });

    group('имяМетода', () {
      test('должен вернуть X когда Y', () {
        // Arrange
        final input = ...;

        // Act
        final result = sut.имяМетода(input);

        // Assert
        expect(result, equals(expected));
      });
    });
  });
}
```

### 3. Что покрывать (чеклист)

#### Для каждой функции/метода:
- [ ] Happy path (успешный сценарий)
- [ ] Пустые входные данные (null, [], '')
- [ ] Граничные значения (0, -1, maxInt)
- [ ] Невалидные входные данные
- [ ] Все ветви if/else
- [ ] Все case в switch
- [ ] Обработка исключений (try-catch)

#### Для async кода:
- [ ] Успешное выполнение
- [ ] Таймаут
- [ ] Ошибка сети/API
- [ ] Отмена операции

#### Для UI (Widget tests):
- [ ] Рендеринг в разных состояниях
- [ ] Взаимодействие пользователя (tap, scroll, input)
- [ ] Отображение ошибок
- [ ] Loading состояния

### 4. Моки и стабы
```dart
// Используй mocktail для моков
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

// В тесте
final mockRepo = MockUserRepository();
when(() => mockRepo.getUser(any())).thenAnswer((_) async => testUser);
```

### 5. Проверка покрытия
```bash
# Запустить тесты с покрытием
flutter test --coverage

# Сгенерировать HTML отчёт (опционально)
genhtml coverage/lcov.info -o coverage/html
```

### 6. Критерии завершения
- Все тесты проходят (`flutter test`)
- Покрытие строк >= 100%
- Покрытие ветвей >= 100%
- Нет пропущенных edge cases

## Naming convention для тестов
```
должен [ожидаемый результат] когда [условие]
```

Примеры:
- `должен вернуть пустой список когда данных нет`
- `должен выбросить исключение когда id невалидный`
- `должен показать loading когда данные загружаются`

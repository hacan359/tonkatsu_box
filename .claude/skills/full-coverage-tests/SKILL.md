---
name: full-coverage-tests
description: Creates unit tests with 100% code coverage. Use after writing any code or when requested by user.
---

# Creating Tests with 100% Coverage

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

#### For UI (Widget tests):
- [ ] Rendering in different states
- [ ] User interaction (tap, scroll, input)
- [ ] Error display
- [ ] Loading states

### 4. Mocks and Stubs
```dart
// Use mocktail for mocks
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

// In tests
final mockRepo = MockUserRepository();
when(() => mockRepo.getUser(any())).thenAnswer((_) async => testUser);
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
- Line coverage >= 100%
- Branch coverage >= 100%
- No missed edge cases

## Test Naming Convention
```
should [expected result] when [condition]
```

Examples:
- `should return empty list when no data exists`
- `should throw exception when id is invalid`
- `should show loading when data is being fetched`

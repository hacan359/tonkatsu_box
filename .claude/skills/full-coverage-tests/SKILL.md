---
name: full-coverage-tests
description: Creates unit and widget tests using shared test helpers (test/helpers/). Targets behaviour coverage of new/changed code. Use after writing any code or when requested by user.
---

# Creating Tests for New Code

## IMPORTANT: Shared Test Helpers

The project uses shared helpers in test/helpers/. Read this directory before writing any test.

### Required Import

One import replaces all mocks, builders, fallbacks, and pumpApp:

  import '../../helpers/test_helpers.dart';

Path depends on nesting depth:
  test/core/api/          -> ../../helpers/test_helpers.dart
  test/features/home/     -> ../../../helpers/test_helpers.dart
  test/shared/models/     -> ../../helpers/test_helpers.dart

### Forbidden

- DO NOT declare mock classes inside test files if they exist in test/helpers/mocks.dart
- DO NOT write registerFallbackValue() inline — use registerAllFallbacks() in setUpAll()
- DO NOT construct Collection(...), CollectionStats(...) manually — use createTestCollection(), createTestStats() from builders.dart
- DO NOT write ProviderScope + MaterialApp + localizationsDelegates manually — use tester.pumpApp()

### When Local Declaration is OK

- Mock/Fake is used only in this one file and does not exist in mocks.dart
- Test data is unique to a specific test case
- If you create a new mock — check if other tests need it too. If yes — add to mocks.dart

---

## What to Test vs What NOT to Test

### DO TEST (logic and behavior):
- Method returns correct value for given input
- State changes after an action (status updated, item added/removed)
- Error handling (exception thrown, error state set)
- Async flows (loading -> data, loading -> error)
- Navigation triggers (screen pushes on tap)
- Conditional rendering (widget shown/hidden based on state)
- Callbacks fire correctly (onTap called, onChanged called with value)
- Data transformations (model parsing, JSON mapping, filtering, sorting)
- Provider state transitions
- Repository CRUD operations

### DO NOT TEST (visual details):
- Button labels and text content — "Save" vs "Submit" is cosmetic, not logic
- Colors — AppColors.brand vs AppColors.error is a design decision
- Font sizes, weights, styles — typography is not behavior
- Icon types — Icons.add vs Icons.plus is cosmetic
- Padding, margins, spacing — layout is not logic
- Border radius, shadows, decorations — visual styling
- Exact widget types for styling wrappers — dont assert find.byType(Container)
- Localized string values — test that text IS displayed, not WHAT exact string

### Why This Matters

Visual tests are brittle. Every design tweak breaks them. A test like
expect(find.text('Save'), findsOneWidget) breaks when you rename the button
to "Submit" or translate to Russian — but nothing is actually broken.
Tests should break only when behavior breaks.

### Examples

BAD — testing visual details:

  test('save button has brand color', () {
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style?.backgroundColor, AppColors.brand);
  });

  test('title shows "My Collection"', () {
    expect(find.text('My Collection'), findsOneWidget);
  });

  test('icon is Icons.folder', () {
    expect(find.byIcon(Icons.folder), findsOneWidget);
  });

GOOD — testing behavior:

  test('should save collection when save button is tapped', () async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    verify(() => mockRepo.save(any())).called(1);
  });

  test('should display collection name from data', () {
    final collection = createTestCollection(name: 'RPG Games');
    // ... setup ...
    expect(find.text('RPG Games'), findsOneWidget);
    // OK — testing that data flows to UI, not a static label
  });

  test('should navigate to detail on item tap', () async {
    await tester.tap(find.byType(CollectionCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(CollectionScreen), findsOneWidget);
  });

### Clarification: Data-Driven Text is OK

Testing that dynamic data renders correctly IS behavior:

  // OK — data flows from model to UI
  expect(find.text('23 items'), findsOneWidget); // computed from stats.total
  expect(find.text('RPG Games'), findsOneWidget); // from collection.name

  // NOT OK — static UI labels
  expect(find.text('Collections'), findsOneWidget); // screen title
  expect(find.text('Add new'), findsOneWidget);     // button label
  expect(find.text('No items yet'), findsOneWidget); // empty state message

---

## Process

### 1. Code Analysis
- Read all code that needs test coverage
- Identify all public methods and functions
- Find all conditional branches (if/else/switch/try-catch)
- Determine edge cases
- Check which dependencies need mocking

### 2. Check Helpers
- Open test/helpers/mocks.dart — does the mock exist?
- Open test/helpers/builders.dart — does the builder exist?
- If something is missing and will be used in 2+ tests — add to helpers first

### 3. Test Structure

  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:xerabora/path/to/class.dart';
  import '../../helpers/test_helpers.dart';

  void main() {
    group('ClassName', () {
      late ClassName sut;
      late MockDependency mockDep;

      setUpAll(() => registerAllFallbacks());

      setUp(() {
        mockDep = MockDependency();
        sut = ClassName(dependency: mockDep);
      });

      group('methodName', () {
        test('should return X when Y', () {
          // Arrange
          when(() => mockDep.getData(any()))
              .thenAnswer((_) async => createTestData());
          // Act
          final result = sut.methodName(input);
          // Assert
          expect(result, equals(expected));
        });
      });
    });
  }

### 4. Widget Tests

  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:xerabora/features/my_feature/screens/my_screen.dart';
  import 'package:xerabora/data/repositories/collection_repository.dart';
  import '../../../helpers/test_helpers.dart';

  void main() {
    group('MyScreen', () {
      late MockCollectionRepository mockRepo;

      setUpAll(() => registerAllFallbacks());

      setUp(() {
        mockRepo = MockCollectionRepository();
      });

      testWidgets('renders without errors', (WidgetTester tester) async {
        when(() => mockRepo.getAll())
            .thenAnswer((_) async => createTestCollections());
        when(() => mockRepo.getStats(any()))
            .thenAnswer((_) async => createTestStats());

        await tester.pumpApp(
          const MyScreen(),
          overrides: [
            collectionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('navigates to detail on tap', (WidgetTester tester) async {
        // ... setup ...
        await tester.pumpApp(const MyScreen(), overrides: [...]);
        await tester.tap(find.byType(CollectionCard).first);
        await tester.pumpAndSettle();
        expect(find.byType(CollectionScreen), findsOneWidget);
      });
    });
  }

### 5. Coverage Checklist

Per method:
- Happy path
- Empty input (null, [], '')
- Boundary values (0, -1, maxInt)
- Invalid input
- All if/else branches
- All switch cases
- Exception handling (try-catch)

Async code:
- Successful execution
- Timeout
- Network/API error
- Cancellation

Widget tests:
- Renders in each state (data, loading, error, empty)
- Tap handlers trigger correct actions
- Conditional widgets show/hide based on state
- Lists render correct item count
- Uses tester.pumpApp()
- NO assertions on colors, labels, icons, spacing

### 6. Available Builders

Check builders.dart before creating test data:

  createTestCollection(name: 'RPG Games', type: CollectionType.own)
  createTestCollections(count: 5)
  createTestStats(total: 10, completed: 7)
  createTestItem(mediaType: MediaType.game, status: ItemStatus.completed)
  createMovieJson(title: 'Inception', voteAverage: 8.8)
  createTvShowJson(name: 'Breaking Bad', numberOfSeasons: 5)
  createGameJson(name: 'Elden Ring', rating: 95.0)

If you need a builder that doesnt exist — add to builders.dart, dont create locally.

### 7. Available Mocks

Check mocks.dart before declaring a mock:

  MockDio, MockDatabase, MockDatabaseService, MockConfigService
  MockTmdbApi, MockIgdbApi, MockSteamGridDbApi, MockVndbApi
  MockImageCacheService, MockTraktZipImportService
  MockCollectionRepository, MockCanvasRepository
  MockGameRepository, MockWishlistRepository
  MockCollectionItemsNotifier, MockWidgetRef, MockS
  FakeCanvasItem, FakeCanvasConnection, FakeCanvasViewport, FakeGame

### 8. Verification

  powershell.exe -Command "cd D:\CODE\xerabora; flutter test"
  powershell.exe -Command "cd D:\CODE\xerabora; flutter test --coverage"

  # Check: no duplicate mocks outside helpers
  grep -r "class Mock" test/ --include="*_test.dart"
  # Result should be empty (all mocks live in helpers/mocks.dart)

### 9. Completion Criteria

- All tests pass (flutter test)
- Every public method/branch of the code you just wrote has at least one test covering it (happy path + each meaningful edge case)
- No missed edge cases
- No duplicate mock classes (all in test/helpers/mocks.dart)
- No inline registerFallbackValue (use registerAllFallbacks())
- No inline builders if equivalent exists in builders.dart
- Widget tests use tester.pumpApp()
- No visual assertions (colors, text labels, icons, spacing)

Note: chasing literal 100% line/branch coverage is not the goal. Behaviour coverage is. A defensive null-guard that can never trigger in practice doesn't need its own test.

## Test Naming

  should [expected result] when [condition]

Examples:
- should return empty list when no data exists
- should throw exception when id is invalid
- should navigate to detail when item is tapped
- should call save when form is submitted

## When Adding New Mocks/Builders

When creating a new class and writing tests for it:

1. Mock needed in 2+ test files? -> Add to test/helpers/mocks.dart
2. Data factory needed in 2+ files? -> Add to test/helpers/builders.dart
3. New fallback value? -> Add to registerAllFallbacks() in test/helpers/fallbacks.dart
4. Mock/builder unique to one test? -> OK to declare locally

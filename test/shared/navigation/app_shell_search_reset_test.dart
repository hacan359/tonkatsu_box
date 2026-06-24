import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/search/providers/browse_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/navigation/app_shell.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';

/// Exposes a real [WidgetRef] so the test drives [resetSearchTabState] exactly
/// as [AppShell] does when the Search tab is entered.
class _ResetHarness extends ConsumerWidget {
  const _ResetHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () => resetSearchTabState(ref),
          child: const Text('reset'),
        ),
      ),
    );
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpAndReset(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _ResetHarness(),
      ),
    );
    await tester.tap(find.text('reset'));
    await tester.pump();
  }

  group('resetSearchTabState', () {
    testWidgets('clears the top bar search query', (WidgetTester tester) async {
      final ProviderContainer container = createContainer();
      container.read(searchTabQueryProvider.notifier).state = 'zelda';

      await pumpAndReset(tester, container);

      expect(container.read(searchTabQueryProvider), isEmpty);
    });

    testWidgets('clears the executed browse search query',
        (WidgetTester tester) async {
      final ProviderContainer container = createContainer();
      container.read(browseProvider.notifier).setSearchQuery('zelda');
      expect(container.read(browseProvider).searchQuery, 'zelda');

      await pumpAndReset(tester, container);

      expect(container.read(browseProvider).searchQuery, isEmpty);
    });

    testWidgets('keeps the chosen browse source (deliberate browse setup)',
        (WidgetTester tester) async {
      final ProviderContainer container = createContainer();
      container.read(browseProvider.notifier).setSource('games');
      container.read(browseProvider.notifier).setSearchQuery('mario');

      await pumpAndReset(tester, container);

      expect(container.read(browseProvider).searchQuery, isEmpty);
      expect(container.read(browseProvider).sourceId, 'games');
    });

    testWidgets('clears the add-target collection', (WidgetTester tester) async {
      final ProviderContainer container = createContainer();
      container.read(searchTargetCollectionProvider.notifier).state = 7;

      await pumpAndReset(tester, container);

      expect(container.read(searchTargetCollectionProvider), isNull);
    });

    testWidgets('is a no-op on an already empty search',
        (WidgetTester tester) async {
      final ProviderContainer container = createContainer();

      await pumpAndReset(tester, container);

      expect(container.read(searchTabQueryProvider), isEmpty);
      expect(container.read(browseProvider).searchQuery, isEmpty);
      expect(container.read(searchTargetCollectionProvider), isNull);
    });
  });
}

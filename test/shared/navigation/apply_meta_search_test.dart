import 'package:core/utils/meta_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('applyMetaSearch', () {
    late WidgetRef ref;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpApp(
        Consumer(
          builder: (BuildContext context, WidgetRef r, Widget? _) {
            ref = r;
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('should switch to meta mode and set the query',
        (WidgetTester tester) async {
      await pump(tester);

      applyMetaSearch(ref, homeSearchQueryProvider, 'Horror');

      expect(ref.read(searchModeProvider), SearchMode.meta);
      expect(ref.read(homeSearchQueryProvider), 'Horror');
    });

    testWidgets('should replace a title-mode query', (WidgetTester tester) async {
      await pump(tester);
      ref.read(homeSearchQueryProvider.notifier).state = 'naruto';

      applyMetaSearch(ref, homeSearchQueryProvider, 'Horror');

      expect(ref.read(homeSearchQueryProvider), 'Horror');
    });

    testWidgets('should narrow an existing meta query with a new AND group',
        (WidgetTester tester) async {
      await pump(tester);
      ref.read(searchModeProvider.notifier).state = SearchMode.meta;
      ref.read(collectionsSearchQueryProvider.notifier).state = 'Horror';

      applyMetaSearch(ref, collectionsSearchQueryProvider, 'Kyoto Animation');

      expect(
        ref.read(collectionsSearchQueryProvider),
        'Horror, Kyoto Animation',
      );
    });

    testWidgets('should flatten separators inside a chip value',
        (WidgetTester tester) async {
      await pump(tester);

      applyMetaSearch(ref, homeSearchQueryProvider, 'AC/DC');

      expect(ref.read(homeSearchQueryProvider), 'AC DC');
    });

    testWidgets('should replace even in meta mode when narrow is false',
        (WidgetTester tester) async {
      await pump(tester);
      ref.read(searchModeProvider.notifier).state = SearchMode.meta;
      ref.read(homeSearchQueryProvider.notifier).state = 'Horror';

      applyMetaSearch(ref, homeSearchQueryProvider, 'Comedy', narrow: false);

      expect(ref.read(homeSearchQueryProvider), 'Comedy');
    });
  });
}

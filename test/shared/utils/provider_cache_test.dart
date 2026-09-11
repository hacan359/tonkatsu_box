import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/provider_cache.dart';

void main() {
  group('cacheFor', () {
    const Duration ttl = Duration(milliseconds: 60);

    test('keeps the value alive without listeners until the ttl passes',
        () async {
      int builds = 0;
      final AutoDisposeFutureProvider<int> provider =
          FutureProvider.autoDispose<int>((Ref ref) async {
        builds++;
        cacheFor(ref, ttl);
        return builds;
      });
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProviderSubscription<AsyncValue<int>> first =
          container.listen(provider, (_, _) {});
      await container.read(provider.future);
      first.close();
      // A plain autoDispose provider would be gone after this tick.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await container.read(provider.future), 1);

      await Future<void>.delayed(ttl * 2);
      expect(await container.read(provider.future), 2);
    });

    test('a failed build is not pinned when cacheFor comes after the await',
        () async {
      int builds = 0;
      final AutoDisposeFutureProvider<int> provider =
          FutureProvider.autoDispose<int>((Ref ref) async {
        builds++;
        if (builds == 1) throw StateError('first call fails');
        cacheFor(ref, ttl);
        return builds;
      });
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProviderSubscription<AsyncValue<int>> first =
          container.listen(provider, (_, _) {});
      await expectLater(container.read(provider.future), throwsStateError);
      first.close();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await container.read(provider.future), 2);
    });
  });
}

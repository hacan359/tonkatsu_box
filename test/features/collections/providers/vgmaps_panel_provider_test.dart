import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/vgmaps_panel_provider.dart';

const int testCollectionId = 10;

ProviderContainer createContainer() {
  return ProviderContainer();
}

void main() {
  group('VgMapsPanelState', () {
    test('should have correct default values', () {
      const VgMapsPanelState state = VgMapsPanelState();

      expect(state.isOpen, false);
      expect(state.currentUrl, vgMapsHomeUrl);
      expect(state.canGoBack, false);
      expect(state.canGoForward, false);
      expect(state.isLoading, false);
      expect(state.capturedImageUrl, isNull);
      expect(state.capturedImageWidth, isNull);
      expect(state.capturedImageHeight, isNull);
      expect(state.error, isNull);
    });

    test('copyWith should preserve all values when no changes', () {
      const VgMapsPanelState state = VgMapsPanelState(
        isOpen: true,
        currentUrl: 'https://example.com',
        canGoBack: true,
        canGoForward: true,
        isLoading: true,
        capturedImageUrl: 'https://example.com/img.png',
        capturedImageWidth: 800,
        capturedImageHeight: 600,
        error: 'some error',
      );

      final VgMapsPanelState copy = state.copyWith();

      expect(copy.isOpen, true);
      expect(copy.currentUrl, 'https://example.com');
      expect(copy.canGoBack, true);
      expect(copy.canGoForward, true);
      expect(copy.isLoading, true);
      expect(copy.capturedImageUrl, 'https://example.com/img.png');
      expect(copy.capturedImageWidth, 800);
      expect(copy.capturedImageHeight, 600);
      expect(copy.error, 'some error');
    });

    test('copyWith should update specified fields', () {
      const VgMapsPanelState state = VgMapsPanelState();

      final VgMapsPanelState copy = state.copyWith(
        isOpen: true,
        currentUrl: 'https://other.com',
        canGoBack: true,
        isLoading: true,
      );

      expect(copy.isOpen, true);
      expect(copy.currentUrl, 'https://other.com');
      expect(copy.canGoBack, true);
      expect(copy.canGoForward, false);
      expect(copy.isLoading, true);
    });

    test('copyWith clearCapturedImage should reset image fields to null', () {
      const VgMapsPanelState state = VgMapsPanelState(
        capturedImageUrl: 'https://example.com/img.png',
        capturedImageWidth: 800,
        capturedImageHeight: 600,
      );

      final VgMapsPanelState copy = state.copyWith(clearCapturedImage: true);

      expect(copy.capturedImageUrl, isNull);
      expect(copy.capturedImageWidth, isNull);
      expect(copy.capturedImageHeight, isNull);
    });

    test('copyWith clearError should reset error to null', () {
      const VgMapsPanelState state = VgMapsPanelState(error: 'some error');

      final VgMapsPanelState copy = state.copyWith(clearError: true);

      expect(copy.error, isNull);
    });
  });

  group('VgMapsPanelNotifier', () {
    group('build', () {
      test('should return default state', () {
        final ProviderContainer container = createContainer();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));

        expect(state.isOpen, false);
        expect(state.currentUrl, vgMapsHomeUrl);
        expect(state.canGoBack, false);
        expect(state.canGoForward, false);
        expect(state.isLoading, false);
        expect(state.capturedImageUrl, isNull);
        expect(state.error, isNull);

        container.dispose();
      });
    });

    group('togglePanel', () {
      test('should open panel when closed', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .togglePanel();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isOpen, true);

        container.dispose();
      });

      test('should close panel when open', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.openPanel();
        notifier.togglePanel();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isOpen, false);

        container.dispose();
      });
    });

    group('openPanel', () {
      test('should set isOpen to true', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .openPanel();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isOpen, true);

        container.dispose();
      });
    });

    group('closePanel', () {
      test('should set isOpen to false', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.openPanel();
        notifier.closePanel();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isOpen, false);

        container.dispose();
      });
    });

    group('setCurrentUrl', () {
      test('should update currentUrl', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .setCurrentUrl('https://www.vgmaps.com/Atlas/');

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.currentUrl, 'https://www.vgmaps.com/Atlas/');

        container.dispose();
      });
    });

    group('setNavigationState', () {
      test('should update canGoBack and canGoForward', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .setNavigationState(canGoBack: true, canGoForward: false);

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.canGoBack, true);
        expect(state.canGoForward, false);

        container.dispose();
      });

      test('should update both to true', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .setNavigationState(canGoBack: true, canGoForward: true);

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.canGoBack, true);
        expect(state.canGoForward, true);

        container.dispose();
      });
    });

    group('setLoading', () {
      test('should set isLoading to true', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .setLoading(isLoading: true);

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isLoading, true);

        container.dispose();
      });

      test('should set isLoading to false', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.setLoading(isLoading: true);
        notifier.setLoading(isLoading: false);

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.isLoading, false);

        container.dispose();
      });
    });

    group('captureImage', () {
      test('should set captured image url', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .captureImage('https://example.com/map.png');

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.capturedImageUrl, 'https://example.com/map.png');
        expect(state.capturedImageWidth, isNull);
        expect(state.capturedImageHeight, isNull);

        container.dispose();
      });

      test('should set captured image with dimensions', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .captureImage(
              'https://example.com/map.png',
              width: 1024,
              height: 768,
            );

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.capturedImageUrl, 'https://example.com/map.png');
        expect(state.capturedImageWidth, 1024);
        expect(state.capturedImageHeight, 768);

        container.dispose();
      });

      test('should overwrite previous capture', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.captureImage('https://example.com/first.png', width: 100, height: 200);
        notifier.captureImage('https://example.com/second.png', width: 300, height: 400);

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.capturedImageUrl, 'https://example.com/second.png');
        expect(state.capturedImageWidth, 300);
        expect(state.capturedImageHeight, 400);

        container.dispose();
      });
    });

    group('clearCapturedImage', () {
      test('should reset captured image to null', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.captureImage('https://example.com/map.png', width: 800, height: 600);
        notifier.clearCapturedImage();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.capturedImageUrl, isNull);
        expect(state.capturedImageWidth, isNull);
        expect(state.capturedImageHeight, isNull);

        container.dispose();
      });

      test('should be no-op when no image captured', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .clearCapturedImage();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.capturedImageUrl, isNull);

        container.dispose();
      });
    });

    group('setError', () {
      test('should set error message', () {
        final ProviderContainer container = createContainer();

        container
            .read(vgMapsPanelProvider(testCollectionId).notifier)
            .setError('WebView failed to load');

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.error, 'WebView failed to load');

        container.dispose();
      });
    });

    group('clearError', () {
      test('should reset error to null', () {
        final ProviderContainer container = createContainer();
        final VgMapsPanelNotifier notifier =
            container.read(vgMapsPanelProvider(testCollectionId).notifier);

        notifier.setError('Some error');
        notifier.clearError();

        final VgMapsPanelState state =
            container.read(vgMapsPanelProvider(testCollectionId));
        expect(state.error, isNull);

        container.dispose();
      });
    });

    group('family provider', () {
      test('different collectionIds should have independent state', () {
        final ProviderContainer container = createContainer();

        container.read(vgMapsPanelProvider(1).notifier).openPanel();
        container.read(vgMapsPanelProvider(2).notifier).setCurrentUrl('https://other.com');

        final VgMapsPanelState state1 = container.read(vgMapsPanelProvider(1));
        final VgMapsPanelState state2 = container.read(vgMapsPanelProvider(2));

        expect(state1.isOpen, true);
        expect(state1.currentUrl, vgMapsHomeUrl);

        expect(state2.isOpen, false);
        expect(state2.currentUrl, 'https://other.com');

        container.dispose();
      });
    });
  });

  group('vgMapsHomeUrl', () {
    test('should be vgmaps.com', () {
      expect(vgMapsHomeUrl, 'https://www.vgmaps.com/');
    });
  });
}

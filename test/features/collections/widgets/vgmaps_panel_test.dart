import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/vgmaps_panel_provider.dart';

const int testCollectionId = 10;

/// Тестовый notifier для VGMaps панели.
class TestVgMapsPanelNotifier extends VgMapsPanelNotifier {
  TestVgMapsPanelNotifier(this._initialState);

  final VgMapsPanelState _initialState;

  @override
  VgMapsPanelState build(int? arg) {
    return _initialState;
  }
}

void _noopAddImage(String url, int? width, int? height) {}

Widget buildTestWidget({
  required VgMapsPanelState panelState,
  void Function(String, int?, int?)? onAddImage,
}) {
  return ProviderScope(
    overrides: <Override>[
      vgMapsPanelProvider.overrideWith(
        () => TestVgMapsPanelNotifier(panelState),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 500,
          height: 800,
          child: _TestableVgMapsPanel(
            collectionId: testCollectionId,
            panelState: panelState,
            onAddImage: onAddImage ?? _noopAddImage,
          ),
        ),
      ),
    ),
  );
}

/// Тестируемая версия VGMaps панели без WebView.
///
/// Реальный VgMapsPanel использует webview_windows, который требует
/// Windows-платформу и не работает в тестах. Этот виджет воспроизводит
/// UI-структуру панели для тестирования.
class _TestableVgMapsPanel extends ConsumerWidget {
  const _TestableVgMapsPanel({
    required this.collectionId,
    required this.panelState,
    required this.onAddImage,
  });

  final int collectionId;
  final VgMapsPanelState panelState;
  final void Function(String, int?, int?) onAddImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VgMapsPanelState state =
        ref.watch(vgMapsPanelProvider(collectionId));
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: 500,
      color: colorScheme.surface,
      child: Column(
        children: <Widget>[
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(Icons.map, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'VGMaps',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close panel',
                  onPressed: () => ref
                      .read(vgMapsPanelProvider(collectionId).notifier)
                      .closePanel(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Тулбар навигации
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  tooltip: 'Back',
                  onPressed: state.canGoBack ? () {} : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  tooltip: 'Forward',
                  onPressed: state.canGoForward ? () {} : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.home, size: 20),
                  tooltip: 'Home',
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Reload',
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search game on VGMaps...',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, size: 16),
                          tooltip: 'Search',
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Индикатор загрузки
          if (state.isLoading) const LinearProgressIndicator(),

          // Ошибка
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: colorScheme.errorContainer,
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline,
                      size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!)),
                ],
              ),
            ),

          // Заглушка WebView
          const Expanded(
            child: Center(child: Text('WebView placeholder')),
          ),

          // Нижняя панель с захваченным изображением
          if (state.capturedImageUrl != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        imageUrl: state.capturedImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Image captured',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (state.capturedImageWidth != null &&
                            state.capturedImageHeight != null)
                          Text(
                            '${state.capturedImageWidth}x${state.capturedImageHeight}',
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      onAddImage(
                        state.capturedImageUrl!,
                        state.capturedImageWidth,
                        state.capturedImageHeight,
                      );
                      ref
                          .read(vgMapsPanelProvider(collectionId).notifier)
                          .clearCapturedImage();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add to Board'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Dismiss',
                    onPressed: () => ref
                        .read(vgMapsPanelProvider(collectionId).notifier)
                        .clearCapturedImage(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  group('VgMapsPanel', () {
    group('header', () {
      testWidgets('should display VGMaps title', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.text('VGMaps'), findsOneWidget);
      });

      testWidgets('should have close button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should have map icon', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.map), findsAtLeast(1));
      });
    });

    group('navigation toolbar', () {
      testWidgets('should have back button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('should have forward button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('should have home button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('should have refresh button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should have search text field', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.text('Search game on VGMaps...'), findsOneWidget);
      });

      testWidgets('should disable back when canGoBack is false',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true, canGoBack: false),
        ));

        final IconButton backButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.arrow_back),
        );
        expect(backButton.onPressed, isNull);
      });

      testWidgets('should enable back when canGoBack is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true, canGoBack: true),
        ));

        final IconButton backButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.arrow_back),
        );
        expect(backButton.onPressed, isNotNull);
      });

      testWidgets('should disable forward when canGoForward is false',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState:
              const VgMapsPanelState(isOpen: true, canGoForward: false),
        ));

        final IconButton forwardButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.arrow_forward),
        );
        expect(forwardButton.onPressed, isNull);
      });

      testWidgets('should enable forward when canGoForward is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true, canGoForward: true),
        ));

        final IconButton forwardButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.arrow_forward),
        );
        expect(forwardButton.onPressed, isNotNull);
      });
    });

    group('loading state', () {
      testWidgets('should show LinearProgressIndicator when loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true, isLoading: true),
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should not show indicator when not loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true, isLoading: false),
        ));

        expect(find.byType(LinearProgressIndicator), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('should display error message', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            error: 'WebView failed to load',
          ),
        ));

        expect(find.text('WebView failed to load'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should not show error when no error',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('captured image bar', () {
      testWidgets('should show bottom bar when image captured',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            capturedImageUrl: 'https://example.com/map.png',
            capturedImageWidth: 1024,
            capturedImageHeight: 768,
          ),
        ));

        expect(find.text('Image captured'), findsOneWidget);
        expect(find.text('1024x768'), findsOneWidget);
        expect(find.text('Add to Board'), findsOneWidget);
      });

      testWidgets('should not show bottom bar when no image captured',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.text('Image captured'), findsNothing);
        expect(find.text('Add to Board'), findsNothing);
      });

      testWidgets('should show thumbnail preview', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            capturedImageUrl: 'https://example.com/map.png',
          ),
        ));

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets('should call onAddImage when Add to Board tapped',
          (WidgetTester tester) async {
        String? addedUrl;
        int? addedWidth;
        int? addedHeight;

        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            capturedImageUrl: 'https://example.com/map.png',
            capturedImageWidth: 1024,
            capturedImageHeight: 768,
          ),
          onAddImage: (String url, int? width, int? height) {
            addedUrl = url;
            addedWidth = width;
            addedHeight = height;
          },
        ));

        await tester.tap(find.text('Add to Board'));
        await tester.pump();

        expect(addedUrl, 'https://example.com/map.png');
        expect(addedWidth, 1024);
        expect(addedHeight, 768);
      });

      testWidgets('should not show dimensions when not available',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            capturedImageUrl: 'https://example.com/map.png',
          ),
        ));

        expect(find.text('Image captured'), findsOneWidget);
        // Не должно быть текста с размерами
        expect(find.textContaining('x'), findsNothing);
      });

      testWidgets('should have dismiss button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(
            isOpen: true,
            capturedImageUrl: 'https://example.com/map.png',
          ),
        ));

        // close icon для dismiss (second one — first is panel close)
        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });
    });

    group('webview placeholder', () {
      testWidgets('should show WebView placeholder in tests',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const VgMapsPanelState(isOpen: true),
        ));

        expect(find.text('WebView placeholder'), findsOneWidget);
      });
    });
  });
}

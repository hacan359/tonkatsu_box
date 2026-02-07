import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/steamgriddb_panel_provider.dart';
import 'package:xerabora/features/collections/widgets/steamgriddb_panel.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/steamgriddb_game.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

const int testCollectionId = 10;

const SteamGridDbGame testGame = SteamGridDbGame(
  id: 123,
  name: 'Chrono Trigger',
  verified: true,
);

const SteamGridDbImage testImage1 = SteamGridDbImage(
  id: 1,
  score: 10,
  style: 'alternate',
  url: 'https://example.com/grid1.png',
  thumb: 'https://example.com/grid1_thumb.png',
  width: 600,
  height: 900,
);

const SteamGridDbImage testImage2 = SteamGridDbImage(
  id: 2,
  score: 5,
  style: 'blurred',
  url: 'https://example.com/grid2.png',
  thumb: 'https://example.com/grid2_thumb.png',
  width: 460,
  height: 215,
);

const SettingsState settingsWithKey = SettingsState(
  steamGridDbApiKey: 'test-key',
);

const SettingsState settingsWithoutKey = SettingsState();

/// Тестовый notifier для SteamGridDB панели.
class TestSteamGridDbPanelNotifier extends SteamGridDbPanelNotifier {
  TestSteamGridDbPanelNotifier(this._initialState);

  final SteamGridDbPanelState _initialState;

  @override
  SteamGridDbPanelState build(int arg) {
    return _initialState;
  }
}

void _noopAddImage(SteamGridDbImage _) {}

Widget buildTestWidget({
  required SteamGridDbPanelState panelState,
  SettingsState settings = settingsWithKey,
  void Function(SteamGridDbImage)? onAddImage,
}) {
  return ProviderScope(
    overrides: <Override>[
      steamGridDbPanelProvider.overrideWith(
        () => TestSteamGridDbPanelNotifier(panelState),
      ),
      settingsNotifierProvider.overrideWith(
        () => _FakeSettingsNotifier(settings),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 600,
          child: SteamGridDbPanel(
            collectionId: testCollectionId,
            collectionName: 'SNES Classics',
            onAddImage: onAddImage ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SteamGridDbPanel', () {
    group('header', () {
      testWidgets('should display SteamGridDB title', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.text('SteamGridDB'), findsOneWidget);
      });

      testWidgets('should have close button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should have image_search icon', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.image_search), findsAtLeast(1));
      });
    });

    group('search bar', () {
      testWidgets('should display search text field', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should have search hint text', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.text('Search game...'), findsOneWidget);
      });

      testWidgets('should have search icon button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should pre-fill with collection name', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'SNES Classics');
      });

      testWidgets('should not pre-fill when collection name is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: <Override>[
            steamGridDbPanelProvider.overrideWith(
              () => TestSteamGridDbPanelNotifier(
                  const SteamGridDbPanelState(isOpen: true)),
            ),
            settingsNotifierProvider.overrideWith(
              () => _FakeSettingsNotifier(settingsWithKey),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 600,
                child: SteamGridDbPanel(
                  collectionId: testCollectionId,
                  collectionName: '',
                  onAddImage: _noopAddImage,
                ),
              ),
            ),
          ),
        ));

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, '');
      });

      testWidgets('should not pre-fill when search results exist',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            searchTerm: 'Chrono',
            searchResults: <SteamGridDbGame>[testGame],
          ),
        ));

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        // Не должен перезаписывать — уже есть результаты
        expect(textField.controller?.text, isNot('SNES Classics'));
      });
    });

    group('no API key warning', () {
      testWidgets('should show warning when API key not set',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
          settings: settingsWithoutKey,
        ));

        expect(find.text('SteamGridDB API key not set. Configure it in Settings.'),
            findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('should not show warning when API key is set',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
          settings: settingsWithKey,
        ));

        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });
    });

    group('search results', () {
      testWidgets('should display search results as list tiles',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            searchTerm: 'Chrono',
            searchResults: <SteamGridDbGame>[
              testGame,
              SteamGridDbGame(id: 456, name: 'Chrono Cross'),
            ],
          ),
        ));

        expect(find.text('Chrono Trigger'), findsOneWidget);
        expect(find.text('Chrono Cross'), findsOneWidget);
      });

      testWidgets('should not show verified icon for non-verified games',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            searchTerm: 'test',
            searchResults: <SteamGridDbGame>[
              SteamGridDbGame(id: 999, name: 'Unverified Game'),
            ],
          ),
        ));

        expect(find.byIcon(Icons.verified), findsNothing);
      });

      testWidgets('should show verified icon for verified games',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            searchTerm: 'test',
            searchResults: <SteamGridDbGame>[testGame],
          ),
        ));

        expect(find.byIcon(Icons.verified), findsOneWidget);
      });
    });

    group('loading states', () {
      testWidgets('should show spinner when searching',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            isSearching: true,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show spinner when loading images',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            isLoadingImages: true,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error states', () {
      testWidgets('should display search error',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            searchError: 'Rate limit exceeded',
          ),
        ));

        expect(find.text('Rate limit exceeded'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should display image error',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            imageError: 'Game not found',
          ),
        ));

        expect(find.text('Game not found'), findsOneWidget);
      });
    });

    group('game header', () {
      testWidgets('should show selected game name',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1],
          ),
        ));

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });

      testWidgets('should show back button when game selected',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1],
          ),
        ));

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('image type selector', () {
      testWidgets('should show segmented button when game selected',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1],
          ),
        ));

        expect(find.byType(SegmentedButton<SteamGridDbImageType>),
            findsOneWidget);
        expect(find.text('Grids'), findsOneWidget);
        expect(find.text('Heroes'), findsOneWidget);
        expect(find.text('Logos'), findsOneWidget);
        expect(find.text('Icons'), findsOneWidget);
      });

      testWidgets('should not show segmented button without game',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.byType(SegmentedButton<SteamGridDbImageType>),
            findsNothing);
      });
    });

    group('image grid', () {
      testWidgets('should display image thumbnails',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1, testImage2],
          ),
        ));

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNWidgets(2));
      });

      testWidgets('should show dimensions on thumbnails',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1],
          ),
        ));

        expect(find.text('600x900'), findsOneWidget);
      });

      testWidgets('should show no images found when empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[],
          ),
        ));

        expect(find.text('No images found'), findsOneWidget);
      });

      testWidgets('should call onAddImage when image tapped',
          (WidgetTester tester) async {
        SteamGridDbImage? addedImage;

        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(
            isOpen: true,
            selectedGame: testGame,
            images: <SteamGridDbImage>[testImage1],
          ),
          onAddImage: (SteamGridDbImage image) => addedImage = image,
        ));

        // Нажимаем на карточку изображения (InkWell внутри Card)
        await tester.tap(find.byType(InkWell).last);
        await tester.pump();

        expect(addedImage, isNotNull);
        expect(addedImage!.id, 1);
        expect(addedImage!.url, 'https://example.com/grid1.png');
      });
    });

    group('empty state', () {
      testWidgets('should show empty state when no results',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          panelState: const SteamGridDbPanelState(isOpen: true),
        ));

        expect(find.text('Search for a game to browse images'), findsOneWidget);
      });
    });
  });
}

/// Фейковый SettingsNotifier для тестов.
class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._initialState);

  final SettingsState _initialState;

  @override
  SettingsState build() {
    return _initialState;
  }
}

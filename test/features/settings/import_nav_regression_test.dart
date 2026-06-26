// Regression guard for the import-result navigation bug (per-tab Navigator).
//
// The app shell keeps one cached Navigator per tab. Re-tapping the active tab
// (or the top-bar gear for Settings) resets that tab's Navigator to its root
// via `popUntil((r) => r.isFirst)`.
//
// The old Kinorium/Trakt import flows did, after a successful import:
//   await Navigator.push(... ImportResultScreen ...);
//   if (mounted) widget.onImportComplete?.call(); // -> Navigator.pop()
// On the result screen the user could open a collection; a later gear tap then
// ran `popUntil(isFirst)`, which removed the awaited ImportResultScreen and
// resolved the pending push. Its continuation called the follow-up pop, which
// popped the freshly-restored tab ROOT -> the Settings Navigator went empty and
// Settings stayed permanently blank.
//
// The fix mirrors the RA importer: push the result screen fire-and-forget (no
// await, no follow-up pop), so a tab-root reset can never resolve a pending
// push into an extra root-pop. These tests drive the real fixed content through
// file-pick -> preview -> import -> result, then simulate the gear's
// `popUntil(isFirst)` and assert the sentinel ROOT route is never popped away.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/sources/kinorium/kinorium_import_service.dart';
import 'package:tonkatsu_box/core/import/sources/trakt/trakt_import_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/settings/screens/import_result_screen.dart';
import 'package:tonkatsu_box/features/settings/screens/kinorium_import_screen.dart';
import 'package:tonkatsu_box/features/settings/screens/trakt_import_screen.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';

import '../../helpers/test_helpers.dart';

/// Sentinel root route of the host (per-tab) Navigator.
const String _rootMarker = 'ROOT';

/// A [FilePicker] that always returns [path] from [pickFiles]. Extending
/// [FilePicker] (rather than mocking it) keeps the real platform-interface
/// token, so the static `FilePicker.platform =` setter accepts it.
class _StubFilePicker extends FilePicker {
  _StubFilePicker(this.path);

  final String path;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult(<PlatformFile>[
      PlatformFile(name: path.split('/').last, size: 0, path: path),
    ]);
  }
}

class _FakeTraktImportOptions extends Fake implements TraktImportOptions {}

class _FakeKinoriumImportOptions extends Fake implements KinoriumImportOptions {}

/// Settings with a non-built-in TMDB key so the import buttons (which require
/// `hasTmdbKey && !isTmdbKeyBuiltIn`) are enabled.
class _TmdbKeySettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState(tmdbApiKey: 'user-tmdb-key');
  }
}

class _TestCollectionsNotifier extends CollectionsNotifier {
  _TestCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async => _collections;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTraktImportOptions());
    registerFallbackValue(_FakeKinoriumImportOptions());
  });

  FilePicker? originalPicker;
  late GlobalKey<NavigatorState> hostKey;

  setUp(() {
    hostKey = GlobalKey<NavigatorState>();
    // FilePicker.platform is `late` and unset in the unit-test VM (no real
    // platform impl), so only capture it if it was already set.
    try {
      originalPicker = FilePicker.platform;
    } on Error {
      originalPicker = null;
    }
    FilePicker.platform = _StubFilePicker('/tmp/export.zip');
  });

  tearDown(() {
    final FilePicker? original = originalPicker;
    if (original != null) {
      FilePicker.platform = original;
    }
  });

  /// Sizes the test view tall enough that the whole scrollable import form
  /// (warning + preview + options + button) lays out without clipping the
  /// button off-screen.
  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1024, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Advances a fixed number of frames. Used instead of
  /// [WidgetTester.pumpAndSettle] because this widget tree never reports an
  /// idle frame (the import progress dialog and the seeded route transitions
  /// keep scheduling), so `pumpAndSettle` would time out. A bounded pump is
  /// enough: the import service is mocked and resolves synchronously, and the
  /// route transitions complete within these frames.
  Future<void> settle(WidgetTester tester, {int frames = 6}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Scrolls [finder] into view, then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
  }

  /// Hosts [child] on a Navigator seeded with two routes: the [_rootMarker]
  /// sentinel as the FIRST (tab-root) route and the import screen pushed on top
  /// of it — mirroring a per-tab Navigator with an import screen opened from
  /// Settings. Both routes are seeded up front (no post-frame push) so the
  /// stack is deterministic.
  Widget hostWithRoot({
    required Widget child,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Navigator(
          key: hostKey,
          onGenerateInitialRoutes: (NavigatorState navigator, String name) {
            return <Route<void>>[
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    const Scaffold(body: Center(child: Text(_rootMarker))),
              ),
              MaterialPageRoute<void>(
                builder: (BuildContext context) => Scaffold(body: child),
              ),
            ];
          },
        ),
      ),
    );
  }

  /// The host (per-tab) NavigatorState — the one the gear resets.
  NavigatorState hostNavigator(WidgetTester tester) {
    final NavigatorState? state = hostKey.currentState;
    expect(state, isNotNull);
    return state!;
  }

  group('Import result navigation regression', () {
    group('TraktImportContent', () {
      const TraktZipInfo validZip = TraktZipInfo(
        isValid: true,
        username: 'tester',
        watchedMovieCount: 2,
      );

      late MockTraktImportService service;

      setUp(() {
        service = MockTraktImportService();
        when(() => service.validateZip(any()))
            .thenAnswer((_) async => validZip);
      });

      UniversalImportResult successResult() {
        return UniversalImportResult(
          sourceName: 'Trakt',
          success: true,
          collection: createTestCollection(id: 7, name: 'Trakt: tester'),
          importedByType: const <MediaType, int>{MediaType.movie: 2},
        );
      }

      Future<void> driveToResultScreen(WidgetTester tester) async {
        when(
          () => service.import(
            any(),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async => successResult());

        useTallView(tester);
        await tester.pumpWidget(
          hostWithRoot(
            child: const TraktImportScreen(),
            overrides: <Override>[
              traktImportServiceProvider.overrideWithValue(service),
              collectionsProvider.overrideWith(
                () => _TestCollectionsNotifier(const <Collection>[]),
              ),
              settingsNotifierProvider.overrideWith(
                _TmdbKeySettingsNotifier.new,
              ),
            ],
          ),
        );
        await settle(tester);

        // File pick -> validateZip -> preview + options + import button appear.
        await tapVisible(tester, find.text('Select ZIP File'));
        await settle(tester);

        expect(find.text('Start Import'), findsOneWidget);

        // Run the import, then dismiss the progress dialog via Done.
        await tapVisible(tester, find.text('Start Import'));
        await settle(tester);
        await tester.tap(find.text('Done').first);
        await settle(tester);
      }

      testWidgets(
        'gear popUntil(isFirst) after import keeps the tab root intact',
        (WidgetTester tester) async {
          await driveToResultScreen(tester);

          // Result screen is shown over the import screen.
          expect(find.byType(ImportResultScreen), findsOneWidget);
          expect(find.text('Open Collection'), findsOneWidget);

          // Simulate the gear: reset the host (tab) navigator to its root.
          hostNavigator(tester).popUntil((Route<dynamic> r) => r.isFirst);
          // Enough frames for the topmost route's pop transition to finish.
          await settle(tester, frames: 24);

          // The sentinel root must survive and the navigator must not be empty.
          expect(find.text(_rootMarker), findsOneWidget);
          expect(hostNavigator(tester).canPop(), isFalse);
          expect(find.byType(ImportResultScreen), findsNothing);
        },
      );

      testWidgets(
        'import does not auto-pop the import screen (no extra pop pending)',
        (WidgetTester tester) async {
          await driveToResultScreen(tester);

          // After import the result screen is pushed; popping it returns to the
          // import screen (still alive), not past the tab root. A reintroduced
          // `await push + onImportComplete pop` would have already popped the
          // import screen out from under the result by now.
          hostNavigator(tester).pop();
          await settle(tester);

          expect(find.byType(TraktImportScreen), findsOneWidget);
          expect(find.text(_rootMarker), findsNothing);
          expect(hostNavigator(tester).canPop(), isTrue);
        },
      );
    });

    group('KinoriumImportContent', () {
      late MockKinoriumImportService service;

      setUp(() {
        service = MockKinoriumImportService();
        FilePicker.platform = _StubFilePicker('/tmp/export.csv');
      });

      UniversalImportResult successResult() {
        return UniversalImportResult(
          sourceName: 'Kinorium',
          success: true,
          collection: createTestCollection(id: 9, name: 'Kinorium'),
          importedByType: const <MediaType, int>{MediaType.movie: 1},
        );
      }

      Future<void> driveToResultScreen(WidgetTester tester) async {
        when(
          () => service.import(
            any(),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async => successResult());

        useTallView(tester);
        await tester.pumpWidget(
          hostWithRoot(
            child: const KinoriumImportScreen(),
            overrides: <Override>[
              kinoriumImportServiceProvider.overrideWithValue(service),
              collectionsProvider.overrideWith(
                () => _TestCollectionsNotifier(const <Collection>[]),
              ),
              settingsNotifierProvider.overrideWith(
                _TmdbKeySettingsNotifier.new,
              ),
            ],
          ),
        );
        await settle(tester);

        // File pick (no validation step) -> options + import button appear.
        await tapVisible(tester, find.text('Select CSV File'));
        await settle(tester);

        expect(find.text('Start Import'), findsOneWidget);

        await tapVisible(tester, find.text('Start Import'));
        await settle(tester);
        await tester.tap(find.text('Done').first);
        await settle(tester);
      }

      testWidgets(
        'gear popUntil(isFirst) after import keeps the tab root intact',
        (WidgetTester tester) async {
          await driveToResultScreen(tester);

          expect(find.byType(ImportResultScreen), findsOneWidget);
          expect(find.text('Open Collection'), findsOneWidget);

          hostNavigator(tester).popUntil((Route<dynamic> r) => r.isFirst);
          // Enough frames for the topmost route's pop transition to finish.
          await settle(tester, frames: 24);

          expect(find.text(_rootMarker), findsOneWidget);
          expect(hostNavigator(tester).canPop(), isFalse);
          expect(find.byType(ImportResultScreen), findsNothing);
        },
      );
    });
  });
}

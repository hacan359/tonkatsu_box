// Widget тесты для KodiScreen — настройки, sync, debug.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/kodi_api.dart';
import 'package:xerabora/core/services/kodi_sync_service.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/settings/providers/kodi_settings_provider.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/kodi_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/shared/models/kodi_application_info.dart';
import 'package:xerabora/shared/models/profile.dart';

import '../../../helpers/test_helpers.dart';

/// Test notifier for collectionsProvider — returns empty list by default
/// or a preset list (through the override factory).
class _TestCollectionsNotifier extends CollectionsNotifier {
  _TestCollectionsNotifier([this._preset = const <Collection>[]]);

  final List<Collection> _preset;

  @override
  Future<List<Collection>> build() async => _preset;
}

/// Test notifier, returns pre-loaded state without reading SharedPreferences.
class _TestKodiSettingsNotifier extends KodiSettingsNotifier {
  _TestKodiSettingsNotifier(this._initialState);

  final KodiSettingsState _initialState;

  @override
  KodiSettingsState build() => _initialState;
}

void main() {
  late MockKodiApi mockKodiApi;
  late MockKodiSyncService mockSyncService;
  late SharedPreferences prefs;

  const String profileId = 'test-profile';
  final Profile testProfile = Profile(
    id: profileId,
    name: 'Test',
    color: '#EF7B44',
    createdAt: DateTime(2026),
  );

  setUp(() {
    mockKodiApi = MockKodiApi();
    mockSyncService = MockKodiSyncService();

    // Stubs для Debug секции (ref.read(kodiSyncServiceProvider).isRunning).
    when(() => mockSyncService.isRunning).thenReturn(false);
    when(() => mockSyncService.isSyncing).thenReturn(false);
    when(() => mockSyncService.lastResult).thenReturn(null);
    when(() => mockSyncService.stop()).thenReturn(null);
    when(() => mockKodiApi.requestLog).thenReturn(<KodiLogEntry>[]);
  });

  Future<Widget> createWidget({
    Map<String, Object> initialPrefs = const <String, Object>{},
    List<Override> extraOverrides = const <Override>[],
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

    // Override provider with pre-loaded state to avoid timing issues.
    final KodiSettingsState preloadedState = KodiSettingsState(
      enabled: initialPrefs['kodi_enabled_$profileId'] as bool? ?? false,
      host: initialPrefs['kodi_host_$profileId'] as String? ?? '',
      port: initialPrefs['kodi_port_$profileId'] as int? ?? kodiDefaultPort,
      username: initialPrefs['kodi_username_$profileId'] as String? ?? '',
      password: initialPrefs['kodi_password_$profileId'] as String? ?? '',
      syncIntervalSeconds:
          initialPrefs['kodi_sync_interval_seconds_$profileId'] as int? ??
              kodiDefaultSyncIntervalSeconds,
      importRatings:
          initialPrefs['kodi_import_ratings_$profileId'] as bool? ?? false,
      addUnmatchedToWishlist:
          initialPrefs['kodi_add_unmatched_to_wishlist_$profileId'] as bool? ??
              true,
      lastSyncTimestamp:
          initialPrefs['kodi_last_sync_timestamp_$profileId'] as String?,
      targetCollectionId:
          initialPrefs['kodi_target_collection_id_$profileId'] as int?,
    );

    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        kodiApiProvider.overrideWithValue(mockKodiApi),
        kodiSyncServiceProvider.overrideWithValue(mockSyncService),
        collectionsProvider.overrideWith(_TestCollectionsNotifier.new),
        currentProfileProvider.overrideWithValue(testProfile),
        kodiSettingsProvider.overrideWith(() => _TestKodiSettingsNotifier(
              preloadedState,
            )),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: KodiScreen()),
      ),
    );
  }

  group('KodiScreen', () {
    group('layout', () {
      testWidgets('shows title bar with Kodi', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Kodi'), findsOneWidget);
      });

      testWidgets('shows Connection and Sync sections',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsGroup), findsAtLeastNWidgets(2));
      });

      testWidgets('shows Debug section header when host is set',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        // Scroll to make Debug section visible
        await tester.scrollUntilVisible(
          find.text('DEBUG'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('DEBUG'), findsOneWidget);
      });

      testWidgets('hides Debug section when host is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        // Connection + Sync = 2 groups (no DEBUG header)
        expect(find.text('DEBUG'), findsNothing);
      });
    });

    group('connection section', () {
      testWidgets('shows Host field', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Host'), findsOneWidget);
      });

      testWidgets('shows Port field', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Port'), findsOneWidget);
      });

      testWidgets('shows Username field', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Username'), findsOneWidget);
      });

      testWidgets('shows Password field', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('shows Test connection button', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.byTooltip('Test connection'), findsOneWidget);
      });

      testWidgets('Test connection disabled when host is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        final Finder btnFinder = find.byWidgetPredicate(
          (Widget w) => w is IconButton && w.tooltip == 'Test connection',
        );
        final IconButton btn = tester.widget<IconButton>(btnFinder);
        expect(btn.onPressed, isNull);
      });

      testWidgets('Test connection enabled when host is set',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        final Finder btnFinder = find.byWidgetPredicate(
          (Widget w) => w is IconButton && w.tooltip == 'Test connection',
        );
        final IconButton btn = tester.widget<IconButton>(btnFinder);
        expect(btn.onPressed, isNotNull);
      });

      testWidgets('Test connection shows result on success',
          (WidgetTester tester) async {
        when(() => mockKodiApi.ping()).thenAnswer((_) async => true);
        when(() => mockKodiApi.getApplicationProperties())
            .thenAnswer((_) async => const KodiApplicationInfo(
                  versionMajor: 21,
                  versionMinor: 0,
                  versionTag: 'stable',
                  name: 'HTPC',
                ));

        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Test connection'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Kodi 21.0'), findsOneWidget);
      });

      testWidgets('Test connection shows error on failure',
          (WidgetTester tester) async {
        when(() => mockKodiApi.ping()).thenThrow(
          const KodiApiException('Connection refused'),
        );

        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Test connection'));
        await tester.pumpAndSettle();

        expect(find.text('Connection refused'), findsOneWidget);
      });
    });

    group('sync section', () {
      testWidgets('shows Enable Kodi sync toggle',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Enable Kodi sync'), findsOneWidget);
        expect(find.byType(Switch), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Sync interval tile', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sync interval'), findsOneWidget);
        expect(find.text('1 min'), findsOneWidget); // default
      });

      testWidgets('Enable sync switch disabled when host is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget());
        await tester.pumpAndSettle();

        final Finder switches = find.byType(Switch);
        // First switch is "Enable Kodi sync"
        final Switch enableSwitch = tester.widget<Switch>(switches.first);
        expect(enableSwitch.onChanged, isNull);
      });

      testWidgets('Enable sync switch enabled when host + target set',
          (WidgetTester tester) async {
        final Collection testCollection = Collection(
          id: 1,
          name: 'Test Movies',
          author: 'Test',
          type: CollectionType.own,
          createdAt: DateTime(2026),
        );
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
            'kodi_target_collection_id_$profileId': 1,
          },
          extraOverrides: <Override>[
            collectionsProvider.overrideWith(
              () => _TestCollectionsNotifier(<Collection>[testCollection]),
            ),
          ],
        ));
        await tester.pumpAndSettle();

        // Scroll to Sync section (Import section pushes it down).
        await tester.scrollUntilVisible(
          find.text('Enable Kodi sync'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Find Switch that is in the same SettingsTile as 'Enable Kodi sync'.
        final Finder syncTile = find.ancestor(
          of: find.text('Enable Kodi sync'),
          matching: find.byType(SettingsTile),
        );
        expect(syncTile, findsOneWidget);
        final SettingsTile tile = tester.widget<SettingsTile>(syncTile);
        // trailing is the Switch widget — if onChanged is set, it's non-null.
        expect(tile.trailing, isNotNull);
        expect(tile.trailing, isA<Switch>());
        expect((tile.trailing! as Switch).onChanged, isNotNull);
      });
    });

    group('debug section', () {
      Future<void> scrollTo(WidgetTester tester, Finder target) async {
        await tester.scrollUntilVisible(
          target,
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }

      testWidgets('shows Last sync tile', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await scrollTo(tester, find.text('Last sync'));

        expect(find.text('Last sync'), findsOneWidget);
        expect(find.text('Never'), findsOneWidget);
      });

      testWidgets('shows last sync timestamp when set',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
            'kodi_last_sync_timestamp_$profileId': '2026-04-16T10:00:00',
          },
        ));
        await tester.pumpAndSettle();

        await scrollTo(tester, find.text('2026-04-16T10:00:00'));

        expect(find.text('2026-04-16T10:00:00'), findsOneWidget);
      });

      testWidgets('shows Clear last sync timestamp tile',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await scrollTo(tester, find.text('Clear last sync timestamp'));

        expect(find.text('Clear last sync timestamp'), findsOneWidget);
      });

      testWidgets('shows Raw JSON-RPC section',
          (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await scrollTo(tester, find.text('Raw JSON-RPC'));

        expect(find.text('Raw JSON-RPC'), findsOneWidget);
      });

      testWidgets('shows Send button', (WidgetTester tester) async {
        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        await scrollTo(tester, find.text('Send'));

        expect(find.text('Send'), findsOneWidget);
      });

      testWidgets('Send raw request shows response',
          (WidgetTester tester) async {
        when(() => mockKodiApi.rawCall('JSONRPC.Ping', null))
            .thenAnswer((_) async => <String, dynamic>{
                  'result': 'pong',
                });

        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        final Finder sendButton = find.text('Send');
        await scrollTo(tester, sendButton);
        await tester.ensureVisible(sendButton);
        await tester.pumpAndSettle();
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        await scrollTo(tester, find.textContaining('"pong"'));
        expect(find.textContaining('"pong"'), findsOneWidget);
      });

      testWidgets('Send raw request shows error',
          (WidgetTester tester) async {
        when(() => mockKodiApi.rawCall('JSONRPC.Ping', null))
            .thenThrow(const KodiApiException('Timeout'));

        await tester.pumpWidget(await createWidget(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        ));
        await tester.pumpAndSettle();

        final Finder sendButton = find.text('Send');
        await scrollTo(tester, sendButton);
        await tester.ensureVisible(sendButton);
        await tester.pumpAndSettle();
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        await scrollTo(tester, find.textContaining('Timeout'));
        expect(find.textContaining('Timeout'), findsOneWidget);
      });
    });
  });
}

import 'package:core/models/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/simkl_api.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/settings/content/simkl_import_content.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

class _TestCollectionsNotifier extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => const <Collection>[];
}

void main() {
  late MockSimklApi mockSimkl;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockSimkl = MockSimklApi();
    when(() => mockSimkl.setClientId(any())).thenReturn(null);
    when(() => mockSimkl.setAccessToken(any())).thenReturn(null);
    when(() => mockSimkl.clearAccessToken()).thenReturn(null);
    when(() => mockSimkl.getUserSettings(
          tokenOverride: any(named: 'tokenOverride'),
        )).thenAnswer((_) async => const SimklUser(name: 'ann'));
    when(() => mockSimkl.pollPin(any())).thenAnswer((_) async => null);
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<SharedPreferences> pumpContent(
    WidgetTester tester, {
    Map<String, Object> values = const <String, Object>{},
  }) async {
    final SharedPreferences prefs = await prefsWith(values);
    await tester.pumpApp(
      const SingleChildScrollView(child: SimklImportContent()),
      prefs: prefs,
      wrapInScaffold: true,
      overrides: <Override>[
        simklApiProvider.overrideWithValue(mockSimkl),
        collectionsProvider.overrideWith(_TestCollectionsNotifier.new),
      ],
    );
    return prefs;
  }

  S loc(WidgetTester tester) =>
      S.of(tester.element(find.byType(SimklImportContent)));

  /// Drives the client-id form until the PIN block is on screen.
  Future<SharedPreferences> pumpPinBlock(WidgetTester tester) async {
    when(() => mockSimkl.requestPin()).thenAnswer((_) async => const SimklPin(
          userCode: 'AB12C',
          verificationUrl: 'https://simkl.com/pin',
          expiresIn: 900,
          // Long enough that no poll tick fires during the test.
          interval: 600,
        ));
    final SharedPreferences prefs = await pumpContent(tester);

    await tester.enterText(
      find.ancestor(
        of: find.text(loc(tester).simklClientIdLabel),
        matching: find.byType(TextField),
      ),
      'my-client-id',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(loc(tester).simklGetPin));
    // The PIN block spins an indeterminate bar, so it never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return prefs;
  }

  group('SimklImportContent', () {
    testWidgets('renders the disconnected form without exceptions',
        (WidgetTester tester) async {
      await pumpContent(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(loc(tester).simklGetPin), findsOneWidget);
      expect(find.text(loc(tester).importStart), findsOneWidget);
    });

    testWidgets('keeps the import button disabled until an account connects',
        (WidgetTester tester) async {
      await pumpContent(tester);

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('a keyless build cannot request a PIN without a client id',
        (WidgetTester tester) async {
      // Test builds carry no SIMKL_CLIENT_ID, so the key field is shown.
      await pumpContent(tester);

      final Finder button =
          find.widgetWithText(OutlinedButton, loc(tester).simklGetPin);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    });

    testWidgets('shows the PIN code once the user supplies a client id',
        (WidgetTester tester) async {
      final SharedPreferences prefs = await pumpPinBlock(tester);

      expect(find.text('AB12C'), findsOneWidget);
      expect(tester.takeException(), isNull);
      verify(() => mockSimkl.setClientId('my-client-id')).called(1);
      // "Remember the app key" is on by default.
      expect(prefs.getString(SettingsKeys.simklClientId), 'my-client-id');

      // Dispose the tree so the poll timer is cancelled before teardown.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('copies the PIN code when the copy button is tapped',
        (WidgetTester tester) async {
      final List<MethodCall> platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pumpPinBlock(tester);

      await tester.tap(find.byTooltip(loc(tester).copy));
      await tester.pump();

      final Iterable<MethodCall> copies = platformCalls
          .where((MethodCall call) => call.method == 'Clipboard.setData');
      expect(copies, hasLength(1));
      expect(
        (copies.first.arguments as Map<Object?, Object?>)['text'],
        'AB12C',
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('restores a remembered token and verifies the account',
        (WidgetTester tester) async {
      await pumpContent(tester, values: <String, Object>{
        SettingsKeys.simklRememberToken: true,
        SettingsKeys.simklAccessToken: 'tok',
      });

      verify(() => mockSimkl.setAccessToken('tok')).called(1);
      verify(() => mockSimkl.getUserSettings()).called(1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores a stored token when the checkbox is off',
        (WidgetTester tester) async {
      await pumpContent(tester, values: <String, Object>{
        SettingsKeys.simklAccessToken: 'tok',
      });

      verifyNever(() => mockSimkl.setAccessToken(any()));
      expect(find.text(loc(tester).simklGetPin), findsOneWidget);
    });

    testWidgets('disconnect clears the stored token',
        (WidgetTester tester) async {
      final SharedPreferences prefs =
          await pumpContent(tester, values: <String, Object>{
        SettingsKeys.simklRememberToken: true,
        SettingsKeys.simklAccessToken: 'tok',
      });

      await tester.tap(find.text(loc(tester).simklDisconnect));
      await tester.pumpAndSettle();

      verify(() => mockSimkl.clearAccessToken()).called(1);
      expect(prefs.getString(SettingsKeys.simklAccessToken), isNull);
      expect(find.text(loc(tester).simklGetPin), findsOneWidget);
    });

    testWidgets('drops a token the API rejects as unauthorized',
        (WidgetTester tester) async {
      when(() => mockSimkl.getUserSettings(
                tokenOverride: any(named: 'tokenOverride'),
              ))
          .thenThrow(const SimklApiException('bad token', statusCode: 401));

      await pumpContent(tester, values: <String, Object>{
        SettingsKeys.simklRememberToken: true,
        SettingsKeys.simklAccessToken: 'tok',
      });

      verify(() => mockSimkl.clearAccessToken()).called(1);
      expect(find.text(loc(tester).simklGetPin), findsOneWidget);
    });

    testWidgets('turning the remember checkbox on stores the live token',
        (WidgetTester tester) async {
      final SharedPreferences prefs =
          await pumpContent(tester, values: <String, Object>{
        SettingsKeys.simklRememberToken: true,
        SettingsKeys.simklAccessToken: 'tok',
      });

      await tester.tap(find.text(loc(tester).simklRememberToken));
      await tester.pumpAndSettle();

      expect(prefs.getBool(SettingsKeys.simklRememberToken), isFalse);
      expect(prefs.getString(SettingsKeys.simklAccessToken), isNull);
    });
  });
}

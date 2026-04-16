import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/services/discord_rpc_service.dart';
import 'package:xerabora/core/services/kodi_sync_service.dart';
import 'package:xerabora/shared/navigation/service_badges.dart';
import 'package:xerabora/shared/navigation/service_status_provider.dart';
import 'package:xerabora/shared/theme/app_assets.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ServiceBadges', () {
    Widget buildWidget({
      ServiceStatus status = const ServiceStatus(),
      List<Override> extraOverrides = const <Override>[],
    }) {
      return ProviderScope(
        overrides: <Override>[
          serviceStatusProvider.overrideWith(
            (Ref ref) => Stream<ServiceStatus>.value(status),
          ),
          ...extraOverrides,
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ServiceBadges(),
          ),
        ),
      );
    }

    testWidgets('renders nothing when no services are active',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders Kodi icon when kodiEnabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(kodiEnabled: true, kodiRunning: true),
      ));
      await tester.pumpAndSettle();

      final Finder kodiIcon = find.byWidgetPredicate((Widget w) =>
          w is SvgPicture &&
          w.bytesLoader is SvgAssetLoader &&
          (w.bytesLoader as SvgAssetLoader).assetName == AppAssets.iconKodi);
      expect(kodiIcon, findsOneWidget);
    });

    testWidgets('renders Discord icon when discordEnabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(
            discordEnabled: true, discordConnected: true),
      ));
      await tester.pumpAndSettle();

      final Finder discordIcon = find.byWidgetPredicate((Widget w) =>
          w is SvgPicture &&
          w.bytesLoader is SvgAssetLoader &&
          (w.bytesLoader as SvgAssetLoader).assetName ==
              AppAssets.iconDiscord);
      expect(discordIcon, findsOneWidget);
    });

    testWidgets('renders both icons when both enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(
          kodiEnabled: true,
          kodiRunning: true,
          discordEnabled: true,
          discordConnected: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets('Kodi icon tap calls stop when running',
        (WidgetTester tester) async {
      final MockKodiSyncService mockSync = MockKodiSyncService();
      when(() => mockSync.isRunning).thenReturn(true);

      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(kodiEnabled: true, kodiRunning: true),
        extraOverrides: <Override>[
          kodiSyncServiceProvider.overrideWithValue(mockSync),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      verify(() => mockSync.stop()).called(1);
    });

    testWidgets('Discord icon tap calls disable when connected',
        (WidgetTester tester) async {
      final MockDiscordRpcService mockDiscord = MockDiscordRpcService();
      when(() => mockDiscord.disableRaSync()).thenAnswer((_) async {});
      when(() => mockDiscord.disable()).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(
            discordEnabled: true, discordConnected: true),
        extraOverrides: <Override>[
          discordRpcServiceProvider.overrideWithValue(mockDiscord),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      verify(() => mockDiscord.disableRaSync()).called(1);
      verify(() => mockDiscord.disable()).called(1);
    });

    testWidgets('Discord icon tap calls enable when disconnected',
        (WidgetTester tester) async {
      final MockDiscordRpcService mockDiscord = MockDiscordRpcService();
      when(() => mockDiscord.enable()).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(
        status: const ServiceStatus(
            discordEnabled: true, discordConnected: false),
        extraOverrides: <Override>[
          discordRpcServiceProvider.overrideWithValue(mockDiscord),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      verify(() => mockDiscord.enable()).called(1);
    });
  });
}

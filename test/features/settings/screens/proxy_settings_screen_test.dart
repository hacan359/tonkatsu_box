import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/app_proxy_config.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/settings/screens/proxy_settings_screen.dart';

import '../../../helpers/test_helpers.dart';

class _RecordingSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();

  @override
  Future<void> setProxyEnabled({required bool enabled}) async {
    state = state.copyWith(proxyEnabled: enabled);
  }
}

void main() {
  tearDown(() => AppProxyConfig.current = const AppProxyConfig.disabled());

  group('ProxySettingsScreen', () {
    testWidgets('should render on a phone-sized screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpApp(const ProxySettingsScreen(), wrapInScaffold: true);

      expect(tester.takeException(), isNull);
      expect(find.text(AppProxyConfig.defaultHost), findsOneWidget);
      expect(find.text('${AppProxyConfig.defaultPort}'), findsOneWidget);
    });

    testWidgets('should turn the proxy on from the switch', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const ProxySettingsScreen(),
        wrapInScaffold: true,
        overrides: <Override>[
          settingsNotifierProvider.overrideWith(_RecordingSettingsNotifier.new),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('proxyEnabledSwitch')),
      );
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ProxySettingsScreen)),
      );
      expect(container.read(settingsNotifierProvider).proxyEnabled, isTrue);
    });
  });
}

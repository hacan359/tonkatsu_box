import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_proxy_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';

/// Lets the user point Dart's HttpClient at the local proxy port a VPN app
/// exposes (e.g. Clash's mixed port), so outbound traffic can leave a
/// restricted network without relying on TUN capture.
class ProxySettingsScreen extends ConsumerStatefulWidget {
  const ProxySettingsScreen({super.key});

  @override
  ConsumerState<ProxySettingsScreen> createState() =>
      _ProxySettingsScreenState();
}

class _ProxySettingsScreenState extends ConsumerState<ProxySettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _hostController = TextEditingController(text: settings.proxyHost);
    _portController =
        TextEditingController(text: settings.proxyPort.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsProxy)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l.settingsProxyHint,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          if (kIsWebBuild)
            Text(
              '此设置仅在桌面端与移动端可用。',
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            SettingsGroup(
              title: l.settingsProxy,
              children: <Widget>[
                SettingsTile(
                  leadingIcon: Icons.lan_outlined,
                  leadingColor: AppColors.textTertiary,
                  title: l.settingsProxyEnabled,
                  showChevron: false,
                  trailing: Switch(
                    value: settings.proxyEnabled,
                    onChanged: (bool value) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setProxyEnabled(enabled: value);
                    },
                  ),
                ),
                if (settings.proxyEnabled) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          l.settingsProxyType,
                          style: AppTypography.body,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SegmentedButton<AppProxyType>(
                          selected: <AppProxyType>{
                            AppProxyType.fromId(settings.proxyType),
                          },
                          onSelectionChanged:
                              (Set<AppProxyType> selection) {
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setProxyType(selection.first.id);
                          },
                          segments: <ButtonSegment<AppProxyType>>[
                            ButtonSegment<AppProxyType>(
                              value: AppProxyType.http,
                              label: Text(AppProxyType.http.label),
                            ),
                            ButtonSegment<AppProxyType>(
                              value: AppProxyType.socks5,
                              label: Text(AppProxyType.socks5.label),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        labelText: l.settingsProxyHost,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (String value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .setProxyHost(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.settingsProxyPort,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (String value) {
                        final int? port = int.tryParse(value);
                        if (port != null) {
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .setProxyPort(port);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

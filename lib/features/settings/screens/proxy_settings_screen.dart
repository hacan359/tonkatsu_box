import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_proxy_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/frame_page.dart';
import '../providers/settings_provider.dart';
import '../widgets/inline_text_field.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';

class ProxySettingsScreen extends ConsumerWidget {
  const ProxySettingsScreen({super.key});

  static const double _desktopBreakpoint = 800;
  static const double _maxWidth = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final SettingsNotifier notifier = ref.read(
      settingsNotifierProvider.notifier,
    );
    final bool isWide = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    Future<void> save(Future<bool> Function() write) async {
      final bool saved = await write();
      if (!saved && context.mounted) {
        context.showSnack(l.settingsProxyInvalid, type: SnackType.error);
      }
    }

    return FramePage(
      title: l.settingsProxy,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? _maxWidth : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            children: <Widget>[
              SettingsGroup(
                title: l.settingsProxy,
                subtitle: l.settingsProxyHint,
                children: <Widget>[
                  SettingsTile(
                    title: l.settingsProxyEnabled,
                    showChevron: false,
                    trailing: Switch(
                      key: const ValueKey<String>('proxyEnabledSwitch'),
                      value: settings.proxyEnabled,
                      onChanged: (bool value) =>
                          notifier.setProxyEnabled(enabled: value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: InlineTextField(
                      key: const ValueKey<String>('proxyHostField'),
                      label: l.settingsProxyHost,
                      value: settings.proxyHost,
                      placeholder: AppProxyConfig.defaultHost,
                      compact: true,
                      onChanged: (String value) =>
                          save(() => notifier.setProxyHost(value)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: InlineTextField(
                      key: const ValueKey<String>('proxyPortField'),
                      label: l.settingsProxyPort,
                      value: settings.proxyPort.toString(),
                      placeholder: AppProxyConfig.defaultPort.toString(),
                      compact: true,
                      onChanged: (String value) => save(() async {
                        final int? port = int.tryParse(value.trim());
                        return port != null &&
                            await notifier.setProxyPort(port);
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

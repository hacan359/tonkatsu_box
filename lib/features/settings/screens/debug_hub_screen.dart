// Экран-хаб для debug инструментов разработчика.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
import '../providers/settings_provider.dart';
import 'gamepad_debug_screen.dart';
import 'image_debug_screen.dart';
import 'steamgriddb_debug_screen.dart';

/// Хаб для debug инструментов разработчика.
///
/// Содержит ссылки на SteamGridDB Debug, Image Debug и Gamepad Debug.
class DebugHubScreen extends ConsumerWidget {
  /// Создаёт [DebugHubScreen].
  const DebugHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BreadcrumbAppBar(
        crumbs: <BreadcrumbItem>[
          BreadcrumbItem(
            label: 'Settings',
            onTap: () => Navigator.of(context).pop(),
          ),
          const BreadcrumbItem(label: 'Debug'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('SteamGridDB Debug Panel'),
                  subtitle: Text(
                    settings.hasSteamGridDbKey
                        ? 'Test API endpoints'
                        : 'Set API key first',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: settings.hasSteamGridDbKey,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const SteamGridDbDebugScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.image_search),
                  title: const Text('Image Debug Panel'),
                  subtitle: const Text('Check poster URLs and loading'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const ImageDebugScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gamepad),
                  title: const Text('Gamepad Debug Panel'),
                  subtitle: const Text('Test controller input events'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const GamepadDebugScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

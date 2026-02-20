// Экран-хаб для debug инструментов разработчика.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_nav_row.dart';
import '../widgets/settings_section.dart';
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
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return BreadcrumbScope(
      label: 'Debug',
      child: Scaffold(
        appBar: const AutoBreadcrumbAppBar(),
        body: ListView(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
          children: <Widget>[
            SettingsSection(
              title: 'Debug Tools',
              icon: Icons.bug_report,
              compact: compact,
              children: <Widget>[
                SettingsNavRow(
                  title: 'SteamGridDB Debug Panel',
                  icon: Icons.grid_view,
                  subtitle: settings.hasSteamGridDbKey
                      ? 'Test API endpoints'
                      : 'Set API key first',
                  enabled: settings.hasSteamGridDbKey,
                  compact: compact,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const BreadcrumbScope(
                          label: 'Debug',
                          child: SteamGridDbDebugScreen(),
                        ),
                      ),
                    );
                  },
                ),
                SettingsNavRow(
                  title: 'Image Debug Panel',
                  icon: Icons.image_search,
                  subtitle: 'Check poster URLs and loading',
                  showDivider: true,
                  compact: compact,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const BreadcrumbScope(
                          label: 'Debug',
                          child: ImageDebugScreen(),
                        ),
                      ),
                    );
                  },
                ),
                SettingsNavRow(
                  title: 'Gamepad Debug Panel',
                  icon: Icons.gamepad,
                  subtitle: 'Test controller input events',
                  showDivider: true,
                  compact: compact,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const BreadcrumbScope(
                          label: 'Debug',
                          child: GamepadDebugScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

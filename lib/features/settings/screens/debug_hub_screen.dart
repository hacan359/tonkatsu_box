// Экран-хаб для debug инструментов разработчика.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_spacing.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_tile.dart';
import 'demo_collections_screen.dart';
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
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return Scaffold(
      appBar: AppBar(),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 600 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: <Widget>[
                SettingsGroup(
                  title: 'Debug Tools',
                  children: <Widget>[
                    SettingsTile(
                      title: 'SteamGridDB Debug Panel',
                      value: settings.hasSteamGridDbKey
                          ? 'Test API endpoints'
                          : 'Set API key first',
                      onTap: settings.hasSteamGridDbKey
                          ? () => _push(context, const SteamGridDbDebugScreen())
                          : null,
                    ),
                    SettingsTile(
                      title: 'Image Debug Panel',
                      value: 'Check poster URLs and loading',
                      onTap: () => _push(context, const ImageDebugScreen()),
                    ),
                    SettingsTile(
                      title: 'Gamepad Debug Panel',
                      value: 'Test controller input events',
                      onTap: () => _push(context, const GamepadDebugScreen()),
                    ),
                    SettingsTile(
                      title: 'Demo Collections Generator',
                      value: settings.hasCredentials && settings.hasTmdbKey
                          ? 'Generate .xcollx files'
                          : 'Set IGDB + TMDB keys first',
                      onTap: settings.hasCredentials && settings.hasTmdbKey
                          ? () => _push(context, const DemoCollectionsScreen())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => screen,
      ),
    );
  }
}

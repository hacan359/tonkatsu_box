// Экран управления профилями.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/profile_service.dart';
import '../providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../providers/profile_provider.dart';
import '../widgets/create_profile_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

/// Экран управления профилями.
class ProfilesScreen extends ConsumerStatefulWidget {
  /// Создаёт [ProfilesScreen].
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  final Map<String, ProfileStats> _stats = <String, ProfileStats>{};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final ProfileService service = ref.read(profileServiceProvider);
    final ProfilesData data = ref.read(profilesDataProvider);

    final Map<String, ProfileStats> loaded = <String, ProfileStats>{};
    for (final Profile profile in data.profiles) {
      loaded[profile.id] = await service.getProfileStats(profile.id);
    }
    if (mounted) {
      setState(() => _stats.addAll(loaded));
    }
  }

  Future<void> _createProfile() async {
    final ({String name, String color})? result =
        await CreateProfileDialog.show(context);
    if (result == null) return;

    final ProfileService service = ref.read(profileServiceProvider);
    await service.createProfile(result.name, result.color);

    // Перечитываем данные
    final ProfilesData updated = await service.loadProfiles();
    ref.read(profilesDataProvider.notifier).state = updated;

    if (mounted) {
      context.showSnack(
        S.of(context).profileCreated,
        type: SnackType.success,
      );
    }
    await _loadStats();
  }

  Future<void> _editProfile(Profile profile) async {
    final ProfilesData data = ref.read(profilesDataProvider);
    final bool canDelete = data.profiles.length > 1;

    final EditProfileResult? result = await EditProfileDialog.show(
      context,
      profile: profile,
      canDelete: canDelete,
    );

    if (result == null) return;

    final ProfileService service = ref.read(profileServiceProvider);

    switch (result) {
      case ProfileUpdated(:final String name, :final String color):
        await service.updateProfile(profile.copyWith(
          name: name,
          color: color,
        ));
      case ProfileDeleteRequested():
        await service.deleteProfile(profile.id);
        if (mounted) {
          context.showSnack(
            S.of(context).profileDeleted,
            type: SnackType.success,
          );
        }
    }

    // Перечитываем данные
    final ProfilesData updated = await service.loadProfiles();
    ref.read(profilesDataProvider.notifier).state = updated;
    await _loadStats();
  }

  Future<void> _switchProfile(Profile profile) async {
    final ProfilesData data = ref.read(profilesDataProvider);
    if (profile.id == data.currentProfileId) return;

    final S l = S.of(context);
    final ProfileService service = ref.read(profileServiceProvider);
    await service.switchProfile(profile.id);

    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.switchingProfile),
        content: Text(l.appWillRestart),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      // Откатываем — пользователь передумал
      final ProfileService revertService = ref.read(profileServiceProvider);
      await revertService.switchProfile(data.currentProfileId);
      return;
    }

    // Пропустить picker при следующем запуске — сразу в home
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('skip_picker_once', true);

    if (!mounted) return;
    await ProfileService.restartApp(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ProfilesData data = ref.watch(profilesDataProvider);

    return Scaffold(
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.textSecondary,
            tooltip: l.addProfile,
            onPressed: _createProfile,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: data.profiles.length,
        itemBuilder: (BuildContext context, int index) {
          final Profile profile = data.profiles[index];
          final bool isCurrent =
              profile.id == data.currentProfileId;
          final ProfileStats stats =
              _stats[profile.id] ?? ProfileStats.empty;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            color: isCurrent
                ? profile.colorValue.withAlpha(15)
                : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(
                color: isCurrent
                    ? profile.colorValue.withAlpha(60)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: profile.colorValue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: <Widget>[
                  Text(profile.name, style: AppTypography.h3),
                  if (isCurrent) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: profile.colorValue,
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                l.profileStats(stats.collectionsCount, stats.itemsCount),
                style: AppTypography.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.settings, size: 18),
                color: AppColors.textTertiary,
                onPressed: () => _editProfile(profile),
              ),
              onTap: isCurrent ? null : () => _switchProfile(profile),
            ),
          );
        },
      ),
    );
  }
}

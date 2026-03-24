// Экран выбора профиля при запуске.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/profile_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/widgets/create_profile_dialog.dart';

/// Ключ SharedPreferences для пропуска выбора профиля.
const String kSkipProfilePickerKey = 'skip_profile_picker';

/// Экран выбора профиля при запуске.
///
/// Показывается после splash, если профилей > 1 и пользователь
/// не отключил этот экран через "Don't ask again".
class ProfilePickerScreen extends ConsumerStatefulWidget {
  /// Создаёт [ProfilePickerScreen].
  const ProfilePickerScreen({super.key});

  @override
  ConsumerState<ProfilePickerScreen> createState() =>
      _ProfilePickerScreenState();
}

class _ProfilePickerScreenState
    extends ConsumerState<ProfilePickerScreen> {
  bool _dontAskAgain = false;

  Future<void> _selectProfile(Profile profile) async {
    final ProfilesData data = ref.read(profilesDataProvider);

    if (profile.id != data.currentProfileId) {
      // Переключаем и перезапускаем
      final ProfileService service = ref.read(profileServiceProvider);
      await service.switchProfile(profile.id);
      if (!mounted) return;
      await ProfileService.restartApp(context, ref);
      return;
    }

    // Текущий профиль — просто идём дальше
    if (_dontAskAgain) {
      final SharedPreferences prefs =
          ref.read(sharedPreferencesProvider);
      await prefs.setBool(kSkipProfilePickerKey, true);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const NavigationShell(),
      ),
    );
  }

  Future<void> _createProfile() async {
    final ({String name, String color})? result =
        await CreateProfileDialog.show(context);
    if (result == null) return;

    final ProfileService service = ref.read(profileServiceProvider);
    final Profile profile =
        await service.createProfile(result.name, result.color);

    // Переключаемся на новый профиль и перезапускаем
    await service.switchProfile(profile.id);
    if (!mounted) return;
    await ProfileService.restartApp(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ProfilesData data = ref.watch(profilesDataProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Title
                Text(
                  l.whoIsPlayingToday,
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Profile grid
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (final Profile profile in data.profiles)
                      _ProfileCard(
                        profile: profile,
                        isCurrent:
                            profile.id == data.currentProfileId,
                        onTap: () => _selectProfile(profile),
                      ),
                    // Add button
                    _AddProfileCard(onTap: _createProfile),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Don't ask again
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Checkbox(
                      value: _dontAskAgain,
                      onChanged: (bool? value) {
                        setState(
                          () => _dontAskAgain = value ?? false,
                        );
                      },
                    ),
                    Text(
                      l.dontAskAgain,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isCurrent,
    required this.onTap,
  });

  final Profile profile;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? profile.colorValue.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isCurrent
                ? profile.colorValue.withAlpha(80)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: profile.colorValue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              profile.name,
              style: AppTypography.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).addProfile,
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

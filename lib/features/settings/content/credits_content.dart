// Контент экрана атрибуции API-провайдеров и лицензий (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../widgets/settings_group.dart';

/// Контент экрана Credits с атрибуцией API-провайдеров и лицензиями.
///
/// Показывает обязательную атрибуцию TMDB, а также IGDB и SteamGridDB.
/// Содержит ссылку на GitHub и кнопку просмотра Open Source лицензий.
/// Используется как standalone в десктопном sidebar и внутри [CreditsScreen].
class CreditsContent extends StatelessWidget {
  /// Создаёт [CreditsContent].
  const CreditsContent({super.key});

  static const String _tmdbUrl = 'https://www.themoviedb.org/';
  static const String _igdbUrl = 'https://www.igdb.com/';
  static const String _steamGridDbUrl = 'https://www.steamgriddb.com/';
  static const String _vndbUrl = 'https://vndb.org/';
  static const String _aniListUrl = 'https://anilist.co/';
  static const String _githubUrl =
      'https://github.com/hacan359/tonkatsu_box';

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsGroup(
          title: l10n.creditsDataProviders,
          children: <Widget>[
            _buildProvider(
              name: 'TMDB',
              description: l10n.creditsTmdbAttribution,
              linkLabel: 'themoviedb.org',
              url: _tmdbUrl,
            ),
            _buildProvider(
              name: 'IGDB',
              description: l10n.creditsIgdbAttribution,
              linkLabel: 'igdb.com',
              url: _igdbUrl,
            ),
            _buildProvider(
              name: 'SteamGridDB',
              description: l10n.creditsSteamGridDbAttribution,
              linkLabel: 'steamgriddb.com',
              url: _steamGridDbUrl,
            ),
            _buildProvider(
              name: 'VNDB',
              description: l10n.creditsVndbAttribution,
              linkLabel: 'vndb.org',
              url: _vndbUrl,
            ),
            _buildProvider(
              name: 'AniList',
              description: l10n.creditsAniListAttribution,
              linkLabel: 'anilist.co',
              url: _aniListUrl,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsGroup(
          title: l10n.creditsOpenSource,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                l10n.creditsOpenSourceDesc,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _buildLinkRow(
              label: 'GitHub',
              linkLabel: 'hacan359/tonkatsu_box',
              url: _githubUrl,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Tonkatsu Box',
                  );
                },
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(l10n.creditsViewLicenses),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Элемент провайдера: название, описание, ссылка.
  Widget _buildProvider({
    required String name,
    required String description,
    required String linkLabel,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  linkLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.brand,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строка со ссылкой (для GitHub и т.п.).
  Widget _buildLinkRow({
    required String label,
    required String linkLabel,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              linkLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.brand,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.open_in_new,
              size: 14,
              color: AppColors.brand,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  try {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } on Exception {
    // Молча игнорируем — ссылка не критична для работы приложения.
  }
}

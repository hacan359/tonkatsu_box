// Контент экрана атрибуции API-провайдеров и лицензий (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_badge.dart';

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
  static const String _githubUrl =
      'https://github.com/hacan359/tonkatsu_box';

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    final S l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          title: l10n.creditsDataProviders,
          compact: compact,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        _ProviderCard(
          logoAsset: 'assets/credits/tmdb_logo.svg',
          logoWidth: compact ? 100.0 : 120.0,
          description: l10n.creditsTmdbAttribution,
          linkLabel: 'themoviedb.org',
          url: _tmdbUrl,
          accentColor: DataSource.tmdb.color,
          compact: compact,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        _ProviderCard(
          logoAsset: 'assets/credits/igdb_logo.svg',
          logoWidth: compact ? 80.0 : 100.0,
          description: l10n.creditsIgdbAttribution,
          linkLabel: 'igdb.com',
          url: _igdbUrl,
          accentColor: DataSource.igdb.color,
          compact: compact,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        _ProviderCard(
          logoAsset: 'assets/credits/steamgriddb_logo.svg',
          logoWidth: compact ? 120.0 : 150.0,
          description: l10n.creditsSteamGridDbAttribution,
          linkLabel: 'steamgriddb.com',
          url: _steamGridDbUrl,
          accentColor: DataSource.steamGridDb.color,
          compact: compact,
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
        _SectionHeader(
          title: l10n.creditsOpenSource,
          compact: compact,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        _OpenSourceCard(compact: compact),
      ],
    );
  }
}

/// Заголовок секции на экране Credits.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: compact ? AppTypography.h3 : AppTypography.h2,
    );
  }
}

/// Карточка провайдера с логотипом, описанием и ссылкой.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.logoAsset,
    required this.logoWidth,
    required this.description,
    required this.linkLabel,
    required this.url,
    required this.accentColor,
    required this.compact,
  });

  final String logoAsset;
  final double logoWidth;
  final String description;
  final String linkLabel;
  final String url;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SvgPicture.asset(
            logoAsset,
            width: logoWidth,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _launchUrl(url),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    linkLabel,
                    style: AppTypography.body.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка Open Source с ссылкой на GitHub и кнопкой лицензий.
class _OpenSourceCard extends StatelessWidget {
  const _OpenSourceCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            S.of(context).creditsOpenSourceDesc,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _launchUrl(CreditsContent._githubUrl),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'github.com/hacan359/tonkatsu_box',
                    style: AppTypography.body.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
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
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Tonkatsu Box',
                );
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(S.of(context).creditsViewLicenses),
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

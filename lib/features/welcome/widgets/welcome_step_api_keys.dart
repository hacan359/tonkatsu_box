// Шаг 2 Welcome Wizard — инструкции получения API ключей.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 2: API Keys — подробные инструкции получения ключей.
class WelcomeStepApiKeys extends StatelessWidget {
  /// Создаёт [WelcomeStepApiKeys].
  const WelcomeStepApiKeys({super.key});

  /// Цвет для SteamGridDB (голубой).
  static const Color _sgdbColor = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: <Widget>[
                const Icon(Icons.key, size: 36, color: AppColors.brand),
                const SizedBox(height: 8),
                const Text(
                  'Getting API Keys',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Free registration, takes 2-3 minutes each',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // IGDB
          const _ApiSection(
            tag: 'IGDB',
            tagColor: AppColors.gameAccent,
            title: 'Game search',
            badge: 'REQUIRED',
            badgeColor: AppColors.brand,
            steps: <String>[
              'Go to dev.twitch.tv/console',
              'Log in with Twitch (create account if needed)',
              'Register Your Application\n'
                  'Name: anything, URL: http://localhost',
              'Copy Client ID and Client Secret',
            ],
            linkTitle: 'Twitch Developer Console',
            linkSubtitle: 'dev.twitch.tv/console/apps',
            linkUrl: 'https://dev.twitch.tv/console/apps',
            linkColor: AppColors.gameAccent,
          ),
          const SizedBox(height: AppSpacing.sm),

          // TMDB
          const _ApiSection(
            tag: 'TMDB',
            tagColor: AppColors.brand,
            title: 'Movies, TV & Anime',
            badge: 'RECOMMENDED',
            badgeColor: AppColors.textTertiary,
            steps: <String>[
              'Go to themoviedb.org',
              'Create free account → Settings → API',
              'Request API Key (Developer type)',
              'Copy API Key (v3 auth)',
            ],
            linkTitle: 'TMDB API',
            linkSubtitle: 'themoviedb.org — Settings → API',
            linkUrl: 'https://www.themoviedb.org/settings/api',
            linkColor: AppColors.brand,
          ),
          const SizedBox(height: AppSpacing.sm),

          // SteamGridDB
          const _ApiSection(
            tag: 'SGDB',
            tagColor: _sgdbColor,
            title: 'Game artwork for boards',
            badge: 'OPTIONAL',
            badgeColor: AppColors.textTertiary,
            steps: <String>[
              'Go to steamgriddb.com',
              'Create account → Preferences → API',
              'Copy API Key',
            ],
            linkTitle: 'SteamGridDB',
            linkSubtitle: 'steamgriddb.com — Preferences → API',
            linkUrl: 'https://www.steamgriddb.com/profile/preferences/api',
            linkColor: _sgdbColor,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(12),
              border: Border.all(color: AppColors.brand.withAlpha(30)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'Enter keys in Settings → Credentials after setup',
              style: AppTypography.body.copyWith(color: AppColors.brandLight),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Секция одного API провайдера с тегом, инструкциями и ссылкой.
class _ApiSection extends StatelessWidget {
  const _ApiSection({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.steps,
    required this.linkTitle,
    required this.linkSubtitle,
    required this.linkUrl,
    required this.linkColor,
  });

  final String tag;
  final Color tagColor;
  final String title;
  final String badge;
  final Color badgeColor;
  final List<String> steps;
  final String linkTitle;
  final String linkSubtitle;
  final String linkUrl;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header row: tag + title + badge
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
              Text(
                title,
                style: AppTypography.h3.copyWith(fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: badgeColor == AppColors.textTertiary
                      ? AppColors.surfaceLight
                      : badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Steps
          ...List<Widget>.generate(steps.length, (int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${index + 1}.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // Link card
          _LinkCard(
            title: linkTitle,
            subtitle: linkSubtitle,
            url: linkUrl,
            color: linkColor,
          ),
        ],
      ),
    );
  }
}

/// Карточка-ссылка на внешний ресурс.
class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: () => _openUrl(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.open_in_new, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(fontSize: 13),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.content_copy, size: 14, color: color.withAlpha(150)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        context.showAppSnackBar('URL copied to clipboard');
      }
    }
  }
}

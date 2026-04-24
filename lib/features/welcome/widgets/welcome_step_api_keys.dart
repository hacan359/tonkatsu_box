// Шаг 4 Welcome Wizard — инструкции получения API ключей.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/api_defaults.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Шаг 4: API Keys — подробные инструкции получения ключей.
class WelcomeStepApiKeys extends StatelessWidget {
  /// Создаёт [WelcomeStepApiKeys].
  const WelcomeStepApiKeys({super.key});

  /// Цвет для SteamGridDB (голубой).
  static const Color _sgdbColor = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

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
                Text(
                  l.welcomeApiTitle,
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l.welcomeApiFreeHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Rate limit warning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(12),
              border: Border.all(color: AppColors.warning.withAlpha(40)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.welcomeApiRateLimitHint,
                    style: AppTypography.body.copyWith(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // IGDB
          if (ApiDefaults.hasIgdbKey)
            _BuiltInKeySection(
              tag: l.welcomeApiIgdbTag,
              tagColor: AppColors.gameAccent,
              iconAsset: AppAssets.iconIgdbColor,
              title: l.welcomeApiIgdbDesc,
              builtInLabel: l.welcomeApiBuiltInKey,
              ownKeyHint: l.welcomeApiOwnKeyHint,
            )
          else
            _ApiSection(
              tag: l.welcomeApiIgdbTag,
              tagColor: AppColors.gameAccent,
              iconAsset: AppAssets.iconIgdbColor,
              title: l.welcomeApiIgdbDesc,
              badge: l.welcomeApiRequired,
              badgeColor: AppColors.brand,
              steps: const <String>[
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
          _ApiSection(
            tag: l.welcomeApiTmdbTag,
            tagColor: AppColors.brand,
            iconAsset: AppAssets.iconTmdbColor,
            title: l.welcomeApiTmdbDesc,
            badge: ApiDefaults.hasTmdbKey
                ? l.welcomeApiBuiltInKey
                : l.welcomeApiRecommended,
            badgeColor: ApiDefaults.hasTmdbKey
                ? AppColors.success
                : AppColors.textTertiary,
            steps: const <String>[
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
          _ApiSection(
            tag: l.welcomeApiSgdbTag,
            tagColor: _sgdbColor,
            iconAsset: AppAssets.iconSteamGridDbColor,
            title: l.welcomeApiSgdbDesc,
            badge: ApiDefaults.hasSteamGridDbKey
                ? l.welcomeApiBuiltInKey
                : l.welcomeApiOptional,
            badgeColor: ApiDefaults.hasSteamGridDbKey
                ? AppColors.success
                : AppColors.textTertiary,
            steps: const <String>[
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
              l.welcomeApiEnterKeysHint,
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
    this.iconAsset,
  });

  final String tag;
  final Color tagColor;
  final String? iconAsset;
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
              if (iconAsset != null)
                Tooltip(
                  message: tag,
                  child: Image.asset(
                    iconAsset!,
                    width: 24,
                    height: 24,
                    filterQuality: FilterQuality.medium,
                  ),
                )
              else
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

/// Секция API с встроенным ключом — компактная, без инструкций.
class _BuiltInKeySection extends StatelessWidget {
  const _BuiltInKeySection({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.builtInLabel,
    required this.ownKeyHint,
    this.iconAsset,
  });

  final String tag;
  final Color tagColor;
  final String? iconAsset;
  final String title;
  final String builtInLabel;
  final String ownKeyHint;

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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (iconAsset != null)
                Tooltip(
                  message: tag,
                  child: Image.asset(
                    iconAsset!,
                    width: 24,
                    height: 24,
                    filterQuality: FilterQuality.medium,
                  ),
                )
              else
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
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  builtInLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  builtInLabel,
                  style: AppTypography.body.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ownKeyHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          // Open URL area
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusSm),
                ),
                onTap: () => _openUrl(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Copy URL button
          Container(
            width: 1,
            height: 32,
            color: AppColors.surfaceBorder,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppSpacing.radiusSm),
              ),
              onTap: () => _copyUrl(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Icon(
                  Icons.content_copy,
                  size: 14,
                  color: color.withAlpha(150),
                ),
              ),
            ),
          ),
        ],
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
      await _copyUrl(context);
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      context.showSnack(S.of(context).credentialsUrlCopied(url));
    }
  }
}

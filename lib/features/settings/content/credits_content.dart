// API-provider attribution and license screen content (no Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/source_catalog.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_logo.dart';
import '../widgets/settings_group.dart';

/// One attribution entry.
typedef _Provider = ({
  DataSource source,
  String name,
  String description,
  String linkLabel,
  String url,
});

/// Credits content: API-provider attribution (with logos) and licenses.
///
/// Each data provider is shown with its brand logo, accent and the media
/// types it powers. Used standalone in the desktop sidebar and inside
/// [CreditsScreen].
class CreditsContent extends StatelessWidget {
  const CreditsContent({super.key});

  static const String _githubUrl =
      'https://github.com/hacan359/tonkatsu_box';
  static const String _discordUrl = 'https://discord.gg/JZVNPF7cS2';

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);

    final List<_Provider> providers = <_Provider>[
      (
        source: DataSource.tmdb,
        name: 'TMDB',
        description: l10n.creditsTmdbAttribution,
        linkLabel: 'themoviedb.org',
        url: 'https://www.themoviedb.org/',
      ),
      (
        source: DataSource.igdb,
        name: 'IGDB',
        description: l10n.creditsIgdbAttribution,
        linkLabel: 'igdb.com',
        url: 'https://www.igdb.com/',
      ),
      (
        source: DataSource.steamGridDb,
        name: 'SteamGridDB',
        description: l10n.creditsSteamGridDbAttribution,
        linkLabel: 'steamgriddb.com',
        url: 'https://www.steamgriddb.com/',
      ),
      (
        source: DataSource.anilist,
        name: 'AniList',
        description: l10n.creditsAniListAttribution,
        linkLabel: 'anilist.co',
        url: 'https://anilist.co/',
      ),
      (
        source: DataSource.mangabaka,
        name: 'MangaBaka',
        description: l10n.creditsMangaBakaAttribution,
        linkLabel: 'mangabaka.org',
        url: 'https://mangabaka.org/',
      ),
      (
        source: DataSource.vndb,
        name: 'VNDB',
        description: l10n.creditsVndbAttribution,
        linkLabel: 'vndb.org',
        url: 'https://vndb.org/',
      ),
      (
        source: DataSource.openLibrary,
        name: 'OpenLibrary',
        description: l10n.creditsOpenLibraryAttribution,
        linkLabel: 'openlibrary.org',
        url: 'https://openlibrary.org/',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsGroup(
          title: l10n.creditsDataProviders,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: <Widget>[
                  for (final _Provider p in providers) ...<Widget>[
                    _ProviderCard(provider: p),
                    if (p != providers.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
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
            _buildLinkRow(
              label: 'Discord',
              linkLabel: l10n.creditsDiscord,
              url: _discordUrl,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Link row for GitHub / Discord (no logo).
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
              style: AppTypography.bodySmall.copyWith(color: AppColors.brand),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.open_in_new, size: 14, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

/// Branded attribution card: logo, name, media-type chips, description, link.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});

  final _Provider provider;

  @override
  Widget build(BuildContext context) {
    final Color accent = provider.source.color;
    final List<MediaType> mediaTypes = _mediaTypesFor(provider.source);
    final BorderRadius radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _launchUrl(provider.url),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[accent.withAlpha(22), AppColors.surface],
            ),
            borderRadius: radius,
            border: Border.all(color: accent.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SourceLogo(source: provider.source, size: 30, showGlow: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.name,
                        style: AppTypography.h3.copyWith(fontSize: 14),
                      ),
                    ),
                    Text(
                      provider.linkLabel,
                      style:
                          AppTypography.bodySmall.copyWith(color: accent),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.open_in_new, size: 14, color: accent),
                  ],
                ),
                if (mediaTypes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final MediaType mt in mediaTypes)
                        _MediaTag(type: mt),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  provider.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Media types a provider powers, from the shared catalog (empty for
  /// artwork-only sources like SteamGridDB).
  List<MediaType> _mediaTypesFor(DataSource source) {
    for (final SourceInfo info in kDataSourceCatalog) {
      if (info.source == source) return info.mediaTypes;
    }
    return const <MediaType>[];
  }
}

/// Small media-type pill used on provider cards.
class _MediaTag extends StatelessWidget {
  const _MediaTag({required this.type});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final Color color = MediaTypeTheme.colorFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        border: Border.all(color: color.withAlpha(50)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        type.localizedLabel(S.of(context)),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
    // Silently ignore — the link isn't critical to app function.
  }
}

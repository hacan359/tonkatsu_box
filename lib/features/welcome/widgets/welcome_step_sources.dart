import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/settings/widgets/inline_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/source_catalog.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/source_logo.dart';
import 'welcome_card.dart';
import 'welcome_chip.dart';
import 'welcome_hero.dart';
import 'welcome_reveal.dart';

/// Sources — every search provider with its logo and media types, plus inline
/// API-key fields for IGDB and TMDB.
class WelcomeStepSources extends StatelessWidget {
  const WelcomeStepSources({super.key});

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
          WelcomeReveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: WelcomeHero(
                icon: Icons.hub_outlined,
                title: l.welcomeSourcesTitle,
                subtitle: l.welcomeSourcesSubtitle,
                compact: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < kDataSourceCatalog.length; i++) ...<Widget>[
            WelcomeReveal(
              index: i + 1,
              child: _SourceCard(info: kDataSourceCatalog[i]),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// One provider card: logo, media types, description and optional key editor.
class _SourceCard extends ConsumerWidget {
  const _SourceCard({required this.info});

  final SourceInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final DataSource source = info.source;

    return WelcomeCard(
      accent: source.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SourceLogo(source: source, size: 30, showGlow: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  source.label,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
              ),
              _KeyBadge(info: info, settings: settings),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _description(l, source),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final MediaType mt in info.mediaTypes)
                WelcomeChip(
                  label: mt.localizedLabel(l),
                  color: MediaTypeTheme.colorFor(mt),
                  icon: MediaTypeTheme.iconFor(mt),
                ),
            ],
          ),
          if (info.keyRequirement != SourceKeyRequirement.none) ...<Widget>[
            const SizedBox(height: 12),
            _KeyEditor(info: info),
          ],
        ],
      ),
    );
  }

  String _description(S l, DataSource source) => switch (source) {
        DataSource.tmdb => l.welcomeSourceDescTmdb,
        DataSource.igdb => l.welcomeSourceDescIgdb,
        DataSource.anilist => l.welcomeSourceDescAniList,
        DataSource.mangabaka => l.welcomeSourceDescMangaBaka,
        DataSource.vndb => l.welcomeSourceDescVndb,
        DataSource.openLibrary => l.welcomeSourceDescOpenLibrary,
        _ => '',
      };
}

/// Inline API-key fields for IGDB (Client ID + Secret) or TMDB (key), saving
/// straight to the settings notifier. Owns its own field state.
class _KeyEditor extends ConsumerStatefulWidget {
  const _KeyEditor({required this.info});

  final SourceInfo info;

  @override
  ConsumerState<_KeyEditor> createState() => _KeyEditorState();
}

class _KeyEditorState extends ConsumerState<_KeyEditor> {
  String _clientId = '';
  String _clientSecret = '';
  String _tmdbKey = '';

  // IGDB needs both halves together, so only persist once both are present.
  void _saveIgdb() {
    final String id = _clientId.trim();
    final String secret = _clientSecret.trim();
    if (id.isEmpty || secret.isEmpty) return;
    ref
        .read(settingsNotifierProvider.notifier)
        .setCredentials(clientId: id, clientSecret: secret);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    switch (widget.info.source) {
      case DataSource.igdb:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InlineTextField(
              label: l.credentialsClientId,
              value: _clientId,
              placeholder: settings.isIgdbKeyBuiltIn
                  ? l.credentialsUsingBuiltInKey
                  : l.credentialsClientIdHint,
              compact: compact,
              onChanged: (String v) {
                setState(() => _clientId = v);
                _saveIgdb();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            InlineTextField(
              label: l.credentialsClientSecret,
              value: _clientSecret,
              placeholder: settings.isIgdbKeyBuiltIn
                  ? l.credentialsUsingBuiltInKey
                  : l.credentialsClientSecretHint,
              obscureText: true,
              compact: compact,
              onChanged: (String v) {
                setState(() => _clientSecret = v);
                _saveIgdb();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _GetKeyLink(url: widget.info.url),
            const SizedBox(height: 6),
            Text(
              l.welcomeSourcesKeyOptionalHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        );
      case DataSource.tmdb:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InlineTextField(
              label: l.credentialsApiKey,
              value: _tmdbKey,
              placeholder: settings.isTmdbKeyBuiltIn
                  ? l.credentialsUsingBuiltInKey
                  : l.credentialsEnterTmdbKey,
              obscureText: true,
              compact: compact,
              onChanged: (String v) {
                setState(() => _tmdbKey = v);
                final String key = v.trim();
                if (key.isNotEmpty) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setTmdbApiKey(key);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _GetKeyLink(url: widget.info.url),
            const SizedBox(height: 6),
            Text(
              l.welcomeSourcesKeyOptionalHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Status pill on a source card: built-in / saved / required / no key.
class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.info, required this.settings});

  final SourceInfo info;
  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final (String label, Color color) = _resolve(l);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _resolve(S l) {
    switch (info.keyRequirement) {
      case SourceKeyRequirement.none:
        return (l.welcomeSourcesNoKeyNeeded, AppColors.success);
      case SourceKeyRequirement.mandatory:
        if (settings.isIgdbKeyBuiltIn) {
          return (l.welcomeApiBuiltInKey, AppColors.success);
        }
        if (settings.hasCredentials) {
          return (l.welcomeSourcesKeySaved, AppColors.success);
        }
        return (l.welcomeApiRequired, AppColors.brand);
      case SourceKeyRequirement.recommended:
        if (settings.isTmdbKeyBuiltIn) {
          return (l.welcomeApiBuiltInKey, AppColors.success);
        }
        if (settings.hasTmdbKey) {
          return (l.welcomeSourcesKeySaved, AppColors.success);
        }
        return (l.welcomeApiRecommended, AppColors.textTertiary);
    }
  }
}

/// "Get a key ↗" link that opens the provider website.
class _GetKeyLink extends StatelessWidget {
  const _GetKeyLink({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.open_in_new, size: 13, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              l.welcomeSourcesGetKey,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

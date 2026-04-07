// Контент экрана импорта RetroAchievements (без Scaffold/AppBar).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/ra_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/ra_import_service.dart';
import '../../../shared/models/ra_user_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/import_result_screen.dart';
import '../widgets/settings_group.dart';

/// Контент экрана импорта RetroAchievements.
///
/// Три состояния: ввод credentials → прогресс → результат.
class RaImportContent extends ConsumerStatefulWidget {
  /// Создаёт [RaImportContent].
  const RaImportContent({super.key});

  @override
  ConsumerState<RaImportContent> createState() => _RaImportContentState();
}

class _RaImportContentState extends ConsumerState<RaImportContent> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isImporting = false;
  bool _isCheckingProfile = false;
  RaImportProgress? _progress;
  RaUserProfile? _profile;

  // Опции
  bool _addToWishlist = true;

  // Выбор коллекции
  bool _useNewCollection = true;
  int? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString(SettingsKeys.raUsername);
    final String? apiKey = prefs.getString(SettingsKeys.raApiKey);
    if (username != null) _usernameController.text = username;
    if (apiKey != null) _apiKeyController.text = apiKey;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  bool get _canStart =>
      _usernameController.text.trim().isNotEmpty &&
      _apiKeyController.text.trim().isNotEmpty &&
      (_useNewCollection || _selectedCollectionId != null) &&
      !_isImporting &&
      _igdbConnected;

  bool get _igdbConnected =>
      ref.read(settingsNotifierProvider).connectionStatus ==
      ConnectionStatus.connected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_igdbConnected) ...<Widget>[
          _buildIgdbWarning(l),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildInputSection(l),
        if (_isImporting && _progress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildProgressSection(l),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IGDB warning
  // ---------------------------------------------------------------------------

  Widget _buildIgdbWarning(S l) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusDropped.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.statusDropped.withAlpha(77)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: AppColors.statusDropped),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l.raImportIgdbRequired,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input fields
  // ---------------------------------------------------------------------------

  Widget _buildInputSection(S l) {
    return SettingsGroup(
      title: l.raImportTitle,
      subtitle: l.raImportSubtitle,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _usernameController,
                enabled: !_isImporting,
                decoration: InputDecoration(
                  labelText: l.raUsername,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _apiKeyController,
                enabled: !_isImporting,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l.raApiKey,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHelperLink(
                l.raGetApiKey,
                'https://retroachievements.org/controlpanel.php',
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _isImporting || _isCheckingProfile
                    ? null
                    : _checkProfile,
                icon: _isCheckingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 18),
                label: Text(l.credentialsVerifyConnection),
              ),
            ],
          ),
        ),
        if (_profile != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildProfileCard(),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Опции
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.raImportOptions,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              CheckboxListTile(
                title: Text(
                  l.raImportOptionWishlist,
                  style: AppTypography.body,
                ),
                value: _addToWishlist,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: _isImporting
                    ? null
                    : (bool? value) {
                        setState(() => _addToWishlist = value ?? true);
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCollectionSelector(l),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _canStart ? _startImport : null,
            icon: const Icon(Icons.download),
            label: Text(l.raImportStart),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Collection selector
  // ---------------------------------------------------------------------------

  Widget _buildCollectionSelector(S l) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l.raImportTargetCollection,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        RadioGroup<bool>(
          groupValue: _useNewCollection,
          onChanged: (bool? value) {
            if (value == null || _isImporting) return;
            setState(() {
              _useNewCollection = value;
              if (value) _selectedCollectionId = null;
            });
          },
          child: Column(
            children: <Widget>[
              RadioListTile<bool>(
                title: Text(l.raImportNewCollection),
                value: true,
                dense: true,
              ),
              RadioListTile<bool>(
                title: Text(l.raImportExistingCollection),
                value: false,
                dense: true,
              ),
            ],
          ),
        ),
        if (!_useNewCollection)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: collectionsAsync.when(
              data: (List<Collection> collections) {
                if (collections.isEmpty) {
                  return Text(
                    l.raImportNoCollections,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                final bool selectedExists = _selectedCollectionId != null &&
                    collections.any(
                      (Collection c) => c.id == _selectedCollectionId,
                    );
                return DropdownButtonFormField<int>(
                  initialValue: selectedExists ? _selectedCollectionId : null,
                  hint: Text(l.raImportSelectCollection),
                  isExpanded: true,
                  items: collections.map((Collection c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _isImporting
                      ? null
                      : (int? value) {
                          setState(() => _selectedCollectionId = value);
                        },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => Text(
                l.raImportErrorLoadingCollections,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDropped,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Widget _buildProgressSection(S l) {
    final RaImportProgress progress = _progress!;

    final String stageText;
    switch (progress.stage) {
      case RaImportStage.fetchingLibrary:
        stageText = l.raImportFetchingLibrary;
      case RaImportStage.matchingGames:
        stageText = l.raImportMatching(progress.currentName ?? '');
      case RaImportStage.completed:
        stageText = l.raImportComplete;
    }

    return SettingsGroup(
      title: stageText,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LinearProgressIndicator(
                value: progress.total > 0
                    ? progress.current / progress.total
                    : null,
              ),
              if (progress.total > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${progress.current} / ${progress.total}',
                  style: AppTypography.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow(
                Icons.check_circle,
                AppColors.statusCompleted,
                l.raImportAdded(progress.addedCount),
              ),
              _buildStatRow(
                Icons.sync,
                AppColors.statusInProgress,
                l.raImportUpdated(progress.updatedCount),
              ),
              _buildStatRow(
                Icons.bookmark_add,
                AppColors.brand,
                l.raImportToWishlist(progress.unmatchedCount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildHelperLink(String text, String url) {
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.brand,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.brand,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.body),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile check
  // ---------------------------------------------------------------------------

  Future<void> _checkProfile() async {
    final String username = _usernameController.text.trim();
    final String apiKey = _apiKeyController.text.trim();
    if (username.isEmpty || apiKey.isEmpty) return;

    setState(() {
      _isCheckingProfile = true;
      _profile = null;
    });

    try {
      final RaApi api = RaApi();
      api.setCredentials(username: username, apiKey: apiKey);
      final RaUserProfile profile = await api.getUserProfile(username);

      // Сохраняем credentials при успешной верификации —
      // нужны для refresh ачивок в карточке без полного импорта.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(SettingsKeys.raUsername, username);
      await prefs.setString(SettingsKeys.raApiKey, apiKey);
      ref.read(raApiProvider).setCredentials(
            username: username,
            apiKey: apiKey,
          );

      if (mounted) {
        setState(() {
          _profile = profile;
          _isCheckingProfile = false;
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingProfile = false);
      context.showSnack(
        S.of(context).raConnectionFailed('$e'),
        type: SnackType.error,
      );
    }
  }

  Widget _buildProfileCard() {
    final RaUserProfile profile = _profile!;
    final S l = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(20),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.success.withAlpha(77)),
        ),
        child: Row(
          children: <Widget>[
            if (profile.userPicUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  profile.userPicUrl!,
                  width: 48,
                  height: 48,
                  errorBuilder: (BuildContext context, Object error,
                          StackTrace? stack) =>
                      const Icon(Icons.person, size: 48),
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    profile.user,
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${l.raProfilePoints(profile.totalPoints)} \u2022 '
                    '${l.raProfileMemberSince(profile.memberSince.split(' ').first)}',
                    style: AppTypography.bodySmall,
                  ),
                  if (profile.richPresenceMsg != null &&
                      profile.richPresenceMsg!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      profile.richPresenceMsg!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Import logic
  // ---------------------------------------------------------------------------

  Future<void> _startImport() async {
    final String username = _usernameController.text.trim();
    final String apiKey = _apiKeyController.text.trim();
    final String authorName =
        ref.read(settingsNotifierProvider).authorName;

    // Сохраняем credentials.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.raUsername, username);
    await prefs.setString(SettingsKeys.raApiKey, apiKey);

    setState(() {
      _isImporting = true;
      _progress = null;
    });

    try {
      // Устанавливаем credentials на API клиенте.
      ref.read(raApiProvider).setCredentials(
            username: username,
            apiKey: apiKey,
          );

      final RaImportService service = ref.read(raImportServiceProvider);

      // Коллекция создаётся лениво — только после успешной загрузки
      // библиотеки RA, чтобы не оставлять пустую коллекцию при ошибке.
      final RaImportResult result = await service.importFromProfile(
        raUsername: username,
        collectionId: _useNewCollection ? null : _selectedCollectionId,
        createCollection: _useNewCollection
            ? () async {
                final DatabaseService db = ref.read(databaseServiceProvider);
                final Collection collection = await db.createCollection(
                  name: 'RA Games',
                  author: authorName,
                );
                return collection.id;
              }
            : null,
        addToWishlist: _addToWishlist,
        onProgress: (RaImportProgress progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      final int collectionId = result.collectionId;

      if (!mounted) return;

      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider(collectionId));
      ref.invalidate(collectionCoversProvider(collectionId));
      ref.invalidate(collectionItemsNotifierProvider(collectionId));
      ref.invalidate(canvasNotifierProvider(collectionId));
      ref.invalidate(allItemsNotifierProvider);
      ref.invalidate(wishlistProvider);

      final Collection? resultCollection = await ref
          .read(databaseServiceProvider)
          .getCollectionById(collectionId);

      setState(() => _isImporting = false);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImportResultScreen(
            result: result.toUniversal(collection: resultCollection),
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showSnack(
        S.of(context).raImportFailed('$e'),
        type: SnackType.error,
      );
    }
  }
}

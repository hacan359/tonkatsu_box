import 'dart:convert';
import 'dart:typed_data';

import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:core/models/item_status.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/import/import_source.dart';
import '../../../core/import/sources/anilist/anilist_import_service.dart';
import '../../../core/import/sources/hardcover/hardcover_import_service.dart';
import '../../../core/import/sources/igdb_list/igdb_list_import_service.dart';
import '../../../core/import/sources/kinorium/kinorium_import_service.dart';
import '../../../core/import/sources/mal/mal_import_service.dart';
import '../../../core/import/sources/ra/ra_import_service.dart';
import '../../../core/import/sources/simkl/simkl_import_service.dart';
import '../../../core/import/sources/steam/steam_import_service.dart';
import '../../../core/import/sources/trakt/trakt_import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/anilist_import_screen.dart';
import '../../settings/screens/custom_cards_import_screen.dart';
import '../../settings/screens/hardcover_import_screen.dart';
import '../../settings/screens/igdb_list_import_screen.dart';
import '../../settings/screens/ra_import_screen.dart';
import '../../settings/screens/simkl_import_screen.dart';
import '../../settings/screens/steam_import_screen.dart';

sealed class SavedImportLaunch {
  const SavedImportLaunch();
}

/// The run can start right away with the saved switches.
final class SavedImportReady extends SavedImportLaunch {
  const SavedImportReady(this.source, this.options);

  final ImportSource source;
  final ImportOptions options;
}

/// Something the record cannot hold is missing (a credential, a platform, a
/// preview step), so the source's own form opens with the collection preset.
final class SavedImportOpenScreen extends SavedImportLaunch {
  const SavedImportOpenScreen(this.screen);

  final Widget screen;
}

final class SavedImportCancelled extends SavedImportLaunch {
  const SavedImportCancelled();
}

abstract final class SavedImportLauncher {
  static Future<SavedImportLaunch> prepare(
    BuildContext context,
    WidgetRef ref,
    CollectionImport saved, {
    required String collectionName,
  }) async {
    final S l = S.of(context);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String author = ref.read(settingsNotifierProvider).authorName;
    final int cid = saved.collectionId;
    final ImportMode mode =
        saved.text(CollectionImportOption.mode) == ImportMode.overwrite.name
        ? ImportMode.overwrite
        : ImportMode.newOnly;

    switch (saved.source) {
      case ImportSourceKind.steam:
        final String? apiKey = _nonBlank(
          prefs.getString(SettingsKeys.steamApiKey),
        );
        final String? steamId = _nonBlank(
          prefs.getString(SettingsKeys.steamId),
        );
        if (apiKey == null || steamId == null) {
          return SavedImportOpenScreen(
            SteamImportScreen(initialCollectionId: cid),
          );
        }
        return SavedImportReady(
          ref.read(steamImportServiceProvider),
          SteamImportOptions(
            apiKey: apiKey,
            steamId: steamId,
            author: author,
            collectionId: cid,
          ),
        );
      case ImportSourceKind.retroAchievements:
        final String? username = _nonBlank(
          prefs.getString(SettingsKeys.raUsername),
        );
        if (username == null) {
          return SavedImportOpenScreen(
            RaImportScreen(initialCollectionId: cid),
          );
        }
        return SavedImportReady(
          ref.read(raImportServiceProvider),
          RaImportOptions(
            raUsername: username,
            author: author,
            newCollectionName: collectionName,
            addToWishlist: saved.flag(
              CollectionImportOption.addToWishlist,
              orElse: true,
            ),
            collectionId: cid,
          ),
        );
      case ImportSourceKind.simkl:
        if (_nonBlank(prefs.getString(SettingsKeys.simklAccessToken)) == null) {
          return SavedImportOpenScreen(
            SimklImportScreen(initialCollectionId: cid),
          );
        }
        return SavedImportReady(
          ref.read(simklImportServiceProvider),
          SimklImportOptions(
            mode: mode,
            author: author,
            newCollectionName: collectionName,
            collectionId: cid,
          ),
        );
      case ImportSourceKind.aniList:
        final String? userName = _nonBlank(
          prefs.getString(SettingsKeys.aniListUsername),
        );
        if (userName == null) {
          return SavedImportOpenScreen(
            AniListImportScreen(initialCollectionId: cid),
          );
        }
        return SavedImportReady(
          ref.read(aniListImportServiceProvider),
          AniListImportOptions(
            userName: userName,
            mode: mode,
            author: author,
            newCollectionName: collectionName,
            includeAnime: saved.flag(
              CollectionImportOption.includeAnime,
              orElse: true,
            ),
            includeManga: saved.flag(
              CollectionImportOption.includeManga,
              orElse: true,
            ),
            collectionId: cid,
          ),
        );
      case ImportSourceKind.hardcover:
        final String? userName = _nonBlank(
          prefs.getString(SettingsKeys.hardcoverUsername),
        );
        if (userName == null) {
          return SavedImportOpenScreen(
            HardcoverImportScreen(initialCollectionId: cid),
          );
        }
        return SavedImportReady(
          ref.read(hardcoverImportServiceProvider),
          HardcoverImportOptions(
            userName: userName,
            mode: mode,
            author: author,
            newCollectionName: collectionName,
            collectionId: cid,
          ),
        );
      case ImportSourceKind.kinorium:
        final Uint8List? bytes = await _pickBytes(
          l.kinoriumSelectCsvExport,
          <String>['csv'],
        );
        if (bytes == null) return const SavedImportCancelled();
        return SavedImportReady(
          ref.read(kinoriumImportServiceProvider),
          KinoriumImportOptions(
            bytes: bytes,
            collectionId: cid,
            isWishlist: saved.flag(
              CollectionImportOption.isWishlist,
              orElse: false,
            ),
            importNotes: saved.flag(
              CollectionImportOption.importNotes,
              orElse: false,
            ),
            reasons: KinoriumWishlistReasons(
              notFound: l.kinoriumReasonNotFound,
              apiError: l.kinoriumReasonApiError,
              unsupportedType: l.kinoriumReasonUnsupportedType,
              duplicate: l.kinoriumReasonDuplicate,
            ),
          ),
        );
      case ImportSourceKind.igdbList:
        final int? platformId = saved.integer(
          CollectionImportOption.platformId,
        );
        if (platformId == null) {
          return SavedImportOpenScreen(
            IgdbListImportScreen(initialCollectionId: cid),
          );
        }
        final Uint8List? bytes = await _pickBytes(
          l.igdbImportSelectCsvExport,
          <String>['csv'],
        );
        if (bytes == null) return const SavedImportCancelled();
        final String? status = saved.text(CollectionImportOption.status);
        return SavedImportReady(
          ref.read(igdbListImportServiceProvider),
          IgdbListImportOptions(
            bytes: bytes,
            author: author,
            platformId: platformId,
            status:
                (status == null ? null : ItemStatus.tryFromString(status)) ??
                ItemStatus.notStarted,
            wishlistReason: l.igdbReasonNotFound,
            collectionId: cid,
          ),
        );
      case ImportSourceKind.trakt:
        final Uint8List? bytes = await _pickBytes(
          l.traktSelectZipExport,
          <String>['zip'],
        );
        if (bytes == null) return const SavedImportCancelled();
        return SavedImportReady(
          ref.read(traktImportServiceProvider),
          TraktImportOptions(
            bytes: bytes,
            collectionId: cid,
            importWatched: saved.flag(
              CollectionImportOption.importWatched,
              orElse: true,
            ),
            importRatings: saved.flag(
              CollectionImportOption.importRatings,
              orElse: true,
            ),
            importWatchlist: saved.flag(
              CollectionImportOption.importWatchlist,
              orElse: true,
            ),
          ),
        );
      case ImportSourceKind.mal:
        final Uint8List? bytes = await _pickBytes(
          l.malImportPickFiles,
          <String>['xml'],
        );
        if (bytes == null) return const SavedImportCancelled();
        final MalImportService service = ref.read(malImportServiceProvider);
        final String xml;
        final MalParsedFile parsed;
        try {
          xml = utf8.decode(bytes);
          parsed = service.parseString(xml);
        } on FormatException catch (e) {
          if (context.mounted) {
            context.showSnack(
              l.malImportInvalidFile(e.message),
              type: SnackType.error,
            );
          }
          return const SavedImportCancelled();
        }
        return SavedImportReady(
          service,
          MalImportOptions(
            animeXml: parsed.kind == MalFileKind.anime ? xml : null,
            mangaXml: parsed.kind == MalFileKind.manga ? xml : null,
            author: author,
            newCollectionName: collectionName,
            overwriteExistingItems: saved.flag(
              CollectionImportOption.overwriteExisting,
              orElse: false,
            ),
            collectionId: cid,
          ),
        );
      case ImportSourceKind.customCards:
        return SavedImportOpenScreen(
          CustomCardsImportScreen(initialCollectionId: cid),
        );
    }
  }

  static String? _nonBlank(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  // Android's FileType.custom does not filter custom extensions, and the
  // browser only ever hands out bytes, so one withData path serves them all.
  static Future<Uint8List?> _pickBytes(
    String dialogTitle,
    List<String> extensions,
  ) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: kIsMobile ? FileType.any : FileType.custom,
      allowedExtensions: kIsMobile ? null : extensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.bytes;
  }
}

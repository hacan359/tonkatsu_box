// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => 'Accueil';

  @override
  String get navCollections => 'Collections';

  @override
  String get navWishlist => 'Liste de souhaits';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navReleases => 'Sorties';

  @override
  String get releasesEmpty => 'Aucune série suivie';

  @override
  String get releasesEmptyHint =>
      'Cliquez sur la cloche sur une série ou un anime pour suivre les nouvelles sorties.';

  @override
  String get releasesTrackShow => 'Suivre les sorties';

  @override
  String get releasesUntrackShow => 'Arrêter de suivre';

  @override
  String get releasesViewDay => 'Jour';

  @override
  String get releasesViewWeek => 'Semaine';

  @override
  String get releasesViewMonth => 'Mois';

  @override
  String get releasesTabCalendar => 'Calendrier';

  @override
  String get releasesTabAll => 'Toutes les sorties';

  @override
  String get releasesToday => 'Aujourd\'hui';

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get releasesNoEpisodes => 'Pas d\'épisodes';

  @override
  String releasesEpisode(int season, int episode) {
    return 'Saison $season · Épisode $episode';
  }

  @override
  String get calendarAdd => 'Ajouter au calendrier';

  @override
  String get calendarRemove => 'Retirer du calendrier';

  @override
  String get date => 'Date';

  @override
  String get calendarRepeat => 'Répéter';

  @override
  String get recurrenceOnce => 'Une fois';

  @override
  String get recurrenceWeekly => 'Hebdomadaire';

  @override
  String get recurrenceMonthly => 'Mensuel';

  @override
  String get statusNotStarted => 'Pas commencé';

  @override
  String get statusPlaying => 'Commencé';

  @override
  String get statusWatching => 'Commencé';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusDropped => 'Abandonné';

  @override
  String get statusPlanned => 'Planifié';

  @override
  String get statusReplay => 'Recommencé';

  @override
  String get rewatchCountEdit => 'Nombre de re-vues';

  @override
  String get rewatchCountHint => 'Vide = non suivi';

  @override
  String get statusReplaying => 'Rejouer';

  @override
  String get statusRewatching => 'Revisionnage';

  @override
  String get statusRereading => 'Relecture';

  @override
  String get all => 'Tout';

  @override
  String get mediaTypeGame => 'Jeu';

  @override
  String get mediaTypeMovie => 'Film';

  @override
  String get mediaTypeTvShow => 'Série';

  @override
  String get mediaTypeAnimation => 'Animation';

  @override
  String get mediaTypeVisualNovel => 'Visual Novel';

  @override
  String get mediaTypeManga => 'Manga';

  @override
  String get mediaTypeAnime => 'Anime';

  @override
  String get mediaTypeBook => 'Livre';

  @override
  String get mediaTypeCustom => 'Personnalisé';

  @override
  String get sortManualDisplay => 'Manuel';

  @override
  String get sortManualDesc => 'Ordre personnalisé';

  @override
  String get sortDateDisplay => 'Date d\'ajout';

  @override
  String get sortDateDesc => 'Date d\'ajout (↓)';

  @override
  String get status => 'Statut';

  @override
  String get sortStatusDesc => 'Actif (↓)';

  @override
  String get name => 'Nom';

  @override
  String get sortNameShort => 'A à Z';

  @override
  String get rating => 'Note';

  @override
  String get sortRatingDesc => 'Note (↓)';

  @override
  String get sortFavoriteDesc => 'Favoris (↓)';

  @override
  String get sortExternalRatingDisplay => 'Note des sources';

  @override
  String get sortExternalRatingShort => 'IGDB/TMDB';

  @override
  String get sortLastActivityDisplay => 'Dernière activité';

  @override
  String get sortLastActivityShort => 'Activité';

  @override
  String get sortLastActivityDesc => 'Activité (↓)';

  @override
  String get sortStartDateDisplay => 'Date de début';

  @override
  String get sortStartDateShort => 'Commencé';

  @override
  String get sortCompletionDateDisplay => 'Date de fin';

  @override
  String get sortCompletionDateShort => 'Terminé';

  @override
  String get sortDateOldest => 'Date d\'ajout (↑)';

  @override
  String get sortStatusFinished => 'Terminé(s) (↓)';

  @override
  String get sortRatingLowest => 'Note (↑)';

  @override
  String get sortFavoriteLast => 'Favoris (↑)';

  @override
  String get searchSortRelevanceShort => 'Pert.';

  @override
  String get searchSortRatingShort => 'Note';

  @override
  String get searchSortRatingDisplay => 'Note';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'OK';

  @override
  String get restore => 'Restaurer';

  @override
  String get create => 'Créer';

  @override
  String get save => 'Sauvegarder';

  @override
  String get add => 'Ajouter';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get retry => 'Réessayer';

  @override
  String get edit => 'Modifier';

  @override
  String get done => 'Fait';

  @override
  String get clear => 'Effacer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get search => 'Rechercher';

  @override
  String get open => 'Ouvrir';

  @override
  String get remove => 'Retirer';

  @override
  String get moveToTop => 'Placer en haut';

  @override
  String get moveToBottom => 'Placer en bas';

  @override
  String get favorite => 'Favori';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String bulkSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get bulkClearSelection => 'Effacer la sélection';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get bulkMove => 'Ajouter la sélection à la collection';

  @override
  String get bulkCopy => 'Copier la sélection et placer dans la collection';

  @override
  String get bulkChangeStatus => 'Changer statut';

  @override
  String bulkRemoveConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return 'Retirer $_temp0 de cette collection ?';
  }

  @override
  String bulkResult(int done, int skipped) {
    return 'Fait: $done • Doublon(s): $skipped';
  }

  @override
  String bulkRemoved(int count) {
    return 'Retiré(s): $count';
  }

  @override
  String bulkStatusUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return 'Statut modifié pour $_temp0';
  }

  @override
  String get bulkExportPngTitle => 'Exporter en PNG';

  @override
  String get columnsCount => 'Colonnes';

  @override
  String bulkExportPngItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String bulkExportPngItemsCountPreview(int total, int preview) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total images',
      one: '1 image',
    );
    return '$_temp0 ($preview dans l\'aperçu)';
  }

  @override
  String bulkExportPngPreparing(int done, int total) {
    return 'Préparation des couvertures: $done / $total';
  }

  @override
  String get bulkExportPngSave => 'Enregistrer en PNG';

  @override
  String get imageSaved => 'Image sauvegardée';

  @override
  String get bulkExportPngFailed => 'Impossible de sauvegarder l\'image';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get update => 'Mettre à jour';

  @override
  String get test => 'Test';

  @override
  String get close => 'Fermer';

  @override
  String get keep => 'Garder';

  @override
  String get change => 'Changer';

  @override
  String get settingsProfile => 'Auteur de la collection';

  @override
  String get settingsProfileSubtitle => 'Nom d\'auteur pour vos collections';

  @override
  String get settingsAuthorName => 'Nom d\'auteur';

  @override
  String get settingsCredentialsSubtitle =>
      'Clés API pour IGDB, SteamGridDB et TMDB';

  @override
  String get settingsCacheSubtitle =>
      'Mode hors-ligne et stockage des couvertures';

  @override
  String get settingsDatabaseSubtitle => 'Exporter, importer, réinitialiser';

  @override
  String get settingsTraktImportSubtitle =>
      'Historique, notes, liste de visionnage';

  @override
  String get settingsKinoriumImport => 'Importer depuis Kinorium';

  @override
  String get settingsKinoriumImportSubtitle =>
      'Films et séries via un fichier CSV';

  @override
  String get settingsDebug => 'Débug';

  @override
  String get settingsDebugSubtitle => 'Outils développeurs';

  @override
  String get settingsDebugSubtitleNoKey =>
      'Ajoutez une clé API SteamGridDB pour accéder aux outils.';

  @override
  String get settingsLaboratory => 'Laboratoire';

  @override
  String get settingsLaboratoryCardDesigns => 'Designs des bannières';

  @override
  String get settingsLaboratoryCardDesignsSubtitle =>
      'Mises en pages expérimentales des affiches';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsWelcomeGuide => 'Première utilisation';

  @override
  String get settingsWelcomeGuideSubtitle =>
      'Première utilisation de Tonkatsu Box';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsCreditsLicenses => 'Crédits & Licences';

  @override
  String get settingsChangelog => 'Nouveautés';

  @override
  String get settingsChangelogEmpty => 'Aucune note de version disponible';

  @override
  String get settingsCreditsLicensesSubtitle =>
      'TMDB, IGDB, SteamGridDB, licences open-source';

  @override
  String get settingsError => 'Erreur';

  @override
  String get settingsAppLanguage => 'Langue de l\'application';

  @override
  String get settingsConnections => 'Connexions';

  @override
  String get settingsApiKeys => 'Clés API';

  @override
  String settingsApiKeysValue(int active, int total) {
    return '$active/$total';
  }

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsAppearanceSubtitle => 'Langue, affichage et contenu';

  @override
  String get settingsAppLanguageSubtitle => 'Langue de l\'interface';

  @override
  String get settingsContentLanguageSubtitle =>
      'TMDB seulement pour l\'instant (films et séries)';

  @override
  String get settingsDataSources => 'Sources';

  @override
  String get settingsDataSourcesSubtitle => 'IGDB, TMDB, SteamGridDB';

  @override
  String get settingsApiKeysSubtitle =>
      'Configurez la connexion aux bases de données';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsStorageSubtitle => 'Cache (images) et base de données';

  @override
  String get settingsBackup => 'Sauvegarde';

  @override
  String get settingsBackupSubtitle => 'Sauvegarde complète et restauration';

  @override
  String get settingsBackupAll => 'Sauvegarder toutes les données';

  @override
  String get settingsBackupAllSubtitle =>
      'Toutes les collections, liste de souhaits et paramètres';

  @override
  String get settingsRestoreBackup => 'Restaurer depuis une sauvegarde';

  @override
  String get settingsRestoreBackupSubtitle => 'Importer une sauvegarde';

  @override
  String backupSuccess(int collections, int items) {
    return 'Sauvegarde effectuée: $collections collections, $items titres';
  }

  @override
  String get restoreConfirmTitle => 'Restaurer la sauvegarde ?';

  @override
  String restoreConfirmBody(int collections, int items, int wishlist) {
    return '$collections collections, $items titres, $wishlist souhaits';
  }

  @override
  String get restoreConfirmHint =>
      'Les collections existantes ne seront pas affectées';

  @override
  String get restoreSettings => 'Restaurer les paramètres';

  @override
  String get restoreWishlist => 'Restaurer la liste de souhaits';

  @override
  String restoreSuccess(int collections, int items) {
    return 'Restauration effectuée : $collections collections, $items titres';
  }

  @override
  String get restoreInvalidArchive => 'Erreur : mauvaise sauvegarde';

  @override
  String get restoreProgressTitle => 'Restauration de la sauvegarde';

  @override
  String get restoreProgressWarning =>
      'Ne fermez pas l\'application. Cela peut prendre plusieurs minutes.';

  @override
  String get restoreStageReading => 'Lecture de la sauvegarde...';

  @override
  String restoreStageCollections(int current, int total) {
    return 'Restauration des collections... ($current/$total)';
  }

  @override
  String get restoreStageWishlist => 'Restauration de la liste de souhaits...';

  @override
  String get restoreStageSettings => 'Restauration des paramètres...';

  @override
  String get restoreStageFinalizing => 'Bientôt terminé...';

  @override
  String get settingsImport => 'Importer';

  @override
  String get settingsImportSubtitle =>
      'Importer des collections depuis des services externes';

  @override
  String get settingsContentLanguage => 'Langue du contenu';

  @override
  String get settingsData => 'Données';

  @override
  String settingsCacheValue(String size) {
    return '$size';
  }

  @override
  String get credentialsTitle => 'Identifiants';

  @override
  String get credentialsWelcome => 'Bienvenue sur Tonkatsu Box !';

  @override
  String get credentialsWelcomeHint =>
      'Pour commencer, vous devez inscrire vos identifiants API pour IGDB. Retrouvez vos Client ID et Client Secret sur la Console de développeur Twitch.';

  @override
  String get credentialsCopyTwitchUrl => 'Copier l\'URL de la Console Twitch';

  @override
  String credentialsUrlCopied(String url) {
    return 'URL copiée : $url';
  }

  @override
  String get credentialsIgdbSection => 'Identifiants pour l\'API IGDB';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Entrez votre Twitch Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Entrez votre Twitch Client Secret';

  @override
  String get credentialsConnectionStatus => 'Statut de connexion';

  @override
  String get credentialsPlatformsSynced => 'Plateformes synchronisées';

  @override
  String get credentialsPlatformsAvailable => 'Plateformes disponibles';

  @override
  String get credentialsLastSync => 'Dernière synchronisation';

  @override
  String get credentialsVerifyConnection => 'Vérifier connexion';

  @override
  String get credentialsRefreshPlatforms => 'Rafraîchir les plateformes';

  @override
  String get credentialsSteamGridDbSection => 'API SteamGridDB';

  @override
  String get credentialsApiKey => 'Clé API';

  @override
  String get credentialsUsingBuiltInKey => 'Utiliser la clé intégrée';

  @override
  String get credentialsEnterSteamGridDbKey =>
      'Entrez votre clé API SteamGridDB';

  @override
  String get credentialsTmdbSection => 'API TMDB (Films et TV)';

  @override
  String get credentialsEnterTmdbKey => 'Entrez votre clé API TMDB (v3)';

  @override
  String get credentialsComicVineSection => 'API ComicVine (Comics)';

  @override
  String get credentialsEnterComicVineKey => 'Entrez votre clé API ComicVine';

  @override
  String get credentialsGoogleBooksSection => 'API Google Books (Livres)';

  @override
  String get credentialsEnterGoogleBooksKey =>
      'Entrez votre clé API Google Books (optionnel)';

  @override
  String get credentialsHardcoverSection => 'API Hardcover (Livres)';

  @override
  String get credentialsEnterHardcoverKey => 'Entrez votre token API Hardcover';

  @override
  String get credentialsOwnKeyHint =>
      'Pour de moins grandes restrictions d\'utilisation, nous recommandons l\'utilisation de vos propres clés API.';

  @override
  String get credentialsConnected => 'Connecté';

  @override
  String get credentialsConnectionError => 'Erreur de connexion';

  @override
  String get credentialsChecking => 'Vérification...';

  @override
  String get credentialsNotConnected => 'Pas connecté';

  @override
  String get credentialsEnterBoth =>
      'Veuillez entrer votre Client ID et Client Secret';

  @override
  String get credentialsConnectedSynced =>
      'Connexion établie, plateformes synchronisées !';

  @override
  String get credentialsConnectedSyncFailed =>
      'Connecté, mais la synchronisation a échoué';

  @override
  String get credentialsPlatformsSyncedOk =>
      'Plateformes synchronisées avec succès !';

  @override
  String get credentialsDownloadingLogos =>
      'Téléchargement des logos de la plateforme...';

  @override
  String credentialsDownloadedLogos(int count) {
    return 'Téléchargé $count logos';
  }

  @override
  String get credentialsFailedDownloadLogos =>
      'Échec lors du téléchargement des logos';

  @override
  String get credentialsApiKeySaved => 'Clé API sauvegardée';

  @override
  String get credentialsNoApiKey => 'Pas de clé API';

  @override
  String get credentialsResetToBuiltIn => 'Réutiliser la clé API intégrée';

  @override
  String get credentialsSteamGridDbKeyValid =>
      'La clé API SteamGridDB est valide';

  @override
  String get credentialsSteamGridDbKeyInvalid =>
      'La clé API SteamGridDB est invalide';

  @override
  String get credentialsTmdbKeyValid => 'La clé API TMDB est valide';

  @override
  String get credentialsTmdbKeyInvalid => 'La clé API TMDB est invalide';

  @override
  String get credentialsComicVineKeyValid => 'La clé API ComicVine est valide';

  @override
  String get credentialsComicVineKeyInvalid =>
      'La clé API ComicVine est invalide';

  @override
  String get credentialsGoogleBooksKeyValid =>
      'La clé API Google Books est valide';

  @override
  String get credentialsGoogleBooksKeyInvalid =>
      'La clé API Google Books est invalide';

  @override
  String get credentialsHardcoverKeyValid => 'La clé API Hardcover est valide';

  @override
  String get credentialsHardcoverKeyInvalid =>
      'La clé API Hardcover est invalide ou a expiré';

  @override
  String get credentialsEnterSteamGridDbKeyError =>
      'Veuillez entrer une clé API SteamGridDB';

  @override
  String get credentialsEnterTmdbKeyError => 'Veuillez entrer une clé API TMDB';

  @override
  String get credentialsTmdbKeySaved => 'Clé API TMDB sauvegardée';

  @override
  String timeAgo(int value, String unit) {
    return 'il y a $value $unit';
  }

  @override
  String timeUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$_temp0';
  }

  @override
  String timeUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'heures',
      one: 'heure',
    );
    return '$_temp0';
  }

  @override
  String timeUnitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'À l\'instant';

  @override
  String get cacheTitle => 'Cache';

  @override
  String get cacheImageCache => 'Cache (images)';

  @override
  String get cacheOfflineMode => 'Mode hors ligne';

  @override
  String get cacheOfflineModeSubtitle =>
      'Sauvegarder les images localement pour une utilisation hors ligne';

  @override
  String get cacheCacheFolder => 'Dossier cache';

  @override
  String get cacheSelectFolder => 'Sélectionnez un dossier';

  @override
  String get cacheCacheSize => 'Taille du cache';

  @override
  String get cacheClearCache => 'Retirer les images inutilisées';

  @override
  String get cacheClearCacheTitle => 'Retirer les images inutilisées ?';

  @override
  String get cacheClearCacheMessage =>
      'Supprime les images téléchargées pour des médias inexistants dans les collections. Vos images importées seront conservées.';

  @override
  String get cacheFolderUpdated => 'Dossier cache mis à jour';

  @override
  String cacheOrphansRemoved(int count) {
    return 'Images non utilisées supprimées : $count';
  }

  @override
  String get cacheSelectFolderDialog =>
      'Sélectionnez un dossier cache pour les images';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count fichiers, $size';
  }

  @override
  String get databaseTitle => 'Base de données';

  @override
  String get databaseConfiguration => 'Configuration';

  @override
  String get databaseConfigSubtitle =>
      'Exportez ou importez vos clés API et paramètres.';

  @override
  String get databaseExportConfig => 'Exporter configuration';

  @override
  String get databaseImportConfig => 'Importer configuration';

  @override
  String get databaseDangerZone => 'Danger Zone';

  @override
  String get databaseDangerZoneMessage =>
      'Vide toutes les collections (jeux, films, séries et tableaux). Vos paramètres et clés API seront conservés.';

  @override
  String get databaseResetDatabase => 'Réinitialiser base de données';

  @override
  String get databaseResetTitle => 'Réinitialiser base de données ?';

  @override
  String get databaseResetMessage =>
      'Cela supprimera de manière permanente toutes vos collections (jeux, films, séries), progressions des épisodes et les données du tableau.\n\nVos clés API et paramètres seront préservés.\n\nCette opération est irréversible.';

  @override
  String databaseConfigExported(String path) {
    return 'Configuration exportée vers $path';
  }

  @override
  String get databaseConfigImported => 'Configuration importée avec succès';

  @override
  String get databaseReset => 'Base de données réinitialisée';

  @override
  String get storageLocationTitle => 'Emplacement des données';

  @override
  String get storageLocationSubtitle =>
      'Dossier qui héberge la base de données et les profils. Les dossiers liés à un service cloud (OneDrive, Syncthing) sont à éviter : la base de données pourrait être corrompue pendant l\'écriture. Pour transférer des données entre appareils, exportez depuis les menus.';

  @override
  String get storageLocationDangerWarning =>
      'Attention : changer le dossier peut entraîner une perte de données. À faire en connaissance des risques.';

  @override
  String get storageLocationFolder => 'Dossier des données';

  @override
  String get storageLocationFallbackWarning =>
      'Le dossier sélectionné est indisponible. Le dossier par défaut sera utilisé.';

  @override
  String get storageLocationChange => 'Changer de dossier';

  @override
  String get storageLocationReset => 'Revenir au dossier par défaut';

  @override
  String get storageLocationSelectDialog => 'Sélectionner dossier';

  @override
  String storageLocationNotWritable(String path) {
    return 'Pas de permissions d\'écriture: $path';
  }

  @override
  String get storageLocationPermissionTitle => 'Accès au stockage requis';

  @override
  String get storageLocationPermissionMessage =>
      'Android a besoin de la permission \"Accéder aux fichiers\" pour un dossier personnalisé. Dans la liste, trouvez Tonkatsu Box, autorisez l\'accès, revenez en arrière et sélectionnez à nouveau le dossier.';

  @override
  String get storageLocationLegacyPermissionMessage =>
      'Un dossier personnalisé requiert la permission pour accéder au stockage. Autorisez l\'accès dans les paramètres de l\'application, puis revenez ici et sélectionnez à nouveau le dossier.';

  @override
  String get storageLocationOpenSettings => 'Ouvrir paramètres';

  @override
  String get storageLocationDbTooNew =>
      'La base de données de ce dossier a été créée par une version ultérieure de l\'application. Mettez l\'application à jour avant de procéder.';

  @override
  String get storageLocationDbCorrupted =>
      'La base de données de ce dossier est corrompue ou incomplète. Si une synchronisation est en cours, réessayez plus tard.';

  @override
  String get storageLocationUseExistingTitle => 'Données existantes trouvées';

  @override
  String get storageLocationUseExistingMessage =>
      'Le dossier sélectionné contient déjà une base de données. L\'application utilisera ces données après redémarrage.';

  @override
  String get storageLocationUseExistingConfirm => 'Utiliser ces données';

  @override
  String get storageLocationCopyTitle => 'Copier les données déjà présentes ?';

  @override
  String get storageLocationCopyMessage =>
      'Le dossier sélectionné est vide. Vos collections seront copiées ici; les images sauvegardées seront téléchargées. Les données de l\'ancien dossier resteront intactes.';

  @override
  String get copy => 'Copier';

  @override
  String get storageLocationCopyImages => 'Copier aussi le cache d\'images';

  @override
  String get storageLocationCopyImagesHint =>
      'Bannières et autres images — plus lourd, mais le nouveau dossier est accessible hors-ligne sans devoir le re-télécharger';

  @override
  String get storageLocationCopyError =>
      'Impossible de copier les données vers le dossier sélectionné';

  @override
  String get storageLocationResetTitle =>
      'Réinitialiser le dossier de données ?';

  @override
  String get storageLocationResetMessage =>
      'L\'application réutilisera le dossier par défaut après redémarrage. Les données du dossier personnalisé resteront intactes.';

  @override
  String get storageLocationRestartTitle => 'Redémarrage requis';

  @override
  String get storageLocationRestartMessage =>
      'Le nouveau dossier de données sera utilisé après redémarrage. Redémarrer maintenant ?';

  @override
  String get storageLocationRestartNow => 'Redémarrer';

  @override
  String get storageLocationRestartLater =>
      'Le changement sera effectif après redémarrage';

  @override
  String get backupRestoreTile => 'Restaurer l\'ancienne base de données';

  @override
  String get backupNone => 'Aucune sauvegarde pour le moment';

  @override
  String get backupRestoreConfirmTitle =>
      'Restaurer l\'ancienne base de données ?';

  @override
  String backupRestoreConfirmMessage(String date) {
    return 'Les données actuelles seront remplacées par la sauvegarde du $date. Les données remplacées seront transformées en sauvegarde, restaurer encore une fois après ça les effacera.';
  }

  @override
  String get backupRestored => 'Base de données restaurée';

  @override
  String get backupRestoreError =>
      'Impossible de restaurer depuis la sauvegarde';

  @override
  String get backupRestartMessage =>
      'Les données restaurées seront utilisées après redémarrage. Redémarrer maintenant ?';

  @override
  String get lanSyncTitle => 'Synchronisation réseau';

  @override
  String get lanSyncOpenTile => 'Appareils à proximité';

  @override
  String get lanSyncTileSubtitle =>
      'Transférer des données entre appareils connectés au même réseau Wi-Fi';

  @override
  String lanSyncVisibleAs(String name) {
    return 'Cet appareil est enregistré sous le nom $name';
  }

  @override
  String get lanSyncNoDevices =>
      'Aucun appareil trouvé. Accédez à cet écran sur les deux appareils connectés au réseau Wi-Fi. Les points d\'accès et les VPN bloquent cette fonction.';

  @override
  String get lanSyncPull => 'Cliquez pour obtenir les données';

  @override
  String get lanSyncReceiveTitle => 'Remplacer les données ?';

  @override
  String lanSyncReceiveMessage(
    String device,
    String date,
    int collections,
    int items,
  ) {
    return 'Les données de $device, $date: $collections collections, $items titres.\n\nLes données déjà présentes seront REMPLACÉES. Une sauvegarde sera stockée aux côtés de la base de données.';
  }

  @override
  String get lanSyncReplace => 'Remplacer';

  @override
  String lanSyncWaiting(String name) {
    return 'Confirmez la demande sur $name...';
  }

  @override
  String get lanSyncIncomingTitle => 'Demande de données';

  @override
  String lanSyncIncomingMessage(String name) {
    return '$name veut obtenir une copie de vos données. L\'autorisez-vous ?';
  }

  @override
  String get lanSyncAllow => 'Autoriser';

  @override
  String get lanSyncDenied => 'L\'autre appareil a décliné la demande';

  @override
  String get lanSyncManifestError => 'Aucune réponse de l\'appareil';

  @override
  String get lanSyncStartError =>
      'Impossible de démarrer le partage par réseau. Vérifiez votre connexion et réessayez.';

  @override
  String get lanSyncReceiveError => 'Impossible d\'obtenir les données';

  @override
  String get lanSyncTooNew =>
      'Les données de cet appareil proviennent d\'une version plus récente de l\'application. Mettez votre application à jour.';

  @override
  String get lanSyncCorrupted =>
      'Le transfert s\'est mal passé. Veuillez réessayer.';

  @override
  String get lanSyncReceived => 'Données reçues';

  @override
  String get lanSyncReceivingImages => 'Transfert des images...';

  @override
  String get lanSyncReceivingSettings => 'Transfert des paramètres...';

  @override
  String get lanSyncImportConfig => 'Transférer aussi les paramètres';

  @override
  String get lanSyncImportConfigSubtitle => 'Clés API incluses. Tout ou rien.';

  @override
  String get lanSyncImagesWarning =>
      'Base de données reçue mais les images n\'ont pas pu être transférées';

  @override
  String get lanSyncRestartMessage =>
      'Les données seront utilisées après redémarrage. Redémarrer maintenant ?';

  @override
  String get lanSyncFirewallNote =>
      'Windows pourrait demander une permission au niveau du pare-feu lors du premier démarrage - autorisez l\'accès sur les réseaux privés.';

  @override
  String get folderPickerNewFolder => 'Nouveau dossier';

  @override
  String get folderPickerVolumeList => 'Périphériques de stockage';

  @override
  String get folderPickerInternalStorage => 'Stockage interne';

  @override
  String get folderPickerSelect => 'Sélectionner';

  @override
  String get folderPickerFolderName => 'Nom du dossier';

  @override
  String get folderPickerInvalidName => 'Nom du dossier non valide';

  @override
  String get folderPickerEmpty => 'Pas de sous-dossier';

  @override
  String get folderPickerReadError => 'Impossible de lire ce dossier';

  @override
  String get folderPickerCreateError => 'Impossible de créer un dossier';

  @override
  String get traktTitle => 'Import Trakt';

  @override
  String get traktImportFrom => 'Importer depuis Trakt.tv';

  @override
  String get traktImportDescription =>
      'Téléchargez vos données depuis trakt.tv/users/YOU/data and sélectionnez le fichier ZIP ci-dessous.';

  @override
  String get traktZipFile => 'Fichier ZIP';

  @override
  String get traktSelectZipFile => 'Sélectionnez le fichier ZIP';

  @override
  String get traktSelectZipExport => 'Exporter un fichier ZIP Trakt';

  @override
  String get preview => 'Prévisualisation';

  @override
  String traktUser(String username) {
    return 'Utilisateur Trakt : $username';
  }

  @override
  String get traktWatchedMovies => 'Films regardés';

  @override
  String get traktWatchedShows => 'Séries regardées';

  @override
  String get traktRatedMovies => 'Films notés';

  @override
  String get traktRatedShows => 'Séries notées';

  @override
  String get traktWatchlist => 'Liste de lecture';

  @override
  String get importOptions => 'Options';

  @override
  String get traktImportWatched => 'Importer déjà regardés';

  @override
  String get traktImportWatchedDesc => 'Films et séries déjà regardés';

  @override
  String get traktImportRatings => 'Importer notes';

  @override
  String get traktImportRatingsDesc =>
      'Applique les notes utilisateurs (1 à 10)';

  @override
  String get traktImportWatchlist => 'Importer liste de lecture';

  @override
  String get traktImportWatchlistDesc =>
      'Ajoute à la liste de souhaits ou applique le statut planifié';

  @override
  String get importTargetCollection => 'Sélectionner collection';

  @override
  String get importUseExistingCollection => 'Utiliser une collection existante';

  @override
  String get importStart => 'Commencer l\'import';

  @override
  String get traktRequiresOwnTmdbKey =>
      'Importer depuis Trakt requiert votre clé API TMDB. Ajoutez-la dans Paramètres → Identifiants.';

  @override
  String get traktInvalidExport => 'Export Trakt non valide';

  @override
  String get kinoriumImportFrom => 'Importer depuis Kinorium';

  @override
  String get kinoriumImportDescription =>
      'Exportez votre liste depuis Kinorium (fichier CSV envoyé par e-mail) et sélectionnez-le ci-dessous.';

  @override
  String get kinoriumSelectCsvFile => 'Sélectionner fichier CSV';

  @override
  String get kinoriumSelectCsvExport => 'Exporter un fichier CSV Kinorium';

  @override
  String get kinoriumIsWatchlist => 'Ceci est un fichier \"Liste de lecture\"';

  @override
  String get kinoriumIsWatchlistDesc =>
      'Importer tous les films et appliquer le statut planifié au lieu de regardé';

  @override
  String get kinoriumImportNotes => 'Importer acteurs et production';

  @override
  String get kinoriumImportNotesDesc =>
      'Ajoute les réalisateurs et les acteurs aux commentaires';

  @override
  String get kinoriumImporting => 'Importation depuis Kinorium...';

  @override
  String get kinoriumRecommendOwnTmdbKey =>
      'Conseil : une clé API TMDB personnelle est recommandée pour des gros imports (Paramètres → Clés API), mais reste optionnel — la clé intégrée fonctionne aussi.';

  @override
  String get kinoriumReasonNotFound => 'Introuvable sur TMDB';

  @override
  String get kinoriumReasonApiError =>
      'Erreur renvoyée par TMDB ou limite d\'utilisation — réessayez plus tard';

  @override
  String kinoriumReasonUnsupportedType(String type) {
    return 'Format non supporté : $type';
  }

  @override
  String kinoriumReasonDuplicate(String title) {
    return 'Doublon de \"$title\"';
  }

  @override
  String traktImportedItems(int count) {
    return 'Importé $count titres';
  }

  @override
  String get traktImporting => 'Importation depuis Trakt';

  @override
  String get creditsTitle => 'Crédits';

  @override
  String get creditsDataProviders => 'Fournisseurs';

  @override
  String get creditsTmdbAttribution =>
      'Ce produit utilise l\'API de TMDB mais n\'est ni approuvé ni certifié par TMDB.';

  @override
  String get creditsTvMazeAttribution =>
      'Données pour les séries fournies par TVmaze.';

  @override
  String get creditsIgdbAttribution =>
      'Données pour les jeux fournies par IGDB.';

  @override
  String get creditsSteamGridDbAttribution =>
      'Illustrations fournies par SteamGridDB.';

  @override
  String get creditsVndbAttribution =>
      'Données pour les visual novels fournies par VNDB.';

  @override
  String get creditsAniListAttribution =>
      'Données pour les mangas fournies par AniList.';

  @override
  String get creditsMangaBakaAttribution =>
      'Données pour les mangas fournies par MangaBaka.';

  @override
  String get creditsMangaDexAttribution =>
      'Données pour les mangas fournies par MangaDex.';

  @override
  String get creditsKitsuAttribution =>
      'Données pour les mangas fournies par Kitsu.';

  @override
  String get creditsOpenLibraryAttribution =>
      'Données pour les livres fournies par Open Library (CC0 / ODbL).';

  @override
  String get creditsFantlabAttribution =>
      'Données pour les livres fournies par Fantlab.';

  @override
  String get creditsComicVineAttribution =>
      'Données pour les comics fournies par ComicVine (utilisation non-commerciale).';

  @override
  String get creditsGoogleBooksAttribution =>
      'Données pour les livres fournies par Google Books.';

  @override
  String get creditsHardcoverAttribution =>
      'Données pour les livres fournies par Hardcover.';

  @override
  String get creditsOpenSource => 'Open Source';

  @override
  String get creditsOpenSourceDesc =>
      'Tonkatsu Box is gratuit et est un logiciel open source, publié sous la Licence MIT.';

  @override
  String get creditsViewLicenses => 'Voir les licences Open Source';

  @override
  String get creditsDiscord => 'Rejoignez-nous sur Discord !';

  @override
  String get collectionsImportCollection => 'Importer collection';

  @override
  String get collectionsNoCollectionsYet => 'Aucune collection pour l\'instant';

  @override
  String get collectionsNoCollectionsHint =>
      'Cliquez sur + pour créer votre première collection\net commencer à organiser votre bibliothèque.';

  @override
  String get collectionsFailedToLoad => 'Impossible de charger les collections';

  @override
  String collectionsCount(int count) {
    return 'Collections ($count)';
  }

  @override
  String get collectionsUncategorized => 'Sans catégorie';

  @override
  String collectionsUncategorizedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String get editCollection => 'Modifier la collection';

  @override
  String get collectionsRenamed => 'Collection mise à jour';

  @override
  String collectionsFailedToRename(String error) {
    return 'Impossible de sauvegarder : $error';
  }

  @override
  String get collectionsDeleted => 'Collection supprimée';

  @override
  String collectionsFailedToDelete(String error) {
    return 'Impossible de supprimer : $error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return 'Impossible de créer une collection : $error';
  }

  @override
  String collectionsImported(String name, int count) {
    return 'Importé \"$name\" possédant $count titres';
  }

  @override
  String get collectionsImporting => 'Importer une collection';

  @override
  String get importTargetTitle => 'Importer vers...';

  @override
  String get importCreateNew => 'Créer une nouvelle collection';

  @override
  String get importUseExisting => 'Ajouter à une collection existante';

  @override
  String get importNoCollections => 'Aucune collection disponible';

  @override
  String get importSelectCollection => 'Sélectionner collection';

  @override
  String get importErrorLoadingCollections =>
      'Impossible de charger les collections';

  @override
  String get importStartButton => 'Importer';

  @override
  String get importUsername => 'Nom d\'utilisateur';

  @override
  String get importUsernameHint => 'ex : votrepseudo';

  @override
  String get importMode => 'Mode';

  @override
  String get importModeNewOnly => 'Ajouter nouveautés';

  @override
  String get importModeNewOnlySubtitle =>
      'Ignore les titres déjà présents dans votre collection';

  @override
  String get importModeOverwrite => 'Écrire par-dessus';

  @override
  String get importModeOverwriteSubtitle =>
      'Met à jour la progression, les statuts et les dates depuis la source';

  @override
  String get importNewCollectionName => 'Nom de la collection';

  @override
  String importNewCollectionDefault(String source, String username) {
    return 'Importation depuis $source — $username';
  }

  @override
  String get importFetchingBooks => 'Récupération de la bibliothèque...';

  @override
  String get importAddingItems => 'Importer des titres';

  @override
  String importProcessingItem(String title) {
    return 'Traitement : $title';
  }

  @override
  String importImportedCount(int count) {
    return '$count importés';
  }

  @override
  String importUpdatedCount(int count) {
    return '$count mis à jour';
  }

  @override
  String importUserNotFound(String username) {
    return 'Utilisateur \"$username\" introuvable';
  }

  @override
  String get importEmptyUsername => 'Entrez un nom d\'utilisateur';

  @override
  String importFailed(String error) {
    return 'Erreur lors de l\'importation : $error';
  }

  @override
  String get collectionNotFound => 'Collection introuvable';

  @override
  String get collectionAddItems => 'Ajouter des titres';

  @override
  String get collectionSwitchToList => 'Passer à Liste';

  @override
  String get collectionSwitchToBoard => 'Passer à Tableau';

  @override
  String get collectionUnlockBoard => 'Déverrouiller le tableau';

  @override
  String get collectionLockBoard => 'Verrouiller le tableau';

  @override
  String get collectionExport => 'Exporter';

  @override
  String get collectionNoItemsYet => 'Vide pour le moment';

  @override
  String get collectionEmpty => 'Vider la collection';

  @override
  String get collectionEmptyAddHint =>
      'Ajoutez des titres pour commencer à construire votre collection';

  @override
  String get collectionEmptyReadonly => 'Cette collection est vide.';

  @override
  String get collectionDeleteEmptyPrompt =>
      'Cette collection est désormais vide. La supprimer ?';

  @override
  String get collectionRemoveItemTitle => 'Retirer ?';

  @override
  String collectionRemoveItemMessage(String name) {
    return 'Retirer $name de cette collection ?';
  }

  @override
  String get collectionMoveToCollection => 'Déplacer à une collection';

  @override
  String get collectionExportFormat => 'Format d\'exportation';

  @override
  String get collectionChooseExportFormat => 'Choisissez un format :';

  @override
  String get collectionExportLight => 'Léger (.xcoll)';

  @override
  String get collectionExportLightDesc => 'Titres seulement, petit fichier';

  @override
  String get collectionExportFull => 'Complet (.xcollx)';

  @override
  String get collectionExportFullDesc =>
      'Avec les images et les toiles — fonctionne hors-ligne';

  @override
  String get collectionExportIncludeUserData => 'Inclure données personnelles';

  @override
  String get collectionExportIncludeUserDataDesc =>
      'Statuts, dates, commentaires, progressions des épisodes';

  @override
  String get customItemCreate => 'Créer un titre personnalisé';

  @override
  String get title => 'Titre';

  @override
  String get customItemTitleHint => 'ex : Jeu fait maison';

  @override
  String get customItemAltTitle => 'Titre alternatif';

  @override
  String get customItemAltTitleHint => 'Titre original, par exemple';

  @override
  String get customItemCoverUrl => 'URL de l\'image';

  @override
  String get year => 'Année';

  @override
  String get genres => 'Genres';

  @override
  String get customItemGenresHint => 'ex : RPG, Action, Puzzle';

  @override
  String get platform => 'Plateforme';

  @override
  String get customItemPlatformHint => 'ex : PC, SNES, Personnalisé';

  @override
  String get format => 'Format';

  @override
  String get progress => 'Progression';

  @override
  String get customMarkCompleted => 'Marquer comme terminé';

  @override
  String get customUnitParts => 'Parties';

  @override
  String get customUnitEpisodes => 'Épisodes';

  @override
  String get customUnitChapters => 'Chapitres';

  @override
  String get customUnitPages => 'Pages';

  @override
  String get customUnitVolumes => 'Tomes';

  @override
  String get customUnitSeasons => 'Saisons';

  @override
  String get description => 'Description';

  @override
  String get customItemDescriptionHint => 'Courte description ou commentaires';

  @override
  String get customItemMyNoteHint => 'Votre commentaire à propos de ce titre';

  @override
  String get customItemTagsHint =>
      'Séparés d\'une virgule, ex : Favoris, Pile de lecture';

  @override
  String get customItemOptionalFields => 'Champs supplémentaires';

  @override
  String get customItemEdit => 'Modifier titre personnalisé';

  @override
  String get customItemFillFromFile => 'Remplir depuis un fichier';

  @override
  String customItemFileMultipleRows(int count) {
    return '$count entrées dans le fichier — la première a été utilisée';
  }

  @override
  String get customItemFileNoValidRows =>
      'Aucune entrée valide dans le fichier';

  @override
  String get customItemAddCover => 'Ajouter image';

  @override
  String get customItemCoverSource => 'Source de l\'image';

  @override
  String get customItemCoverRatio =>
      'Ratio dimensions recommandé : 2:3 (ex : 600×900)';

  @override
  String get customItemCoverFromFile => 'Depuis un fichier';

  @override
  String get customItemSearchHint =>
      'Rechercher ou entrer valeur personnalisée...';

  @override
  String get customItemUseCustom => 'Utiliser valeur personnalisée';

  @override
  String get customItemExternalUrl => 'URL externe';

  @override
  String get customItemErrorEmptyTitle => 'Titre requis';

  @override
  String get customItemCreated => 'Titre personnalisé créé';

  @override
  String get customItemUpdated => 'Titre personnalisé mis à jour';

  @override
  String get tagLabel => 'Tag';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagCreate => 'Nouveau tag';

  @override
  String get tagCreateHint => 'Nom de tag';

  @override
  String tagCreateNamed(String name) {
    return 'Créer \"$name\"';
  }

  @override
  String get tagRename => 'Renommer tag';

  @override
  String get tagDelete => 'Supprimer tag';

  @override
  String tagDeleteConfirm(String name) {
    return 'Supprimer le tag \"$name\"? Les titres perdront leur tag.';
  }

  @override
  String get tagManage => 'Gérer les tags';

  @override
  String get tagAssign => 'Assigner les tags';

  @override
  String get tagNone => 'Pas de tags';

  @override
  String get tagPickerTitle => 'Sélectionner tags';

  @override
  String get tagTextColor => 'Couleur du texte';

  @override
  String get tagCreated => 'Tag créé';

  @override
  String get tagRenamed => 'Tag renommé';

  @override
  String get tagDeleted => 'Tag supprimé';

  @override
  String get tagUpdateFailed => 'Impossible de mettre à jour le tag';

  @override
  String get refreshItemFromApi => 'Rafraîchir depuis la source';

  @override
  String get refreshItemSuccess => 'Titre mis à jour depuis la source';

  @override
  String get refreshItemNotFound => 'La source ne liste plus ce titre';

  @override
  String get refreshItemUnsupported =>
      'Les titres personnalisés n\'ont pas de source';

  @override
  String refreshItemFailed(String error) {
    return 'Impossible de rafraîchir : $error';
  }

  @override
  String get renameDialogHint => 'Nom d\'affichage';

  @override
  String renameOriginalLabel(String name) {
    return 'Initial : $name';
  }

  @override
  String get renameResetToOriginal => 'Revenir au nom initial';

  @override
  String get renameSaved => 'Renommé';

  @override
  String get tierListExportFailed => 'Impossible d\'exporter l\'image';

  @override
  String get browseCollectionsDownloadFailedGeneric =>
      'Impossible de télécharger la collection';

  @override
  String get tagFilterAll => 'Tous les tags';

  @override
  String get tagSidebarGroup => 'Groupe';

  @override
  String get colorPickerTitle => 'Couleur';

  @override
  String get colorPickerNoColor => 'Pas de couleur';

  @override
  String get raLinkButton => 'Associer RetroAchievements';

  @override
  String get raLinkTitle => 'Trouver un jeu sur RetroAchievements';

  @override
  String get raLinkSearchHint => 'Rechercher par nom...';

  @override
  String raLinkLoading(String platform) {
    return 'Chargement des jeux pour $platform...';
  }

  @override
  String get raLinkNotFound => 'Aucune correspondance';

  @override
  String get raLinkSuccess => 'Jeu couplé à RetroAchievements';

  @override
  String raLinkAchievements(int count) {
    return '$count succès';
  }

  @override
  String get raUnlinkButton => 'Dissocier';

  @override
  String get raUnlinkTitle => 'Dissocier RetroAchievements';

  @override
  String get raUnlinkConfirm =>
      'Dissocier RetroAchievements et supprimer les données pour ce jeu ?';

  @override
  String get collectionFilterByType => 'Filtrer par type';

  @override
  String get collectionFilterGames => 'Jeux';

  @override
  String get collectionFilterMovies => 'Films';

  @override
  String get collectionFilterTvShows => 'Séries';

  @override
  String get collectionFilterVisualNovels => 'Visual Novels';

  @override
  String get collectionFilterBooks => 'Livres';

  @override
  String get searchHint => 'Recherche...';

  @override
  String get sort => 'Trier';

  @override
  String get collectionFilterAscending => 'Ascendant';

  @override
  String get collectionFilterDescending => 'Descendant';

  @override
  String get collectionFilterFilters => 'Filtres';

  @override
  String get collectionFilterClearAll => 'Tout effacer';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name déplacé vers $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name existe déjà dans $collection';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name retiré';
  }

  @override
  String get boardTab => 'Tableau';

  @override
  String get imageAddedToBoard => 'Image ajoutée au tableau';

  @override
  String get mapAddedToBoard => 'Carte ajoutée au tableau';

  @override
  String get loading => 'Chargement...';

  @override
  String get gameNotFound => 'Jeu introuvable';

  @override
  String get movieNotFound => 'Film introuvable';

  @override
  String get tvShowNotFound => 'Série introuvable';

  @override
  String get animationNotFound => 'Film d\'animation introuvable';

  @override
  String get visualNovelNotFound => 'Visual novel introuvable';

  @override
  String get mangaNotFound => 'Manga introuvable';

  @override
  String get readingProgress => 'Progression lecture';

  @override
  String get mangaChapters => 'Chapitres';

  @override
  String get mangaVolumes => 'Tomes';

  @override
  String get mangaMarkCompleted => 'Marquer comme terminé';

  @override
  String get animeProgress => 'Progression';

  @override
  String get animeEpisodes => 'Épisodes';

  @override
  String get animeMarkCompleted => 'Marquer comme terminé';

  @override
  String get bookPages => 'Pages';

  @override
  String get bookIssues => 'Numéros';

  @override
  String get bookMarkCompleted => 'Marquer comme terminé';

  @override
  String animeNextEpisode(int episode) {
    return 'L\'épisode $episode sort bientôt';
  }

  @override
  String get animatedMovie => 'Film animé';

  @override
  String get animatedSeries => 'Série animée';

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String runtimeHours(int hours) {
    return '${hours}h';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '${minutes}min';
  }

  @override
  String totalSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
    );
    return '$_temp0';
  }

  @override
  String totalEpisodes(int count) {
    return '$count épisodes';
  }

  @override
  String seasonName(int number) {
    return 'Saison $number';
  }

  @override
  String get episodeProgress => 'Progression épisode';

  @override
  String episodesWatchedOf(int watched, int total) {
    return '$watched/$total regardé';
  }

  @override
  String episodesWatched(int count) {
    return '$count regardé';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total épisodes';
  }

  @override
  String get noSeasonData => 'Aucune donnée sur la saison';

  @override
  String get refreshFromTmdb => 'Rafraîchir depuis TMDB';

  @override
  String get markAllWatched => 'Marquer tous les épisodes comme regardé';

  @override
  String get markNextWatched => 'Marquer le prochain épisode';

  @override
  String get unmarkAll => 'Retirer toutes les mentions regardé';

  @override
  String get noEpisodesFound => 'Aucun épisode trouvé';

  @override
  String episodeWatchedDate(String date) {
    return 'regardé le $date';
  }

  @override
  String get createCollectionTitle => 'Nouvelle collection';

  @override
  String get createCollectionNameLabel => 'Nom de la collection';

  @override
  String get createCollectionNameHint => 'ex : Classiques de  la SNES';

  @override
  String get createCollectionEnterName => 'Veuillez entrer un nom';

  @override
  String get createCollectionNameTooShort =>
      'Le nom doit contenir au moins 2 caractères';

  @override
  String get renameCollectionTitle => 'Renommer la collection';

  @override
  String get deleteCollectionTitle => 'Supprimer la collection ?';

  @override
  String deleteCollectionMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name ?\n\nCette action est irréversible.';
  }

  @override
  String get canvasAddText => 'Ajouter un texte';

  @override
  String get canvasAddImage => 'Ajouter une image';

  @override
  String get canvasAddLink => 'Ajouter un lien';

  @override
  String get canvasFindImages => 'Trouver des images...';

  @override
  String get canvasBrowseMaps => 'Parcourir des cartes...';

  @override
  String get canvasConnect => 'Connecter';

  @override
  String get canvasBringToFront => 'Amener au premier plan';

  @override
  String get canvasSendToBack => 'Envoyer à l\'arrière-plan';

  @override
  String get canvasEditConnection => 'Modifier connexion';

  @override
  String get canvasDeleteConnection => 'Supprimer connexion';

  @override
  String get canvasDeleteElement => 'Supprimer l\'élément';

  @override
  String get canvasDeleteElementMessage =>
      'Êtes-vous sûr de vouloir supprimer cet élément ?';

  @override
  String get canvasAddToBoard => 'Ajouter au tableau';

  @override
  String get editTextTitle => 'Modifier le texte';

  @override
  String get textContentLabel => 'Contenu du texte';

  @override
  String get fontSizeLabel => 'Police (taille)';

  @override
  String get fontSizeSmall => 'Petit';

  @override
  String get fontSizeMedium => 'Moyen';

  @override
  String get fontSizeLarge => 'Grand';

  @override
  String get fontSizeTitle => 'Titre';

  @override
  String get editImageTitle => 'Modifier l\'image';

  @override
  String get imageFromUrl => 'Depuis une URL';

  @override
  String get imageFromFile => 'Depuis un fichier';

  @override
  String get imageUrlLabel => 'URL de l\'image';

  @override
  String get imageUrlHint => 'https://exemple.com/image.png';

  @override
  String get imageChooseFile => 'Choisir le fichier';

  @override
  String get imageChooseAnother => 'Choisir un autre';

  @override
  String get editLinkTitle => 'Modifier le lien';

  @override
  String get linkLabelOptional => 'Étiquette (optionnel)';

  @override
  String get linkLabelHint => 'Mon lien';

  @override
  String get connectionLabelHint => 'ex : dépend de..., lié à...';

  @override
  String get connectionStyleLabel => 'Style';

  @override
  String get connectionStyleSolid => 'Épais';

  @override
  String get connectionStyleDashed => 'Discontinu';

  @override
  String get connectionStyleArrow => 'Flèche';

  @override
  String get searchTabTv => 'TV';

  @override
  String get searchHintMovies => 'Rechercher des films...';

  @override
  String get searchHintTv => 'Rechercher des séries...';

  @override
  String get searchHintAnime => 'Rechercher des animes...';

  @override
  String get searchHintGames => 'Rechercher des jeux...';

  @override
  String get searchHintVisualNovels => 'Rechercher des visual novels...';

  @override
  String get searchSourceVisualNovels => 'V. Novels';

  @override
  String get searchSourceOpenLibrary => 'OpenLibrary';

  @override
  String get searchSourceFantlab => 'Fantlab';

  @override
  String get searchSourceComics => 'Comics';

  @override
  String get searchHintManga => 'Rechercher des mangas';

  @override
  String get searchHintBooks => 'Rechercher des livres...';

  @override
  String get searchHintComics => 'Rechercher des comics...';

  @override
  String get language => 'Langue';

  @override
  String get bookFilterSearchBy => 'Rechercher par';

  @override
  String get type => 'Type';

  @override
  String get bookSearchAuthor => 'Auteur';

  @override
  String get bookSearchSubject => 'Sujet';

  @override
  String get bookSimilarTitle => 'Livres similaires';

  @override
  String get bookMoreByAuthorTitle => 'Plus de cet auteur';

  @override
  String get bookTitleCopied => 'Titre copié';

  @override
  String get editionPickerTitle => 'Choisir l\'édition';

  @override
  String get editionPickerEmpty => 'Aucune édition trouvée';

  @override
  String get fantlabTypeNovel => 'Roman';

  @override
  String get fantlabTypeNovella => 'Roman court';

  @override
  String get fantlabTypeShortStory => 'Nouvelle';

  @override
  String get fantlabTypeCycle => 'Cycle';

  @override
  String get searchSelectPlatform => 'Sélectionner plateforme';

  @override
  String get searchAddToCollection => 'Ajouter à la collection';

  @override
  String searchAddedToCollection(String name) {
    return '$name ajouté à la collection';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name ajouté à $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name déjà dans la collection';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name déjà dans $collection';
  }

  @override
  String searchAddedToCollections(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '1 collection',
    );
    return '$name ajouté à $_temp0';
  }

  @override
  String searchAlreadyInCollections(String name) {
    return '$name déjà dans les collections sélectionnées';
  }

  @override
  String get goToSettings => 'Aller dans les Paramètres';

  @override
  String get searchMinCharsHint =>
      'Entrez au moins 2 caractères et appuyez sur Entrer';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String searchNothingFoundFor(String query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get searchNoInternet => 'Pas de connexion Internet';

  @override
  String get searchFailed => 'Échec de la recherche';

  @override
  String get searchCheckConnection => 'Vérifiez votre connexion et réessayez.';

  @override
  String get copyErrorDetails => 'Détails erreur de copie';

  @override
  String get errorDetailsCopied => 'Détails de l\'erreur copiés';

  @override
  String get errorDetailsTitle => 'Détails de l\'erreur';

  @override
  String get errorDetailsShow => 'Détails';

  @override
  String get showMore => 'Plus…';

  @override
  String get showLess => 'Fermer';

  @override
  String get platformFilterTitle => 'Sélectionner plateformes';

  @override
  String get platformFilterClearAll => 'Tout effacer';

  @override
  String get platformFilterSearchHint => 'Rechercher plateformes...';

  @override
  String selectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String platformFilterCount(int count) {
    return '$count plateformes';
  }

  @override
  String get platformFilterShowAll => 'Montrer tout';

  @override
  String platformFilterApply(int count) {
    return 'Appliquer ($count)';
  }

  @override
  String get platformFilterNone => 'Aucune plateforme trouvée';

  @override
  String get platformFilterTryDifferent => 'Essayez un autre terme';

  @override
  String get wishlistHideResolved => 'Cacher collecté';

  @override
  String get wishlistShowResolved => 'Montrer collecté';

  @override
  String get wishlistClearResolved => 'Effacer collecté';

  @override
  String get wishlistEmpty => 'Aucun titre dans la liste de souhaits';

  @override
  String get wishlistEmptyHint =>
      'Cliquez sur + pour ajouter quelque chose à votre liste';

  @override
  String get wishlistDeleteItem => 'Supprimer titre';

  @override
  String wishlistDeletePrompt(String name) {
    return 'Supprimer \"$name\" de votre liste de souhaits ?';
  }

  @override
  String wishlistClearResolvedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count titres collectés ?',
      one: 'Supprimer 1 titre collecté ?',
    );
    return '$_temp0';
  }

  @override
  String get wishlistMarkResolved => 'Marquer en collecté';

  @override
  String get wishlistUnresolve => 'Plus collecté';

  @override
  String get wishlistTitleHint => 'Nom de jeu, film ou série...';

  @override
  String get wishlistTitleMinChars => 'Au moins 2 caractères';

  @override
  String get wishlistTypeOptional => 'Type (optionnel)';

  @override
  String get any => 'Tout';

  @override
  String get wishlistNoteOptional => 'Commentaire (optionnel)';

  @override
  String get wishlistNoteHint => 'Plateforme, année, recommandé par...';

  @override
  String get wishlistTagOptional => 'Tag (optionnel)';

  @override
  String get wishlistTagHint =>
      'Entrées groupées — ex : une importation par batch ou une source';

  @override
  String get wishlistTagUntagged => 'Retirer tag';

  @override
  String get wishlistTagFilterLabel => 'Liste';

  @override
  String get wishlistTagManage => 'Gérer le tag';

  @override
  String get wishlistTagDelete => 'Supprimer le tag et toutes les entrées';

  @override
  String wishlistTagDeleteConfirm(String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
    );
    return 'Supprimer le tag \"$tag\" et $_temp0?';
  }

  @override
  String wishlistBulkActionsButton(int count) {
    return '$count correspondances';
  }

  @override
  String get wishlistBulkApplyTag => 'Appliquer un tag aux entrées visibles';

  @override
  String wishlistBulkApplyTagHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tagger les $count entrées visibles en tant que',
      one: 'Tagger l\'entrée visible en tant que',
    );
    return '$_temp0';
  }

  @override
  String get wishlistBulkRemoveTag => 'Supprimer un tag des entrées visibles';

  @override
  String get wishlistBulkDelete => 'Supprimer des entrées visibles';

  @override
  String wishlistBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count entrées visibles ?',
      one: 'Supprimer 1 entrée visible ?',
    );
    return '$_temp0';
  }

  @override
  String get apply => 'Appliquer';

  @override
  String get welcomeStepWelcome => 'Bienvenue';

  @override
  String get welcomeStepReady => 'Prêt !';

  @override
  String get welcomeNameTitle => 'Comment vous appelez-vous ?';

  @override
  String get welcomeNameSubtitle =>
      'Votre nom apparaîtra en tant qu\'auteur des collections que vous créerez';

  @override
  String get welcomeChangeLaterHint =>
      'Vous pouvez le changer plus tard dans les Paramètres';

  @override
  String get welcomeLanguageTitle => 'Choisissez votre langue';

  @override
  String get welcomeLanguageSubtitle =>
      'Sélectionnez la langue de l\'interface';

  @override
  String get welcomeTitle => 'Tonkatsu Box vous souhaite la bienvenue';

  @override
  String get welcomeSubtitle =>
      'Organisez vos collections de jeux, films,\nséries, animes, visual novels, mangas et livres';

  @override
  String get welcomeWhatYouCanDo => 'Ce que vous pouvez faire';

  @override
  String get welcomeFeatureCollections =>
      'Créer des collections par plateforme, genre ou n\'importe quel thème';

  @override
  String get welcomeFeatureSearch =>
      'Rechercher des jeux, films, séries, animes, visual novels, mangas & livres via des API';

  @override
  String get welcomeFeatureTracking =>
      'Marquer votre progression, noter de 1 à 10, ajouter des commentaires';

  @override
  String get welcomeFeatureBoards =>
      'Tableaux canvas visuels avec des illustrations';

  @override
  String get welcomeFeatureExport =>
      'Exporter et importer — partager vos collections avec vos amis';

  @override
  String get welcomeWorksWithoutKeys => 'Fonctionne sans clés API';

  @override
  String get welcomeChipImport => 'Importer .xcoll';

  @override
  String get welcomeChipCanvas => 'Tableaux canvas';

  @override
  String get welcomeChipRatings => 'Notes et commentaires';

  @override
  String get welcomeApiKeysHint =>
      'Les clés API sont seulement nécessaires pour rechercher des nouveaux jeux, films et séries. Vous pouvez importer des collections et les utiliser hors-ligne.';

  @override
  String get welcomeChipGames => 'Jeux (IGDB)';

  @override
  String get welcomeChipMovies => 'Films (TMDB)';

  @override
  String get welcomeChipTvShows => 'Séries (TMDB)';

  @override
  String get welcomeChipAnime => 'Animes (TMDB)';

  @override
  String get welcomeChipVisualNovels => 'Visual Novels (VNDB)';

  @override
  String get welcomeChipManga => 'Mangas (AniList)';

  @override
  String get welcomeApiTitle => 'Obtenir des clés API';

  @override
  String get welcomeApiFreeHint =>
      'Inscriptions gratuites, prend 2 à 3 minutes pour chaque site';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => 'Recherche de jeux';

  @override
  String get welcomeApiRequired => 'REQUIS';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => 'Films, séries et animes';

  @override
  String get welcomeApiComicVineDesc => 'Comics et romans graphiques';

  @override
  String get welcomeApiGoogleBooksDesc => 'Catalogue de livres de Google';

  @override
  String get welcomeApiHardcoverDesc =>
      'Catalogue communautaire de livres, nécessite un token personnel';

  @override
  String get welcomeApiRecommended => 'RECOMMANDÉ';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => 'Illustrations de jeux pour les tableaux';

  @override
  String get welcomeApiOptional => 'OPTIONNEL';

  @override
  String get welcomeApiBuiltInKey => 'CLÉ INTÉGRÉE';

  @override
  String get welcomeApiOwnKeyHint =>
      'Vous pouvez ajouter vos propres clés plus tard dans Paramètres pour augmenter les limites d\'utilisation';

  @override
  String get welcomeApiEnterKeysHint =>
      'Entrez les clés dans Paramètres → Identifiants plus tard';

  @override
  String get welcomeApiRateLimitHint =>
      'Les clés intégrées sont partagées entre tous les utilisateurs et ont une limite d\'utilisation. Pour une meilleure expérience, utilisez vos propres clés — c\'est gratuit et prend seulement quelques minutes.';

  @override
  String get welcomeHowTitle => 'Comment ça fonctionne';

  @override
  String get welcomeHowAppStructure => 'Structure de l\'application';

  @override
  String get welcomeHowMainDesc =>
      'Toutes vos collections sur une seule page. Filtrez par type, rangez par note.';

  @override
  String get welcomeHowCollectionsDesc =>
      'Vos collections. Créez, organisez, gérez. Affichage liste ou grille, différent pour chaque collection.';

  @override
  String get welcomeHowTierListsDesc =>
      'Classez et comparez des titres depuis vos collections grâce à des tier lists personnalisées.';

  @override
  String get welcomeHowWishlistDesc =>
      'Courte liste des titres à vérifier plus tard. Pas besoin d\'API.';

  @override
  String get welcomeHowSearchDesc =>
      'Trouvez des jeux, films, séries, visual novels et mangas via les API. Ajoutez les à n\'importe quelle collection.';

  @override
  String get welcomeHowSettingsDesc =>
      'Clés API, cache, exporter/importer base de données, outils debugging.';

  @override
  String get welcomeHowPersonalizationDesc =>
      'Tous vos intêrets dans une seule page : un cloud de vos genres favoris, ainsi que des recommandations mises en avant en comparant vos notes.';

  @override
  String get welcomeHowQuickStart => 'Démarrage rapide';

  @override
  String get welcomeHowStep1 =>
      'Allez dans Paramètres → Identifiants, entrez vos clés API';

  @override
  String get welcomeHowStep2 =>
      'Cliquez sur Vérifier connexion, attendez que les plateformes se synchronisent';

  @override
  String get welcomeHowStep3 =>
      'Allez dans Collections → + Nouvelle collection';

  @override
  String get welcomeHowStep4 =>
      'Nommez-la, puis Ajouter des titres → Rechercher → Ajouter';

  @override
  String get welcomeHowStep5 =>
      'Notez, suivez votre progression, ajoutez des commentaires — vous êtes prêt !';

  @override
  String get welcomeHowSharing => 'Partager';

  @override
  String get welcomeHowSharingDesc1 =>
      'Exporter des collections, deux formats : ';

  @override
  String get welcomeHowSharingDesc2 => ' (léger, métadonnées seulement) ou ';

  @override
  String get welcomeHowSharingDesc3 =>
      ' (complet, images et canvas — fonctionne hors-ligne). Importer grâce à vos amis — pas besoin d\'API !';

  @override
  String get welcomeReadyTitle => 'Vous êtes prêt !';

  @override
  String get welcomeReadyMessage =>
      'Allez dans Paramètres → Identifiants pour ajouter vos clés API ou commencer en important une collection.';

  @override
  String get welcomeReadySkip => 'Passer — explorez l\'application vous-même';

  @override
  String get welcomeReadyReturnHint =>
      'Vous pouvez toujours revoir ce tutoriel depuis les Paramètres';

  @override
  String get welcomeStepSources => 'Sources';

  @override
  String get welcomeStepTour => 'Visite';

  @override
  String get welcomeChipBooks => 'Livres (OpenLibrary, Fantlab)';

  @override
  String get welcomeSourcesTitle => 'Provenance des données';

  @override
  String get welcomeSourcesSubtitle =>
      'Ces fournisseurs alimentent la fonction recherche de l\'application. La plupart fonctionnent tout de suite — les autres demandant une clé API gratuite.';

  @override
  String get welcomeSourcesNoKeyNeeded => 'AUCUNE CLÉ NÉCESSAIRE';

  @override
  String get welcomeSourcesKeySaved => 'Clé sauvegardée';

  @override
  String get welcomeSourcesGetKey => 'Obtenir une clé';

  @override
  String get welcomeSourcesKeyOptionalHint =>
      'Optionnel — votre clé augmente la limite d\'utilisation. La recherche fonctionne sans.';

  @override
  String get welcomeSourcesHardcoverTokenHint =>
      'Requis — la recherche et l\'import sont désactivés par défaut. Les tokens expirent chaque 1er janvier.';

  @override
  String get welcomeSourceDescTmdb => 'Films, séries et films d\'animation.';

  @override
  String get welcomeSourceDescTvMaze => 'Séries.';

  @override
  String get welcomeSourceDescIgdb =>
      'Jeux vidéos, toutes plateformes confondues.';

  @override
  String get welcomeSourceDescAniList =>
      'Animes et mangas, métadonnées enrichies.';

  @override
  String get welcomeSourceDescMangaBaka =>
      'Mangas, manhwas, manhuas et light novels.';

  @override
  String get welcomeSourceDescMangaDex =>
      'Un large catalogue de mangas avec des titres traduits et un compteur de chapitres.';

  @override
  String get welcomeSourceDescKitsu =>
      'Un catalogue indépendant de mangas avec des notes et des couvertures.';

  @override
  String get welcomeSourceDescVndb => 'Base de données pour les visual novels.';

  @override
  String get welcomeSourceDescOpenLibrary =>
      'Catalogue de bibliothèque ouvert, des millions de livres.';

  @override
  String get welcomeSourceDescFantlab =>
      'Catalogue détaillé de livres avec des notes, récompenses et cycles.';

  @override
  String get welcomeSourceDescComicVine =>
      'Un large catalogue de comics et romans graphiques.';

  @override
  String get welcomeSourceDescGoogleBooks =>
      'Des millions d\'éditions en provenance de Google Books, recherches par titre, auteur ou ISBN.';

  @override
  String get welcomeSourceDescHardcover =>
      'Catalogue communautaire de livres listant des cycles, genres, humeurs et notes. Nécessite un token personnel (gratuit).';

  @override
  String get welcomeTourTitle => 'Apprenez à connaître le menu';

  @override
  String get welcomeTourSubtitle =>
      'Une visite rapide de la navigation — cliquez sur Suivant pour passer à la suite.';

  @override
  String get welcomeTourStart => 'Explorez maintenant';

  @override
  String get welcomeHowReleasesDesc =>
      'Nouveaux épisodes et sorties pour les séries et les jeux que vous suivez.';

  @override
  String updateAvailable(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String updateCurrent(String version) {
    return 'Actuelle : v$version';
  }

  @override
  String get updateWarningTitle => 'Avant de mettre à jour';

  @override
  String get updateWarningBody =>
      'Cette application est en développement. Les mises à jours peuvent inclure des migrations de base de données modifiant le format des données.\n\nVeuillez créer une sauvegarde avant de mettre à jour (Paramètres → Sauvegarde). Ainsi, vous pouvez restaurer vos données au moindre problème.';

  @override
  String get updateWarningProceed => 'Aller à la page de release';

  @override
  String get chooseCollection => 'Choisir collection';

  @override
  String get withoutCollection => 'Sans collection';

  @override
  String get detailMyRating => 'Ma note';

  @override
  String detailRatingValue(String rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => 'Activité et progression';

  @override
  String get detailAuthorReview => 'Critique de l\'auteur';

  @override
  String get detailEditAuthorReview => 'Modifier la critique de l\'auteur';

  @override
  String get detailWriteReviewHint => 'Écrivez votre critique...';

  @override
  String get detailReviewVisibility =>
      'Visible une fois partagé. Votre critique de ce titre.';

  @override
  String get detailNoReviewEditable =>
      'Aucune critique. Cliquez sur Modifier pour en ajouter une.';

  @override
  String get detailNoReviewReadonly => 'Aucune critique écrite par l\'auteur.';

  @override
  String get detailMyNotes => 'Mes commentaires';

  @override
  String get detailEditMyNotes => 'Modifier mes commentaires';

  @override
  String get detailWriteNotesHint => 'Écrivez vos commentaires...';

  @override
  String get detailNoNotesYet =>
      'Aucun commentaire. Cliquez sur Modifier pour ajouter des commentaires.';

  @override
  String get detailNoNotesReadonly => 'Aucun commentaire de l\'auteur.';

  @override
  String get unknownGame => 'Jeu inconnu';

  @override
  String get unknownMovie => 'Film inconnu';

  @override
  String get unknownTvShow => 'Série inconnue';

  @override
  String get unknownAnimation => 'Film d\'animation inconnu';

  @override
  String get unknownVisualNovel => 'Visual novel inconnu';

  @override
  String get unknownManga => 'Manga inconnu';

  @override
  String get unknownCustom => 'Titre personnalisé inconnu';

  @override
  String get unknownPlatform => 'Plateforme inconnue';

  @override
  String get defaultAuthor => 'Utilisateur';

  @override
  String errorPrefix(String error) {
    return 'Erreur : $error';
  }

  @override
  String get allItemsRatingAsc => 'Note ↑';

  @override
  String get allItemsRatingDesc => 'Note ↓';

  @override
  String get allItemsNoItems => 'Aucun titre';

  @override
  String get allItemsNoMatch => 'Aucun titre ne correspond aux filtres';

  @override
  String get allItemsAddViaCollections =>
      'Allez dans Collections → créer une collection → ajouter des titres\nvia Recherche. Ils apparaitront ici automatiquement.';

  @override
  String get allItemsFailedToLoad => 'Impossible de charger les titres';

  @override
  String get allPlatforms => 'Toutes les plateformes';

  @override
  String get allItemsFilterPlatformsTitle => 'Filtrer par plateforme';

  @override
  String get debugIgdbMedia => 'IGDB Media';

  @override
  String get debugGamepad => 'Manette';

  @override
  String get debugClearLogs => 'Effacer journal';

  @override
  String get debugRawEvents => 'Évènements bruts (Gamepads.events)';

  @override
  String get debugServiceEvents => 'Évènements service (filtré)';

  @override
  String debugEventsCount(int count) {
    return '$count évènements';
  }

  @override
  String get debugPressButton =>
      'Appuyez sur n\'importe\nquel bouton sur la manette...';

  @override
  String get debugExportLog => 'Exporter journal';

  @override
  String debugLogExported(String path) {
    return 'Journal exporté vers $path';
  }

  @override
  String get debugLogEmpty => 'Aucun event à exporter';

  @override
  String get settingsGamepadDebug => 'Debug manette';

  @override
  String get debugSearchGames => 'Rechercher des jeux';

  @override
  String get debugEnterGameName => 'Entrez un nom de jeu';

  @override
  String get debugEnterGameNameHint =>
      'Entrez un nom de jeu pour lancer la recherche';

  @override
  String get debugGameId => 'ID du jeu';

  @override
  String get debugEnterGameId => 'Entrez une ID SteamGridDB';

  @override
  String debugLoadTab(String tabName) {
    return 'Charger $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return 'Entrez l\'ID d\'un jeu et cliquez sur Charger $tabName';
  }

  @override
  String get debugNoImagesFound => 'Aucune image trouvée';

  @override
  String collectionTileStats(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0 · $percent terminé';
  }

  @override
  String get collectionTileError =>
      'Erreur lors du chargement des statistiques';

  @override
  String get activityDatesTitle => 'Dates d\'activité';

  @override
  String get activityDatesAdded => 'Ajouté';

  @override
  String get activityDatesStarted => 'Commencé';

  @override
  String get activityDatesCompleted => 'Terminé';

  @override
  String get activityDatesSelectStart => 'Sélectionner une date de début';

  @override
  String get activityDatesSelectCompletion =>
      'Sélectionner une date de complétion';

  @override
  String get settingsDateFormat => 'Format de la date';

  @override
  String get settingsDateFormatSubtitle =>
      'Comment les dates sont affichées dans l\'application';

  @override
  String get settingsAnimeMangaTitleLanguage =>
      'Langue des titres pour les animes et mangas';

  @override
  String get settingsAnimeMangaTitleLanguageSubtitle =>
      'Titre affiché pour les animes et mangas';

  @override
  String get settingsAnimeMangaTitleLanguageRomaji => 'Romaji';

  @override
  String get settingsAnimeMangaTitleLanguageEnglish => 'Anglais';

  @override
  String get settingsAnimeMangaTitleLanguageNative => 'Original';

  @override
  String get dualDatePickerErrorEmpty => 'Entrez une date';

  @override
  String get dualDatePickerErrorFormat => 'Utilisez ce format : aaaa-MM-jj';

  @override
  String get dualDatePickerErrorRange => 'La date n\'est pas valide';

  @override
  String activityDatesCompletionTime(String duration) {
    return 'Complété en $duration';
  }

  @override
  String get timeSpentTitle => 'Temps écoulé';

  @override
  String get timeSpentAdd => 'Ajouter une durée';

  @override
  String get timeSpentEdit => 'Modifier temps';

  @override
  String get timeSpentHours => 'Heures';

  @override
  String get timeSpentMinutes => 'Minutes';

  @override
  String get durationLessThanDay => 'moins d\'un jour';

  @override
  String get durationOneDay => '1 jour';

  @override
  String durationDays(int count) {
    return '$count jours';
  }

  @override
  String durationWeeks(int count) {
    return '$count semaines';
  }

  @override
  String durationMonths(int count) {
    return '$count mois';
  }

  @override
  String durationYears(String count) {
    return '$count années';
  }

  @override
  String get canvasFailedToLoad => 'Impossible de charger le tableau';

  @override
  String get canvasBoardEmpty => 'Le tableau est vide';

  @override
  String get canvasBoardEmptyHint =>
      'Ajoutez des titres à la collection d\'abord';

  @override
  String get canvasCenterView => 'Centrer affichage';

  @override
  String get canvasResetPositions => 'Réinitialiser les positions';

  @override
  String get canvasVgmapsBrowser => 'Navigateur VGMaps';

  @override
  String get canvasSteamGridDbImages => 'Images SteamGridDB';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get closePanel => 'Fermer panneau';

  @override
  String get steamGridDbSearchHint => 'Recherche un jeu...';

  @override
  String get steamGridDbNoApiKey =>
      'La clé API SteamGridDB n\'a pas été fournie. Configurez dans les Paramètres.';

  @override
  String get steamGridDbBackToSearch => 'Retour à la recherche';

  @override
  String get steamGridDbGrids => 'Grids';

  @override
  String get steamGridDbHeroes => 'Heroes';

  @override
  String get steamGridDbLogos => 'Logos';

  @override
  String get steamGridDbIcons => 'Icons';

  @override
  String get steamGridDbSearchFirst => 'Recherchez un jeu d\'abord';

  @override
  String get vgmapsBack => 'Retour';

  @override
  String get vgmapsForward => 'Suivant';

  @override
  String get vgmapsHome => 'Accueil';

  @override
  String get vgmapsReload => 'Recharger';

  @override
  String get vgmapsCaptureImage => 'Enregistrer l\'image de la carte';

  @override
  String get vgmapsSearchHint => 'Rechercher un jeu sur VGMaps...';

  @override
  String get vgmapsDismiss => 'Rejeter';

  @override
  String vgmapsFailedInit(String error) {
    return 'Impossible de démarrer WebView : $error';
  }

  @override
  String get discoverTitle => 'Découvrir';

  @override
  String get discoverCustomize => 'Personnaliser';

  @override
  String get discoverTrending => 'Populaire cette semaine';

  @override
  String get discoverTopRatedMovies => 'Films les mieux notés';

  @override
  String get discoverTopRatedTvShows => 'Séries les mieux notées';

  @override
  String get discoverPopularTvShows => 'Séries populaires';

  @override
  String get discoverUpcoming => 'À venir';

  @override
  String get discoverCustomizeTitle => 'Personnaliser Découvrir';

  @override
  String get discoverCustomizeHint => 'Choisissez quelles sections montrer';

  @override
  String get discoverResetDefault => 'Réinitialiser l\'affichage';

  @override
  String get discoverAlreadyInCollection => 'Déjà dans la collection';

  @override
  String get discoverShowWithBadge => 'Montrer avec un badge';

  @override
  String get discoverHideCompletely => 'Cacher totalement';

  @override
  String get recommendationsTitle => 'Recommandations';

  @override
  String get reviewsTitle => 'Critiques';

  @override
  String reviewsShowAll(int count) {
    return 'Montrer les $count critiques';
  }

  @override
  String get reviewsReadMore => 'Lire plus';

  @override
  String get reviewsInEnglish => 'Critiques en anglais';

  @override
  String get settingsShowRecommendationsSubtitle =>
      'Films et séries similaires sur les pages de détails';

  @override
  String get settingsHideEmptyMediaTypeChevrons =>
      'Cacher les filtres sans contenu';

  @override
  String get settingsHideEmptyMediaTypeChevronsSubtitle =>
      'Cache les filtres (Jeux, Films, etc.) qui ne contiennent aucun titre du même type.';

  @override
  String get settingsAlwaysShowSubcategories =>
      'Toujours montrer les sous-catégories';

  @override
  String get settingsAlwaysShowSubcategoriesSubtitle =>
      'Montre les filtres de sous-catégories (plateformes de jeux, genres de mangas/animes) sans sélectionner leur type en premier lieu.';

  @override
  String get settingsShowPlatformOverlay =>
      'Jacquettes des plateformes de jeux';

  @override
  String get settingsShowPlatformOverlaySubtitle =>
      'Montrer le logo de la plateforme sur la jacquette des jeux (PS5, Switch, etc.)';

  @override
  String get settingsShowBlurayOverlay => 'Jacquettes Blu-ray';

  @override
  String get settingsShowBlurayOverlaySubtitle =>
      'Montrer le logo Blu-ray sur la jacquette des films et des séries';

  @override
  String get settingsRichCollections => 'Vue enrichie des collections';

  @override
  String get settingsRichCollectionsSubtitle =>
      'Personnalisez les collections avec des jacquettes et des descriptions';

  @override
  String get settingsCardScale => 'Taille jacquettes';

  @override
  String get settingsCardScaleSubtitle =>
      'Taille des cartes dans les collections (mode grille)';

  @override
  String get collectionEditHeroImage => 'Bannière';

  @override
  String get collectionEditHeroImageHint =>
      '2560×1080 recommandé (21:9). Sujet principal sur la droite — le côté gauche est recouvert par le titre — le bas disparaît dans le fond';

  @override
  String get collectionEditHeroPick => 'Choisir une image';

  @override
  String get collectionEditHeroReplace => 'Remplacer l\'image';

  @override
  String get collectionEditHeroRemove => 'Retirer l\'image';

  @override
  String get collectionEditDescriptionHint =>
      'Un court slogan s\'affichant par-dessus la bannière';

  @override
  String get collectionEditDialogTitle => 'Paramètres de collection';

  @override
  String get settingsDiscordRpc => 'Intégration dans Discord';

  @override
  String get settingsDiscordRpcSubtitle =>
      'Affiche le titre regardé dans votre statut Discord';

  @override
  String get settingsDiscordRaSync => 'Synchroniser RetroAchievements';

  @override
  String get settingsDiscordRaSyncSubtitle =>
      'Affiche votre activité RetroAchievements dans votre profil Discord';

  @override
  String get uncategorizedBanner =>
      'Ajouter à une collection pour débloquer l\'affichage tableau et le suivi des épisodes';

  @override
  String get uncategorizedDeprecationNotice =>
      'Cette collection sera bientôt retirée. Créez votre propre collection et déplacez les titres dedans.';

  @override
  String get uncategorizedDeprecationBadge => 'Sera retirée';

  @override
  String get browseFilterGenre => 'Genre';

  @override
  String get browseFilterLength => 'Durée';

  @override
  String get vndbLengthVeryShort => 'Très courte';

  @override
  String get vndbLengthShort => 'Courte';

  @override
  String get vndbLengthMedium => 'Moyenne';

  @override
  String get vndbLengthLong => 'Longue';

  @override
  String get vndbLengthVeryLong => 'Très longue';

  @override
  String get browseFilterAnimeAdaptation => 'Adaptation anime';

  @override
  String get vndbHasAnimeAdaptation => 'A une adaptation';

  @override
  String get tagPickerSearchHint => 'Rechercher tags';

  @override
  String get tagPickerShowSpoilers => 'Montrer les tags spoiler';

  @override
  String get tagPickerShowAdult => 'Montrer les tags +18';

  @override
  String get tagPickerRefresh => 'Rafraîchir catalogue';

  @override
  String get tagPickerEmpty => 'Aucun tag trouvé';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get browseFilterSeason => 'Saison';

  @override
  String get browseFilterGameMode => 'Mode de jeu';

  @override
  String get browseFilterMinRating => 'Note minimum';

  @override
  String get browseFilterMinVotes => 'Votes minimum';

  @override
  String get seasonWinter => 'Hiver';

  @override
  String get seasonSpring => 'Printemps';

  @override
  String get seasonSummer => 'Été';

  @override
  String get seasonFall => 'Automne';

  @override
  String get animeFormatTv => 'TV';

  @override
  String get animeFormatMovie => 'Film';

  @override
  String get animeFormatOva => 'OVA';

  @override
  String get animeFormatOna => 'ONA';

  @override
  String get animeFormatSpecial => 'Spécial';

  @override
  String get animeFormatTvShort => 'Court épisode TV';

  @override
  String get mangaStatusPublishing => 'En cours de publication';

  @override
  String get mangaStatusFinished => 'Terminé';

  @override
  String get mangaStatusNotYetPublished => 'Pas encore publié';

  @override
  String get mangaStatusCancelled => 'Annulé';

  @override
  String get mangaStatusHiatus => 'En pause';

  @override
  String get gameModeSinglePlayer => 'Solo';

  @override
  String get gameModeMultiplayer => 'Multijoueur';

  @override
  String get gameModeCoOperative => 'Coopération';

  @override
  String get gameModeSplitScreen => 'Écran partagé';

  @override
  String get gameModeMmo => 'MMO';

  @override
  String get gameModeBattleRoyale => 'Battle Royale';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageJapanese => 'Japonais';

  @override
  String get languageKorean => 'Coréen';

  @override
  String get languageChinese => 'Chinois';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageRussian => 'Russe';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get mangaFormatManhwa => 'Manhwa';

  @override
  String get mangaFormatManhua => 'Manhua';

  @override
  String get mangaFormatOneShot => 'One-shot';

  @override
  String get mangaFormatNovel => 'Roman';

  @override
  String get mangaFormatLightNovel => 'Light Novel';

  @override
  String get browseFilterContentRating => 'Classification du contenu';

  @override
  String get browseFilterDemographic => 'Démographie';

  @override
  String get contentRatingSafe => 'Sûr';

  @override
  String get contentRatingSuggestive => 'Suggestif';

  @override
  String get contentRatingErotica => 'Érotique';

  @override
  String get contentRatingPornographic => 'Pornographique';

  @override
  String get browseSortRelevance => 'Pertinence';

  @override
  String get browseSortPopular => 'Populaire';

  @override
  String get browseSortTopRated => 'Mieux noté';

  @override
  String get browseSortNewest => 'Plus récent';

  @override
  String get browseSortMostVoted => 'Plus de votes';

  @override
  String get browseSortMostRead => 'Plus lu';

  @override
  String get browseSortTrending => 'Tendance';

  @override
  String get browseSortNameAsc => 'Nom (A à Z)';

  @override
  String get browseSortNameDesc => 'Nom (Z à A)';

  @override
  String get browseSortRecentlyUpdated => 'Récemment mis à jour';

  @override
  String get browseSortRecentlyAdded => 'Récemment ajouté';

  @override
  String get browseAnimeTypeSeries => 'Séries';

  @override
  String get browseAnimeTypeMovies => 'Films';

  @override
  String get browseEmptyFilters => 'Choisir un filtre ou rechercher';

  @override
  String get browseBackToBrowse => 'Retour à la navigation';

  @override
  String get browseSortDisabledHint =>
      'Tri impossible pendant la recherche écrite';

  @override
  String get animeStatusAiring => 'En cours de diffusion';

  @override
  String get animeStatusFinished => 'Terminé';

  @override
  String get animeStatusNotYetAired => 'Pas encore diffusé';

  @override
  String get animeStatusCancelled => 'Annulé';

  @override
  String get typeToFilterHint => 'Filtrer...';

  @override
  String get appBarSearchHint => 'Écrivez pour commencer la recherche';

  @override
  String get insertLink => 'Insérer un lien';

  @override
  String get linkText => 'Texte';

  @override
  String get linkHint => 'Guide';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'https://exemple.com';

  @override
  String get markdownBold => 'Gras';

  @override
  String get markdownItalic => 'Italique';

  @override
  String get insert => 'Insérer';

  @override
  String get navTierLists => 'Tier lists';

  @override
  String get tierListCreate => 'Nouvelle tier list';

  @override
  String get tierListCreateFromCollection => 'Créer tier list';

  @override
  String get tierListNameHint => 'Nom de la tier list';

  @override
  String get tierListScopeAll => 'Tous les titres';

  @override
  String get tierListScopeCollection => 'Depuis la collection';

  @override
  String tierListFromCollection(String name) {
    return 'Depuis : $name';
  }

  @override
  String tierListRankedCount(int count) {
    return '$count classés';
  }

  @override
  String get tierListTitle => 'Tier list';

  @override
  String get tierListUnranked => 'Sans classement';

  @override
  String get exportAsImage => 'Exporter en tant qu\'image';

  @override
  String get tierListImageSaved => 'Tier list sauvegardé en tant qu\'image';

  @override
  String get tierListRename => 'Renommer le tier';

  @override
  String get tierListChangeColor => 'Changer la couleur';

  @override
  String get tierListMoveUp => 'Monter';

  @override
  String get tierListMoveDown => 'Descendre';

  @override
  String get tierListDeleteTier => 'Supprimer le tier';

  @override
  String get tierListAddTier => 'Ajouter un tier';

  @override
  String get tierListClearConfirm =>
      'Retirer tous les titres des tiers ? Ils seront alors sans classement.';

  @override
  String get tierListDeleteConfirm => 'Supprimer cette tier list ?';

  @override
  String get tierListEmpty => 'Aucune tier list pour l\'instant';

  @override
  String get tierListEmptyHint =>
      'Cliquez sur + pour créer une tier list\net classez les titres de vos collections.';

  @override
  String get tierListAllRanked => 'Tous les titres sont classés !';

  @override
  String get tierListErrorEmptyName => 'Entrez un nom pour la tier list';

  @override
  String get tierListErrorNoCollection => 'Sélectionnez une collection';

  @override
  String get collectionPickerFilter => 'Filtrer les collections...';

  @override
  String get collectionPickerAlreadyAdded => '✓ ajouté';

  @override
  String collectionPickerAlreadyInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Déjà dans $count collections',
      one: 'Déjà dans $count collection',
    );
    return '$_temp0';
  }

  @override
  String get settingsSteamImport => 'Bibliothèque Steam';

  @override
  String get settingsSteamImportSubtitle =>
      'Importez des jeux via l\'API Web de Steam';

  @override
  String get settingsIgdbImport => 'Liste IGDB';

  @override
  String get settingsIgdbImportSubtitle =>
      'Importez une liste de jeux depuis IGDB (format CSV)';

  @override
  String get igdbImportTitle => 'Importer une liste IGDB';

  @override
  String get igdbImportDescription =>
      'Choisissez une liste CSV téléchargée depuis IGDB. Les jeux se voient attribués un ID par IGDB; ceux qui ne sont plus présents sur le site seront ajoutés à la liste de souhaits.';

  @override
  String get igdbImportSelectCsvFile => 'Sélectionner un fichier CSV';

  @override
  String get igdbImportSelectCsvExport => 'Sélectionner un fichier CSV de IGDB';

  @override
  String get igdbImportStatusLabel => 'Statuts pour les jeux importés';

  @override
  String get igdbImportPlatformSelect => 'Sélectionner une plateforme';

  @override
  String get importIgdbRequired =>
      'Une connexion à IGDB est requise. Paramétrez la clé API dans Paramètres → Identifiants.';

  @override
  String get importing => 'Importation...';

  @override
  String get igdbReasonNotFound => 'Pas trouvé sur IGDB';

  @override
  String get steamImportTitle => 'Importer la Bibliothèque Steam';

  @override
  String get importIgdbMatchNote =>
      'Les jeux seront importés en accordance avec la base de données IGDB';

  @override
  String get steamImportApiKey => 'Clé API Steam';

  @override
  String get steamImportApiKeyHint =>
      'Obtenez une clé API gratuite sur steamcommunity.com/dev/apikey';

  @override
  String get steamImportSteamId => 'ID Steam (64-bit)';

  @override
  String get steamImportSteamIdHint => 'Trouvé sur steamidfinder.com';

  @override
  String get steamImportPublicWarning => 'Votre profil Steam doit être public';

  @override
  String get steamImportButton => 'Importer la Bibliothèque';

  @override
  String get steamImportFetchingLibrary => 'Récupération de la Bibliothèque...';

  @override
  String get steamImportMatching => 'Couplage des jeux avec IGDB...';

  @override
  String steamImportLookingUp(String name) {
    return 'Recherche de : $name';
  }

  @override
  String steamImportImported(int count) {
    return 'Importés : $count';
  }

  @override
  String steamImportWishlisted(int count) {
    return 'Ajoutés à la liste de souhaits : $count';
  }

  @override
  String steamImportUpdated(int count) {
    return 'Mis à jours : $count';
  }

  @override
  String get importComplete => 'Importation terminée !';

  @override
  String steamImportGamesImported(int count) {
    return '$count jeux importés';
  }

  @override
  String steamImportWishlistedInIgdb(int count) {
    return '$count ajoutés à la liste de souhaits';
  }

  @override
  String steamImportUpdatedDuplicates(int count) {
    return '$count mis à jours (déjà présents)';
  }

  @override
  String get steamImportPlayedStatus =>
      'Jeux commencés marqués comme \"En cours\"';

  @override
  String get steamImportPlaytimeComment =>
      'Le temps de jeu sauvegardé dans les commentaires';

  @override
  String get openCollection => 'Ouvrir collection';

  @override
  String get steamImportRememberCredentials => 'Sauvegarder les identifiants';

  @override
  String get collectionListSortCreatedDate => 'Date ajoutée';

  @override
  String get collectionListSortAlphabeticalAZ => 'A à Z';

  @override
  String get collectionListSortAlphabeticalZA => 'Z à A';

  @override
  String get collectionListViewGrid => 'Affichage grille';

  @override
  String get collectionListViewList => 'Affichage liste';

  @override
  String get collectionListViewTable => 'Affichage tableur';

  @override
  String get collectionTableExternalRating => 'Externe';

  @override
  String get collectionCopyToCollection => 'Copier vers la collection';

  @override
  String collectionItemCopiedTo(Object collection, Object name) {
    return '$name copier vers $collection';
  }

  @override
  String collectionItemAlreadyInTarget(Object collection, Object name) {
    return '$name est déjà dans $collection';
  }

  @override
  String get openInCollection => 'Ouvrir dans la collection';

  @override
  String get importResultTitle => 'Résultats d\'importation';

  @override
  String importResultComplete(String source) {
    return 'Importation de $source terminée !';
  }

  @override
  String importResultFailed(String source) {
    return 'Importation de $source échouée';
  }

  @override
  String get importResultImported => 'Importé';

  @override
  String get importResultWishlisted => 'Ajouté à la liste de souhaits';

  @override
  String get importResultUpdated => 'Mis à jour';

  @override
  String importResultErrors(int count) {
    return 'Erreurs ($count)';
  }

  @override
  String get importResultErrorsCopied => 'Erreurs copiées';

  @override
  String importResultSkipped(int count) {
    return '$count omis';
  }

  @override
  String get importResultOpenCollection => 'Ouvrir la collection';

  @override
  String get importResultWishlistHint =>
      'Les titres introuvables dans votre base de données ont été sauvegardés dans votre liste de souhaits.';

  @override
  String get importResultSourceCollectionFile => 'Fichier de collection';

  @override
  String get settingsBrowseCollections => 'Regarder les collections';

  @override
  String get settingsBrowseCollectionsSubtitle =>
      'Télécharger des collections pré-établies';

  @override
  String browseCollectionsSummary(int count, int items) {
    return '$count collections, $items titres';
  }

  @override
  String get browseCollectionsSearch => 'Rechercher des collections...';

  @override
  String get browseCollectionsAllCategories => 'Toutes les catégories';

  @override
  String browseCollectionsItems(int count) {
    return '$count titres';
  }

  @override
  String get browseCollectionsFormatLight => 'Léger (clés API nécessaires)';

  @override
  String get browseCollectionsFormatFull => 'Complet (hors-ligne)';

  @override
  String get browseCollectionsDownloading => 'Téléchargement...';

  @override
  String browseCollectionsImportSuccess(String name) {
    return 'Collection importée : $name';
  }

  @override
  String get browseCollectionsEmpty => 'Aucune collection trouvée';

  @override
  String get browseCollectionsLoadError =>
      'Impossible de charger les collections';

  @override
  String get browseCollectionsImportTarget => 'Importer vers';

  @override
  String get browseCollectionsNewCollection => 'Nouvelle collection';

  @override
  String get browseCollectionsExistingCollection => 'Collection existante';

  @override
  String get noCollectionsYet => 'Aucune collection pour l\'instant';

  @override
  String get settingsRaImport => 'RetroAchievements';

  @override
  String get settingsRaImportSubtitle =>
      'Importer des jeux depuis RetroAchievements';

  @override
  String get raImportTitle => 'Importation RetroAchievements';

  @override
  String get raGetApiKey =>
      'Obtenez votre clé API sur retroachievements.org/controlpanel.php';

  @override
  String get raImportOptionWishlist =>
      'Ajoutez les jeux non listés à votre liste de souhaits';

  @override
  String get raImportFetchingLibrary =>
      'Récupération de la bibliothèque RetroAchievements...';

  @override
  String get raImportSearchingIgdb => 'Recherche des jeux sur IGDB...';

  @override
  String raImportMatching(String title) {
    return 'Correspondance : $title';
  }

  @override
  String raImportAdded(int count) {
    return '$count jeux ajoutés';
  }

  @override
  String raImportUpdated(int count) {
    return '$count jeux mis à jours';
  }

  @override
  String raImportToWishlist(int count) {
    return '$count ajoutés à la liste des souhaits';
  }

  @override
  String raConnectionFailed(String error) {
    return 'Connexion impossible : $error';
  }

  @override
  String raProfilePoints(int points) {
    return '$points points';
  }

  @override
  String raProfileMemberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get raRefresh => 'Rafraîchir les succès';

  @override
  String get raOpenOnRa => 'Ouvrir dans RA ↗';

  @override
  String get raHardcore => 'Hardcore';

  @override
  String get raCompletion => 'Complétion';

  @override
  String get raRecentUnlocks => 'Obtentions récentes';

  @override
  String get raUpNext => 'Suivant';

  @override
  String raViewAll(int count) {
    return 'Voir tous les $count succès →';
  }

  @override
  String get raMastered => 'Maîtrisé';

  @override
  String get raHardcoreMastered => 'Hardcore maîtrisé';

  @override
  String get raBeaten => 'Terminé';

  @override
  String get raBeatenSoftcore => 'Softcore terminé';

  @override
  String get raHardcoreBeaten => 'Hardcore terminé';

  @override
  String get raYesterday => 'Hier';

  @override
  String raDaysAgo(int days) {
    return '$days jours auparavant';
  }

  @override
  String get raPoints => 'pts';

  @override
  String get raAchievements => 'succès';

  @override
  String get raMissable => 'MANQUABLE';

  @override
  String get raFilterEarned => 'Obtenu';

  @override
  String get raFilterLocked => 'Verrouillé';

  @override
  String get raFilterMissable => 'Manquable';

  @override
  String get raFilterProgression => 'Progression';

  @override
  String get raFilterWinCondition => 'Condition de victoire';

  @override
  String get raBeatenProgress => 'Progression (terminé)';

  @override
  String get raStatsAchievements => 'succès';

  @override
  String get raStatsWorth => 'valant';

  @override
  String get raStatsPoints => 'points';

  @override
  String get raStatsUnlocked => 'Déverrouillé';

  @override
  String get copyAsText => 'Copié en tant que texte…';

  @override
  String copiedToClipboard(int count) {
    return 'Copié $count titres dans le presse-papiers';
  }

  @override
  String get template => 'Modèle';

  @override
  String get textExportTokens => 'Tokens';

  @override
  String get textExportSortBy => 'Trier par';

  @override
  String get textExportSortCurrent => 'Ordre actuel';

  @override
  String get textExportSortName => 'Nom (A à Z)';

  @override
  String get textExportSortYear => 'Année ↓';

  @override
  String get textExportSortAdded => 'Date d\'ajout ↓';

  @override
  String get textExportEmptyTemplate => 'Modèle vide';

  @override
  String get filtersClear => 'Effacer';

  @override
  String get collectionTableColumns => 'Colonnes';

  @override
  String get tableFilterHint => 'Les règles de tri s\'appliquent TOUTES (ET).';

  @override
  String get tableFilterAddRule => 'Ajouter règle';

  @override
  String get tableFilterCondContains => 'Contient';

  @override
  String get tableFilterCondEquals => 'Égal à';

  @override
  String get tableFilterCondStartsWith => 'Commence par';

  @override
  String get tableFilterCondEndsWith => 'Termine par';

  @override
  String get tableFilterCondAtLeast => 'Au moins (≥)';

  @override
  String get tableFilterCondAtMost => 'Au plus (≤)';

  @override
  String get profiles => 'Profils';

  @override
  String currentProfile(String name) {
    return 'Actuel : $name';
  }

  @override
  String get switchProfile => 'Changer de profil';

  @override
  String get addProfile => 'Ajouter un profil';

  @override
  String get createProfile => 'Créer un profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get deleteProfile => 'Supprimer le profil';

  @override
  String deleteProfileConfirm(String name) {
    return 'Supprimer le profil $name? Cela supprimera toutes les collections, la liste de souhaits et les paramètres. La suppression est définitive.';
  }

  @override
  String get cannotDeleteLastProfile =>
      'Impossible de supprimer le dernier profil';

  @override
  String get profileName => 'Nom';

  @override
  String get whoIsPlayingToday => 'Qui joue aujourd\'hui ?';

  @override
  String get dontAskAgain => 'Ne pas demander de nouveau';

  @override
  String profileStats(int collections, int items) {
    return '$collections collections, $items titres';
  }

  @override
  String get switchingProfile => 'Changement de profil…';

  @override
  String get appWillRestart =>
      'L\'application va redémarrer pour appliquer les changements.';

  @override
  String get profileCreated => 'Profil créé';

  @override
  String get profileDeleted => 'Profil supprimé';

  @override
  String get settingsIntegrations => 'Intégrations';

  @override
  String get settingsKodiSubtitle =>
      'Synchronisation vidéo depuis le lecteur média Kodi';

  @override
  String get settingsOn => 'Marche';

  @override
  String get kodiConnectionTitle => 'Connexion';

  @override
  String get kodiConnectionSubtitle =>
      'Kodi HTTP JSON-RPC (Paramètres → Services → Control)';

  @override
  String get kodiHost => 'Hôte';

  @override
  String get kodiPort => 'Port';

  @override
  String get kodiPassword => 'Mot de passe';

  @override
  String get kodiPasswordHint => 'Entrez le mot de passe';

  @override
  String get kodiTestConnection => 'Test de connexion';

  @override
  String get kodiConnecting => 'Connexion…';

  @override
  String get kodiPingFailed => 'Échec du ping — réponse inattendue';

  @override
  String kodiConnectedTo(String version, String name) {
    return 'Kodi $version \"$name\"';
  }

  @override
  String get kodiSyncTitle => 'Synchronisation';

  @override
  String get kodiTargetCollectionSubtitle =>
      'Tous les films de Kodi se synchronisent ici';

  @override
  String get kodiTargetNotSelected => 'Aucune sélection';

  @override
  String kodiTargetDeletedLabel(int id) {
    return 'Supprimé (#$id)';
  }

  @override
  String get kodiEnableSync => 'Activer la synchronisation Kodi';

  @override
  String get kodiEnableSyncActiveSubtitle =>
      'Actif tant que Tonkatsu est ouvert';

  @override
  String get kodiEnableSyncDisabledSubtitle =>
      'Sélectionnez d\'abord une collection';

  @override
  String get kodiSyncInterval => 'Interval de synchronisation';

  @override
  String get kodiCreateSubCollections =>
      'Créer des sous-collections importées de Kodi';

  @override
  String get kodiCreateSubCollectionsSubtitle =>
      'ex : \"Collection Harry Potter (kodi)\"';

  @override
  String get kodiImportRatings => 'Importer les notes depuis Kodi';

  @override
  String get kodiImportRatingsSubtitle =>
      'Copier les notes utilisateurs de Kodi (1-10)';

  @override
  String get kodiCollectionLibraryName => 'Bibliothèque Kodi';

  @override
  String kodiCollectionCreated(String name) {
    return 'Créé \"$name\"';
  }

  @override
  String get kodiTargetDeletedSnack =>
      'La collection a été supprimée — synchronisation arrêtée';

  @override
  String get kodiSyncStatus => 'Statut de synchronisation';

  @override
  String get kodiSyncRunning => 'En cours';

  @override
  String get kodiSyncStopped => 'Arrêtée';

  @override
  String get kodiLastSyncNever => 'Jamais';

  @override
  String get kodiClearLastSync =>
      'Effacer les horodatages de la dernière synchronisation';

  @override
  String get kodiClearLastSyncSubtitle =>
      'La prochaine synchronisation récupérera tous les titres regardés';

  @override
  String get kodiLastSyncCleared =>
      'Horodatages de la dernière synchronisation effacés';

  @override
  String kodiRequestLog(int count) {
    return 'Journal de requêtes : ($count)';
  }

  @override
  String get kodiCopyLog => 'Copier le journal';

  @override
  String get kodiLogCopied => 'Journal copié';

  @override
  String get kodiClearLog => 'Effacer le journal';

  @override
  String get kodiNoRequests => 'Aucune requête pour l\'instant';

  @override
  String get kodiRawJsonRpc => 'JSON-RPC brut';

  @override
  String get kodiMethod => 'Méthode';

  @override
  String get kodiParams => 'Paramètres (JSON)';

  @override
  String get kodiSend => 'Envoyer';

  @override
  String get kodiCopyToClipboard => 'Copier vers le presse-papiers';

  @override
  String get kodiCopiedToClipboard => 'Copié vers le presse-papiers';

  @override
  String get kodiParamsNotObject =>
      'Erreur : les paramètres doivent être un objet JSON';

  @override
  String kodiJsonParseError(String message) {
    return 'Erreur d\'analyse JSON (parse error) : $message';
  }

  @override
  String kodiRawError(String message) {
    return 'Erreur : $message';
  }

  @override
  String get settingsMalImport => 'MyAnimeList';

  @override
  String get settingsMalImportSubtitle =>
      'Importez des animes/mangas depuis un fichier XML';

  @override
  String get malImportTitle => 'Importation MyAnimeList';

  @override
  String get malImportSubtitle =>
      'Les animes et mangas importés seront identiques à ceux listés chez AniList';

  @override
  String get malImportPickFiles => 'Ajouter fichier XML';

  @override
  String get malImportFilesHint =>
      'Exporter fichier XML depuis myanimelist.net/panel.php?go=export';

  @override
  String get importAnimeList => 'Liste d\'animes';

  @override
  String get importMangaList => 'Liste de mangas';

  @override
  String malImportEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
    );
    return '$_temp0';
  }

  @override
  String get malImportReadingFiles => 'Lecture des fichiers...';

  @override
  String get malImportResolvingAnime => 'Vérification des animes sur AniList';

  @override
  String get malImportResolvingManga => 'Vérification des mangas sur AniList';

  @override
  String malImportWishlisted(int count) {
    return '$count ajoutés à la liste de souhaits';
  }

  @override
  String get malImportOverwriteExisting =>
      'Écraser les entrées déjà existantes';

  @override
  String get malImportOverwriteExistingHint =>
      'Si désactivé, les titres déjà présents dans la collection gardent leurs statut, note, progression, dates et commentaires. Les nouveaux titres sont tout de même importés.';

  @override
  String malImportFailedLookup(int count) {
    return '$count omis (AniList injoignable)';
  }

  @override
  String malImportRateLimitWait(int seconds, int attempt, int max) {
    return 'Limite de débit d\'AniList atteinte — nouvelle tentative dans ${seconds}s (tentative $attempt/$max)';
  }

  @override
  String malImportInvalidFile(String error) {
    return 'Impossible d\'analyser le fichier XML : $error';
  }

  @override
  String malImportFilePicked(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
    );
    return 'Choisi : $kind ($_temp0)';
  }

  @override
  String get settingsAniListImport => 'AniList';

  @override
  String get settingsAniListImportSubtitle =>
      'Importez des listes d\'animes/mangas via un nom d\'utilisateur publique';

  @override
  String get settingsHardcoverImportSubtitle =>
      'Importez une bibliothèque depuis hardcover.app via un nom d\'utilisateur';

  @override
  String get hardcoverImportTitle => 'Importation Hardcover';

  @override
  String get hardcoverImportSubtitle =>
      'Récupère la bibliothèque d\'un utilisateur depuis hardcover.app — seules les données publiques seront visibles par les autres utilisateurs.';

  @override
  String get hardcoverImportTokenMissing =>
      'Le token API Hardcover n\'est pas configuré. Ajoutez-le dans Paramètres → Identifiants.';

  @override
  String get aniListImportTitle => 'Importation AniList';

  @override
  String get aniListImportSubtitle =>
      'Récupère des listes publiques depuis anilist.co — aucune connexion requise';

  @override
  String get aniListImportUsername => 'Nom d\'utilisateur AniList';

  @override
  String get aniListImportInclude => 'Ce que vous pouvez importer';

  @override
  String get aniListImportModeOverwriteSubtitle =>
      'Mettez à jour la progression, le statut et les dates de vos titres depuis AniList';

  @override
  String aniListImportNewCollectionDefault(String username) {
    return 'Importation AniList — $username';
  }

  @override
  String get aniListImportFetchingAnime =>
      'Récupération de la liste d\'animes...';

  @override
  String get aniListImportFetchingManga =>
      'Récupération de la liste de mangas...';

  @override
  String aniListImportUserNotFound(String username) {
    return 'L\'utilisateur \"$username\" n\'a pas été trouvé sur AniList';
  }

  @override
  String aniListImportPrivateProfile(String username) {
    return 'Le profil de \"$username\" sur AniList est privé';
  }

  @override
  String get aniListImportEmptyUsername =>
      'Entrez votre nom d\'utilisateur AniList';

  @override
  String get aniListImportSelectAtLeastOne =>
      'Sélectionnez les animes ou mangas à importer';

  @override
  String get settingsCustomCardsImport => 'Cartes personnalisées';

  @override
  String get settingsCustomCardsImportSubtitle =>
      'Importez des cartes depuis un fichier JSON ou CSV';

  @override
  String get customImportTitle => 'Importer des cartes personnalisées';

  @override
  String get customImportDescription =>
      'Chargez un fichier JSON ou CSV généré par votre propre script ou parser — chaque rangée devient une carte personnalisée. Téléchargez un modèle pour voir tous les champs et les valeurs supportés.';

  @override
  String get customImportSelectFile => 'Sélectionner un fichier JSON/CSV';

  @override
  String get customImportCsvTemplate => 'Modèle CSV';

  @override
  String get customImportJsonTemplate => 'Modèle JSON';

  @override
  String get customImportTemplateSaved => 'Modèle sauvegardé';

  @override
  String get customImportPreviewButton => 'Aperçu et importer';

  @override
  String get customImportPreviewTitle => 'Aperçu de l\'importation';

  @override
  String customImportSummary(int valid, int errors, int duplicates) {
    return 'Reconnus $valid · Erreurs $errors · Doublons $duplicates';
  }

  @override
  String get customImportSelectNone => 'Tout déselectionner';

  @override
  String customImportSelectedCount(int selected, int total) {
    return '$selected sélectionné sur $total';
  }

  @override
  String get customImportDuplicate => 'Doublon — déjà dans la collection';

  @override
  String customImportRowLabel(int index) {
    return 'Rangée $index';
  }

  @override
  String get customImportStart => 'Importer la selection';

  @override
  String get customImportImporting =>
      'Importation des cartes personnalisées...';

  @override
  String get customImportErrorEmptyFile => 'Le fichier est vide';

  @override
  String get customImportErrorInvalidJson =>
      'JSON invalide — le fichier n\'a pas pu être analysé';

  @override
  String get customImportErrorMissingColumns =>
      'Le fichier CSV doit contenir des colonnes \"title\" et \"type\"';

  @override
  String get customImportIssueNotAnObject => 'Pas un objet JSON';

  @override
  String get customImportIssueMissingTitle => '\"title\" manquant';

  @override
  String get customImportIssueMissingType => '\"type\" manquant';

  @override
  String customImportIssueUnknownType(String value) {
    return 'Type inconnu : $value';
  }

  @override
  String customImportIssueInvalidNumber(String field, String value) {
    return 'Valeur invalide dans \"$field\": $value';
  }

  @override
  String customImportIssueUnknownStatus(String value) {
    return 'Statut inconnu : $value';
  }

  @override
  String customImportIssueUnknownFormat(String value) {
    return 'Format inconnu : $value';
  }

  @override
  String get customImportIssueFormatNotApplicable =>
      '\"format\" est utilisé seulement par les animes et les mangas';

  @override
  String get customImportIssueInvalidCover =>
      '\"cover\" doit être une URL http(s)';

  @override
  String customImportIssueInvalidDate(String field, String value) {
    return 'Date invalide dans \"$field\": $value (format YYYY-MM-DD attendu)';
  }

  @override
  String customImportIssueInvalidBool(String value) {
    return '\"favorite\" doit être vrai/faux : $value';
  }

  @override
  String get moodGridCreate => 'Créer une grille d\'humeur';

  @override
  String get moodGridCreateTitle => 'Nouvelle grille d\'humeur';

  @override
  String get moodGridPresetAboutMe => 'À propos de moi : Tonkatsu Box';

  @override
  String get moodGridPresetAboutMeSubtitle =>
      '1×5 — jeu, film, série, anime et manga favoris';

  @override
  String get moodGridPresetBlank => 'Vide';

  @override
  String get moodGridPresetBlankSubtitle =>
      'Une grille vide avec la taille de votre choix';

  @override
  String get moodGridRows => 'Rangées';

  @override
  String get moodGridBadge => 'Grille d\'humeur';

  @override
  String get moodGridDeleteTitle => 'Supprimer cette grille ?';

  @override
  String get moodGridDeleteMessage =>
      'Cette grille sera supprimée. La suppression est définitive.';

  @override
  String get moodGridAddRow => 'Ajouter une rangée';

  @override
  String get moodGridRemoveRow => 'Retirer une rangée';

  @override
  String get moodGridAddCol => 'Ajouter une colonne';

  @override
  String get moodGridRemoveCol => 'Retirer une colonne';

  @override
  String get moodGridShrinkTitle => 'Rétrécir la grille ?';

  @override
  String get moodGridShrinkMessage =>
      'Les cellules en dehors des nouvelles limites seront supprimées.';

  @override
  String get moodGridShrinkConfirm => 'Rétrécir';

  @override
  String get moodGridEditLabel => 'Modifier l\'étiquette';

  @override
  String get moodGridLabelHint => 'Nom de catégorie';

  @override
  String get moodGridPickItem => 'Sélectionner un titre';

  @override
  String get moodGridReplaceItem => 'Remplacer le titre';

  @override
  String get moodGridClearItem => 'Effacer le titre';

  @override
  String get moodGridCaptionTemplate => 'Légendes de rangée';

  @override
  String get moodGridCaptionTemplateHint =>
      'Modèle appliqué à chaque cellule. Utilisable : nom, année, genre, note.';

  @override
  String get moodGridCellLabelTemplate => 'Étiquettes de la cellule';

  @override
  String get moodGridCellSize => 'Taille';

  @override
  String get collection => 'Collection';

  @override
  String get moodGridPickerAllCollections => 'Toutes les collections';

  @override
  String get moodGridPickerSearchHint => 'Rechercher par nom';

  @override
  String get moodGridPickerEmpty => 'Rien à sélectionner';

  @override
  String get screenScraperSection => 'API ScreenScraper';

  @override
  String get screenScraperSourceDesc =>
      'Métadonnées de jeux + médias (jacquettes, captures d\'écran, illustrations)';

  @override
  String get screenScraperUserCredsHint =>
      'Identifiants utilisateur (ssid / sspassword). Un quota est attribué à chaque utilisateur.';

  @override
  String get screenScraperSsidLabel => 'ssid';

  @override
  String get screenScraperSsidPlaceholder => 'Votre identifiant ScreenScraper';

  @override
  String get screenScraperSspasswordLabel => 'sspassword';

  @override
  String get screenScraperSspasswordPlaceholder =>
      'Votre mot de passe ScreenScraper';

  @override
  String get screenScraperCheckQuota => 'Vérifier le quota';

  @override
  String get screenScraperRequestsToday => 'Nombre de requêtes ce jour';

  @override
  String get screenScraperPerMinLimit => 'Limite par minute';

  @override
  String get screenScraperParallelThreads => 'Threads parallèles';

  @override
  String get screenScraperAccountLevel => 'Niveau du compte';

  @override
  String get screenScraperGalleryTitle => 'Médias ScreenScraper';

  @override
  String get screenScraperScreenshotsTitle => 'Captures d\'écran';

  @override
  String get screenScraperLoading => 'Chargement des médias ScreenScraper…';

  @override
  String screenScraperError(String message) {
    return 'Erreur ScreenScraper : $message';
  }

  @override
  String get screenScraperMediaBox => 'Boîte';

  @override
  String get screenScraperMediaBoxBack => 'Boîte (noire)';

  @override
  String get screenScraperMediaBox3D => 'Boîte 3D';

  @override
  String get screenScraperMediaWheel => 'Roue';

  @override
  String get screenScraperMediaMarquee => 'Marquee';

  @override
  String get screenScraperMediaTitle => 'Titre';

  @override
  String get screenScraperMediaScreenshot => 'Capture d\'écran';

  @override
  String get screenScraperMediaFanart => 'Fanart';

  @override
  String get screenScraperMediaMix => 'Mix';

  @override
  String get genreCloudTitle => 'Personnalisation';

  @override
  String get genreCloudEmpty => 'Aucun genre pour l\'instant';

  @override
  String get genreCloudEmptyHint =>
      'Ajoutez des titres avec des genres pour créer un cloud';

  @override
  String get genreCloudExportImage => 'Sauvegarder en tant qu\'image';

  @override
  String get genreCloudExportFailed => 'Impossible de sauvegarder l\'image';

  @override
  String get genreCloudResetView => 'Recentrer';

  @override
  String genreCloudHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cachés (ne correspondaient pas)',
      one: '1 caché (ne correspondait pas)',
    );
    return '$_temp0';
  }

  @override
  String get facetPlatform => 'Plateformes';

  @override
  String get facetDecade => 'Décennies';

  @override
  String get personalizationTabCloud => 'Cloud';

  @override
  String get recommendationsEmpty => 'Aucune recommandation pour l\'instant';

  @override
  String get recommendationsEmptyHint =>
      'Terminez et notez quelques films ou séries pour obtenir des recommandations';

  @override
  String get recommendationsNoCandidates => 'Aucune nouvelle suggestion';

  @override
  String get recommendationsNoCandidatesHint =>
      'Nous n\'avons rien trouvé de nouveau à vous suggérer. Réessayez plus tard !';

  @override
  String get recommendationsNoApiKey => 'Clé API TMDB requise';

  @override
  String get recommendationsNoApiKeyHint =>
      'Ajoutez votre clé API TMDB dans Paramètres pour obtenir des recommandations';

  @override
  String get recommendationsBecauseLabel => 'Parce que vous avez aimé';

  @override
  String recommendationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recommandations',
      one: '1 recommandation',
    );
    return '$_temp0';
  }

  @override
  String get itemMarkLike => 'J\'aime';

  @override
  String get itemMarkNote => 'Commentaire';

  @override
  String get itemMarkNoteHint => 'Écrire un commentaire…';

  @override
  String get itemMarkSectionTitle => 'Commentaires et mentions J\'aime';

  @override
  String get itemMarkAdd => 'Ajouter un signe';

  @override
  String get itemMarkEmpty => 'Aucun signe pour l\'instant';

  @override
  String get itemMarkNumber => 'Nombre';

  @override
  String get itemMarkNumberHint => 'ex : 12';

  @override
  String get itemMarkNumberHelper => 'Requis pour sauvegarder';

  @override
  String get itemMarkCustomType => 'Type personnalisé';

  @override
  String get itemMarkFilterLiked => 'J\'aime';

  @override
  String get itemMarkFilterCommented => 'Avec commentaires';

  @override
  String itemMarkUnitLabel(String type, int number) {
    return '$type $number';
  }

  @override
  String itemMarkEpisodeShort(int season, int episode) {
    return 'S$season·E$episode';
  }

  @override
  String get unitEpisode => 'Épisode';

  @override
  String get unitSeason => 'Saison';

  @override
  String get unitChapter => 'Chapitre';

  @override
  String get unitVolume => 'Tome';

  @override
  String get unitPage => 'Page';

  @override
  String get unitPart => 'Partie';

  @override
  String get cardLinkCopy => 'Copier le lien de la carte';

  @override
  String get cardLinkCopied => 'Lien de la carte copié';

  @override
  String get cardLinkNotFound => 'Carte introuvable';

  @override
  String get cardLinkSearchTitle => 'Partager une carte';

  @override
  String get cardLinkSearchHint => 'Rechercher des cartes';

  @override
  String get shortcutsDialogTitle => 'Raccourcis clavier';

  @override
  String get shortcutsGroupNavigation => 'Navigation';

  @override
  String get shortcutSwitchTab => 'Changer d\'onglet';

  @override
  String get shortcutNextTab => 'Onglet suivant';

  @override
  String get shortcutPreviousTab => 'Onglet précédent';

  @override
  String get shortcutThisHelp => 'Peut aider';

  @override
  String get shortcutCreateCollection => 'Créer une collection';

  @override
  String get shortcutImportCollection => 'Importer une collection';

  @override
  String get shortcutToggleView => 'Alterner affichage';

  @override
  String get shortcutDeleteCollection => 'Supprimer la collection';

  @override
  String get shortcutRenameCollection => 'Renommer la collection';

  @override
  String get shortcutAddItems => 'Ajouter des titres';

  @override
  String get shortcutExportCollection => 'Exporter la collection';

  @override
  String get shortcutImportIntoCollection => 'Importer dans la collection';

  @override
  String get shortcutToggleBoard => 'Alterner Tableau/Canvas';

  @override
  String get shortcutDeleteItem => 'Supprimer le titre';

  @override
  String get shortcutMoveItem => 'Déplacer le titre';

  @override
  String get shortcutsGroupItemDetail => 'Détails du titre';

  @override
  String get shortcutLockCanvas => 'Vérrouiller/dévérrouiller le tableau';

  @override
  String get shortcutMoveToCollection => 'Déplacer vers la collection';

  @override
  String get shortcutSetRating => 'Noter';

  @override
  String get shortcutResetRating => 'Réinitialiser la note';

  @override
  String get shortcutsGroupTierLists => 'Tier lists';

  @override
  String get shortcutCreateTierList => 'Créer une tier list';

  @override
  String get shortcutOpenTierList => 'Ouvrir tier list';

  @override
  String get shortcutDeleteTierList => 'Supprimer la tier list';

  @override
  String get shortcutsGroupTierList => 'Tier list';

  @override
  String get shortcutAddItem => 'Ajouter un titre';

  @override
  String get shortcutToggleCompleted => 'Montrer/cacher complétés';

  @override
  String get shortcutClearCompleted => 'Effacer complétés';

  @override
  String get shortcutFocusSearchField => 'Focus sur la barre de recherche';

  @override
  String get shortcutClearOrBack => 'Effacer / précédent';

  @override
  String get shortcutRunSearch => 'Lancer la recherche';

  @override
  String get debugKeyEvents => 'Événements des touches/boutons';

  @override
  String get settingsGamepadDebugSubtitle =>
      'Enregistrer les codes des boutons de la manette';
}

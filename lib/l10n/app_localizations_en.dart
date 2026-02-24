// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => 'Main';

  @override
  String get navCollections => 'Collections';

  @override
  String get navWishlist => 'Wishlist';

  @override
  String get navSearch => 'Search';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusNotStarted => 'Not Started';

  @override
  String get statusPlaying => 'Playing';

  @override
  String get statusWatching => 'Watching';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusOnHold => 'On Hold';

  @override
  String get mediaTypeGame => 'Game';

  @override
  String get mediaTypeMovie => 'Movie';

  @override
  String get mediaTypeTvShow => 'TV Show';

  @override
  String get mediaTypeAnimation => 'Animation';

  @override
  String get sortManualDisplay => 'Manual';

  @override
  String get sortManualShort => 'Manual';

  @override
  String get sortManualDesc => 'Custom order';

  @override
  String get sortDateDisplay => 'Date Added';

  @override
  String get sortDateShort => 'Date';

  @override
  String get sortDateDesc => 'Newest first';

  @override
  String get sortStatusDisplay => 'Status';

  @override
  String get sortStatusShort => 'Status';

  @override
  String get sortStatusDesc => 'Active first';

  @override
  String get sortNameDisplay => 'Name';

  @override
  String get sortNameShort => 'A-Z';

  @override
  String get sortNameDesc => 'A to Z';

  @override
  String get sortRatingDisplay => 'My Rating';

  @override
  String get sortRatingShort => 'Rating';

  @override
  String get sortRatingDesc => 'Highest first';

  @override
  String get searchSortRelevanceShort => 'Rel';

  @override
  String get searchSortRelevanceDisplay => 'Relevance';

  @override
  String get searchSortDateShort => 'Date';

  @override
  String get searchSortDateDisplay => 'Date';

  @override
  String get searchSortRatingShort => 'Rate';

  @override
  String get searchSortRatingDisplay => 'Rating';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get retry => 'Retry';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get search => 'Search';

  @override
  String get open => 'Open';

  @override
  String get remove => 'Remove';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get update => 'Update';

  @override
  String get test => 'Test';

  @override
  String get close => 'Close';

  @override
  String get keep => 'Keep';

  @override
  String get change => 'Change';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAuthorName => 'Author name';

  @override
  String get settingsSettings => 'Settings';

  @override
  String get settingsCredentials => 'Credentials';

  @override
  String get settingsCredentialsSubtitle => 'IGDB, SteamGridDB, TMDB API keys';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsCacheSubtitle => 'Image cache settings';

  @override
  String get settingsDatabase => 'Database';

  @override
  String get settingsDatabaseSubtitle => 'Export, import, reset';

  @override
  String get settingsTraktImport => 'Trakt Import';

  @override
  String get settingsTraktImportSubtitle => 'Import from Trakt.tv ZIP export';

  @override
  String get settingsDebug => 'Debug';

  @override
  String get settingsDebugSubtitle => 'Developer tools';

  @override
  String get settingsDebugSubtitleNoKey =>
      'Set SteamGridDB key first for some tools';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsWelcomeGuide => 'Welcome Guide';

  @override
  String get settingsWelcomeGuideSubtitle =>
      'Getting started with Tonkatsu Box';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsCreditsLicenses => 'Credits & Licenses';

  @override
  String get settingsCreditsLicensesSubtitle =>
      'TMDB, IGDB, SteamGridDB, open-source licenses';

  @override
  String get settingsError => 'Error';

  @override
  String get settingsAppLanguage => 'App Language';

  @override
  String get credentialsTitle => 'Credentials';

  @override
  String get credentialsWelcome => 'Welcome to Tonkatsu Box!';

  @override
  String get credentialsWelcomeHint =>
      'To get started, you need to set up your IGDB API credentials. Get your Client ID and Client Secret from the Twitch Developer Console.';

  @override
  String get credentialsCopyTwitchUrl => 'Copy Twitch Console URL';

  @override
  String credentialsUrlCopied(String url) {
    return 'URL copied: $url';
  }

  @override
  String get credentialsIgdbSection => 'IGDB API Credentials';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Enter your Twitch Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Enter your Twitch Client Secret';

  @override
  String get credentialsConnectionStatus => 'Connection Status';

  @override
  String get credentialsPlatformsSynced => 'Platforms synced';

  @override
  String get credentialsLastSync => 'Last sync';

  @override
  String get credentialsVerifyConnection => 'Verify Connection';

  @override
  String get credentialsRefreshPlatforms => 'Refresh Platforms';

  @override
  String get credentialsSteamGridDbSection => 'SteamGridDB API';

  @override
  String get credentialsApiKey => 'API Key';

  @override
  String get credentialsUsingBuiltInKey => 'Using built-in key';

  @override
  String get credentialsEnterSteamGridDbKey => 'Enter your SteamGridDB API key';

  @override
  String get credentialsTmdbSection => 'TMDB API (Movies & TV)';

  @override
  String get credentialsEnterTmdbKey => 'Enter your TMDB API key (v3)';

  @override
  String get credentialsContentLanguage => 'Content Language';

  @override
  String get credentialsOwnKeyHint =>
      'For better rate limits we recommend using your own API key.';

  @override
  String get credentialsConnected => 'Connected';

  @override
  String get credentialsConnectionError => 'Connection Error';

  @override
  String get credentialsChecking => 'Checking...';

  @override
  String get credentialsNotConnected => 'Not Connected';

  @override
  String get credentialsEnterBoth =>
      'Please enter both Client ID and Client Secret';

  @override
  String get credentialsConnectedSynced => 'Connected & platforms synced!';

  @override
  String get credentialsConnectedSyncFailed =>
      'Connected, but platform sync failed';

  @override
  String get credentialsPlatformsSyncedOk => 'Platforms synced successfully!';

  @override
  String get credentialsDownloadingLogos => 'Downloading platform logos...';

  @override
  String credentialsDownloadedLogos(int count) {
    return 'Downloaded $count logos';
  }

  @override
  String get credentialsFailedDownloadLogos => 'Failed to download logos';

  @override
  String get credentialsApiKeySaved => 'API key saved';

  @override
  String get credentialsNoApiKey => 'No API key';

  @override
  String get credentialsResetToBuiltIn => 'Reset to built-in key';

  @override
  String get credentialsSteamGridDbKeyValid => 'SteamGridDB API key is valid';

  @override
  String get credentialsSteamGridDbKeyInvalid =>
      'SteamGridDB API key is invalid';

  @override
  String get credentialsTmdbKeyValid => 'TMDB API key is valid';

  @override
  String get credentialsTmdbKeyInvalid => 'TMDB API key is invalid';

  @override
  String get credentialsEnterSteamGridDbKeyError =>
      'Please enter a SteamGridDB API key';

  @override
  String get credentialsEnterTmdbKeyError => 'Please enter a TMDB API key';

  @override
  String get credentialsTmdbKeySaved => 'TMDB API key saved';

  @override
  String timeAgo(int value, String unit) {
    return '$value $unit ago';
  }

  @override
  String timeUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String timeUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
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
  String get timeJustNow => 'Just now';

  @override
  String get cacheTitle => 'Cache';

  @override
  String get cacheImageCache => 'Image Cache';

  @override
  String get cacheOfflineMode => 'Offline mode';

  @override
  String get cacheOfflineModeSubtitle => 'Save images locally for offline use';

  @override
  String get cacheCacheFolder => 'Cache folder';

  @override
  String get cacheSelectFolder => 'Select folder';

  @override
  String get cacheCacheSize => 'Cache size';

  @override
  String get cacheClearCache => 'Clear cache';

  @override
  String get cacheClearCacheTitle => 'Clear cache?';

  @override
  String get cacheClearCacheMessage =>
      'This will delete all locally saved images. They will be downloaded again during the next sync.';

  @override
  String get cacheFolderUpdated => 'Cache folder updated';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get cacheSelectFolderDialog => 'Select cache folder for images';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count files, $size';
  }

  @override
  String get databaseTitle => 'Database';

  @override
  String get databaseConfiguration => 'Configuration';

  @override
  String get databaseConfigSubtitle =>
      'Export or import your API keys and settings.';

  @override
  String get databaseExportConfig => 'Export Config';

  @override
  String get databaseImportConfig => 'Import Config';

  @override
  String get databaseDangerZone => 'Danger Zone';

  @override
  String get databaseDangerZoneMessage =>
      'Clears all collections, games, movies, TV shows and board data. Settings and API keys will be preserved.';

  @override
  String get databaseResetDatabase => 'Reset Database';

  @override
  String get databaseResetTitle => 'Reset Database?';

  @override
  String get databaseResetMessage =>
      'This will permanently delete all your collections, games, movies, TV shows, episode progress, and board data.\n\nYour API keys and settings will be preserved.\n\nThis action cannot be undone.';

  @override
  String databaseConfigExported(String path) {
    return 'Config exported to $path';
  }

  @override
  String get databaseConfigImported => 'Config imported successfully';

  @override
  String get databaseReset => 'Database has been reset';

  @override
  String get traktTitle => 'Trakt Import';

  @override
  String get traktImportFrom => 'Import from Trakt.tv';

  @override
  String get traktImportDescription =>
      'Download your data from trakt.tv/users/YOU/data and select the ZIP file below.';

  @override
  String get traktZipFile => 'ZIP File';

  @override
  String get traktSelectZipFile => 'Select ZIP File';

  @override
  String get traktSelectZipExport => 'Select Trakt ZIP Export';

  @override
  String get traktPreview => 'Preview';

  @override
  String traktUser(String username) {
    return 'Trakt user: $username';
  }

  @override
  String get traktWatchedMovies => 'Watched movies';

  @override
  String get traktWatchedShows => 'Watched shows';

  @override
  String get traktRatedMovies => 'Rated movies';

  @override
  String get traktRatedShows => 'Rated shows';

  @override
  String get traktWatchlist => 'Watchlist';

  @override
  String get traktOptions => 'Options';

  @override
  String get traktImportWatched => 'Import watched items';

  @override
  String get traktImportWatchedDesc => 'Movies and TV shows as completed';

  @override
  String get traktImportRatings => 'Import ratings';

  @override
  String get traktImportRatingsDesc => 'Apply user ratings (1-10)';

  @override
  String get traktImportWatchlist => 'Import watchlist';

  @override
  String get traktImportWatchlistDesc => 'Add as planned or to wishlist';

  @override
  String get traktTargetCollection => 'Target collection';

  @override
  String get traktCreateNew => 'Create new collection';

  @override
  String get traktUseExisting => 'Use existing collection';

  @override
  String get traktNoCollections => 'No collections available';

  @override
  String get traktSelectCollection => 'Select collection';

  @override
  String get traktErrorLoadingCollections => 'Error loading collections';

  @override
  String get traktStartImport => 'Start Import';

  @override
  String get traktInvalidExport => 'Invalid Trakt export';

  @override
  String traktImportedItems(int count) {
    return 'Imported $count items';
  }

  @override
  String get traktImporting => 'Importing from Trakt';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get creditsDataProviders => 'Data Providers';

  @override
  String get creditsTmdbAttribution =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get creditsIgdbAttribution => 'Game data provided by IGDB.';

  @override
  String get creditsSteamGridDbAttribution =>
      'Artwork provided by SteamGridDB.';

  @override
  String get creditsOpenSource => 'Open Source';

  @override
  String get creditsOpenSourceDesc =>
      'Tonkatsu Box is free and open source software, released under the MIT License.';

  @override
  String get creditsViewLicenses => 'View Open Source Licenses';

  @override
  String get collectionsNewCollection => 'New Collection';

  @override
  String get collectionsImportCollection => 'Import Collection';

  @override
  String get collectionsNoCollectionsYet => 'No Collections Yet';

  @override
  String get collectionsNoCollectionsHint =>
      'Create your first collection to start tracking\nyour gaming journey.';

  @override
  String get collectionsFailedToLoad => 'Failed to load collections';

  @override
  String collectionsCount(int count) {
    return 'Collections ($count)';
  }

  @override
  String get collectionsUncategorized => 'Uncategorized';

  @override
  String collectionsUncategorizedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get collectionsRenamed => 'Collection renamed';

  @override
  String collectionsFailedToRename(String error) {
    return 'Failed to rename: $error';
  }

  @override
  String get collectionsDeleted => 'Collection deleted';

  @override
  String collectionsFailedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return 'Failed to create collection: $error';
  }

  @override
  String collectionsImported(String name, int count) {
    return 'Imported \"$name\" with $count items';
  }

  @override
  String get collectionsImporting => 'Importing Collection';

  @override
  String get collectionNotFound => 'Collection not found';

  @override
  String get collectionAddItems => 'Add Items';

  @override
  String get collectionSwitchToList => 'Switch to List';

  @override
  String get collectionSwitchToBoard => 'Switch to Board';

  @override
  String get collectionUnlockBoard => 'Unlock board';

  @override
  String get collectionLockBoard => 'Lock board';

  @override
  String get collectionExport => 'Export';

  @override
  String get collectionNoItemsYet => 'No Items Yet';

  @override
  String get collectionEmpty => 'Empty Collection';

  @override
  String get collectionDeleteEmptyPrompt =>
      'This collection is now empty. Delete it?';

  @override
  String get collectionRemoveItemTitle => 'Remove Item?';

  @override
  String collectionRemoveItemMessage(String name) {
    return 'Remove $name from this collection?';
  }

  @override
  String get collectionMoveToCollection => 'Move to Collection';

  @override
  String get collectionExportFormat => 'Export Format';

  @override
  String get collectionChooseExportFormat => 'Choose export format:';

  @override
  String get collectionExportLight => 'Light (.xcoll)';

  @override
  String get collectionExportLightDesc => 'Items only, smaller file';

  @override
  String get collectionExportFull => 'Full (.xcollx)';

  @override
  String get collectionExportFullDesc => 'With images & canvas — works offline';

  @override
  String get collectionFilterAll => 'All';

  @override
  String get collectionFilterByType => 'Filter by type';

  @override
  String get collectionFilterGames => 'Games';

  @override
  String get collectionFilterMovies => 'Movies';

  @override
  String get collectionFilterTvShows => 'TV Shows';

  @override
  String get collectionFilterAnimation => 'Animation';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name moved to $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name already exists in $collection';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name removed';
  }

  @override
  String get detailsTab => 'Details';

  @override
  String get boardTab => 'Board';

  @override
  String get imageAddedToBoard => 'Image added to board';

  @override
  String get mapAddedToBoard => 'Map added to board';

  @override
  String get loading => 'Loading...';

  @override
  String get gameNotFound => 'Game not found';

  @override
  String get movieNotFound => 'Movie not found';

  @override
  String get tvShowNotFound => 'TV Show not found';

  @override
  String get animationNotFound => 'Animation not found';

  @override
  String get animatedMovie => 'Animated Movie';

  @override
  String get animatedSeries => 'Animated Series';

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String runtimeHours(int hours) {
    return '${hours}h';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String totalSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }

  @override
  String totalEpisodes(int count) {
    return '$count ep';
  }

  @override
  String get episodeProgress => 'Episode Progress';

  @override
  String episodesWatchedOf(int watched, int total) {
    return '$watched/$total watched';
  }

  @override
  String episodesWatched(int count) {
    return '$count watched';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total episodes';
  }

  @override
  String get noSeasonData => 'No season data available';

  @override
  String get refreshFromTmdb => 'Refresh from TMDB';

  @override
  String get markAllWatched => 'Mark all watched';

  @override
  String get unmarkAll => 'Unmark all';

  @override
  String get noEpisodesFound => 'No episodes found';

  @override
  String episodeWatchedDate(String date) {
    return 'watched $date';
  }

  @override
  String get createCollectionTitle => 'New Collection';

  @override
  String get createCollectionNameLabel => 'Collection Name';

  @override
  String get createCollectionNameHint => 'e.g., SNES Classics';

  @override
  String get createCollectionEnterName => 'Please enter a name';

  @override
  String get createCollectionNameTooShort =>
      'Name must be at least 2 characters';

  @override
  String get createCollectionAuthor => 'Author';

  @override
  String get createCollectionAuthorHint => 'Your name or username';

  @override
  String get createCollectionEnterAuthor => 'Please enter an author name';

  @override
  String get renameCollectionTitle => 'Rename Collection';

  @override
  String get deleteCollectionTitle => 'Delete Collection?';

  @override
  String deleteCollectionMessage(String name) {
    return 'Are you sure you want to delete $name?\n\nThis action cannot be undone.';
  }

  @override
  String get canvasAddText => 'Add Text';

  @override
  String get canvasAddImage => 'Add Image';

  @override
  String get canvasAddLink => 'Add Link';

  @override
  String get canvasFindImages => 'Find images...';

  @override
  String get canvasBrowseMaps => 'Browse maps...';

  @override
  String get canvasConnect => 'Connect';

  @override
  String get canvasBringToFront => 'Bring to Front';

  @override
  String get canvasSendToBack => 'Send to Back';

  @override
  String get canvasEditConnection => 'Edit Connection';

  @override
  String get canvasDeleteConnection => 'Delete Connection';

  @override
  String get canvasDeleteElement => 'Delete element';

  @override
  String get canvasDeleteElementMessage =>
      'Are you sure you want to delete this element?';

  @override
  String get canvasAddToBoard => 'Add to Board';

  @override
  String get addTextTitle => 'Add Text';

  @override
  String get editTextTitle => 'Edit Text';

  @override
  String get textContentLabel => 'Text content';

  @override
  String get fontSizeLabel => 'Font size';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeTitle => 'Title';

  @override
  String get addImageTitle => 'Add Image';

  @override
  String get editImageTitle => 'Edit Image';

  @override
  String get imageFromUrl => 'From URL';

  @override
  String get imageFromFile => 'From File';

  @override
  String get imageUrlLabel => 'Image URL';

  @override
  String get imageUrlHint => 'https://example.com/image.png';

  @override
  String get imageChooseFile => 'Choose File';

  @override
  String get imageChooseAnother => 'Choose Another';

  @override
  String get addLinkTitle => 'Add Link';

  @override
  String get editLinkTitle => 'Edit Link';

  @override
  String get linkUrlLabel => 'URL';

  @override
  String get linkUrlHint => 'https://example.com';

  @override
  String get linkLabelOptional => 'Label (optional)';

  @override
  String get linkLabelHint => 'My Link';

  @override
  String get connectionColorGray => 'Gray';

  @override
  String get connectionColorRed => 'Red';

  @override
  String get connectionColorOrange => 'Orange';

  @override
  String get connectionColorYellow => 'Yellow';

  @override
  String get connectionColorGreen => 'Green';

  @override
  String get connectionColorBlue => 'Blue';

  @override
  String get connectionColorPurple => 'Purple';

  @override
  String get connectionColorBlack => 'Black';

  @override
  String get connectionColorWhite => 'White';

  @override
  String get editConnectionTitle => 'Edit Connection';

  @override
  String get connectionLabelHint => 'e.g. depends on, related to...';

  @override
  String get connectionColorLabel => 'Color';

  @override
  String get connectionStyleLabel => 'Style';

  @override
  String get connectionStyleSolid => 'Solid';

  @override
  String get connectionStyleDashed => 'Dashed';

  @override
  String get connectionStyleArrow => 'Arrow';

  @override
  String get searchTabTv => 'TV';

  @override
  String get searchTabGames => 'Games';

  @override
  String get searchHintTv => 'Search TV...';

  @override
  String get searchHintGames => 'Search games...';

  @override
  String get searchSelectPlatform => 'Select Platform';

  @override
  String get searchAddToCollection => 'Add to Collection';

  @override
  String searchAddedToCollection(String name) {
    return '$name added to collection';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name added to $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name already in collection';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name already in $collection';
  }

  @override
  String get searchGoToSettings => 'Go to Settings';

  @override
  String get searchDescription => 'Description';

  @override
  String get platformFilterTitle => 'Select Platforms';

  @override
  String get platformFilterClearAll => 'Clear All';

  @override
  String get platformFilterSearchHint => 'Search platforms...';

  @override
  String platformFilterSelected(int count) {
    return '$count selected';
  }

  @override
  String platformFilterCount(int count) {
    return '$count platforms';
  }

  @override
  String get platformFilterShowAll => 'Show All';

  @override
  String platformFilterApply(int count) {
    return 'Apply ($count)';
  }

  @override
  String get platformFilterNone => 'No platforms found';

  @override
  String get platformFilterTryDifferent => 'Try a different search term';

  @override
  String get wishlistHideResolved => 'Hide resolved';

  @override
  String get wishlistShowResolved => 'Show resolved';

  @override
  String get wishlistClearResolved => 'Clear resolved';

  @override
  String get wishlistEmpty => 'No wishlist items yet';

  @override
  String get wishlistEmptyHint => 'Tap + to add something to find later';

  @override
  String get wishlistDeleteItem => 'Delete item';

  @override
  String wishlistDeletePrompt(String name) {
    return 'Delete \"$name\" from wishlist?';
  }

  @override
  String get wishlistClearResolvedTitle => 'Clear resolved';

  @override
  String wishlistClearResolvedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count resolved items?',
      one: 'Delete 1 resolved item?',
    );
    return '$_temp0';
  }

  @override
  String get wishlistMarkResolved => 'Mark resolved';

  @override
  String get wishlistUnresolve => 'Unresolve';

  @override
  String get wishlistAddTitle => 'Add';

  @override
  String get wishlistEditTitle => 'Edit';

  @override
  String get wishlistTitleLabel => 'Title';

  @override
  String get wishlistTitleHint => 'Game, movie, or TV show name...';

  @override
  String get wishlistTitleMinChars => 'At least 2 characters';

  @override
  String get wishlistTypeOptional => 'Type (optional)';

  @override
  String get wishlistTypeAny => 'Any';

  @override
  String get wishlistNoteOptional => 'Note (optional)';

  @override
  String get wishlistNoteHint => 'Platform, year, who recommended...';

  @override
  String get welcomeStepWelcome => 'Welcome';

  @override
  String get welcomeStepApiKeys => 'API Keys';

  @override
  String get welcomeStepHowItWorks => 'How it works';

  @override
  String get welcomeStepReady => 'Ready!';

  @override
  String get welcomeTitle => 'Welcome to Tonkatsu Box';

  @override
  String get welcomeSubtitle =>
      'Organize your collections of retro games,\nmovies, TV shows & anime';

  @override
  String get welcomeWhatYouCanDo => 'What you can do';

  @override
  String get welcomeFeatureCollections =>
      'Create collections by platform, genre, or any theme';

  @override
  String get welcomeFeatureSearch =>
      'Search games, movies, TV shows & anime via APIs';

  @override
  String get welcomeFeatureTracking => 'Track progress, rate 1-10, add notes';

  @override
  String get welcomeFeatureBoards => 'Visual canvas boards with artwork';

  @override
  String get welcomeFeatureExport =>
      'Export & import — share collections with friends';

  @override
  String get welcomeWorksWithoutKeys => 'Works without API keys';

  @override
  String get welcomeChipCollections => 'Collections';

  @override
  String get welcomeChipWishlist => 'Wishlist';

  @override
  String get welcomeChipImport => 'Import .xcoll';

  @override
  String get welcomeChipCanvas => 'Canvas boards';

  @override
  String get welcomeChipRatings => 'Ratings & notes';

  @override
  String get welcomeApiKeysHint =>
      'API keys are only needed for searching new games, movies & TV shows. You can import collections and work with them offline.';

  @override
  String get welcomeChipGames => 'Games (IGDB)';

  @override
  String get welcomeChipMovies => 'Movies (TMDB)';

  @override
  String get welcomeChipTvShows => 'TV Shows (TMDB)';

  @override
  String get welcomeChipAnime => 'Anime (TMDB)';

  @override
  String get welcomeApiTitle => 'Getting API Keys';

  @override
  String get welcomeApiFreeHint => 'Free registration, takes 2-3 minutes each';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => 'Game search';

  @override
  String get welcomeApiRequired => 'REQUIRED';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => 'Movies, TV & Anime';

  @override
  String get welcomeApiRecommended => 'RECOMMENDED';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => 'Game artwork for boards';

  @override
  String get welcomeApiOptional => 'OPTIONAL';

  @override
  String get welcomeApiEnterKeysHint =>
      'Enter keys in Settings → Credentials after setup';

  @override
  String get welcomeHowTitle => 'How it works';

  @override
  String get welcomeHowAppStructure => 'App structure';

  @override
  String get welcomeHowMainDesc =>
      'All items from all collections in one view. Filter by type, sort by rating.';

  @override
  String get welcomeHowCollectionsDesc =>
      'Your collections. Create, organize, manage. Grid or list view per collection.';

  @override
  String get welcomeHowWishlistDesc =>
      'Quick list of items to check out later. No API needed.';

  @override
  String get welcomeHowSearchDesc =>
      'Find games, movies & TV shows via API. Add to any collection.';

  @override
  String get welcomeHowSettingsDesc =>
      'API keys, cache, database export/import, debug tools.';

  @override
  String get welcomeHowQuickStart => 'Quick Start';

  @override
  String get welcomeHowStep1 => 'Go to Settings → Credentials, enter API keys';

  @override
  String get welcomeHowStep2 =>
      'Click Verify Connection, wait for platforms sync';

  @override
  String get welcomeHowStep3 => 'Go to Collections → + New Collection';

  @override
  String get welcomeHowStep4 => 'Name it, then Add Items → Search → Add';

  @override
  String get welcomeHowStep5 =>
      'Rate, track progress, add notes — you\'re set!';

  @override
  String get welcomeHowSharing => 'Sharing';

  @override
  String get welcomeHowSharingDesc1 => 'Export collections as ';

  @override
  String get welcomeHowSharingDesc2 => ' (light, metadata only) or ';

  @override
  String get welcomeHowSharingDesc3 =>
      ' (full, with images & canvas — works offline). Import from friends — no API needed!';

  @override
  String get welcomeReadyTitle => 'You\'re all set!';

  @override
  String get welcomeReadyMessage =>
      'Head to Settings → Credentials to enter your API keys, or start by importing a collection.';

  @override
  String get welcomeReadyGoToSettings => 'Go to Settings';

  @override
  String get welcomeReadySkip => 'Skip — explore on my own';

  @override
  String get welcomeReadyReturnHint =>
      'You can always return here from Settings';

  @override
  String updateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String updateCurrent(String version) {
    return 'Current: v$version';
  }

  @override
  String get chooseCollection => 'Choose Collection';

  @override
  String get withoutCollection => 'Without Collection';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailMyRating => 'My Rating';

  @override
  String detailRatingValue(int rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => 'Activity & Progress';

  @override
  String get detailAuthorReview => 'Author\'s Review';

  @override
  String get detailEditAuthorReview => 'Edit Author\'s Review';

  @override
  String get detailWriteReviewHint => 'Write your review...';

  @override
  String get detailReviewVisibility =>
      'Visible to others when shared. Your review of this title.';

  @override
  String get detailNoReviewEditable => 'No review yet. Tap Edit to add one.';

  @override
  String get detailNoReviewReadonly => 'No review from the author.';

  @override
  String get detailMyNotes => 'My Notes';

  @override
  String get detailEditMyNotes => 'Edit My Notes';

  @override
  String get detailWriteNotesHint => 'Write your personal notes...';

  @override
  String get detailNoNotesYet =>
      'No notes yet. Tap Edit to add your personal notes.';

  @override
  String get detailNoNotesReadonly => 'No notes from the author.';

  @override
  String get unknownGame => 'Unknown Game';

  @override
  String get unknownMovie => 'Unknown Movie';

  @override
  String get unknownTvShow => 'Unknown TV Show';

  @override
  String get unknownAnimation => 'Unknown Animation';

  @override
  String get unknownPlatform => 'Unknown Platform';

  @override
  String get defaultAuthor => 'User';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get allItemsAll => 'All';

  @override
  String get allItemsGames => 'Games';

  @override
  String get allItemsMovies => 'Movies';

  @override
  String get allItemsTvShows => 'TV Shows';

  @override
  String get allItemsAnimation => 'Animation';

  @override
  String get allItemsRatingAsc => 'Rating ↑';

  @override
  String get allItemsRatingDesc => 'Rating ↓';

  @override
  String get allItemsRating => 'Rating';

  @override
  String get allItemsNoItems => 'No items yet';

  @override
  String get allItemsNoMatch => 'No items match filter';

  @override
  String get allItemsAddViaCollections => 'Add items via Collections tab';

  @override
  String get allItemsFailedToLoad => 'Failed to load items';

  @override
  String get debugIgdbMedia => 'IGDB Media';

  @override
  String get debugSteamGridDb => 'SteamGridDB';

  @override
  String get debugGamepad => 'Gamepad';

  @override
  String get debugClearLogs => 'Clear logs';

  @override
  String get debugRawEvents => 'Raw Events (Gamepads.events)';

  @override
  String get debugServiceEvents => 'Service Events (filtered)';

  @override
  String debugEventsCount(int count) {
    return '$count events';
  }

  @override
  String get debugPressButton => 'Press any button\non the gamepad...';

  @override
  String get debugSearchGames => 'Search games';

  @override
  String get debugEnterGameName => 'Enter game name';

  @override
  String get debugEnterGameNameHint => 'Enter a game name to search';

  @override
  String get debugGameId => 'Game ID';

  @override
  String get debugEnterGameId => 'Enter SteamGridDB game ID';

  @override
  String debugLoadTab(String tabName) {
    return 'Load $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return 'Enter a game ID and press Load $tabName';
  }

  @override
  String get debugNoImagesFound => 'No images found';

  @override
  String get debugSearchTab => 'Search';

  @override
  String get debugGridsTab => 'Grids';

  @override
  String get debugHeroesTab => 'Heroes';

  @override
  String get debugLogosTab => 'Logos';

  @override
  String get debugIconsTab => 'Icons';

  @override
  String collectionTileStats(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · $percent completed';
  }

  @override
  String get collectionTileError => 'Error loading stats';

  @override
  String get activityDatesTitle => 'Activity Dates';

  @override
  String get activityDatesAdded => 'Added';

  @override
  String get activityDatesStarted => 'Started';

  @override
  String get activityDatesCompleted => 'Completed';

  @override
  String get activityDatesLastActivity => 'Last Activity';

  @override
  String get activityDatesSelectStart => 'Select start date';

  @override
  String get activityDatesSelectCompletion => 'Select completion date';

  @override
  String get canvasFailedToLoad => 'Failed to load board';

  @override
  String get canvasBoardEmpty => 'Board is empty';

  @override
  String get canvasBoardEmptyHint => 'Add items to the collection first';

  @override
  String get canvasCenterView => 'Center view';

  @override
  String get canvasResetPositions => 'Reset positions';

  @override
  String get canvasVgmapsBrowser => 'VGMaps Browser';

  @override
  String get canvasSteamGridDbImages => 'SteamGridDB Images';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get steamGridDbClosePanel => 'Close panel';

  @override
  String get steamGridDbSearchHint => 'Search game...';

  @override
  String get steamGridDbNoApiKey =>
      'SteamGridDB API key not set. Configure it in Settings.';

  @override
  String get steamGridDbBackToSearch => 'Back to search';

  @override
  String get steamGridDbGrids => 'Grids';

  @override
  String get steamGridDbHeroes => 'Heroes';

  @override
  String get steamGridDbLogos => 'Logos';

  @override
  String get steamGridDbIcons => 'Icons';

  @override
  String get steamGridDbNoResults => 'No results found';

  @override
  String get steamGridDbSearchFirst => 'Search for a game first';

  @override
  String get vgmapsClosePanel => 'Close panel';

  @override
  String get vgmapsBack => 'Back';

  @override
  String get vgmapsForward => 'Forward';

  @override
  String get vgmapsHome => 'Home';

  @override
  String get vgmapsReload => 'Reload';

  @override
  String get vgmapsCaptureImage => 'Capture map image';

  @override
  String get vgmapsSearchHint => 'Search game on VGMaps...';

  @override
  String get vgmapsDismiss => 'Dismiss';

  @override
  String vgmapsFailedInit(String error) {
    return 'Failed to initialize WebView: $error';
  }
}

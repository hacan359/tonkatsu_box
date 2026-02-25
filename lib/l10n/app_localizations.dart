import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tonkatsu Box'**
  String get appName;

  /// No description provided for @navMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get navMain;

  /// No description provided for @navCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get navCollections;

  /// No description provided for @navWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get navWishlist;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get statusNotStarted;

  /// No description provided for @statusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get statusPlaying;

  /// No description provided for @statusWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get statusWatching;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get statusDropped;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @mediaTypeGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get mediaTypeGame;

  /// No description provided for @mediaTypeMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get mediaTypeMovie;

  /// No description provided for @mediaTypeTvShow.
  ///
  /// In en, this message translates to:
  /// **'TV Show'**
  String get mediaTypeTvShow;

  /// No description provided for @mediaTypeAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get mediaTypeAnimation;

  /// No description provided for @sortManualDisplay.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sortManualDisplay;

  /// No description provided for @sortManualShort.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sortManualShort;

  /// No description provided for @sortManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Custom order'**
  String get sortManualDesc;

  /// No description provided for @sortDateDisplay.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get sortDateDisplay;

  /// No description provided for @sortDateShort.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDateShort;

  /// No description provided for @sortDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortDateDesc;

  /// No description provided for @sortStatusDisplay.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortStatusDisplay;

  /// No description provided for @sortStatusShort.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortStatusShort;

  /// No description provided for @sortStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Active first'**
  String get sortStatusDesc;

  /// No description provided for @sortNameDisplay.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortNameDisplay;

  /// No description provided for @sortNameShort.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get sortNameShort;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortNameDesc;

  /// No description provided for @sortRatingDisplay.
  ///
  /// In en, this message translates to:
  /// **'My Rating'**
  String get sortRatingDisplay;

  /// No description provided for @sortRatingShort.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRatingShort;

  /// No description provided for @sortRatingDesc.
  ///
  /// In en, this message translates to:
  /// **'Highest first'**
  String get sortRatingDesc;

  /// No description provided for @searchSortRelevanceShort.
  ///
  /// In en, this message translates to:
  /// **'Rel'**
  String get searchSortRelevanceShort;

  /// No description provided for @searchSortRelevanceDisplay.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get searchSortRelevanceDisplay;

  /// No description provided for @searchSortDateShort.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchSortDateShort;

  /// No description provided for @searchSortDateDisplay.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchSortDateDisplay;

  /// No description provided for @searchSortRatingShort.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get searchSortRatingShort;

  /// No description provided for @searchSortRatingDisplay.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get searchSortRatingDisplay;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAuthorName.
  ///
  /// In en, this message translates to:
  /// **'Author name'**
  String get settingsAuthorName;

  /// No description provided for @settingsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSettings;

  /// No description provided for @settingsCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get settingsCredentials;

  /// No description provided for @settingsCredentialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'IGDB, SteamGridDB, TMDB API keys'**
  String get settingsCredentialsSubtitle;

  /// No description provided for @settingsCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsCache;

  /// No description provided for @settingsCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Image cache settings'**
  String get settingsCacheSubtitle;

  /// No description provided for @settingsDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsDatabase;

  /// No description provided for @settingsDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export, import, reset'**
  String get settingsDatabaseSubtitle;

  /// No description provided for @settingsTraktImport.
  ///
  /// In en, this message translates to:
  /// **'Trakt Import'**
  String get settingsTraktImport;

  /// No description provided for @settingsTraktImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Trakt.tv ZIP export'**
  String get settingsTraktImportSubtitle;

  /// No description provided for @settingsDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsDebug;

  /// No description provided for @settingsDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get settingsDebugSubtitle;

  /// No description provided for @settingsDebugSubtitleNoKey.
  ///
  /// In en, this message translates to:
  /// **'Set SteamGridDB key first for some tools'**
  String get settingsDebugSubtitleNoKey;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsWelcomeGuide.
  ///
  /// In en, this message translates to:
  /// **'Welcome Guide'**
  String get settingsWelcomeGuide;

  /// No description provided for @settingsWelcomeGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Getting started with Tonkatsu Box'**
  String get settingsWelcomeGuideSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsCreditsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Credits & Licenses'**
  String get settingsCreditsLicenses;

  /// No description provided for @settingsCreditsLicensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'TMDB, IGDB, SteamGridDB, open-source licenses'**
  String get settingsCreditsLicensesSubtitle;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get settingsError;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsAppLanguage;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentialsTitle;

  /// No description provided for @credentialsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tonkatsu Box!'**
  String get credentialsWelcome;

  /// No description provided for @credentialsWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'To get started, you need to set up your IGDB API credentials. Get your Client ID and Client Secret from the Twitch Developer Console.'**
  String get credentialsWelcomeHint;

  /// No description provided for @credentialsCopyTwitchUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Twitch Console URL'**
  String get credentialsCopyTwitchUrl;

  /// No description provided for @credentialsUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied: {url}'**
  String credentialsUrlCopied(String url);

  /// No description provided for @credentialsIgdbSection.
  ///
  /// In en, this message translates to:
  /// **'IGDB API Credentials'**
  String get credentialsIgdbSection;

  /// No description provided for @credentialsClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get credentialsClientId;

  /// No description provided for @credentialsClientIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Twitch Client ID'**
  String get credentialsClientIdHint;

  /// No description provided for @credentialsClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get credentialsClientSecret;

  /// No description provided for @credentialsClientSecretHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Twitch Client Secret'**
  String get credentialsClientSecretHint;

  /// No description provided for @credentialsConnectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get credentialsConnectionStatus;

  /// No description provided for @credentialsPlatformsSynced.
  ///
  /// In en, this message translates to:
  /// **'Platforms synced'**
  String get credentialsPlatformsSynced;

  /// No description provided for @credentialsLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get credentialsLastSync;

  /// No description provided for @credentialsVerifyConnection.
  ///
  /// In en, this message translates to:
  /// **'Verify Connection'**
  String get credentialsVerifyConnection;

  /// No description provided for @credentialsRefreshPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Refresh Platforms'**
  String get credentialsRefreshPlatforms;

  /// No description provided for @credentialsSteamGridDbSection.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB API'**
  String get credentialsSteamGridDbSection;

  /// No description provided for @credentialsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get credentialsApiKey;

  /// No description provided for @credentialsUsingBuiltInKey.
  ///
  /// In en, this message translates to:
  /// **'Using built-in key'**
  String get credentialsUsingBuiltInKey;

  /// No description provided for @credentialsEnterSteamGridDbKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your SteamGridDB API key'**
  String get credentialsEnterSteamGridDbKey;

  /// No description provided for @credentialsTmdbSection.
  ///
  /// In en, this message translates to:
  /// **'TMDB API (Movies & TV)'**
  String get credentialsTmdbSection;

  /// No description provided for @credentialsEnterTmdbKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your TMDB API key (v3)'**
  String get credentialsEnterTmdbKey;

  /// No description provided for @credentialsContentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Content Language'**
  String get credentialsContentLanguage;

  /// No description provided for @credentialsOwnKeyHint.
  ///
  /// In en, this message translates to:
  /// **'For better rate limits we recommend using your own API key.'**
  String get credentialsOwnKeyHint;

  /// No description provided for @credentialsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get credentialsConnected;

  /// No description provided for @credentialsConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get credentialsConnectionError;

  /// No description provided for @credentialsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get credentialsChecking;

  /// No description provided for @credentialsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get credentialsNotConnected;

  /// No description provided for @credentialsEnterBoth.
  ///
  /// In en, this message translates to:
  /// **'Please enter both Client ID and Client Secret'**
  String get credentialsEnterBoth;

  /// No description provided for @credentialsConnectedSynced.
  ///
  /// In en, this message translates to:
  /// **'Connected & platforms synced!'**
  String get credentialsConnectedSynced;

  /// No description provided for @credentialsConnectedSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Connected, but platform sync failed'**
  String get credentialsConnectedSyncFailed;

  /// No description provided for @credentialsPlatformsSyncedOk.
  ///
  /// In en, this message translates to:
  /// **'Platforms synced successfully!'**
  String get credentialsPlatformsSyncedOk;

  /// No description provided for @credentialsDownloadingLogos.
  ///
  /// In en, this message translates to:
  /// **'Downloading platform logos...'**
  String get credentialsDownloadingLogos;

  /// No description provided for @credentialsDownloadedLogos.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} logos'**
  String credentialsDownloadedLogos(int count);

  /// No description provided for @credentialsFailedDownloadLogos.
  ///
  /// In en, this message translates to:
  /// **'Failed to download logos'**
  String get credentialsFailedDownloadLogos;

  /// No description provided for @credentialsApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved'**
  String get credentialsApiKeySaved;

  /// No description provided for @credentialsNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'No API key'**
  String get credentialsNoApiKey;

  /// No description provided for @credentialsResetToBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Reset to built-in key'**
  String get credentialsResetToBuiltIn;

  /// No description provided for @credentialsSteamGridDbKeyValid.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB API key is valid'**
  String get credentialsSteamGridDbKeyValid;

  /// No description provided for @credentialsSteamGridDbKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB API key is invalid'**
  String get credentialsSteamGridDbKeyInvalid;

  /// No description provided for @credentialsTmdbKeyValid.
  ///
  /// In en, this message translates to:
  /// **'TMDB API key is valid'**
  String get credentialsTmdbKeyValid;

  /// No description provided for @credentialsTmdbKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'TMDB API key is invalid'**
  String get credentialsTmdbKeyInvalid;

  /// No description provided for @credentialsEnterSteamGridDbKeyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a SteamGridDB API key'**
  String get credentialsEnterSteamGridDbKeyError;

  /// No description provided for @credentialsEnterTmdbKeyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a TMDB API key'**
  String get credentialsEnterTmdbKeyError;

  /// No description provided for @credentialsTmdbKeySaved.
  ///
  /// In en, this message translates to:
  /// **'TMDB API key saved'**
  String get credentialsTmdbKeySaved;

  /// No description provided for @timeAgo.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} ago'**
  String timeAgo(int value, String unit);

  /// No description provided for @timeUnitDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String timeUnitDays(int count);

  /// No description provided for @timeUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{hour} other{hours}}'**
  String timeUnitHours(int count);

  /// No description provided for @timeUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{minute} other{minutes}}'**
  String timeUnitMinutes(int count);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @cacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cacheTitle;

  /// No description provided for @cacheImageCache.
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get cacheImageCache;

  /// No description provided for @cacheOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get cacheOfflineMode;

  /// No description provided for @cacheOfflineModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save images locally for offline use'**
  String get cacheOfflineModeSubtitle;

  /// No description provided for @cacheCacheFolder.
  ///
  /// In en, this message translates to:
  /// **'Cache folder'**
  String get cacheCacheFolder;

  /// No description provided for @cacheSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select folder'**
  String get cacheSelectFolder;

  /// No description provided for @cacheCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size'**
  String get cacheCacheSize;

  /// No description provided for @cacheClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get cacheClearCache;

  /// No description provided for @cacheClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get cacheClearCacheTitle;

  /// No description provided for @cacheClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all locally saved images. They will be downloaded again during the next sync.'**
  String get cacheClearCacheMessage;

  /// No description provided for @cacheFolderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cache folder updated'**
  String get cacheFolderUpdated;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @cacheSelectFolderDialog.
  ///
  /// In en, this message translates to:
  /// **'Select cache folder for images'**
  String get cacheSelectFolderDialog;

  /// No description provided for @cacheCacheStats.
  ///
  /// In en, this message translates to:
  /// **'{count} files, {size}'**
  String cacheCacheStats(int count, String size);

  /// No description provided for @databaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get databaseTitle;

  /// No description provided for @databaseConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get databaseConfiguration;

  /// No description provided for @databaseConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export or import your API keys and settings.'**
  String get databaseConfigSubtitle;

  /// No description provided for @databaseExportConfig.
  ///
  /// In en, this message translates to:
  /// **'Export Config'**
  String get databaseExportConfig;

  /// No description provided for @databaseImportConfig.
  ///
  /// In en, this message translates to:
  /// **'Import Config'**
  String get databaseImportConfig;

  /// No description provided for @databaseDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get databaseDangerZone;

  /// No description provided for @databaseDangerZoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Clears all collections, games, movies, TV shows and board data. Settings and API keys will be preserved.'**
  String get databaseDangerZoneMessage;

  /// No description provided for @databaseResetDatabase.
  ///
  /// In en, this message translates to:
  /// **'Reset Database'**
  String get databaseResetDatabase;

  /// No description provided for @databaseResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Database?'**
  String get databaseResetTitle;

  /// No description provided for @databaseResetMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your collections, games, movies, TV shows, episode progress, and board data.\n\nYour API keys and settings will be preserved.\n\nThis action cannot be undone.'**
  String get databaseResetMessage;

  /// No description provided for @databaseConfigExported.
  ///
  /// In en, this message translates to:
  /// **'Config exported to {path}'**
  String databaseConfigExported(String path);

  /// No description provided for @databaseConfigImported.
  ///
  /// In en, this message translates to:
  /// **'Config imported successfully'**
  String get databaseConfigImported;

  /// No description provided for @databaseReset.
  ///
  /// In en, this message translates to:
  /// **'Database has been reset'**
  String get databaseReset;

  /// No description provided for @traktTitle.
  ///
  /// In en, this message translates to:
  /// **'Trakt Import'**
  String get traktTitle;

  /// No description provided for @traktImportFrom.
  ///
  /// In en, this message translates to:
  /// **'Import from Trakt.tv'**
  String get traktImportFrom;

  /// No description provided for @traktImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Download your data from trakt.tv/users/YOU/data and select the ZIP file below.'**
  String get traktImportDescription;

  /// No description provided for @traktZipFile.
  ///
  /// In en, this message translates to:
  /// **'ZIP File'**
  String get traktZipFile;

  /// No description provided for @traktSelectZipFile.
  ///
  /// In en, this message translates to:
  /// **'Select ZIP File'**
  String get traktSelectZipFile;

  /// No description provided for @traktSelectZipExport.
  ///
  /// In en, this message translates to:
  /// **'Select Trakt ZIP Export'**
  String get traktSelectZipExport;

  /// No description provided for @traktPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get traktPreview;

  /// No description provided for @traktUser.
  ///
  /// In en, this message translates to:
  /// **'Trakt user: {username}'**
  String traktUser(String username);

  /// No description provided for @traktWatchedMovies.
  ///
  /// In en, this message translates to:
  /// **'Watched movies'**
  String get traktWatchedMovies;

  /// No description provided for @traktWatchedShows.
  ///
  /// In en, this message translates to:
  /// **'Watched shows'**
  String get traktWatchedShows;

  /// No description provided for @traktRatedMovies.
  ///
  /// In en, this message translates to:
  /// **'Rated movies'**
  String get traktRatedMovies;

  /// No description provided for @traktRatedShows.
  ///
  /// In en, this message translates to:
  /// **'Rated shows'**
  String get traktRatedShows;

  /// No description provided for @traktWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get traktWatchlist;

  /// No description provided for @traktOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get traktOptions;

  /// No description provided for @traktImportWatched.
  ///
  /// In en, this message translates to:
  /// **'Import watched items'**
  String get traktImportWatched;

  /// No description provided for @traktImportWatchedDesc.
  ///
  /// In en, this message translates to:
  /// **'Movies and TV shows as completed'**
  String get traktImportWatchedDesc;

  /// No description provided for @traktImportRatings.
  ///
  /// In en, this message translates to:
  /// **'Import ratings'**
  String get traktImportRatings;

  /// No description provided for @traktImportRatingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply user ratings (1-10)'**
  String get traktImportRatingsDesc;

  /// No description provided for @traktImportWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Import watchlist'**
  String get traktImportWatchlist;

  /// No description provided for @traktImportWatchlistDesc.
  ///
  /// In en, this message translates to:
  /// **'Add as planned or to wishlist'**
  String get traktImportWatchlistDesc;

  /// No description provided for @traktTargetCollection.
  ///
  /// In en, this message translates to:
  /// **'Target collection'**
  String get traktTargetCollection;

  /// No description provided for @traktCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new collection'**
  String get traktCreateNew;

  /// No description provided for @traktUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use existing collection'**
  String get traktUseExisting;

  /// No description provided for @traktNoCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections available'**
  String get traktNoCollections;

  /// No description provided for @traktSelectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select collection'**
  String get traktSelectCollection;

  /// No description provided for @traktErrorLoadingCollections.
  ///
  /// In en, this message translates to:
  /// **'Error loading collections'**
  String get traktErrorLoadingCollections;

  /// No description provided for @traktStartImport.
  ///
  /// In en, this message translates to:
  /// **'Start Import'**
  String get traktStartImport;

  /// No description provided for @traktInvalidExport.
  ///
  /// In en, this message translates to:
  /// **'Invalid Trakt export'**
  String get traktInvalidExport;

  /// No description provided for @traktImportedItems.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items'**
  String traktImportedItems(int count);

  /// No description provided for @traktImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing from Trakt'**
  String get traktImporting;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsDataProviders.
  ///
  /// In en, this message translates to:
  /// **'Data Providers'**
  String get creditsDataProviders;

  /// No description provided for @creditsTmdbAttribution.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get creditsTmdbAttribution;

  /// No description provided for @creditsIgdbAttribution.
  ///
  /// In en, this message translates to:
  /// **'Game data provided by IGDB.'**
  String get creditsIgdbAttribution;

  /// No description provided for @creditsSteamGridDbAttribution.
  ///
  /// In en, this message translates to:
  /// **'Artwork provided by SteamGridDB.'**
  String get creditsSteamGridDbAttribution;

  /// No description provided for @creditsOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get creditsOpenSource;

  /// No description provided for @creditsOpenSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Tonkatsu Box is free and open source software, released under the MIT License.'**
  String get creditsOpenSourceDesc;

  /// No description provided for @creditsViewLicenses.
  ///
  /// In en, this message translates to:
  /// **'View Open Source Licenses'**
  String get creditsViewLicenses;

  /// No description provided for @collectionsNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get collectionsNewCollection;

  /// No description provided for @collectionsImportCollection.
  ///
  /// In en, this message translates to:
  /// **'Import Collection'**
  String get collectionsImportCollection;

  /// No description provided for @collectionsNoCollectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No Collections Yet'**
  String get collectionsNoCollectionsYet;

  /// No description provided for @collectionsNoCollectionsHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first collection to start tracking\nyour gaming journey.'**
  String get collectionsNoCollectionsHint;

  /// No description provided for @collectionsFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections'**
  String get collectionsFailedToLoad;

  /// No description provided for @collectionsCount.
  ///
  /// In en, this message translates to:
  /// **'Collections ({count})'**
  String collectionsCount(int count);

  /// No description provided for @collectionsUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get collectionsUncategorized;

  /// No description provided for @collectionsUncategorizedItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String collectionsUncategorizedItems(int count);

  /// No description provided for @collectionsRenamed.
  ///
  /// In en, this message translates to:
  /// **'Collection renamed'**
  String get collectionsRenamed;

  /// No description provided for @collectionsFailedToRename.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: {error}'**
  String collectionsFailedToRename(String error);

  /// No description provided for @collectionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted'**
  String get collectionsDeleted;

  /// No description provided for @collectionsFailedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String collectionsFailedToDelete(String error);

  /// No description provided for @collectionsFailedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create collection: {error}'**
  String collectionsFailedToCreate(String error);

  /// No description provided for @collectionsImported.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{name}\" with {count} items'**
  String collectionsImported(String name, int count);

  /// No description provided for @collectionsImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing Collection'**
  String get collectionsImporting;

  /// No description provided for @collectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Collection not found'**
  String get collectionNotFound;

  /// No description provided for @collectionAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get collectionAddItems;

  /// No description provided for @collectionSwitchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to List'**
  String get collectionSwitchToList;

  /// No description provided for @collectionSwitchToBoard.
  ///
  /// In en, this message translates to:
  /// **'Switch to Board'**
  String get collectionSwitchToBoard;

  /// No description provided for @collectionUnlockBoard.
  ///
  /// In en, this message translates to:
  /// **'Unlock board'**
  String get collectionUnlockBoard;

  /// No description provided for @collectionLockBoard.
  ///
  /// In en, this message translates to:
  /// **'Lock board'**
  String get collectionLockBoard;

  /// No description provided for @collectionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get collectionExport;

  /// No description provided for @collectionNoItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No Items Yet'**
  String get collectionNoItemsYet;

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty Collection'**
  String get collectionEmpty;

  /// No description provided for @collectionDeleteEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'This collection is now empty. Delete it?'**
  String get collectionDeleteEmptyPrompt;

  /// No description provided for @collectionRemoveItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Item?'**
  String get collectionRemoveItemTitle;

  /// No description provided for @collectionRemoveItemMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this collection?'**
  String collectionRemoveItemMessage(String name);

  /// No description provided for @collectionMoveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Move to Collection'**
  String get collectionMoveToCollection;

  /// No description provided for @collectionExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get collectionExportFormat;

  /// No description provided for @collectionChooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose export format:'**
  String get collectionChooseExportFormat;

  /// No description provided for @collectionExportLight.
  ///
  /// In en, this message translates to:
  /// **'Light (.xcoll)'**
  String get collectionExportLight;

  /// No description provided for @collectionExportLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Items only, smaller file'**
  String get collectionExportLightDesc;

  /// No description provided for @collectionExportFull.
  ///
  /// In en, this message translates to:
  /// **'Full (.xcollx)'**
  String get collectionExportFull;

  /// No description provided for @collectionExportFullDesc.
  ///
  /// In en, this message translates to:
  /// **'With images & canvas — works offline'**
  String get collectionExportFullDesc;

  /// No description provided for @collectionFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get collectionFilterAll;

  /// No description provided for @collectionFilterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get collectionFilterByType;

  /// No description provided for @collectionFilterGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get collectionFilterGames;

  /// No description provided for @collectionFilterMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get collectionFilterMovies;

  /// No description provided for @collectionFilterTvShows.
  ///
  /// In en, this message translates to:
  /// **'TV Shows'**
  String get collectionFilterTvShows;

  /// No description provided for @collectionFilterAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get collectionFilterAnimation;

  /// No description provided for @collectionItemMovedTo.
  ///
  /// In en, this message translates to:
  /// **'{name} moved to {collection}'**
  String collectionItemMovedTo(String name, String collection);

  /// No description provided for @collectionItemAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists in {collection}'**
  String collectionItemAlreadyExists(String name, String collection);

  /// No description provided for @collectionItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String collectionItemRemoved(String name);

  /// No description provided for @boardTab.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardTab;

  /// No description provided for @imageAddedToBoard.
  ///
  /// In en, this message translates to:
  /// **'Image added to board'**
  String get imageAddedToBoard;

  /// No description provided for @mapAddedToBoard.
  ///
  /// In en, this message translates to:
  /// **'Map added to board'**
  String get mapAddedToBoard;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @gameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Game not found'**
  String get gameNotFound;

  /// No description provided for @movieNotFound.
  ///
  /// In en, this message translates to:
  /// **'Movie not found'**
  String get movieNotFound;

  /// No description provided for @tvShowNotFound.
  ///
  /// In en, this message translates to:
  /// **'TV Show not found'**
  String get tvShowNotFound;

  /// No description provided for @animationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Animation not found'**
  String get animationNotFound;

  /// No description provided for @animatedMovie.
  ///
  /// In en, this message translates to:
  /// **'Animated Movie'**
  String get animatedMovie;

  /// No description provided for @animatedSeries.
  ///
  /// In en, this message translates to:
  /// **'Animated Series'**
  String get animatedSeries;

  /// No description provided for @runtimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String runtimeHoursMinutes(int hours, int minutes);

  /// No description provided for @runtimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String runtimeHours(int hours);

  /// No description provided for @runtimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String runtimeMinutes(int minutes);

  /// No description provided for @totalSeasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 season} other{{count} seasons}}'**
  String totalSeasons(int count);

  /// No description provided for @totalEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count} ep'**
  String totalEpisodes(int count);

  /// No description provided for @seasonName.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonName(int number);

  /// No description provided for @episodeProgress.
  ///
  /// In en, this message translates to:
  /// **'Episode Progress'**
  String get episodeProgress;

  /// No description provided for @episodesWatchedOf.
  ///
  /// In en, this message translates to:
  /// **'{watched}/{total} watched'**
  String episodesWatchedOf(int watched, int total);

  /// No description provided for @episodesWatched.
  ///
  /// In en, this message translates to:
  /// **'{count} watched'**
  String episodesWatched(int count);

  /// No description provided for @seasonEpisodesProgress.
  ///
  /// In en, this message translates to:
  /// **'{watched}/{total} episodes'**
  String seasonEpisodesProgress(int watched, int total);

  /// No description provided for @noSeasonData.
  ///
  /// In en, this message translates to:
  /// **'No season data available'**
  String get noSeasonData;

  /// No description provided for @refreshFromTmdb.
  ///
  /// In en, this message translates to:
  /// **'Refresh from TMDB'**
  String get refreshFromTmdb;

  /// No description provided for @markAllWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark all watched'**
  String get markAllWatched;

  /// No description provided for @unmarkAll.
  ///
  /// In en, this message translates to:
  /// **'Unmark all'**
  String get unmarkAll;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found'**
  String get noEpisodesFound;

  /// No description provided for @episodeWatchedDate.
  ///
  /// In en, this message translates to:
  /// **'watched {date}'**
  String episodeWatchedDate(String date);

  /// No description provided for @createCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get createCollectionTitle;

  /// No description provided for @createCollectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get createCollectionNameLabel;

  /// No description provided for @createCollectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., SNES Classics'**
  String get createCollectionNameHint;

  /// No description provided for @createCollectionEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get createCollectionEnterName;

  /// No description provided for @createCollectionNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get createCollectionNameTooShort;

  /// No description provided for @createCollectionAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get createCollectionAuthor;

  /// No description provided for @createCollectionAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Your name or username'**
  String get createCollectionAuthorHint;

  /// No description provided for @createCollectionEnterAuthor.
  ///
  /// In en, this message translates to:
  /// **'Please enter an author name'**
  String get createCollectionEnterAuthor;

  /// No description provided for @renameCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Collection'**
  String get renameCollectionTitle;

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection?'**
  String get deleteCollectionTitle;

  /// No description provided for @deleteCollectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?\n\nThis action cannot be undone.'**
  String deleteCollectionMessage(String name);

  /// No description provided for @canvasAddText.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get canvasAddText;

  /// No description provided for @canvasAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get canvasAddImage;

  /// No description provided for @canvasAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get canvasAddLink;

  /// No description provided for @canvasFindImages.
  ///
  /// In en, this message translates to:
  /// **'Find images...'**
  String get canvasFindImages;

  /// No description provided for @canvasBrowseMaps.
  ///
  /// In en, this message translates to:
  /// **'Browse maps...'**
  String get canvasBrowseMaps;

  /// No description provided for @canvasConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get canvasConnect;

  /// No description provided for @canvasBringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to Front'**
  String get canvasBringToFront;

  /// No description provided for @canvasSendToBack.
  ///
  /// In en, this message translates to:
  /// **'Send to Back'**
  String get canvasSendToBack;

  /// No description provided for @canvasEditConnection.
  ///
  /// In en, this message translates to:
  /// **'Edit Connection'**
  String get canvasEditConnection;

  /// No description provided for @canvasDeleteConnection.
  ///
  /// In en, this message translates to:
  /// **'Delete Connection'**
  String get canvasDeleteConnection;

  /// No description provided for @canvasDeleteElement.
  ///
  /// In en, this message translates to:
  /// **'Delete element'**
  String get canvasDeleteElement;

  /// No description provided for @canvasDeleteElementMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this element?'**
  String get canvasDeleteElementMessage;

  /// No description provided for @canvasAddToBoard.
  ///
  /// In en, this message translates to:
  /// **'Add to Board'**
  String get canvasAddToBoard;

  /// No description provided for @addTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addTextTitle;

  /// No description provided for @editTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Text'**
  String get editTextTitle;

  /// No description provided for @textContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Text content'**
  String get textContentLabel;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeLabel;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeMedium;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fontSizeTitle;

  /// No description provided for @addImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImageTitle;

  /// No description provided for @editImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get editImageTitle;

  /// No description provided for @imageFromUrl.
  ///
  /// In en, this message translates to:
  /// **'From URL'**
  String get imageFromUrl;

  /// No description provided for @imageFromFile.
  ///
  /// In en, this message translates to:
  /// **'From File'**
  String get imageFromFile;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @imageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/image.png'**
  String get imageUrlHint;

  /// No description provided for @imageChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get imageChooseFile;

  /// No description provided for @imageChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose Another'**
  String get imageChooseAnother;

  /// No description provided for @addLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLinkTitle;

  /// No description provided for @editLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Link'**
  String get editLinkTitle;

  /// No description provided for @linkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get linkUrlLabel;

  /// No description provided for @linkUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get linkUrlHint;

  /// No description provided for @linkLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get linkLabelOptional;

  /// No description provided for @linkLabelHint.
  ///
  /// In en, this message translates to:
  /// **'My Link'**
  String get linkLabelHint;

  /// No description provided for @connectionColorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get connectionColorGray;

  /// No description provided for @connectionColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get connectionColorRed;

  /// No description provided for @connectionColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get connectionColorOrange;

  /// No description provided for @connectionColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get connectionColorYellow;

  /// No description provided for @connectionColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get connectionColorGreen;

  /// No description provided for @connectionColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get connectionColorBlue;

  /// No description provided for @connectionColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get connectionColorPurple;

  /// No description provided for @connectionColorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get connectionColorBlack;

  /// No description provided for @connectionColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get connectionColorWhite;

  /// No description provided for @editConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Connection'**
  String get editConnectionTitle;

  /// No description provided for @connectionLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. depends on, related to...'**
  String get connectionLabelHint;

  /// No description provided for @connectionColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get connectionColorLabel;

  /// No description provided for @connectionStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get connectionStyleLabel;

  /// No description provided for @connectionStyleSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get connectionStyleSolid;

  /// No description provided for @connectionStyleDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get connectionStyleDashed;

  /// No description provided for @connectionStyleArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get connectionStyleArrow;

  /// No description provided for @searchTabTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get searchTabTv;

  /// No description provided for @searchTabGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get searchTabGames;

  /// No description provided for @searchHintTv.
  ///
  /// In en, this message translates to:
  /// **'Search TV...'**
  String get searchHintTv;

  /// No description provided for @searchHintGames.
  ///
  /// In en, this message translates to:
  /// **'Search games...'**
  String get searchHintGames;

  /// No description provided for @searchSelectPlatform.
  ///
  /// In en, this message translates to:
  /// **'Select Platform'**
  String get searchSelectPlatform;

  /// No description provided for @searchAddToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to Collection'**
  String get searchAddToCollection;

  /// No description provided for @searchAddedToCollection.
  ///
  /// In en, this message translates to:
  /// **'{name} added to collection'**
  String searchAddedToCollection(String name);

  /// No description provided for @searchAddedToNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} added to {collection}'**
  String searchAddedToNamed(String name, String collection);

  /// No description provided for @searchAlreadyInCollection.
  ///
  /// In en, this message translates to:
  /// **'{name} already in collection'**
  String searchAlreadyInCollection(String name);

  /// No description provided for @searchAlreadyInNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} already in {collection}'**
  String searchAlreadyInNamed(String name, String collection);

  /// No description provided for @searchGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get searchGoToSettings;

  /// No description provided for @searchMinCharsHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters and press Enter'**
  String get searchMinCharsHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchNothingFoundFor.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for \"{query}\"'**
  String searchNothingFoundFor(String query);

  /// No description provided for @searchNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get searchNoInternet;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @searchCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get searchCheckConnection;

  /// No description provided for @searchDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get searchDescription;

  /// No description provided for @platformFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Platforms'**
  String get platformFilterTitle;

  /// No description provided for @platformFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get platformFilterClearAll;

  /// No description provided for @platformFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search platforms...'**
  String get platformFilterSearchHint;

  /// No description provided for @platformFilterSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String platformFilterSelected(int count);

  /// No description provided for @platformFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} platforms'**
  String platformFilterCount(int count);

  /// No description provided for @platformFilterShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get platformFilterShowAll;

  /// No description provided for @platformFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply ({count})'**
  String platformFilterApply(int count);

  /// No description provided for @platformFilterNone.
  ///
  /// In en, this message translates to:
  /// **'No platforms found'**
  String get platformFilterNone;

  /// No description provided for @platformFilterTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get platformFilterTryDifferent;

  /// No description provided for @wishlistHideResolved.
  ///
  /// In en, this message translates to:
  /// **'Hide resolved'**
  String get wishlistHideResolved;

  /// No description provided for @wishlistShowResolved.
  ///
  /// In en, this message translates to:
  /// **'Show resolved'**
  String get wishlistShowResolved;

  /// No description provided for @wishlistClearResolved.
  ///
  /// In en, this message translates to:
  /// **'Clear resolved'**
  String get wishlistClearResolved;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wishlist items yet'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add something to find later'**
  String get wishlistEmptyHint;

  /// No description provided for @wishlistDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get wishlistDeleteItem;

  /// No description provided for @wishlistDeletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" from wishlist?'**
  String wishlistDeletePrompt(String name);

  /// No description provided for @wishlistClearResolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear resolved'**
  String get wishlistClearResolvedTitle;

  /// No description provided for @wishlistClearResolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 resolved item?} other{Delete {count} resolved items?}}'**
  String wishlistClearResolvedMessage(int count);

  /// No description provided for @wishlistMarkResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get wishlistMarkResolved;

  /// No description provided for @wishlistUnresolve.
  ///
  /// In en, this message translates to:
  /// **'Unresolve'**
  String get wishlistUnresolve;

  /// No description provided for @wishlistAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get wishlistAddTitle;

  /// No description provided for @wishlistEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get wishlistEditTitle;

  /// No description provided for @wishlistTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get wishlistTitleLabel;

  /// No description provided for @wishlistTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Game, movie, or TV show name...'**
  String get wishlistTitleHint;

  /// No description provided for @wishlistTitleMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get wishlistTitleMinChars;

  /// No description provided for @wishlistTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'Type (optional)'**
  String get wishlistTypeOptional;

  /// No description provided for @wishlistTypeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get wishlistTypeAny;

  /// No description provided for @wishlistNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get wishlistNoteOptional;

  /// No description provided for @wishlistNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Platform, year, who recommended...'**
  String get wishlistNoteHint;

  /// No description provided for @welcomeStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeStepWelcome;

  /// No description provided for @welcomeStepApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get welcomeStepApiKeys;

  /// No description provided for @welcomeStepHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get welcomeStepHowItWorks;

  /// No description provided for @welcomeStepReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get welcomeStepReady;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tonkatsu Box'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your collections of retro games,\nmovies, TV shows & anime'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeWhatYouCanDo.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get welcomeWhatYouCanDo;

  /// No description provided for @welcomeFeatureCollections.
  ///
  /// In en, this message translates to:
  /// **'Create collections by platform, genre, or any theme'**
  String get welcomeFeatureCollections;

  /// No description provided for @welcomeFeatureSearch.
  ///
  /// In en, this message translates to:
  /// **'Search games, movies, TV shows & anime via APIs'**
  String get welcomeFeatureSearch;

  /// No description provided for @welcomeFeatureTracking.
  ///
  /// In en, this message translates to:
  /// **'Track progress, rate 1-10, add notes'**
  String get welcomeFeatureTracking;

  /// No description provided for @welcomeFeatureBoards.
  ///
  /// In en, this message translates to:
  /// **'Visual canvas boards with artwork'**
  String get welcomeFeatureBoards;

  /// No description provided for @welcomeFeatureExport.
  ///
  /// In en, this message translates to:
  /// **'Export & import — share collections with friends'**
  String get welcomeFeatureExport;

  /// No description provided for @welcomeWorksWithoutKeys.
  ///
  /// In en, this message translates to:
  /// **'Works without API keys'**
  String get welcomeWorksWithoutKeys;

  /// No description provided for @welcomeChipCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get welcomeChipCollections;

  /// No description provided for @welcomeChipWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get welcomeChipWishlist;

  /// No description provided for @welcomeChipImport.
  ///
  /// In en, this message translates to:
  /// **'Import .xcoll'**
  String get welcomeChipImport;

  /// No description provided for @welcomeChipCanvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas boards'**
  String get welcomeChipCanvas;

  /// No description provided for @welcomeChipRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings & notes'**
  String get welcomeChipRatings;

  /// No description provided for @welcomeApiKeysHint.
  ///
  /// In en, this message translates to:
  /// **'API keys are only needed for searching new games, movies & TV shows. You can import collections and work with them offline.'**
  String get welcomeApiKeysHint;

  /// No description provided for @welcomeChipGames.
  ///
  /// In en, this message translates to:
  /// **'Games (IGDB)'**
  String get welcomeChipGames;

  /// No description provided for @welcomeChipMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies (TMDB)'**
  String get welcomeChipMovies;

  /// No description provided for @welcomeChipTvShows.
  ///
  /// In en, this message translates to:
  /// **'TV Shows (TMDB)'**
  String get welcomeChipTvShows;

  /// No description provided for @welcomeChipAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime (TMDB)'**
  String get welcomeChipAnime;

  /// No description provided for @welcomeApiTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting API Keys'**
  String get welcomeApiTitle;

  /// No description provided for @welcomeApiFreeHint.
  ///
  /// In en, this message translates to:
  /// **'Free registration, takes 2-3 minutes each'**
  String get welcomeApiFreeHint;

  /// No description provided for @welcomeApiIgdbTag.
  ///
  /// In en, this message translates to:
  /// **'IGDB'**
  String get welcomeApiIgdbTag;

  /// No description provided for @welcomeApiIgdbDesc.
  ///
  /// In en, this message translates to:
  /// **'Game search'**
  String get welcomeApiIgdbDesc;

  /// No description provided for @welcomeApiRequired.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get welcomeApiRequired;

  /// No description provided for @welcomeApiTmdbTag.
  ///
  /// In en, this message translates to:
  /// **'TMDB'**
  String get welcomeApiTmdbTag;

  /// No description provided for @welcomeApiTmdbDesc.
  ///
  /// In en, this message translates to:
  /// **'Movies, TV & Anime'**
  String get welcomeApiTmdbDesc;

  /// No description provided for @welcomeApiRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get welcomeApiRecommended;

  /// No description provided for @welcomeApiSgdbTag.
  ///
  /// In en, this message translates to:
  /// **'SGDB'**
  String get welcomeApiSgdbTag;

  /// No description provided for @welcomeApiSgdbDesc.
  ///
  /// In en, this message translates to:
  /// **'Game artwork for boards'**
  String get welcomeApiSgdbDesc;

  /// No description provided for @welcomeApiOptional.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get welcomeApiOptional;

  /// No description provided for @welcomeApiEnterKeysHint.
  ///
  /// In en, this message translates to:
  /// **'Enter keys in Settings → Credentials after setup'**
  String get welcomeApiEnterKeysHint;

  /// No description provided for @welcomeHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get welcomeHowTitle;

  /// No description provided for @welcomeHowAppStructure.
  ///
  /// In en, this message translates to:
  /// **'App structure'**
  String get welcomeHowAppStructure;

  /// No description provided for @welcomeHowMainDesc.
  ///
  /// In en, this message translates to:
  /// **'All items from all collections in one view. Filter by type, sort by rating.'**
  String get welcomeHowMainDesc;

  /// No description provided for @welcomeHowCollectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your collections. Create, organize, manage. Grid or list view per collection.'**
  String get welcomeHowCollectionsDesc;

  /// No description provided for @welcomeHowWishlistDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick list of items to check out later. No API needed.'**
  String get welcomeHowWishlistDesc;

  /// No description provided for @welcomeHowSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Find games, movies & TV shows via API. Add to any collection.'**
  String get welcomeHowSearchDesc;

  /// No description provided for @welcomeHowSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'API keys, cache, database export/import, debug tools.'**
  String get welcomeHowSettingsDesc;

  /// No description provided for @welcomeHowQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get welcomeHowQuickStart;

  /// No description provided for @welcomeHowStep1.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Credentials, enter API keys'**
  String get welcomeHowStep1;

  /// No description provided for @welcomeHowStep2.
  ///
  /// In en, this message translates to:
  /// **'Click Verify Connection, wait for platforms sync'**
  String get welcomeHowStep2;

  /// No description provided for @welcomeHowStep3.
  ///
  /// In en, this message translates to:
  /// **'Go to Collections → + New Collection'**
  String get welcomeHowStep3;

  /// No description provided for @welcomeHowStep4.
  ///
  /// In en, this message translates to:
  /// **'Name it, then Add Items → Search → Add'**
  String get welcomeHowStep4;

  /// No description provided for @welcomeHowStep5.
  ///
  /// In en, this message translates to:
  /// **'Rate, track progress, add notes — you\'re set!'**
  String get welcomeHowStep5;

  /// No description provided for @welcomeHowSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get welcomeHowSharing;

  /// No description provided for @welcomeHowSharingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Export collections as '**
  String get welcomeHowSharingDesc1;

  /// No description provided for @welcomeHowSharingDesc2.
  ///
  /// In en, this message translates to:
  /// **' (light, metadata only) or '**
  String get welcomeHowSharingDesc2;

  /// No description provided for @welcomeHowSharingDesc3.
  ///
  /// In en, this message translates to:
  /// **' (full, with images & canvas — works offline). Import from friends — no API needed!'**
  String get welcomeHowSharingDesc3;

  /// No description provided for @welcomeReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get welcomeReadyTitle;

  /// No description provided for @welcomeReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Head to Settings → Credentials to enter your API keys, or start by importing a collection.'**
  String get welcomeReadyMessage;

  /// No description provided for @welcomeReadyGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get welcomeReadyGoToSettings;

  /// No description provided for @welcomeReadySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip — explore on my own'**
  String get welcomeReadySkip;

  /// No description provided for @welcomeReadyReturnHint.
  ///
  /// In en, this message translates to:
  /// **'You can always return here from Settings'**
  String get welcomeReadyReturnHint;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String updateAvailable(String version);

  /// No description provided for @updateCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: v{version}'**
  String updateCurrent(String version);

  /// No description provided for @chooseCollection.
  ///
  /// In en, this message translates to:
  /// **'Choose Collection'**
  String get chooseCollection;

  /// No description provided for @withoutCollection.
  ///
  /// In en, this message translates to:
  /// **'Without Collection'**
  String get withoutCollection;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @detailMyRating.
  ///
  /// In en, this message translates to:
  /// **'My Rating'**
  String get detailMyRating;

  /// No description provided for @detailRatingValue.
  ///
  /// In en, this message translates to:
  /// **'{rating}/10'**
  String detailRatingValue(int rating);

  /// No description provided for @detailActivityProgress.
  ///
  /// In en, this message translates to:
  /// **'Activity & Progress'**
  String get detailActivityProgress;

  /// No description provided for @detailAuthorReview.
  ///
  /// In en, this message translates to:
  /// **'Author\'s Review'**
  String get detailAuthorReview;

  /// No description provided for @detailEditAuthorReview.
  ///
  /// In en, this message translates to:
  /// **'Edit Author\'s Review'**
  String get detailEditAuthorReview;

  /// No description provided for @detailWriteReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write your review...'**
  String get detailWriteReviewHint;

  /// No description provided for @detailReviewVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visible to others when shared. Your review of this title.'**
  String get detailReviewVisibility;

  /// No description provided for @detailNoReviewEditable.
  ///
  /// In en, this message translates to:
  /// **'No review yet. Tap Edit to add one.'**
  String get detailNoReviewEditable;

  /// No description provided for @detailNoReviewReadonly.
  ///
  /// In en, this message translates to:
  /// **'No review from the author.'**
  String get detailNoReviewReadonly;

  /// No description provided for @detailMyNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get detailMyNotes;

  /// No description provided for @detailEditMyNotes.
  ///
  /// In en, this message translates to:
  /// **'Edit My Notes'**
  String get detailEditMyNotes;

  /// No description provided for @detailWriteNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Write your personal notes...'**
  String get detailWriteNotesHint;

  /// No description provided for @detailNoNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Tap Edit to add your personal notes.'**
  String get detailNoNotesYet;

  /// No description provided for @detailNoNotesReadonly.
  ///
  /// In en, this message translates to:
  /// **'No notes from the author.'**
  String get detailNoNotesReadonly;

  /// No description provided for @unknownGame.
  ///
  /// In en, this message translates to:
  /// **'Unknown Game'**
  String get unknownGame;

  /// No description provided for @unknownMovie.
  ///
  /// In en, this message translates to:
  /// **'Unknown Movie'**
  String get unknownMovie;

  /// No description provided for @unknownTvShow.
  ///
  /// In en, this message translates to:
  /// **'Unknown TV Show'**
  String get unknownTvShow;

  /// No description provided for @unknownAnimation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Animation'**
  String get unknownAnimation;

  /// No description provided for @unknownPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unknown Platform'**
  String get unknownPlatform;

  /// No description provided for @defaultAuthor.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultAuthor;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @allItemsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allItemsAll;

  /// No description provided for @allItemsGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get allItemsGames;

  /// No description provided for @allItemsMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get allItemsMovies;

  /// No description provided for @allItemsTvShows.
  ///
  /// In en, this message translates to:
  /// **'TV Shows'**
  String get allItemsTvShows;

  /// No description provided for @allItemsAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get allItemsAnimation;

  /// No description provided for @allItemsRatingAsc.
  ///
  /// In en, this message translates to:
  /// **'Rating ↑'**
  String get allItemsRatingAsc;

  /// No description provided for @allItemsRatingDesc.
  ///
  /// In en, this message translates to:
  /// **'Rating ↓'**
  String get allItemsRatingDesc;

  /// No description provided for @allItemsRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get allItemsRating;

  /// No description provided for @allItemsNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get allItemsNoItems;

  /// No description provided for @allItemsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No items match filter'**
  String get allItemsNoMatch;

  /// No description provided for @allItemsAddViaCollections.
  ///
  /// In en, this message translates to:
  /// **'Add items via Collections tab'**
  String get allItemsAddViaCollections;

  /// No description provided for @allItemsFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get allItemsFailedToLoad;

  /// No description provided for @debugIgdbMedia.
  ///
  /// In en, this message translates to:
  /// **'IGDB Media'**
  String get debugIgdbMedia;

  /// No description provided for @debugSteamGridDb.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB'**
  String get debugSteamGridDb;

  /// No description provided for @debugGamepad.
  ///
  /// In en, this message translates to:
  /// **'Gamepad'**
  String get debugGamepad;

  /// No description provided for @debugClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get debugClearLogs;

  /// No description provided for @debugRawEvents.
  ///
  /// In en, this message translates to:
  /// **'Raw Events (Gamepads.events)'**
  String get debugRawEvents;

  /// No description provided for @debugServiceEvents.
  ///
  /// In en, this message translates to:
  /// **'Service Events (filtered)'**
  String get debugServiceEvents;

  /// No description provided for @debugEventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String debugEventsCount(int count);

  /// No description provided for @debugPressButton.
  ///
  /// In en, this message translates to:
  /// **'Press any button\non the gamepad...'**
  String get debugPressButton;

  /// No description provided for @debugSearchGames.
  ///
  /// In en, this message translates to:
  /// **'Search games'**
  String get debugSearchGames;

  /// No description provided for @debugEnterGameName.
  ///
  /// In en, this message translates to:
  /// **'Enter game name'**
  String get debugEnterGameName;

  /// No description provided for @debugEnterGameNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a game name to search'**
  String get debugEnterGameNameHint;

  /// No description provided for @debugGameId.
  ///
  /// In en, this message translates to:
  /// **'Game ID'**
  String get debugGameId;

  /// No description provided for @debugEnterGameId.
  ///
  /// In en, this message translates to:
  /// **'Enter SteamGridDB game ID'**
  String get debugEnterGameId;

  /// No description provided for @debugLoadTab.
  ///
  /// In en, this message translates to:
  /// **'Load {tabName}'**
  String debugLoadTab(String tabName);

  /// No description provided for @debugEnterGameIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a game ID and press Load {tabName}'**
  String debugEnterGameIdHint(String tabName);

  /// No description provided for @debugNoImagesFound.
  ///
  /// In en, this message translates to:
  /// **'No images found'**
  String get debugNoImagesFound;

  /// No description provided for @debugSearchTab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get debugSearchTab;

  /// No description provided for @debugGridsTab.
  ///
  /// In en, this message translates to:
  /// **'Grids'**
  String get debugGridsTab;

  /// No description provided for @debugHeroesTab.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get debugHeroesTab;

  /// No description provided for @debugLogosTab.
  ///
  /// In en, this message translates to:
  /// **'Logos'**
  String get debugLogosTab;

  /// No description provided for @debugIconsTab.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get debugIconsTab;

  /// No description provided for @collectionTileStats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} · {percent} completed'**
  String collectionTileStats(int count, String percent);

  /// No description provided for @collectionTileError.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get collectionTileError;

  /// No description provided for @activityDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Dates'**
  String get activityDatesTitle;

  /// No description provided for @activityDatesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get activityDatesAdded;

  /// No description provided for @activityDatesStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get activityDatesStarted;

  /// No description provided for @activityDatesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get activityDatesCompleted;

  /// No description provided for @activityDatesLastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get activityDatesLastActivity;

  /// No description provided for @activityDatesSelectStart.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get activityDatesSelectStart;

  /// No description provided for @activityDatesSelectCompletion.
  ///
  /// In en, this message translates to:
  /// **'Select completion date'**
  String get activityDatesSelectCompletion;

  /// No description provided for @canvasFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load board'**
  String get canvasFailedToLoad;

  /// No description provided for @canvasBoardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Board is empty'**
  String get canvasBoardEmpty;

  /// No description provided for @canvasBoardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add items to the collection first'**
  String get canvasBoardEmptyHint;

  /// No description provided for @canvasCenterView.
  ///
  /// In en, this message translates to:
  /// **'Center view'**
  String get canvasCenterView;

  /// No description provided for @canvasResetPositions.
  ///
  /// In en, this message translates to:
  /// **'Reset positions'**
  String get canvasResetPositions;

  /// No description provided for @canvasVgmapsBrowser.
  ///
  /// In en, this message translates to:
  /// **'VGMaps Browser'**
  String get canvasVgmapsBrowser;

  /// No description provided for @canvasSteamGridDbImages.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB Images'**
  String get canvasSteamGridDbImages;

  /// No description provided for @steamGridDbPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB'**
  String get steamGridDbPanelTitle;

  /// No description provided for @steamGridDbClosePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get steamGridDbClosePanel;

  /// No description provided for @steamGridDbSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search game...'**
  String get steamGridDbSearchHint;

  /// No description provided for @steamGridDbNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'SteamGridDB API key not set. Configure it in Settings.'**
  String get steamGridDbNoApiKey;

  /// No description provided for @steamGridDbBackToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get steamGridDbBackToSearch;

  /// No description provided for @steamGridDbGrids.
  ///
  /// In en, this message translates to:
  /// **'Grids'**
  String get steamGridDbGrids;

  /// No description provided for @steamGridDbHeroes.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get steamGridDbHeroes;

  /// No description provided for @steamGridDbLogos.
  ///
  /// In en, this message translates to:
  /// **'Logos'**
  String get steamGridDbLogos;

  /// No description provided for @steamGridDbIcons.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get steamGridDbIcons;

  /// No description provided for @steamGridDbNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get steamGridDbNoResults;

  /// No description provided for @steamGridDbSearchFirst.
  ///
  /// In en, this message translates to:
  /// **'Search for a game first'**
  String get steamGridDbSearchFirst;

  /// No description provided for @vgmapsClosePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get vgmapsClosePanel;

  /// No description provided for @vgmapsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get vgmapsBack;

  /// No description provided for @vgmapsForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get vgmapsForward;

  /// No description provided for @vgmapsHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get vgmapsHome;

  /// No description provided for @vgmapsReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get vgmapsReload;

  /// No description provided for @vgmapsCaptureImage.
  ///
  /// In en, this message translates to:
  /// **'Capture map image'**
  String get vgmapsCaptureImage;

  /// No description provided for @vgmapsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search game on VGMaps...'**
  String get vgmapsSearchHint;

  /// No description provided for @vgmapsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get vgmapsDismiss;

  /// No description provided for @vgmapsFailedInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize WebView: {error}'**
  String vgmapsFailedInit(String error);

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get discoverCustomize;

  /// No description provided for @discoverTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending This Week'**
  String get discoverTrending;

  /// No description provided for @discoverTopRatedMovies.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Movies'**
  String get discoverTopRatedMovies;

  /// No description provided for @discoverTopRatedTvShows.
  ///
  /// In en, this message translates to:
  /// **'Top Rated TV Shows'**
  String get discoverTopRatedTvShows;

  /// No description provided for @discoverPopularTvShows.
  ///
  /// In en, this message translates to:
  /// **'Popular TV Shows'**
  String get discoverPopularTvShows;

  /// No description provided for @discoverUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get discoverUpcoming;

  /// No description provided for @discoverAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get discoverAnime;

  /// No description provided for @discoverCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Discover'**
  String get discoverCustomizeTitle;

  /// No description provided for @discoverCustomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections to show'**
  String get discoverCustomizeHint;

  /// No description provided for @discoverResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get discoverResetDefault;

  /// No description provided for @discoverAlreadyInCollection.
  ///
  /// In en, this message translates to:
  /// **'Already in collection'**
  String get discoverAlreadyInCollection;

  /// No description provided for @discoverShowWithBadge.
  ///
  /// In en, this message translates to:
  /// **'Show with badge'**
  String get discoverShowWithBadge;

  /// No description provided for @discoverHideCompletely.
  ///
  /// In en, this message translates to:
  /// **'Hide completely'**
  String get discoverHideCompletely;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} reviews'**
  String reviewsShowAll(int count);

  /// No description provided for @reviewsReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get reviewsReadMore;

  /// No description provided for @reviewsInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Reviews in English'**
  String get reviewsInEnglish;

  /// No description provided for @settingsShowRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get settingsShowRecommendations;

  /// No description provided for @settingsShowRecommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show recommendations and reviews on item details'**
  String get settingsShowRecommendationsSubtitle;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

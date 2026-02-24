// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => 'Главная';

  @override
  String get navCollections => 'Коллекции';

  @override
  String get navWishlist => 'Список';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navSettings => 'Настройки';

  @override
  String get statusNotStarted => 'Не начато';

  @override
  String get statusPlaying => 'Играю';

  @override
  String get statusWatching => 'Смотрю';

  @override
  String get statusCompleted => 'Завершено';

  @override
  String get statusDropped => 'Брошено';

  @override
  String get statusPlanned => 'Запланировано';

  @override
  String get mediaTypeGame => 'Игра';

  @override
  String get mediaTypeMovie => 'Фильм';

  @override
  String get mediaTypeTvShow => 'Сериал';

  @override
  String get mediaTypeAnimation => 'Анимация';

  @override
  String get sortManualDisplay => 'Вручную';

  @override
  String get sortManualShort => 'Вручную';

  @override
  String get sortManualDesc => 'Свой порядок';

  @override
  String get sortDateDisplay => 'Дата добавления';

  @override
  String get sortDateShort => 'Дата';

  @override
  String get sortDateDesc => 'Сначала новые';

  @override
  String get sortStatusDisplay => 'Статус';

  @override
  String get sortStatusShort => 'Статус';

  @override
  String get sortStatusDesc => 'Сначала активные';

  @override
  String get sortNameDisplay => 'Название';

  @override
  String get sortNameShort => 'А-Я';

  @override
  String get sortNameDesc => 'По алфавиту';

  @override
  String get sortRatingDisplay => 'Мой рейтинг';

  @override
  String get sortRatingShort => 'Оценка';

  @override
  String get sortRatingDesc => 'Сначала лучшие';

  @override
  String get searchSortRelevanceShort => 'Рел';

  @override
  String get searchSortRelevanceDisplay => 'Релевантность';

  @override
  String get searchSortDateShort => 'Дата';

  @override
  String get searchSortDateDisplay => 'Дата';

  @override
  String get searchSortRatingShort => 'Оценка';

  @override
  String get searchSortRatingDisplay => 'Рейтинг';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get save => 'Сохранить';

  @override
  String get add => 'Добавить';

  @override
  String get delete => 'Удалить';

  @override
  String get rename => 'Переименовать';

  @override
  String get retry => 'Повторить';

  @override
  String get edit => 'Редактировать';

  @override
  String get done => 'Готово';

  @override
  String get clear => 'Очистить';

  @override
  String get reset => 'Сбросить';

  @override
  String get search => 'Поиск';

  @override
  String get open => 'Открыть';

  @override
  String get remove => 'Убрать';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get skip => 'Пропустить';

  @override
  String get update => 'Обновить';

  @override
  String get test => 'Тест';

  @override
  String get close => 'Закрыть';

  @override
  String get keep => 'Оставить';

  @override
  String get change => 'Изменить';

  @override
  String get settingsProfile => 'Профиль';

  @override
  String get settingsAuthorName => 'Имя автора';

  @override
  String get settingsSettings => 'Настройки';

  @override
  String get settingsCredentials => 'Учётные данные';

  @override
  String get settingsCredentialsSubtitle =>
      'Ключи API: IGDB, SteamGridDB, TMDB';

  @override
  String get settingsCache => 'Кэш';

  @override
  String get settingsCacheSubtitle => 'Настройки кэша изображений';

  @override
  String get settingsDatabase => 'База данных';

  @override
  String get settingsDatabaseSubtitle => 'Экспорт, импорт, сброс';

  @override
  String get settingsTraktImport => 'Импорт Trakt';

  @override
  String get settingsTraktImportSubtitle => 'Импорт из ZIP-экспорта Trakt.tv';

  @override
  String get settingsDebug => 'Отладка';

  @override
  String get settingsDebugSubtitle => 'Инструменты разработчика';

  @override
  String get settingsDebugSubtitleNoKey => 'Сначала укажите ключ SteamGridDB';

  @override
  String get settingsHelp => 'Справка';

  @override
  String get settingsWelcomeGuide => 'Вводный тур';

  @override
  String get settingsWelcomeGuideSubtitle => 'Знакомство с Tonkatsu Box';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsCreditsLicenses => 'Благодарности и лицензии';

  @override
  String get settingsCreditsLicensesSubtitle =>
      'TMDB, IGDB, SteamGridDB, open-source лицензии';

  @override
  String get settingsError => 'Ошибка';

  @override
  String get settingsAppLanguage => 'Язык приложения';

  @override
  String get credentialsTitle => 'Учётные данные';

  @override
  String get credentialsWelcome => 'Добро пожаловать в Tonkatsu Box!';

  @override
  String get credentialsWelcomeHint =>
      'Для начала работы настройте учётные данные IGDB API. Получите Client ID и Client Secret в Twitch Developer Console.';

  @override
  String get credentialsCopyTwitchUrl => 'Копировать ссылку на Twitch Console';

  @override
  String credentialsUrlCopied(String url) {
    return 'URL скопирован: $url';
  }

  @override
  String get credentialsIgdbSection => 'Учётные данные IGDB API';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Введите ваш Twitch Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Введите ваш Twitch Client Secret';

  @override
  String get credentialsConnectionStatus => 'Статус подключения';

  @override
  String get credentialsPlatformsSynced => 'Платформы синхронизированы';

  @override
  String get credentialsLastSync => 'Последняя синхронизация';

  @override
  String get credentialsVerifyConnection => 'Проверить подключение';

  @override
  String get credentialsRefreshPlatforms => 'Обновить платформы';

  @override
  String get credentialsSteamGridDbSection => 'SteamGridDB API';

  @override
  String get credentialsApiKey => 'Ключ API';

  @override
  String get credentialsUsingBuiltInKey => 'Используется встроенный ключ';

  @override
  String get credentialsEnterSteamGridDbKey =>
      'Введите ваш ключ SteamGridDB API';

  @override
  String get credentialsTmdbSection => 'TMDB API (фильмы и сериалы)';

  @override
  String get credentialsEnterTmdbKey => 'Введите ваш ключ TMDB API (v3)';

  @override
  String get credentialsContentLanguage => 'Язык контента';

  @override
  String get credentialsOwnKeyHint =>
      'Для лучших лимитов рекомендуем использовать свой ключ API.';

  @override
  String get credentialsConnected => 'Подключено';

  @override
  String get credentialsConnectionError => 'Ошибка подключения';

  @override
  String get credentialsChecking => 'Проверка...';

  @override
  String get credentialsNotConnected => 'Не подключено';

  @override
  String get credentialsEnterBoth => 'Введите и Client ID, и Client Secret';

  @override
  String get credentialsConnectedSynced =>
      'Подключено, платформы синхронизированы!';

  @override
  String get credentialsConnectedSyncFailed =>
      'Подключено, но синхронизация платформ не удалась';

  @override
  String get credentialsPlatformsSyncedOk =>
      'Платформы успешно синхронизированы!';

  @override
  String get credentialsDownloadingLogos => 'Загрузка логотипов платформ...';

  @override
  String credentialsDownloadedLogos(int count) {
    return 'Загружено логотипов: $count';
  }

  @override
  String get credentialsFailedDownloadLogos => 'Не удалось загрузить логотипы';

  @override
  String get credentialsApiKeySaved => 'Ключ API сохранён';

  @override
  String get credentialsNoApiKey => 'Нет ключа API';

  @override
  String get credentialsResetToBuiltIn => 'Сбросить на встроенный ключ';

  @override
  String get credentialsSteamGridDbKeyValid =>
      'Ключ SteamGridDB API действителен';

  @override
  String get credentialsSteamGridDbKeyInvalid =>
      'Ключ SteamGridDB API недействителен';

  @override
  String get credentialsTmdbKeyValid => 'Ключ TMDB API действителен';

  @override
  String get credentialsTmdbKeyInvalid => 'Ключ TMDB API недействителен';

  @override
  String get credentialsEnterSteamGridDbKeyError =>
      'Введите ключ SteamGridDB API';

  @override
  String get credentialsEnterTmdbKeyError => 'Введите ключ TMDB API';

  @override
  String get credentialsTmdbKeySaved => 'Ключ TMDB API сохранён';

  @override
  String timeAgo(int value, String unit) {
    return '$value $unit назад';
  }

  @override
  String timeUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String timeUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'часов',
      few: 'часа',
      one: 'час',
    );
    return '$_temp0';
  }

  @override
  String timeUnitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'минут',
      few: 'минуты',
      one: 'минуту',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'Только что';

  @override
  String get cacheTitle => 'Кэш';

  @override
  String get cacheImageCache => 'Кэш изображений';

  @override
  String get cacheOfflineMode => 'Офлайн-режим';

  @override
  String get cacheOfflineModeSubtitle =>
      'Сохранять изображения локально для офлайн-доступа';

  @override
  String get cacheCacheFolder => 'Папка кэша';

  @override
  String get cacheSelectFolder => 'Выбрать папку';

  @override
  String get cacheCacheSize => 'Размер кэша';

  @override
  String get cacheClearCache => 'Очистить кэш';

  @override
  String get cacheClearCacheTitle => 'Очистить кэш?';

  @override
  String get cacheClearCacheMessage =>
      'Все локально сохранённые изображения будут удалены. Они загрузятся снова при следующей синхронизации.';

  @override
  String get cacheFolderUpdated => 'Папка кэша обновлена';

  @override
  String get cacheCleared => 'Кэш очищен';

  @override
  String get cacheSelectFolderDialog => 'Выберите папку для кэша изображений';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count файлов, $size';
  }

  @override
  String get databaseTitle => 'База данных';

  @override
  String get databaseConfiguration => 'Конфигурация';

  @override
  String get databaseConfigSubtitle =>
      'Экспорт или импорт ваших ключей API и настроек.';

  @override
  String get databaseExportConfig => 'Экспорт конфигурации';

  @override
  String get databaseImportConfig => 'Импорт конфигурации';

  @override
  String get databaseDangerZone => 'Опасная зона';

  @override
  String get databaseDangerZoneMessage =>
      'Удаляет все коллекции, игры, фильмы, сериалы и данные доски. Настройки и ключи API сохранятся.';

  @override
  String get databaseResetDatabase => 'Сбросить базу данных';

  @override
  String get databaseResetTitle => 'Сбросить базу данных?';

  @override
  String get databaseResetMessage =>
      'Это навсегда удалит все ваши коллекции, игры, фильмы, сериалы, прогресс просмотра и данные доски.\n\nВаши ключи API и настройки сохранятся.\n\nЭто действие нельзя отменить.';

  @override
  String databaseConfigExported(String path) {
    return 'Конфигурация экспортирована в $path';
  }

  @override
  String get databaseConfigImported => 'Конфигурация успешно импортирована';

  @override
  String get databaseReset => 'База данных сброшена';

  @override
  String get traktTitle => 'Импорт Trakt';

  @override
  String get traktImportFrom => 'Импорт из Trakt.tv';

  @override
  String get traktImportDescription =>
      'Скачайте данные с trakt.tv/users/YOU/data и выберите ZIP-файл ниже.';

  @override
  String get traktZipFile => 'ZIP-файл';

  @override
  String get traktSelectZipFile => 'Выбрать ZIP-файл';

  @override
  String get traktSelectZipExport => 'Выберите ZIP-экспорт Trakt';

  @override
  String get traktPreview => 'Предпросмотр';

  @override
  String traktUser(String username) {
    return 'Пользователь Trakt: $username';
  }

  @override
  String get traktWatchedMovies => 'Просмотренные фильмы';

  @override
  String get traktWatchedShows => 'Просмотренные сериалы';

  @override
  String get traktRatedMovies => 'Оценённые фильмы';

  @override
  String get traktRatedShows => 'Оценённые сериалы';

  @override
  String get traktWatchlist => 'Список просмотра';

  @override
  String get traktOptions => 'Параметры';

  @override
  String get traktImportWatched => 'Импортировать просмотренное';

  @override
  String get traktImportWatchedDesc => 'Фильмы и сериалы как завершённые';

  @override
  String get traktImportRatings => 'Импортировать оценки';

  @override
  String get traktImportRatingsDesc =>
      'Применить пользовательские оценки (1-10)';

  @override
  String get traktImportWatchlist => 'Импортировать список просмотра';

  @override
  String get traktImportWatchlistDesc =>
      'Добавить как запланированные или в вишлист';

  @override
  String get traktTargetCollection => 'Целевая коллекция';

  @override
  String get traktCreateNew => 'Создать новую коллекцию';

  @override
  String get traktUseExisting => 'Использовать существующую';

  @override
  String get traktNoCollections => 'Нет доступных коллекций';

  @override
  String get traktSelectCollection => 'Выберите коллекцию';

  @override
  String get traktErrorLoadingCollections => 'Ошибка загрузки коллекций';

  @override
  String get traktStartImport => 'Начать импорт';

  @override
  String get traktInvalidExport => 'Некорректный экспорт Trakt';

  @override
  String traktImportedItems(int count) {
    return 'Импортировано элементов: $count';
  }

  @override
  String get traktImporting => 'Импорт из Trakt';

  @override
  String get creditsTitle => 'Благодарности';

  @override
  String get creditsDataProviders => 'Источники данных';

  @override
  String get creditsTmdbAttribution =>
      'Приложение использует TMDB API, но не одобрено и не сертифицировано TMDB.';

  @override
  String get creditsIgdbAttribution => 'Данные об играх предоставлены IGDB.';

  @override
  String get creditsSteamGridDbAttribution =>
      'Иллюстрации предоставлены SteamGridDB.';

  @override
  String get creditsOpenSource => 'Открытый исходный код';

  @override
  String get creditsOpenSourceDesc =>
      'Tonkatsu Box — бесплатное ПО с открытым исходным кодом, распространяемое под лицензией MIT.';

  @override
  String get creditsViewLicenses => 'Посмотреть лицензии';

  @override
  String get collectionsNewCollection => 'Новая коллекция';

  @override
  String get collectionsImportCollection => 'Импорт коллекции';

  @override
  String get collectionsNoCollectionsYet => 'Пока нет коллекций';

  @override
  String get collectionsNoCollectionsHint =>
      'Создайте свою первую коллекцию, чтобы начать\nвести учёт игрового прогресса.';

  @override
  String get collectionsFailedToLoad => 'Не удалось загрузить коллекции';

  @override
  String collectionsCount(int count) {
    return 'Коллекции ($count)';
  }

  @override
  String get collectionsUncategorized => 'Без категории';

  @override
  String collectionsUncategorizedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count элементов',
      few: '$count элемента',
      one: '1 элемент',
    );
    return '$_temp0';
  }

  @override
  String get collectionsRenamed => 'Коллекция переименована';

  @override
  String collectionsFailedToRename(String error) {
    return 'Ошибка переименования: $error';
  }

  @override
  String get collectionsDeleted => 'Коллекция удалена';

  @override
  String collectionsFailedToDelete(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return 'Ошибка создания коллекции: $error';
  }

  @override
  String collectionsImported(String name, int count) {
    return 'Импортирована \"$name\" — $count элементов';
  }

  @override
  String get collectionsImporting => 'Импорт коллекции';

  @override
  String get collectionNotFound => 'Коллекция не найдена';

  @override
  String get collectionAddItems => 'Добавить элементы';

  @override
  String get collectionSwitchToList => 'Переключить на список';

  @override
  String get collectionSwitchToBoard => 'Переключить на доску';

  @override
  String get collectionUnlockBoard => 'Разблокировать доску';

  @override
  String get collectionLockBoard => 'Заблокировать доску';

  @override
  String get collectionExport => 'Экспорт';

  @override
  String get collectionNoItemsYet => 'Пока нет элементов';

  @override
  String get collectionEmpty => 'Пустая коллекция';

  @override
  String get collectionDeleteEmptyPrompt =>
      'Коллекция теперь пуста. Удалить её?';

  @override
  String get collectionRemoveItemTitle => 'Убрать элемент?';

  @override
  String collectionRemoveItemMessage(String name) {
    return 'Убрать $name из этой коллекции?';
  }

  @override
  String get collectionMoveToCollection => 'Переместить в коллекцию';

  @override
  String get collectionExportFormat => 'Формат экспорта';

  @override
  String get collectionChooseExportFormat => 'Выберите формат экспорта:';

  @override
  String get collectionExportLight => 'Лёгкий (.xcoll)';

  @override
  String get collectionExportLightDesc => 'Только элементы, файл меньше';

  @override
  String get collectionExportFull => 'Полный (.xcollx)';

  @override
  String get collectionExportFullDesc =>
      'С изображениями и доской — работает офлайн';

  @override
  String get collectionFilterAll => 'Все';

  @override
  String get collectionFilterByType => 'Фильтр по типу';

  @override
  String get collectionFilterGames => 'Игры';

  @override
  String get collectionFilterMovies => 'Фильмы';

  @override
  String get collectionFilterTvShows => 'Сериалы';

  @override
  String get collectionFilterAnimation => 'Анимация';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name перемещён в $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name уже есть в $collection';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name удалён';
  }

  @override
  String get boardTab => 'Доска';

  @override
  String get imageAddedToBoard => 'Изображение добавлено на доску';

  @override
  String get mapAddedToBoard => 'Карта добавлена на доску';

  @override
  String get loading => 'Загрузка...';

  @override
  String get gameNotFound => 'Игра не найдена';

  @override
  String get movieNotFound => 'Фильм не найден';

  @override
  String get tvShowNotFound => 'Сериал не найден';

  @override
  String get animationNotFound => 'Анимация не найдена';

  @override
  String get animatedMovie => 'Мультфильм';

  @override
  String get animatedSeries => 'Мультсериал';

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '$hoursч $minutesм';
  }

  @override
  String runtimeHours(int hours) {
    return '$hoursч';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '$minutesм';
  }

  @override
  String totalSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сезонов',
      few: '$count сезона',
      one: '1 сезон',
    );
    return '$_temp0';
  }

  @override
  String totalEpisodes(int count) {
    return '$count эп';
  }

  @override
  String seasonName(int number) {
    return 'Сезон $number';
  }

  @override
  String get episodeProgress => 'Прогресс просмотра';

  @override
  String episodesWatchedOf(int watched, int total) {
    return 'Просмотрено $watched/$total';
  }

  @override
  String episodesWatched(int count) {
    return 'Просмотрено: $count';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total эпизодов';
  }

  @override
  String get noSeasonData => 'Данные о сезонах недоступны';

  @override
  String get refreshFromTmdb => 'Обновить из TMDB';

  @override
  String get markAllWatched => 'Отметить все';

  @override
  String get unmarkAll => 'Снять отметки';

  @override
  String get noEpisodesFound => 'Эпизоды не найдены';

  @override
  String episodeWatchedDate(String date) {
    return 'просмотрено $date';
  }

  @override
  String get createCollectionTitle => 'Новая коллекция';

  @override
  String get createCollectionNameLabel => 'Название коллекции';

  @override
  String get createCollectionNameHint => 'напр., Классика SNES';

  @override
  String get createCollectionEnterName => 'Введите название';

  @override
  String get createCollectionNameTooShort =>
      'Название должно содержать минимум 2 символа';

  @override
  String get createCollectionAuthor => 'Автор';

  @override
  String get createCollectionAuthorHint => 'Ваше имя или ник';

  @override
  String get createCollectionEnterAuthor => 'Введите имя автора';

  @override
  String get renameCollectionTitle => 'Переименовать коллекцию';

  @override
  String get deleteCollectionTitle => 'Удалить коллекцию?';

  @override
  String deleteCollectionMessage(String name) {
    return 'Вы уверены, что хотите удалить $name?\n\nЭто действие нельзя отменить.';
  }

  @override
  String get canvasAddText => 'Добавить текст';

  @override
  String get canvasAddImage => 'Добавить изображение';

  @override
  String get canvasAddLink => 'Добавить ссылку';

  @override
  String get canvasFindImages => 'Найти изображения...';

  @override
  String get canvasBrowseMaps => 'Обзор карт...';

  @override
  String get canvasConnect => 'Соединить';

  @override
  String get canvasBringToFront => 'На передний план';

  @override
  String get canvasSendToBack => 'На задний план';

  @override
  String get canvasEditConnection => 'Редактировать соединение';

  @override
  String get canvasDeleteConnection => 'Удалить соединение';

  @override
  String get canvasDeleteElement => 'Удалить элемент';

  @override
  String get canvasDeleteElementMessage =>
      'Вы уверены, что хотите удалить этот элемент?';

  @override
  String get canvasAddToBoard => 'Добавить на доску';

  @override
  String get addTextTitle => 'Добавить текст';

  @override
  String get editTextTitle => 'Редактировать текст';

  @override
  String get textContentLabel => 'Содержимое текста';

  @override
  String get fontSizeLabel => 'Размер шрифта';

  @override
  String get fontSizeSmall => 'Маленький';

  @override
  String get fontSizeMedium => 'Средний';

  @override
  String get fontSizeLarge => 'Большой';

  @override
  String get fontSizeTitle => 'Заголовок';

  @override
  String get addImageTitle => 'Добавить изображение';

  @override
  String get editImageTitle => 'Редактировать изображение';

  @override
  String get imageFromUrl => 'По URL';

  @override
  String get imageFromFile => 'Из файла';

  @override
  String get imageUrlLabel => 'URL изображения';

  @override
  String get imageUrlHint => 'https://example.com/image.png';

  @override
  String get imageChooseFile => 'Выбрать файл';

  @override
  String get imageChooseAnother => 'Выбрать другой';

  @override
  String get addLinkTitle => 'Добавить ссылку';

  @override
  String get editLinkTitle => 'Редактировать ссылку';

  @override
  String get linkUrlLabel => 'URL';

  @override
  String get linkUrlHint => 'https://example.com';

  @override
  String get linkLabelOptional => 'Подпись (необязательно)';

  @override
  String get linkLabelHint => 'Моя ссылка';

  @override
  String get connectionColorGray => 'Серый';

  @override
  String get connectionColorRed => 'Красный';

  @override
  String get connectionColorOrange => 'Оранжевый';

  @override
  String get connectionColorYellow => 'Жёлтый';

  @override
  String get connectionColorGreen => 'Зелёный';

  @override
  String get connectionColorBlue => 'Синий';

  @override
  String get connectionColorPurple => 'Фиолетовый';

  @override
  String get connectionColorBlack => 'Чёрный';

  @override
  String get connectionColorWhite => 'Белый';

  @override
  String get editConnectionTitle => 'Редактировать соединение';

  @override
  String get connectionLabelHint => 'напр. зависит от, связано с...';

  @override
  String get connectionColorLabel => 'Цвет';

  @override
  String get connectionStyleLabel => 'Стиль';

  @override
  String get connectionStyleSolid => 'Сплошная';

  @override
  String get connectionStyleDashed => 'Пунктирная';

  @override
  String get connectionStyleArrow => 'Стрелка';

  @override
  String get searchTabTv => 'ТВ';

  @override
  String get searchTabGames => 'Игры';

  @override
  String get searchHintTv => 'Поиск ТВ...';

  @override
  String get searchHintGames => 'Поиск игр...';

  @override
  String get searchSelectPlatform => 'Выбрать платформу';

  @override
  String get searchAddToCollection => 'Добавить в коллекцию';

  @override
  String searchAddedToCollection(String name) {
    return '$name добавлен в коллекцию';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name добавлен в $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name уже в коллекции';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name уже в $collection';
  }

  @override
  String get searchGoToSettings => 'Перейти в настройки';

  @override
  String get searchMinCharsHint => 'Введите минимум 2 символа и нажмите Enter';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String searchNothingFoundFor(String query) {
    return 'Ничего не найдено по запросу «$query»';
  }

  @override
  String get searchNoInternet => 'Нет подключения к интернету';

  @override
  String get searchFailed => 'Ошибка поиска';

  @override
  String get searchCheckConnection =>
      'Проверьте подключение к интернету и попробуйте снова.';

  @override
  String get searchDescription => 'Описание';

  @override
  String get platformFilterTitle => 'Выбор платформ';

  @override
  String get platformFilterClearAll => 'Очистить всё';

  @override
  String get platformFilterSearchHint => 'Поиск платформ...';

  @override
  String platformFilterSelected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String platformFilterCount(int count) {
    return 'Платформ: $count';
  }

  @override
  String get platformFilterShowAll => 'Показать все';

  @override
  String platformFilterApply(int count) {
    return 'Применить ($count)';
  }

  @override
  String get platformFilterNone => 'Платформы не найдены';

  @override
  String get platformFilterTryDifferent => 'Попробуйте другой запрос';

  @override
  String get wishlistHideResolved => 'Скрыть выполненные';

  @override
  String get wishlistShowResolved => 'Показать выполненные';

  @override
  String get wishlistClearResolved => 'Удалить выполненные';

  @override
  String get wishlistEmpty => 'Список желаний пуст';

  @override
  String get wishlistEmptyHint =>
      'Нажмите + чтобы добавить что-нибудь на потом';

  @override
  String get wishlistDeleteItem => 'Удалить элемент';

  @override
  String wishlistDeletePrompt(String name) {
    return 'Удалить \"$name\" из списка желаний?';
  }

  @override
  String get wishlistClearResolvedTitle => 'Удалить выполненные';

  @override
  String wishlistClearResolvedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count выполненных элементов?',
      few: 'Удалить $count выполненных элемента?',
      one: 'Удалить 1 выполненный элемент?',
    );
    return '$_temp0';
  }

  @override
  String get wishlistMarkResolved => 'Выполнено';

  @override
  String get wishlistUnresolve => 'Вернуть';

  @override
  String get wishlistAddTitle => 'Добавить';

  @override
  String get wishlistEditTitle => 'Редактировать';

  @override
  String get wishlistTitleLabel => 'Название';

  @override
  String get wishlistTitleHint => 'Игра, фильм или сериал...';

  @override
  String get wishlistTitleMinChars => 'Минимум 2 символа';

  @override
  String get wishlistTypeOptional => 'Тип (необязательно)';

  @override
  String get wishlistTypeAny => 'Любой';

  @override
  String get wishlistNoteOptional => 'Заметка (необязательно)';

  @override
  String get wishlistNoteHint => 'Платформа, год, кто рекомендовал...';

  @override
  String get welcomeStepWelcome => 'Добро пожаловать';

  @override
  String get welcomeStepApiKeys => 'Ключи API';

  @override
  String get welcomeStepHowItWorks => 'Как это работает';

  @override
  String get welcomeStepReady => 'Готово!';

  @override
  String get welcomeTitle => 'Добро пожаловать в Tonkatsu Box';

  @override
  String get welcomeSubtitle =>
      'Организуйте коллекции ретро-игр,\nфильмов, сериалов и аниме';

  @override
  String get welcomeWhatYouCanDo => 'Что вы можете делать';

  @override
  String get welcomeFeatureCollections =>
      'Создавайте коллекции по платформе, жанру или любой теме';

  @override
  String get welcomeFeatureSearch =>
      'Ищите игры, фильмы, сериалы и аниме через API';

  @override
  String get welcomeFeatureTracking =>
      'Отслеживайте прогресс, оценивайте 1-10, добавляйте заметки';

  @override
  String get welcomeFeatureBoards => 'Визуальные доски с иллюстрациями';

  @override
  String get welcomeFeatureExport =>
      'Экспорт и импорт — делитесь коллекциями с друзьями';

  @override
  String get welcomeWorksWithoutKeys => 'Работает без ключей API';

  @override
  String get welcomeChipCollections => 'Коллекции';

  @override
  String get welcomeChipWishlist => 'Список желаний';

  @override
  String get welcomeChipImport => 'Импорт .xcoll';

  @override
  String get welcomeChipCanvas => 'Доски';

  @override
  String get welcomeChipRatings => 'Оценки и заметки';

  @override
  String get welcomeApiKeysHint =>
      'Ключи API нужны только для поиска новых игр, фильмов и сериалов. Вы можете импортировать коллекции и работать с ними офлайн.';

  @override
  String get welcomeChipGames => 'Игры (IGDB)';

  @override
  String get welcomeChipMovies => 'Фильмы (TMDB)';

  @override
  String get welcomeChipTvShows => 'Сериалы (TMDB)';

  @override
  String get welcomeChipAnime => 'Аниме (TMDB)';

  @override
  String get welcomeApiTitle => 'Получение ключей API';

  @override
  String get welcomeApiFreeHint => 'Бесплатная регистрация, займёт 2-3 минуты';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => 'Поиск игр';

  @override
  String get welcomeApiRequired => 'ОБЯЗАТЕЛЬНО';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => 'Фильмы, сериалы и аниме';

  @override
  String get welcomeApiRecommended => 'РЕКОМЕНДУЕТСЯ';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => 'Иллюстрации для досок';

  @override
  String get welcomeApiOptional => 'НЕОБЯЗАТЕЛЬНО';

  @override
  String get welcomeApiEnterKeysHint =>
      'Введите ключи в Настройки → Учётные данные';

  @override
  String get welcomeHowTitle => 'Как это работает';

  @override
  String get welcomeHowAppStructure => 'Структура приложения';

  @override
  String get welcomeHowMainDesc =>
      'Все элементы из всех коллекций в одном месте. Фильтрация по типу, сортировка по оценке.';

  @override
  String get welcomeHowCollectionsDesc =>
      'Ваши коллекции. Создавайте, организуйте, управляйте. Сетка или список.';

  @override
  String get welcomeHowWishlistDesc =>
      'Быстрый список того, что хотите посмотреть позже. API не нужен.';

  @override
  String get welcomeHowSearchDesc =>
      'Поиск игр, фильмов и сериалов через API. Добавляйте в любую коллекцию.';

  @override
  String get welcomeHowSettingsDesc =>
      'Ключи API, кэш, экспорт/импорт БД, отладочные инструменты.';

  @override
  String get welcomeHowQuickStart => 'Быстрый старт';

  @override
  String get welcomeHowStep1 =>
      'Откройте Настройки → Учётные данные, введите ключи API';

  @override
  String get welcomeHowStep2 =>
      'Нажмите «Проверить подключение», дождитесь синхронизации';

  @override
  String get welcomeHowStep3 => 'Перейдите в Коллекции → + Новая коллекция';

  @override
  String get welcomeHowStep4 =>
      'Назовите её, затем Добавить → Поиск → Добавить';

  @override
  String get welcomeHowStep5 =>
      'Оценивайте, отслеживайте прогресс, пишите заметки — готово!';

  @override
  String get welcomeHowSharing => 'Обмен';

  @override
  String get welcomeHowSharingDesc1 => 'Экспортируйте коллекции в формате ';

  @override
  String get welcomeHowSharingDesc2 => ' (лёгкий, только метаданные) или ';

  @override
  String get welcomeHowSharingDesc3 =>
      ' (полный, с изображениями и доской — работает офлайн). Импортируйте у друзей — API не нужен!';

  @override
  String get welcomeReadyTitle => 'Всё готово!';

  @override
  String get welcomeReadyMessage =>
      'Перейдите в Настройки → Учётные данные, чтобы ввести ключи API, или начните с импорта коллекции.';

  @override
  String get welcomeReadyGoToSettings => 'Перейти в настройки';

  @override
  String get welcomeReadySkip => 'Пропустить — разберусь сам';

  @override
  String get welcomeReadyReturnHint =>
      'Вы всегда можете вернуться сюда из Настроек';

  @override
  String updateAvailable(String version) {
    return 'Доступно обновление: v$version';
  }

  @override
  String updateCurrent(String version) {
    return 'Текущая: v$version';
  }

  @override
  String get chooseCollection => 'Выбрать коллекцию';

  @override
  String get withoutCollection => 'Без коллекции';

  @override
  String get detailStatus => 'Статус';

  @override
  String get detailMyRating => 'Мой рейтинг';

  @override
  String detailRatingValue(int rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => 'Активность и прогресс';

  @override
  String get detailAuthorReview => 'Рецензия автора';

  @override
  String get detailEditAuthorReview => 'Редактировать рецензию';

  @override
  String get detailWriteReviewHint => 'Напишите вашу рецензию...';

  @override
  String get detailReviewVisibility =>
      'Видна другим при обмене. Ваша рецензия на этот тайтл.';

  @override
  String get detailNoReviewEditable =>
      'Рецензии пока нет. Нажмите «Редактировать», чтобы добавить.';

  @override
  String get detailNoReviewReadonly => 'Автор не оставил рецензию.';

  @override
  String get detailMyNotes => 'Мои заметки';

  @override
  String get detailEditMyNotes => 'Редактировать заметки';

  @override
  String get detailWriteNotesHint => 'Напишите ваши личные заметки...';

  @override
  String get detailNoNotesYet =>
      'Заметок пока нет. Нажмите «Редактировать», чтобы добавить.';

  @override
  String get detailNoNotesReadonly => 'Автор не оставил заметок.';

  @override
  String get unknownGame => 'Неизвестная игра';

  @override
  String get unknownMovie => 'Неизвестный фильм';

  @override
  String get unknownTvShow => 'Неизвестный сериал';

  @override
  String get unknownAnimation => 'Неизвестная анимация';

  @override
  String get unknownPlatform => 'Неизвестная платформа';

  @override
  String get defaultAuthor => 'Пользователь';

  @override
  String errorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get allItemsAll => 'Все';

  @override
  String get allItemsGames => 'Игры';

  @override
  String get allItemsMovies => 'Фильмы';

  @override
  String get allItemsTvShows => 'Сериалы';

  @override
  String get allItemsAnimation => 'Анимация';

  @override
  String get allItemsRatingAsc => 'Оценка ↑';

  @override
  String get allItemsRatingDesc => 'Оценка ↓';

  @override
  String get allItemsRating => 'Оценка';

  @override
  String get allItemsNoItems => 'Пока нет элементов';

  @override
  String get allItemsNoMatch => 'Нет элементов по фильтру';

  @override
  String get allItemsAddViaCollections =>
      'Добавьте элементы через вкладку Коллекции';

  @override
  String get allItemsFailedToLoad => 'Не удалось загрузить элементы';

  @override
  String get debugIgdbMedia => 'IGDB Медиа';

  @override
  String get debugSteamGridDb => 'SteamGridDB';

  @override
  String get debugGamepad => 'Геймпад';

  @override
  String get debugClearLogs => 'Очистить логи';

  @override
  String get debugRawEvents => 'Сырые события (Gamepads.events)';

  @override
  String get debugServiceEvents => 'Обработанные события (фильтрованные)';

  @override
  String debugEventsCount(int count) {
    return 'Событий: $count';
  }

  @override
  String get debugPressButton => 'Нажмите любую кнопку\nна геймпаде...';

  @override
  String get debugSearchGames => 'Поиск игр';

  @override
  String get debugEnterGameName => 'Название игры';

  @override
  String get debugEnterGameNameHint => 'Введите название игры для поиска';

  @override
  String get debugGameId => 'ID игры';

  @override
  String get debugEnterGameId => 'Введите SteamGridDB ID игры';

  @override
  String debugLoadTab(String tabName) {
    return 'Загрузить $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return 'Введите ID игры и нажмите «Загрузить $tabName»';
  }

  @override
  String get debugNoImagesFound => 'Изображения не найдены';

  @override
  String get debugSearchTab => 'Поиск';

  @override
  String get debugGridsTab => 'Обложки';

  @override
  String get debugHeroesTab => 'Баннеры';

  @override
  String get debugLogosTab => 'Логотипы';

  @override
  String get debugIconsTab => 'Иконки';

  @override
  String collectionTileStats(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count элементов',
      few: '$count элемента',
      one: '1 элемент',
    );
    return '$_temp0 · $percent завершено';
  }

  @override
  String get collectionTileError => 'Ошибка загрузки статистики';

  @override
  String get activityDatesTitle => 'Даты активности';

  @override
  String get activityDatesAdded => 'Добавлено';

  @override
  String get activityDatesStarted => 'Начато';

  @override
  String get activityDatesCompleted => 'Завершено';

  @override
  String get activityDatesLastActivity => 'Последняя активность';

  @override
  String get activityDatesSelectStart => 'Выберите дату начала';

  @override
  String get activityDatesSelectCompletion => 'Выберите дату завершения';

  @override
  String get canvasFailedToLoad => 'Не удалось загрузить доску';

  @override
  String get canvasBoardEmpty => 'Доска пуста';

  @override
  String get canvasBoardEmptyHint => 'Сначала добавьте элементы в коллекцию';

  @override
  String get canvasCenterView => 'Центрировать вид';

  @override
  String get canvasResetPositions => 'Сбросить позиции';

  @override
  String get canvasVgmapsBrowser => 'Браузер VGMaps';

  @override
  String get canvasSteamGridDbImages => 'Изображения SteamGridDB';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get steamGridDbClosePanel => 'Закрыть панель';

  @override
  String get steamGridDbSearchHint => 'Поиск игры...';

  @override
  String get steamGridDbNoApiKey =>
      'Ключ SteamGridDB API не задан. Настройте его в Настройках.';

  @override
  String get steamGridDbBackToSearch => 'Назад к поиску';

  @override
  String get steamGridDbGrids => 'Обложки';

  @override
  String get steamGridDbHeroes => 'Баннеры';

  @override
  String get steamGridDbLogos => 'Логотипы';

  @override
  String get steamGridDbIcons => 'Иконки';

  @override
  String get steamGridDbNoResults => 'Ничего не найдено';

  @override
  String get steamGridDbSearchFirst => 'Сначала найдите игру';

  @override
  String get vgmapsClosePanel => 'Закрыть панель';

  @override
  String get vgmapsBack => 'Назад';

  @override
  String get vgmapsForward => 'Вперёд';

  @override
  String get vgmapsHome => 'Домой';

  @override
  String get vgmapsReload => 'Обновить';

  @override
  String get vgmapsCaptureImage => 'Сохранить изображение карты';

  @override
  String get vgmapsSearchHint => 'Поиск игры на VGMaps...';

  @override
  String get vgmapsDismiss => 'Закрыть';

  @override
  String vgmapsFailedInit(String error) {
    return 'Не удалось инициализировать WebView: $error';
  }
}

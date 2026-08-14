// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => '主页';

  @override
  String get navCollections => '收藏';

  @override
  String get navWishlist => '愿望单';

  @override
  String get navSettings => '设置';

  @override
  String get navReleases => '新番';

  @override
  String get releasesEmpty => '暂无追踪的节目';

  @override
  String get releasesEmptyHint => '点击电视节目或动漫上的铃铛图标以追踪新剧集。';

  @override
  String get releasesTrackShow => '追踪更新';

  @override
  String get releasesUntrackShow => '取消追踪';

  @override
  String get releasesViewDay => '日';

  @override
  String get releasesViewWeek => '周';

  @override
  String get releasesViewMonth => '月';

  @override
  String get releasesTabCalendar => '日历';

  @override
  String get releasesTabAll => '全部更新';

  @override
  String get releasesToday => '今天';

  @override
  String get refresh => '刷新';

  @override
  String get releasesNoEpisodes => '暂无剧集';

  @override
  String releasesEpisode(int season, int episode) {
    return '第 $season 季 · 第 $episode 集';
  }

  @override
  String get calendarAdd => '添加到日历';

  @override
  String get calendarRemove => '从日历移除';

  @override
  String get date => '日期';

  @override
  String get calendarRepeat => '重复';

  @override
  String get recurrenceOnce => '仅一次';

  @override
  String get recurrenceWeekly => '每周';

  @override
  String get recurrenceMonthly => '每月';

  @override
  String get statusNotStarted => '未开始';

  @override
  String get statusPlaying => '游玩中';

  @override
  String get statusWatching => '观看中';

  @override
  String get statusListening => '收听中';

  @override
  String get statusInProgress => '进行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusDropped => '已弃置';

  @override
  String get statusPlanned => '计划中';

  @override
  String get statusReplay => '重玩';

  @override
  String get rewatchCountEdit => '重玩次数';

  @override
  String get rewatchCountHint => '留空 = 不追踪';

  @override
  String get statusReplaying => '重玩中';

  @override
  String get statusRewatching => '重看中';

  @override
  String get statusRereading => '重读中';

  @override
  String get statusRelistening => '重听中';

  @override
  String get all => '全部';

  @override
  String get mediaTypeGame => '游戏';

  @override
  String get mediaTypeMovie => '电影';

  @override
  String get mediaTypeTvShow => '电视剧';

  @override
  String get mediaTypeAnimation => '动画';

  @override
  String get mediaTypeVisualNovel => '视觉小说';

  @override
  String get mediaTypeManga => '漫画';

  @override
  String get mediaTypeAnime => '动漫';

  @override
  String get mediaTypeBook => '书籍';

  @override
  String get mediaTypeAudio => '音频';

  @override
  String get mediaTypeCustom => '自定义';

  @override
  String get sortManualDisplay => '手动';

  @override
  String get sortManualDesc => '自定义排序';

  @override
  String get sortDateDisplay => '添加日期';

  @override
  String get sortDateDesc => '最新优先';

  @override
  String get status => '状态';

  @override
  String get movieStatusReleased => '已上映';

  @override
  String get movieStatusCompleted => '已完成';

  @override
  String get movieStatusPostProduction => '拍摄 / 后期制作';

  @override
  String get movieStatusPreProduction => '前期筹备';

  @override
  String get movieStatusAnnounced => '已公布';

  @override
  String get sortStatusDesc => '活跃优先';

  @override
  String get name => '名称';

  @override
  String get sortNameShort => 'A-Z';

  @override
  String get rating => '评分';

  @override
  String get sortRatingDesc => '最高优先';

  @override
  String get sortFavoriteDesc => '收藏优先';

  @override
  String get sortExternalRatingDisplay => '外部评分';

  @override
  String get sortExternalRatingShort => 'IGDB/TMDB';

  @override
  String get sortLastActivityDisplay => '最近活动';

  @override
  String get sortLastActivityShort => '活动';

  @override
  String get sortLastActivityDesc => '最近优先';

  @override
  String get sortStartDateDisplay => '开始日期';

  @override
  String get sortStartDateShort => '开始';

  @override
  String get sortCompletionDateDisplay => '完成日期';

  @override
  String get sortCompletionDateShort => '完成';

  @override
  String get sortDateOldest => '最早优先';

  @override
  String get sortStatusFinished => '已完成优先';

  @override
  String get sortRatingLowest => '最低优先';

  @override
  String get sortFavoriteLast => '收藏最后';

  @override
  String get searchSortRelevanceShort => '相关';

  @override
  String get searchSortRatingShort => '评分';

  @override
  String get searchSortRatingDisplay => '评分';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get restore => '恢复';

  @override
  String get create => '创建';

  @override
  String get save => '保存';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get rename => '重命名';

  @override
  String get retry => '重试';

  @override
  String get edit => '编辑';

  @override
  String get done => '完成';

  @override
  String get clear => '清除';

  @override
  String get reset => '重置';

  @override
  String get search => '搜索';

  @override
  String get open => '打开';

  @override
  String get remove => '移除';

  @override
  String get moveToTop => '移到顶部';

  @override
  String get moveToBottom => '移到底部';

  @override
  String get favorite => '收藏';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏移除';

  @override
  String bulkSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get bulkClearSelection => '清除选择';

  @override
  String get selectAll => '全选';

  @override
  String get bulkMove => '移动到收藏';

  @override
  String get bulkCopy => '复制到收藏';

  @override
  String get bulkChangeStatus => '更改状态';

  @override
  String bulkRemoveConfirm(int count) {
    return '确定要从该收藏中移除 $count 项吗？';
  }

  @override
  String bulkResult(int done, int skipped) {
    return '完成：$done · 重复：$skipped';
  }

  @override
  String bulkRemoved(int count) {
    return '已移除：$count';
  }

  @override
  String bulkStatusUpdated(int count) {
    return '已更新 $count 项的状态';
  }

  @override
  String get bulkAddTags => '添加标签';

  @override
  String get bulkRemoveTags => '移除标签';

  @override
  String bulkAddTagsTitle(int count) {
    return '为 $count 项添加标签';
  }

  @override
  String bulkRemoveTagsTitle(int count) {
    return '从 $count 项移除标签';
  }

  @override
  String bulkTagsAdded(int count) {
    return '已添加标签：$count';
  }

  @override
  String bulkTagsRemoved(int count) {
    return '已移除标签：$count';
  }

  @override
  String get bulkTagsUnchanged => '无需更改';

  @override
  String get bulkExportPngTitle => '导出为 PNG';

  @override
  String get columnsCount => '列数';

  @override
  String bulkExportPngItemsCount(int count) {
    return '$count 个项目';
  }

  @override
  String bulkExportPngItemsCountPreview(int total, int preview) {
    return '$total 个项目（预览显示 $preview 个）';
  }

  @override
  String bulkExportPngPreparing(int done, int total) {
    return '准备封面：$done / $total';
  }

  @override
  String get bulkExportPngSave => '保存 PNG';

  @override
  String get imageSaved => '图片已保存';

  @override
  String get bulkExportPngFailed => '保存图片失败';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get skip => '跳过';

  @override
  String get update => '更新';

  @override
  String get test => '测试';

  @override
  String get close => '关闭';

  @override
  String get keep => '保留';

  @override
  String get change => '更改';

  @override
  String get settingsProfile => '收藏作者';

  @override
  String get settingsProfileSubtitle => '您的收藏的作者名称';

  @override
  String get settingsAuthorName => '作者名称';

  @override
  String get settingsCredentialsSubtitle => 'IGDB、SteamGridDB、TMDB API 密钥';

  @override
  String get settingsCacheSubtitle => '离线模式和封面存储';

  @override
  String get settingsDatabaseSubtitle => '导出、导入、重置';

  @override
  String get settingsTraktImportSubtitle => '观看历史、评分、观看列表';

  @override
  String get settingsKinoriumImport => 'Kinorium 导入';

  @override
  String get settingsKinoriumImportSubtitle => '从 CSV 导出中导入电影和节目';

  @override
  String get settingsDebug => '调试';

  @override
  String get settingsDebugSubtitle => '开发者工具';

  @override
  String get settingsDebugSubtitleNoKey => '部分工具需先设置 SteamGridDB 密钥';

  @override
  String get settingsLaboratory => '实验室';

  @override
  String get settingsLaboratoryCardDesigns => '卡片横幅设计';

  @override
  String get settingsLaboratoryCardDesignsSubtitle => '海报卡片的实验性布局';

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsWelcomeGuide => '欢迎指南';

  @override
  String get settingsWelcomeGuideSubtitle => '开始使用 Tonkatsu Box';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsCreditsLicenses => '致谢与许可';

  @override
  String get settingsChangelog => '新功能';

  @override
  String get settingsChangelogEmpty => '暂无更新说明';

  @override
  String get settingsCreditsLicensesSubtitle => 'TMDB、IGDB、SteamGridDB、开源许可';

  @override
  String get settingsError => '错误';

  @override
  String get settingsAppLanguage => '应用语言';

  @override
  String get settingsConnections => '连接';

  @override
  String get settingsApiKeys => 'API 密钥';

  @override
  String get credentialsServerManagedTitle => '密钥保存在服务器上';

  @override
  String get credentialsServerManagedBody =>
      '下面填写的内容会保存到自托管服务器，而不是这个浏览器——对 API 的请求正是从那里发出的。你也可以从桌面端导出的配置文件加载它们。';

  @override
  String get credentialsUploadFromConfig => '从配置文件加载密钥';

  @override
  String get credentialsUploadNoKeys => '该文件中没有 API 密钥';

  @override
  String credentialsUploadDone(int count) {
    return '已在服务器上保存 $count 个密钥';
  }

  @override
  String settingsApiKeysValue(int active, int total) {
    return '$active/$total';
  }

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAppearanceSubtitle => '语言、显示和内容';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSubtitle => '应用配色主题';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeSakura => '樱花';

  @override
  String get settingsAppLanguageSubtitle => '界面语言';

  @override
  String get settingsContentLanguageSubtitle => '目前仅适用于 TMDB（电影和剧集）';

  @override
  String get settingsDataSources => '数据源';

  @override
  String get settingsDataSourcesSubtitle => 'IGDB、TMDB、SteamGridDB';

  @override
  String get settingsApiKeysSubtitle => '配置数据库连接';

  @override
  String get settingsStorage => '存储';

  @override
  String get settingsStorageSubtitle => '图片缓存和数据库';

  @override
  String get settingsBackup => '备份';

  @override
  String get settingsBackupSubtitle => '完整数据备份与恢复';

  @override
  String get settingsBackupAll => '备份所有数据';

  @override
  String get settingsBackupAllSubtitle => '所有收藏、愿望单和设置';

  @override
  String get settingsRestoreBackup => '从备份恢复';

  @override
  String get settingsRestoreBackupSubtitle => '导入备份存档';

  @override
  String backupSuccess(int collections, int items) {
    return '备份已保存：$collections 个收藏，$items 个项目';
  }

  @override
  String get restoreConfirmTitle => '恢复备份？';

  @override
  String restoreConfirmBody(int collections, int items, int wishlist) {
    return '$collections 个收藏，$items 个项目，$wishlist 个愿望单条目';
  }

  @override
  String get restoreConfirmHint => '现有收藏不会受到影响';

  @override
  String get restoreSettings => '恢复设置';

  @override
  String get restoreWishlist => '恢复愿望单';

  @override
  String restoreSuccess(int collections, int items) {
    return '已恢复 $collections 个收藏，$items 个项目';
  }

  @override
  String get restoreInvalidArchive => '无效的备份存档';

  @override
  String get restoreProgressTitle => '正在恢复备份';

  @override
  String get restoreProgressWarning => '请勿关闭应用。大型备份可能需要几分钟时间。';

  @override
  String get restoreStageReading => '正在读取存档…';

  @override
  String restoreStageCollections(int current, int total) {
    return '正在恢复收藏…（$current/$total）';
  }

  @override
  String get restoreStageWishlist => '正在恢复愿望单…';

  @override
  String get restoreStageSettings => '正在恢复设置…';

  @override
  String get restoreStageFinalizing => '正在完成…';

  @override
  String get settingsImport => '导入';

  @override
  String get settingsImportSubtitle => '从外部服务导入收藏';

  @override
  String get settingsContentLanguage => '内容语言';

  @override
  String get settingsData => '数据';

  @override
  String settingsCacheValue(String size) {
    return '$size';
  }

  @override
  String get credentialsTitle => '凭证';

  @override
  String get credentialsWelcome => '欢迎使用 Tonkatsu Box！';

  @override
  String get credentialsWelcomeHint =>
      '首先，您需要设置 IGDB API 凭证。请从 Twitch 开发者控制台获取 Client ID 和 Client Secret。';

  @override
  String get credentialsCopyTwitchUrl => '复制 Twitch 控制台地址';

  @override
  String credentialsUrlCopied(String url) {
    return '已复制地址：$url';
  }

  @override
  String get credentialsIgdbSection => 'IGDB API 凭证';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => '输入您的 Twitch Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => '输入您的 Twitch Client Secret';

  @override
  String get credentialsConnectionStatus => '连接状态';

  @override
  String get credentialsPlatformsSynced => '平台已同步';

  @override
  String get credentialsPlatformsAvailable => '可用平台';

  @override
  String get credentialsLastSync => '上次同步';

  @override
  String get credentialsVerifyConnection => '验证连接';

  @override
  String get credentialsRefreshPlatforms => '刷新平台';

  @override
  String get credentialsSteamGridDbSection => 'SteamGridDB API';

  @override
  String get credentialsApiKey => 'API 密钥';

  @override
  String get credentialsUsingBuiltInKey => '使用内置密钥';

  @override
  String get credentialsEnterSteamGridDbKey => '输入您的 SteamGridDB API 密钥';

  @override
  String get credentialsTmdbSection => 'TMDB API（电影和电视剧）';

  @override
  String get credentialsTvdbSection => 'TheTVDB API（电影与剧集）';

  @override
  String get credentialsEnterTmdbKey => '输入您的 TMDB API 密钥（v3）';

  @override
  String get credentialsEnterTvdbKey => '输入你的 TheTVDB API 密钥（v4）';

  @override
  String get credentialsComicVineSection => 'ComicVine API（漫画）';

  @override
  String get credentialsEnterComicVineKey => '输入您的 ComicVine API 密钥';

  @override
  String get credentialsGoogleBooksSection => 'Google Books API（书籍）';

  @override
  String get credentialsEnterGoogleBooksKey => '输入您的 Google Books API 密钥（可选）';

  @override
  String get credentialsHardcoverSection => 'Hardcover API（书籍）';

  @override
  String get credentialsEnterHardcoverKey => '输入您的 Hardcover API 令牌';

  @override
  String get credentialsOwnKeyHint => '为了更好的速率限制，建议使用自己的 API 密钥。';

  @override
  String get credentialsConnected => '已连接';

  @override
  String get credentialsConnectionError => '连接错误';

  @override
  String get credentialsChecking => '检查中...';

  @override
  String get credentialsNotConnected => '未连接';

  @override
  String get credentialsEnterBoth => '请输入 Client ID 和 Client Secret';

  @override
  String get credentialsConnectedSynced => '已连接且平台已同步！';

  @override
  String get credentialsConnectedSyncFailed => '已连接，但平台同步失败';

  @override
  String get credentialsPlatformsSyncedOk => '平台同步成功！';

  @override
  String get credentialsDownloadingLogos => '正在下载平台图标...';

  @override
  String credentialsDownloadedLogos(int count) {
    return '已下载 $count 个图标';
  }

  @override
  String get credentialsFailedDownloadLogos => '下载图标失败';

  @override
  String get credentialsApiKeySaved => 'API 密钥已保存';

  @override
  String get credentialsNoApiKey => '无 API 密钥';

  @override
  String get credentialsResetToBuiltIn => '重置为内置密钥';

  @override
  String get credentialsSteamGridDbKeyValid => 'SteamGridDB API 密钥有效';

  @override
  String get credentialsSteamGridDbKeyInvalid => 'SteamGridDB API 密钥无效';

  @override
  String get credentialsTmdbKeyValid => 'TMDB API 密钥有效';

  @override
  String get credentialsTmdbKeyInvalid => 'TMDB API 密钥无效';

  @override
  String get credentialsTvdbKeyValid => 'TheTVDB API 密钥有效';

  @override
  String get credentialsTvdbKeyInvalid => 'TheTVDB API 密钥无效';

  @override
  String get credentialsComicVineKeyValid => 'ComicVine API 密钥有效';

  @override
  String get credentialsComicVineKeyInvalid => 'ComicVine API 密钥无效';

  @override
  String get credentialsGoogleBooksKeyValid => 'Google Books API 密钥有效';

  @override
  String get credentialsGoogleBooksKeyInvalid => 'Google Books API 密钥无效';

  @override
  String get credentialsHardcoverKeyValid => 'Hardcover API 令牌有效';

  @override
  String get credentialsHardcoverKeyInvalid => 'Hardcover API 令牌无效或已过期';

  @override
  String get credentialsEnterSteamGridDbKeyError => '请输入 SteamGridDB API 密钥';

  @override
  String get credentialsEnterTmdbKeyError => '请输入 TMDB API 密钥';

  @override
  String get credentialsTmdbKeySaved => 'TMDB API 密钥已保存';

  @override
  String timeAgo(int value, String unit) {
    return '$value $unit前';
  }

  @override
  String timeUnitDays(int count) {
    return '$count 天';
  }

  @override
  String timeUnitHours(int count) {
    return '$count 小时';
  }

  @override
  String timeUnitMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String get cacheTitle => '缓存';

  @override
  String get cacheImageCache => '图片缓存';

  @override
  String get cacheOfflineMode => '离线模式';

  @override
  String get cacheOfflineModeSubtitle => '在本地保存图片以供离线使用';

  @override
  String get cacheCacheFolder => '缓存文件夹';

  @override
  String get cacheSelectFolder => '选择文件夹';

  @override
  String get cacheCacheSize => '缓存大小';

  @override
  String get cacheClearCache => '清理未使用的图片';

  @override
  String get cacheClearCacheTitle => '清理未使用的图片？';

  @override
  String get cacheClearCacheMessage => '删除已不在任何收藏中的媒体的已下载封面。您的自定义封面和看板图片将被保留。';

  @override
  String get cacheFolderUpdated => '缓存文件夹已更新';

  @override
  String cacheOrphansRemoved(int count) {
    return '已清理未使用的图片：$count';
  }

  @override
  String get cacheSelectFolderDialog => '选择图片缓存文件夹';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count 个文件，$size';
  }

  @override
  String get databaseTitle => '数据库';

  @override
  String get databaseConfiguration => '配置';

  @override
  String get databaseConfigSubtitle => '导出或导入您的 API 密钥和设置。';

  @override
  String get databaseExportConfig => '导出配置';

  @override
  String get databaseImportConfig => '导入配置';

  @override
  String get databaseDangerZone => '危险区域';

  @override
  String get databaseDangerZoneMessage =>
      '清除所有收藏、游戏、电影、电视剧和看板数据。设置和 API 密钥将被保留。';

  @override
  String get databaseResetDatabase => '重置数据库';

  @override
  String get databaseResetTitle => '重置数据库？';

  @override
  String get databaseResetMessage =>
      '这将永久删除您的所有收藏、游戏、电影、电视剧、剧集进度和看板数据。\n\n您的 API 密钥和设置将被保留。\n\n此操作无法撤销。';

  @override
  String databaseConfigExported(String path) {
    return '配置已导出到 $path';
  }

  @override
  String get databaseConfigImported => '配置导入成功';

  @override
  String get databaseReset => '数据库已重置';

  @override
  String get storageLocationTitle => '数据位置';

  @override
  String get storageLocationSubtitle =>
      '存储数据库和配置的文件夹。请避免使用云服务实时同步的文件夹（OneDrive、Syncthing）：数据库可能在写入过程中损坏。要在设备间传输数据，请使用导出功能。';

  @override
  String get storageLocationDangerWarning => '警告：更改数据文件夹可能导致数据丢失。风险自负。';

  @override
  String get storageLocationFolder => '数据文件夹';

  @override
  String get storageLocationFallbackWarning => '所选文件夹不可用，使用默认文件夹';

  @override
  String get storageLocationChange => '更改文件夹';

  @override
  String get storageLocationReset => '重置为默认';

  @override
  String get storageLocationSelectDialog => '选择数据文件夹';

  @override
  String storageLocationNotWritable(String path) {
    return '无写入权限：$path';
  }

  @override
  String get storageLocationPermissionTitle => '需要存储权限';

  @override
  String get storageLocationPermissionMessage =>
      'Android 需要「所有文件访问」权限才能使用自定义数据文件夹。在打开的列表中找到 Tonkatsu Box，启用访问权限，然后返回重新选择文件夹。';

  @override
  String get storageLocationLegacyPermissionMessage =>
      '自定义数据文件夹需要存储权限。请在应用设置中启用，然后返回重新选择文件夹。';

  @override
  String get storageLocationOpenSettings => '打开设置';

  @override
  String get storageLocationDbTooNew => '此文件夹中的数据库由更新版本的应用创建。请先在此设备上更新应用。';

  @override
  String get storageLocationDbCorrupted =>
      '此文件夹中的数据库已损坏或不完整。如果有同步工具正在复制，请稍后重试。';

  @override
  String get storageLocationUseExistingTitle => '发现现有数据';

  @override
  String get storageLocationUseExistingMessage => '所选文件夹已包含数据库。应用将在重启后切换到该数据。';

  @override
  String get storageLocationUseExistingConfirm => '使用';

  @override
  String get storageLocationCopyTitle => '复制当前数据？';

  @override
  String get storageLocationCopyMessage =>
      '所选文件夹为空。您的收藏将被复制到该处；保存的图片将在需要时重新下载。旧文件夹中的数据不会被修改。';

  @override
  String get copy => '复制';

  @override
  String get storageLocationCopyImages => '同时复制图片缓存';

  @override
  String get storageLocationCopyImagesHint =>
      '横幅和已保存的封面——文件较大，但新文件夹可离线使用无需重新下载';

  @override
  String get storageLocationCopyError => '复制数据到所选文件夹失败';

  @override
  String get storageLocationResetTitle => '重置数据文件夹？';

  @override
  String get storageLocationResetMessage =>
      '应用将在重启后切换回默认数据文件夹。自定义文件夹中的数据不会被修改。';

  @override
  String get storageLocationRestartTitle => '需要重启';

  @override
  String get storageLocationRestartMessage => '新数据文件夹将在重启后生效。立即重启吗？';

  @override
  String get storageLocationRestartNow => '重启';

  @override
  String get storageLocationRestartLater => '更改将在重启后生效';

  @override
  String get backupRestoreTile => '恢复之前的数据库';

  @override
  String get backupNone => '暂无备份';

  @override
  String get backupRestoreConfirmTitle => '恢复之前的数据库？';

  @override
  String backupRestoreConfirmMessage(String date) {
    return '当前数据将被替换为 $date 的备份。被替换的数据将成为新备份，因此再次恢复可撤销此操作。';
  }

  @override
  String get backupRestored => '数据库已恢复';

  @override
  String get backupRestoreError => '恢复备份失败';

  @override
  String get backupRestartMessage => '恢复的数据将在重启后生效。立即重启吗？';

  @override
  String get lanSyncTitle => '网络同步';

  @override
  String get lanSyncOpenTile => '附近的设备';

  @override
  String get lanSyncTileSubtitle => '在同一 Wi-Fi 网络上的设备之间直接传输数据';

  @override
  String lanSyncVisibleAs(String name) {
    return '此设备显示为 $name';
  }

  @override
  String get lanSyncNoDevices =>
      '未找到设备。请在连接到同一 Wi-Fi 网络的两台设备上打开此屏幕。接入点隔离和 VPN 会阻止发现。';

  @override
  String get lanSyncPull => '点击获取其数据';

  @override
  String get lanSyncReceiveTitle => '替换数据？';

  @override
  String lanSyncReceiveMessage(
    String device,
    String date,
    int collections,
    int items,
  ) {
    return '来自 $device（$date）的数据：$collections 个收藏，$items 个项目。\n\n当前数据将被替换。备份副本将保存在数据库旁边。';
  }

  @override
  String get lanSyncReplace => '替换';

  @override
  String lanSyncWaiting(String name) {
    return '在 $name 上确认请求...';
  }

  @override
  String get lanSyncIncomingTitle => '数据请求';

  @override
  String lanSyncIncomingMessage(String name) {
    return '$name 想要获取您的数据副本。允许吗？';
  }

  @override
  String get lanSyncAllow => '允许';

  @override
  String get lanSyncDenied => '对方设备拒绝了请求';

  @override
  String get lanSyncManifestError => '设备未响应';

  @override
  String get lanSyncStartError => '无法启动网络共享。请检查网络连接后重新打开此屏幕。';

  @override
  String get lanSyncReceiveError => '获取数据失败';

  @override
  String get lanSyncTooNew => '该设备上的数据由更新版本的应用创建。请先在此设备上更新应用。';

  @override
  String get lanSyncCorrupted => '传输数据已损坏。请重试。';

  @override
  String get lanSyncReceived => '数据已接收';

  @override
  String get lanSyncReceivingImages => '正在传输图片...';

  @override
  String get lanSyncReceivingSettings => '正在传输设置...';

  @override
  String get lanSyncImportConfig => '同时传输设置';

  @override
  String get lanSyncImportConfigSubtitle => '包括 API 密钥。全部或不传。';

  @override
  String get lanSyncImagesWarning => '数据库已接收，但图片未能传输';

  @override
  String get lanSyncRestartMessage => '接收的数据将在重启后生效。立即重启吗？';

  @override
  String get lanSyncFirewallNote => 'Windows 可能会在首次启动时请求防火墙权限——请允许在专用网络上访问。';

  @override
  String get folderPickerNewFolder => '新建文件夹';

  @override
  String get folderPickerVolumeList => '存储设备';

  @override
  String get folderPickerInternalStorage => '内部存储';

  @override
  String get folderPickerSelect => '选择';

  @override
  String get folderPickerFolderName => '文件夹名称';

  @override
  String get folderPickerInvalidName => '无效的文件夹名称';

  @override
  String get folderPickerEmpty => '无子文件夹';

  @override
  String get folderPickerReadError => '无法读取此文件夹';

  @override
  String get folderPickerCreateError => '无法创建文件夹';

  @override
  String get traktTitle => 'Trakt 导入';

  @override
  String get traktImportFrom => '从 Trakt.tv 导入';

  @override
  String get traktImportDescription =>
      '从 trakt.tv/users/您的用户名/data 下载数据，然后选择下方的 ZIP 文件。';

  @override
  String get traktZipFile => 'ZIP 文件';

  @override
  String get traktSelectZipFile => '选择 ZIP 文件';

  @override
  String get traktSelectZipExport => '选择 Trakt ZIP 导出';

  @override
  String get preview => '预览';

  @override
  String traktUser(String username) {
    return 'Trakt 用户：$username';
  }

  @override
  String get traktWatchedMovies => '已看电影';

  @override
  String get traktWatchedShows => '已看节目';

  @override
  String get traktRatedMovies => '已评电影';

  @override
  String get traktRatedShows => '已评节目';

  @override
  String get traktWatchlist => '观看列表';

  @override
  String get importOptions => '选项';

  @override
  String get traktImportWatched => '导入已看项目';

  @override
  String get traktImportWatchedDesc => '电影和电视剧标记为已完成';

  @override
  String get traktImportRatings => '导入评分';

  @override
  String get traktImportRatingsDesc => '应用用户评分（1-10）';

  @override
  String get traktImportWatchlist => '导入观看列表';

  @override
  String get traktImportWatchlistDesc => '添加为计划中或加入愿望单';

  @override
  String get importTargetCollection => '目标收藏';

  @override
  String get importUseExistingCollection => '使用现有收藏';

  @override
  String get importStart => '开始导入';

  @override
  String get traktRequiresOwnTmdbKey =>
      'Trakt 导入需要您自己的 TMDB API 密钥。请在设置 → 凭证中添加。';

  @override
  String get traktInvalidExport => '无效的 Trakt 导出';

  @override
  String get kinoriumImportFrom => '从 Kinorium 导入';

  @override
  String get kinoriumImportDescription =>
      '从 Kinorium 导出您的列表（通过邮件收到 CSV 文件），然后选择下方的文件。';

  @override
  String get kinoriumSelectCsvFile => '选择 CSV 文件';

  @override
  String get kinoriumSelectCsvExport => '选择 Kinorium CSV 导出';

  @override
  String get kinoriumIsWatchlist => '这是「观看列表」文件';

  @override
  String get kinoriumIsWatchlistDesc => '将所有标题导入为计划中而非已看';

  @override
  String get kinoriumImportNotes => '导入演员和工作人员';

  @override
  String get kinoriumImportNotesDesc => '将导演和演员添加到项目备注中';

  @override
  String get kinoriumImporting => '正在从 Kinorium 导入...';

  @override
  String get kinoriumRecommendOwnTmdbKey =>
      '提示：大型导入建议使用个人 TMDB API 密钥（设置 → API 密钥），但这不是必须的——内置密钥也可以使用。';

  @override
  String get kinoriumReasonNotFound => '在 TMDB 上未找到';

  @override
  String get kinoriumReasonApiError => 'TMDB 错误或速率限制——请稍后重试';

  @override
  String kinoriumReasonUnsupportedType(String type) {
    return '不支持的类型：$type';
  }

  @override
  String kinoriumReasonDuplicate(String title) {
    return '「$title」的重复项';
  }

  @override
  String traktImportedItems(int count) {
    return '已导入 $count 个项目';
  }

  @override
  String get traktImporting => '正在从 Trakt 导入';

  @override
  String get creditsTitle => '致谢';

  @override
  String get creditsDataProviders => '数据提供商';

  @override
  String get creditsTmdbAttribution => '本产品使用 TMDB API，但未经 TMDB 认可或认证。';

  @override
  String get creditsTvdbAttribution => '元数据由 TheTVDB 提供。欢迎补充缺失信息或订阅支持。';

  @override
  String get creditsTvMazeAttribution => '电视剧数据由 TVmaze 提供。';

  @override
  String get creditsIgdbAttribution => '游戏数据由 IGDB 提供。';

  @override
  String get creditsSteamGridDbAttribution => '美术素材由 SteamGridDB 提供。';

  @override
  String get creditsVndbAttribution => '视觉小说数据由 VNDB 提供。';

  @override
  String get creditsAniListAttribution => '漫画数据由 AniList 提供。';

  @override
  String get creditsMangaBakaAttribution => '漫画数据由 MangaBaka 提供。';

  @override
  String get creditsMangaDexAttribution => '漫画数据由 MangaDex 提供。';

  @override
  String get creditsKitsuAttribution => '漫画数据由 Kitsu 提供。';

  @override
  String get creditsOpenLibraryAttribution =>
      '书籍数据来自 Open Library（CC0 / ODbL）。';

  @override
  String get creditsFantlabAttribution => '书籍数据来自 Fantlab。';

  @override
  String get creditsComicVineAttribution => '漫画数据来自 ComicVine（非商业用途）。';

  @override
  String get creditsMusicBrainzAttribution =>
      '音乐数据来自 MusicBrainz，封面来自 Cover Art Archive，收听数据来自 ListenBrainz。';

  @override
  String get creditsGoogleBooksAttribution => '书籍数据来自 Google Books。';

  @override
  String get creditsHardcoverAttribution => '书籍数据来自 Hardcover。';

  @override
  String get creditsOpenSource => '开源';

  @override
  String get creditsOpenSourceDesc => 'Tonkatsu Box 是免费的开源软件，基于 MIT 许可证发布。';

  @override
  String get creditsViewLicenses => '查看开源许可';

  @override
  String get creditsDiscord => '加入 Discord';

  @override
  String get collectionsImportCollection => '导入收藏';

  @override
  String get collectionsNoCollectionsYet => '暂无收藏';

  @override
  String get collectionsNoCollectionsHint => '点击 + 创建您的第一个收藏，\n开始整理您的媒体库。';

  @override
  String get collectionsFailedToLoad => '加载收藏失败';

  @override
  String collectionsCount(int count) {
    return '收藏（$count）';
  }

  @override
  String get collectionsUncategorized => '未分类';

  @override
  String collectionsUncategorizedItems(int count) {
    return '$count 个项目';
  }

  @override
  String get editCollection => '编辑收藏';

  @override
  String get collectionsRenamed => '收藏已更新';

  @override
  String collectionsFailedToRename(String error) {
    return '保存失败：$error';
  }

  @override
  String get collectionsDeleted => '收藏已删除';

  @override
  String collectionsFailedToDelete(String error) {
    return '删除失败：$error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return '创建收藏失败：$error';
  }

  @override
  String collectionsImported(String name, int count) {
    return '已导入「$name」，包含 $count 个项目';
  }

  @override
  String get collectionsImporting => '正在导入收藏';

  @override
  String get importTargetTitle => '导入到...';

  @override
  String get importCreateNew => '创建新收藏';

  @override
  String get importUseExisting => '添加到现有收藏';

  @override
  String get importNoCollections => '暂无可用收藏';

  @override
  String get importSelectCollection => '选择收藏';

  @override
  String get importErrorLoadingCollections => '加载收藏出错';

  @override
  String get importStartButton => '导入';

  @override
  String get importUsername => '用户名';

  @override
  String get importUsernameHint => '例如 yourname';

  @override
  String get importMode => '模式';

  @override
  String get importModeNewOnly => '仅添加新条目';

  @override
  String get importModeNewOnlySubtitle => '跳过合集中已有的条目';

  @override
  String get importModeOverwrite => '覆盖现有条目';

  @override
  String get importModeOverwriteSubtitle => '从数据源更新进度、状态和日期';

  @override
  String get importNewCollectionName => '收藏名称';

  @override
  String importNewCollectionDefault(String source, String username) {
    return '$source 导入 — $username';
  }

  @override
  String get importFetchingBooks => '正在获取书库...';

  @override
  String get importAddingItems => '正在导入条目';

  @override
  String importProcessingItem(String title) {
    return '正在处理：$title';
  }

  @override
  String importImportedCount(int count) {
    return '已导入 $count 个';
  }

  @override
  String importUpdatedCount(int count) {
    return '已更新 $count 个';
  }

  @override
  String importUserNotFound(String username) {
    return '未找到用户\"$username\"';
  }

  @override
  String get importEmptyUsername => '请输入用户名';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get collectionNotFound => '未找到收藏';

  @override
  String get collectionAddItems => '添加项目';

  @override
  String get collectionSwitchToList => '切换到列表';

  @override
  String get collectionSwitchToBoard => '切换到看板';

  @override
  String get collectionUnlockBoard => '解锁看板';

  @override
  String get collectionLockBoard => '锁定看板';

  @override
  String get collectionExport => '导出';

  @override
  String get collectionNoItemsYet => '暂无项目';

  @override
  String get collectionEmpty => '空收藏';

  @override
  String get collectionEmptyAddHint => '添加项目以开始构建您的收藏。';

  @override
  String get collectionEmptyReadonly => '此收藏为空。';

  @override
  String get collectionDeleteEmptyPrompt => '此收藏现在为空。要删除吗？';

  @override
  String get collectionRemoveItemTitle => '移除项目？';

  @override
  String collectionRemoveItemMessage(String name) {
    return '确定要从该收藏中移除 $name 吗？';
  }

  @override
  String get collectionMoveToCollection => '移动到收藏';

  @override
  String get collectionExportFormat => '导出格式';

  @override
  String get collectionChooseExportFormat => '选择导出格式：';

  @override
  String get collectionExportLight => '轻量（.xcoll）';

  @override
  String get collectionExportLightDesc => '仅项目数据，文件更小';

  @override
  String get collectionExportFull => '完整（.xcollx）';

  @override
  String get collectionExportFullDesc => '包含图片和看板——可离线使用';

  @override
  String get collectionExportIncludeUserData => '包含个人数据';

  @override
  String get collectionExportIncludeUserDataDesc => '状态、日期、备注、剧集进度';

  @override
  String get customItemCreate => '创建自定义项目';

  @override
  String get title => '标题';

  @override
  String get customItemTitleHint => '例如：我的自制游戏';

  @override
  String get customItemAltTitle => '副标题';

  @override
  String get customItemAltTitleHint => '原始语言名称';

  @override
  String get customItemCoverUrl => '封面图片链接';

  @override
  String get year => '年份';

  @override
  String get genres => '类型';

  @override
  String get customItemGenresHint => '例如：RPG、动作、益智';

  @override
  String get platform => '平台';

  @override
  String get customItemPlatformHint => '例如：PC、SNES、自定义';

  @override
  String get format => '格式';

  @override
  String get progress => '进度';

  @override
  String get customMarkCompleted => '标记为已完成';

  @override
  String get customUnitParts => '部分';

  @override
  String get customUnitEpisodes => '集';

  @override
  String get customUnitChapters => '章';

  @override
  String get customUnitPages => '页';

  @override
  String get customUnitVolumes => '卷';

  @override
  String get customUnitSeasons => '季';

  @override
  String get description => '描述';

  @override
  String get customItemDescriptionHint => '简要描述或备注';

  @override
  String get customItemMyNoteHint => '你对此条目的备注';

  @override
  String get customItemTagsHint => '用逗号分隔，例如：待玩、收藏';

  @override
  String get customItemOptionalFields => '更多字段';

  @override
  String get customItemEdit => '编辑自定义项目';

  @override
  String get customItemFillFromFile => '从文件填充';

  @override
  String customItemFileMultipleRows(int count) {
    return '文件中有 $count 条记录，已使用第一条';
  }

  @override
  String get customItemFileNoValidRows => '文件中没有有效记录';

  @override
  String get customItemAddCover => '添加封面';

  @override
  String get customItemCoverSource => '封面来源';

  @override
  String get customItemCoverRatio => '推荐宽高比：2:3（例如 600×900）';

  @override
  String get customItemCoverFromFile => '从文件';

  @override
  String get customItemSearchHint => '搜索或输入自定义...';

  @override
  String get customItemUseCustom => '使用自定义值';

  @override
  String get customItemExternalUrl => '外部链接';

  @override
  String get customItemErrorEmptyTitle => '标题为必填项';

  @override
  String get customItemCreated => '自定义项目已创建';

  @override
  String get customItemUpdated => '自定义项目已更新';

  @override
  String get tagLabel => '标签';

  @override
  String get tagsLabel => '标签';

  @override
  String get tagCreate => '新建标签';

  @override
  String get tagCreateHint => '标签名称';

  @override
  String tagCreateNamed(String name) {
    return '创建“$name”';
  }

  @override
  String get tagRename => '重命名标签';

  @override
  String get tagDelete => '删除标签';

  @override
  String tagDeleteConfirm(String name) {
    return '删除标签「$name」？项目将被取消标签。';
  }

  @override
  String get tagManage => '管理标签';

  @override
  String get tagSortTooltip => '排序';

  @override
  String get tagSortManual => '手动';

  @override
  String get tagSortAlphaAsc => '按字母 (A–Z)';

  @override
  String get tagSortAlphaDesc => '按字母 (Z–A)';

  @override
  String get tagAssign => '分配标签';

  @override
  String get tagNone => '无标签';

  @override
  String get tagPickerTitle => '选择标签';

  @override
  String get tagTextColor => '文字颜色';

  @override
  String get tagCreated => '标签已创建';

  @override
  String get tagRenamed => '标签已重命名';

  @override
  String get tagDeleted => '标签已删除';

  @override
  String get tagUpdateFailed => '更新标签失败';

  @override
  String get refreshItemFromApi => '从源刷新';

  @override
  String get refreshItemSuccess => '项目已从源更新';

  @override
  String get refreshItemNotFound => '源已不再包含此项目';

  @override
  String get refreshItemUnsupported => '自定义项目没有外部源';

  @override
  String refreshItemFailed(String error) {
    return '刷新失败：$error';
  }

  @override
  String get renameDialogHint => '显示名称';

  @override
  String renameOriginalLabel(String name) {
    return '原文：$name';
  }

  @override
  String get renameResetToOriginal => '重置为原文';

  @override
  String get renameSaved => '已重命名';

  @override
  String get tierListExportFailed => '导出图片失败';

  @override
  String get browseCollectionsDownloadFailedGeneric => '下载收藏失败';

  @override
  String get tagFilterAll => '所有标签';

  @override
  String get tagSidebarGroup => '分组';

  @override
  String get colorPickerTitle => '颜色';

  @override
  String get colorPickerNoColor => '无颜色';

  @override
  String get raLinkButton => '关联 RetroAchievements';

  @override
  String get raLinkTitle => '在 RetroAchievements 上查找游戏';

  @override
  String get raLinkSearchHint => '按名称搜索...';

  @override
  String raLinkLoading(String platform) {
    return '正在加载 $platform 的游戏...';
  }

  @override
  String get raLinkNotFound => '未找到匹配项';

  @override
  String get raLinkSuccess => '游戏已关联到 RetroAchievements';

  @override
  String raLinkAchievements(int count) {
    return '$count 个成就';
  }

  @override
  String get raUnlinkButton => '取消关联';

  @override
  String get raUnlinkTitle => '取消 RetroAchievements 关联';

  @override
  String get raUnlinkConfirm => '移除此游戏的 RetroAchievements 关联和成就数据？';

  @override
  String get collectionFilterByType => '按类型筛选';

  @override
  String get collectionFilterGames => '游戏';

  @override
  String get collectionFilterMovies => '电影';

  @override
  String get collectionFilterTvShows => '电视剧';

  @override
  String get collectionFilterVisualNovels => '视觉小说';

  @override
  String get collectionFilterBooks => '书籍';

  @override
  String get searchHint => '搜索...';

  @override
  String get sort => '排序';

  @override
  String get collectionFilterAscending => '升序';

  @override
  String get collectionFilterDescending => '降序';

  @override
  String get collectionFilterFilters => '筛选';

  @override
  String get collectionFilterClearAll => '清除全部';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name 已移动到 $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name 已存在于 $collection 中';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name 已移除';
  }

  @override
  String get boardTab => '看板';

  @override
  String get imageAddedToBoard => '图片已添加到看板';

  @override
  String get mapAddedToBoard => '地图已添加到看板';

  @override
  String get loading => '加载中...';

  @override
  String get gameNotFound => '未找到游戏';

  @override
  String get movieNotFound => '未找到电影';

  @override
  String get tvShowNotFound => '未找到电视剧';

  @override
  String get animationNotFound => '未找到动画';

  @override
  String get visualNovelNotFound => '未找到视觉小说';

  @override
  String get mangaNotFound => '未找到漫画';

  @override
  String get readingProgress => '阅读进度';

  @override
  String get mangaChapters => '章节';

  @override
  String get mangaVolumes => '卷数';

  @override
  String get mangaMarkCompleted => '标记为已完成';

  @override
  String get animeProgress => '观看进度';

  @override
  String get animeEpisodes => '集数';

  @override
  String get animeMarkCompleted => '标记为已完成';

  @override
  String get bookPages => '页数';

  @override
  String get bookIssues => '期数';

  @override
  String get bookMarkCompleted => '标记为已完成';

  @override
  String animeNextEpisode(int episode) {
    return '第 $episode 集即将播出';
  }

  @override
  String get animatedMovie => '动画电影';

  @override
  String get animatedSeries => '动画系列';

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '$hours小时$minutes分钟';
  }

  @override
  String runtimeHours(int hours) {
    return '$hours小时';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes分钟';
  }

  @override
  String totalSeasons(int count) {
    return '$count 季';
  }

  @override
  String totalEpisodes(int count) {
    return '$count 集';
  }

  @override
  String seasonName(int number) {
    return '第 $number 季';
  }

  @override
  String get episodeProgress => '剧集进度';

  @override
  String episodesWatchedOf(int watched, int total) {
    return '已看 $watched/$total';
  }

  @override
  String episodesWatched(int count) {
    return '已看 $count 集';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total 集';
  }

  @override
  String get noSeasonData => '暂无季度数据';

  @override
  String get refreshFromTmdb => '从 TMDB 刷新';

  @override
  String get markAllWatched => '全部标记为已看';

  @override
  String get markNextWatched => '标记下一集';

  @override
  String get unmarkAll => '全部取消标记';

  @override
  String get noEpisodesFound => '未找到剧集';

  @override
  String episodeWatchedDate(String date) {
    return '观看于 $date';
  }

  @override
  String get createCollectionTitle => '新建收藏';

  @override
  String get createCollectionNameLabel => '收藏名称';

  @override
  String get createCollectionNameHint => '例如：SNES 经典游戏';

  @override
  String get createCollectionEnterName => '请输入名称';

  @override
  String get createCollectionNameTooShort => '名称至少需要 2 个字符';

  @override
  String get createCollectionHiddenLabel => '隐藏收藏';

  @override
  String get createCollectionHiddenHint => '卡片不显示封面，其条目也不会出现在「全部条目」中';

  @override
  String get collectionHide => '隐藏收藏';

  @override
  String get collectionUnhide => '取消隐藏';

  @override
  String get renameCollectionTitle => '重命名收藏';

  @override
  String get deleteCollectionTitle => '删除收藏？';

  @override
  String deleteCollectionMessage(String name) {
    return '确定要删除「$name」吗？\n\n此操作无法撤销。';
  }

  @override
  String get canvasAddText => '添加文字';

  @override
  String get canvasAddImage => '添加图片';

  @override
  String get canvasAddLink => '添加链接';

  @override
  String get canvasFindImages => '查找图片...';

  @override
  String get canvasBrowseMaps => '浏览地图...';

  @override
  String get canvasConnect => '连接';

  @override
  String get canvasBringToFront => '置于顶层';

  @override
  String get canvasSendToBack => '置于底层';

  @override
  String get canvasEditConnection => '编辑连接';

  @override
  String get canvasDeleteConnection => '删除连接';

  @override
  String get canvasDeleteElement => '删除元素';

  @override
  String get canvasDeleteElementMessage => '确定要删除此元素吗？';

  @override
  String get canvasAddToBoard => '添加到看板';

  @override
  String get editTextTitle => '编辑文字';

  @override
  String get textContentLabel => '文字内容';

  @override
  String get fontSizeLabel => '字号';

  @override
  String get fontSizeSmall => '小';

  @override
  String get fontSizeMedium => '中';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeTitle => '标题';

  @override
  String get editImageTitle => '编辑图片';

  @override
  String get imageFromUrl => '从链接';

  @override
  String get imageFromFile => '从文件';

  @override
  String get imageUrlLabel => '图片链接';

  @override
  String get imageUrlHint => 'https://example.com/image.png';

  @override
  String get imageChooseFile => '选择文件';

  @override
  String get imageChooseAnother => '重新选择';

  @override
  String get editLinkTitle => '编辑链接';

  @override
  String get linkLabelOptional => '标签（可选）';

  @override
  String get linkLabelHint => '我的链接';

  @override
  String get connectionLabelHint => '例如：依赖于、相关于...';

  @override
  String get connectionStyleLabel => '样式';

  @override
  String get connectionStyleSolid => '实线';

  @override
  String get connectionStyleDashed => '虚线';

  @override
  String get connectionStyleArrow => '箭头';

  @override
  String get searchTabTv => '电视剧';

  @override
  String get searchHintMovies => '搜索电影...';

  @override
  String get searchHintTv => '搜索电视剧...';

  @override
  String get searchHintAnime => '搜索动漫...';

  @override
  String get searchHintGames => '搜索游戏...';

  @override
  String get searchHintVisualNovels => '搜索视觉小说...';

  @override
  String get searchSourceVisualNovels => '视觉小说';

  @override
  String get searchSourceOpenLibrary => 'OpenLibrary';

  @override
  String get searchSourceFantlab => 'Fantlab';

  @override
  String get searchSourceComics => '漫画';

  @override
  String get searchHintManga => '搜索漫画...';

  @override
  String get searchHintBooks => '搜索书籍...';

  @override
  String get searchHintComics => '搜索漫画...';

  @override
  String get searchSourceMusic => '音乐';

  @override
  String get searchHintMusic => '搜索专辑...';

  @override
  String get musicFilterAlbumsDefault => '专辑';

  @override
  String get musicFilterAllTypes => '所有类型';

  @override
  String get musicFilterTypeEp => 'EP';

  @override
  String get musicFilterTypeSingle => '单曲';

  @override
  String get musicFilterTypeBroadcast => '广播';

  @override
  String get musicFilterTypeOther => '其他';

  @override
  String get musicFilterEdition => '版本';

  @override
  String get musicFilterStudioOnly => '仅录音室专辑';

  @override
  String get musicSheetEditions => '版本';

  @override
  String get musicSheetTracks => '曲目';

  @override
  String musicSheetDisc(int number) {
    return '碟 $number';
  }

  @override
  String get musicSheetEditionsUnavailable => '无法加载版本';

  @override
  String musicTracksCount(int count) {
    return '$count 首曲目';
  }

  @override
  String get musicTrackerNoTracks => '没有曲目列表';

  @override
  String get musicDiscoverFreshReleases => '新专辑';

  @override
  String get musicDiscoverUnavailable => '无法加载推荐';

  @override
  String get musicSearchArtist => '艺术家';

  @override
  String get language => '语言';

  @override
  String get bookFilterSearchBy => '搜索方式';

  @override
  String get type => '类型';

  @override
  String get bookSearchAuthor => '作者';

  @override
  String get bookSearchSubject => '主题';

  @override
  String get bookSimilarTitle => '相似书籍';

  @override
  String get bookMoreByAuthorTitle => '该作者的更多作品';

  @override
  String get bookTitleCopied => '标题已复制';

  @override
  String get editionPickerTitle => '选择版本';

  @override
  String get editionPickerEmpty => '未找到版本';

  @override
  String get fantlabTypeNovel => '长篇小说';

  @override
  String get fantlabTypeNovella => '中篇小说';

  @override
  String get fantlabTypeShortStory => '短篇小说';

  @override
  String get fantlabTypeCycle => '系列';

  @override
  String get searchSelectPlatform => '选择平台';

  @override
  String get searchAddToCollection => '添加到收藏';

  @override
  String searchAddedToCollection(String name) {
    return '$name 已添加到收藏';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name 已添加到 $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name 已在收藏中';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name 已在 $collection 中';
  }

  @override
  String searchAddedToCollections(String name, int count) {
    return '$name 已添加到 $count 个收藏';
  }

  @override
  String searchAlreadyInCollections(String name) {
    return '$name 已在所选收藏中';
  }

  @override
  String get goToSettings => '前往设置';

  @override
  String get searchMinCharsHint => '输入至少 2 个字符并按回车';

  @override
  String get searchNoResults => '未找到结果';

  @override
  String get searchWhatToFind => '查找内容';

  @override
  String get searchSortNeedsSingleSource => '仅在单一来源时可排序';

  @override
  String get searchSortUnavailableInSearch => '该来源不支持对搜索结果排序';

  @override
  String get searchSourcesLabel => '来源';

  @override
  String get searchTextOnlyHint => '仅支持文本搜索';

  @override
  String get searchSourceNoResponse => '无响应';

  @override
  String get searchCommonFilters => '通用';

  @override
  String get searchShowAll => '全部';

  @override
  String get searchNarrowedBySource => '已按该来源的筛选缩小';

  @override
  String get searchSourceLacksValue => '不支持所选值';

  @override
  String searchNothingFoundFor(String query) {
    return '未找到「$query」的相关结果';
  }

  @override
  String get searchNoInternet => '无网络连接';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get searchCheckConnection => '请检查网络连接后重试。';

  @override
  String get copyErrorDetails => '复制错误详情';

  @override
  String get errorDetailsCopied => '错误详情已复制';

  @override
  String get errorDetailsTitle => '错误详情';

  @override
  String get errorDetailsShow => '详情';

  @override
  String get showMore => '更多…';

  @override
  String get showLess => '收起';

  @override
  String get platformFilterTitle => '选择平台';

  @override
  String get platformFilterClearAll => '清除全部';

  @override
  String get platformFilterSearchHint => '搜索平台...';

  @override
  String selectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String platformFilterCount(int count) {
    return '$count 个平台';
  }

  @override
  String get platformFilterShowAll => '显示全部';

  @override
  String platformFilterApply(int count) {
    return '应用（$count）';
  }

  @override
  String get platformFilterNone => '未找到平台';

  @override
  String get platformFilterTryDifferent => '请尝试不同的搜索词';

  @override
  String get wishlistHideResolved => '隐藏已解决';

  @override
  String get wishlistShowResolved => '显示已解决';

  @override
  String get wishlistClearResolved => '清除已解决';

  @override
  String get wishlistEmpty => '暂无愿望单项目';

  @override
  String get wishlistEmptyHint => '点击 + 添加想要稍后查找的内容';

  @override
  String get wishlistDeleteItem => '删除项目';

  @override
  String wishlistDeletePrompt(String name) {
    return '从愿望单中删除「$name」？';
  }

  @override
  String wishlistClearResolvedMessage(int count) {
    return '删除 $count 个已解决的项目？';
  }

  @override
  String get wishlistMarkResolved => '标记为已解决';

  @override
  String get wishlistUnresolve => '取消解决';

  @override
  String get wishlistTitleHint => '游戏、电影或电视剧名称...';

  @override
  String get wishlistTitleMinChars => '至少 2 个字符';

  @override
  String get wishlistTypeOptional => '类型（可选）';

  @override
  String get any => '任意';

  @override
  String get wishlistNoteOptional => '备注（可选）';

  @override
  String get wishlistNoteHint => '平台、年份、推荐人...';

  @override
  String get wishlistTagOptional => '标签（可选）';

  @override
  String get wishlistTagHint => '分组条目——例如导入批次或来源';

  @override
  String get wishlistTagUntagged => '未标记';

  @override
  String get wishlistTagFilterLabel => '列表';

  @override
  String get wishlistTagManage => '管理标签';

  @override
  String get wishlistTagDelete => '删除标签及所有条目';

  @override
  String wishlistTagDeleteConfirm(String tag, int count) {
    return '删除标签「$tag」及 $count 个条目？';
  }

  @override
  String wishlistBulkActionsButton(int count) {
    return '$count 个匹配项';
  }

  @override
  String get wishlistBulkApplyTag => '对可见项应用标签';

  @override
  String wishlistBulkApplyTagHint(int count) {
    return '将 $count 个可见条目标记为';
  }

  @override
  String get wishlistBulkRemoveTag => '从可见项移除标签';

  @override
  String get wishlistBulkDelete => '删除可见项';

  @override
  String wishlistBulkDeleteConfirm(int count) {
    return '删除 $count 个可见条目？';
  }

  @override
  String get apply => '应用';

  @override
  String get welcomeStepWelcome => '欢迎';

  @override
  String get welcomeStepReady => '准备就绪！';

  @override
  String get welcomeNameTitle => '您的名字是？';

  @override
  String get welcomeNameSubtitle => '此名称将作为您创建的收藏的作者显示';

  @override
  String get welcomeChangeLaterHint => '您可以稍后在设置中更改';

  @override
  String get welcomeLanguageTitle => '选择语言';

  @override
  String get welcomeLanguageSubtitle => '选择应用界面语言';

  @override
  String get welcomeTitle => '欢迎使用 Tonkatsu Box';

  @override
  String get welcomeSubtitle => '整理您的游戏、电影、电视剧、\n动漫、视觉小说、漫画和书籍收藏';

  @override
  String get welcomeWhatYouCanDo => '功能介绍';

  @override
  String get welcomeFeatureCollections => '按平台、类型或任意主题创建收藏';

  @override
  String get welcomeFeatureSearch => '通过 API 搜索游戏、电影、电视剧、动漫、视觉小说、漫画和书籍';

  @override
  String get welcomeFeatureTracking => '追踪进度、1-10 评分、添加备注';

  @override
  String get welcomeFeatureBoards => '带有美术素材的可视化看板';

  @override
  String get welcomeFeatureExport => '导出和导入——与朋友分享收藏';

  @override
  String get welcomeWorksWithoutKeys => '无需 API 密钥即可使用';

  @override
  String get welcomeChipImport => '导入 .xcoll';

  @override
  String get welcomeChipCanvas => '看板';

  @override
  String get welcomeChipRatings => '评分和备注';

  @override
  String get welcomeApiKeysHint => 'API 密钥仅在搜索新游戏、电影和电视剧时需要。您可以导入收藏并离线使用。';

  @override
  String get welcomeChipGames => '游戏（IGDB）';

  @override
  String get welcomeChipMovies => '电影（TMDB）';

  @override
  String get welcomeChipTvShows => '电视剧（TMDB）';

  @override
  String get welcomeChipAnime => '动漫（TMDB）';

  @override
  String get welcomeChipVisualNovels => '视觉小说（VNDB）';

  @override
  String get welcomeChipManga => '漫画（AniList）';

  @override
  String get welcomeApiTitle => '获取 API 密钥';

  @override
  String get welcomeApiFreeHint => '免费注册，每个只需 2-3 分钟';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => '游戏搜索';

  @override
  String get welcomeApiRequired => '必需';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => '电影、电视剧和动漫';

  @override
  String get welcomeApiTvdbDesc => '电影与剧集，自带分集数据';

  @override
  String get welcomeApiComicVineDesc => '漫画和图像小说';

  @override
  String get welcomeApiGoogleBooksDesc => 'Google 全球图书目录';

  @override
  String get welcomeApiHardcoverDesc => '社区图书目录，需要个人令牌';

  @override
  String get welcomeApiRecommended => '推荐';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => '看板游戏美术素材';

  @override
  String get welcomeApiOptional => '可选';

  @override
  String get welcomeApiBuiltInKey => '内置密钥';

  @override
  String get welcomeApiOwnKeyHint => '您可以在设置中添加自己的密钥以获得更高速率限制';

  @override
  String get welcomeApiEnterKeysHint => '设置完成后在设置 → 凭证中输入密钥';

  @override
  String get welcomeApiRateLimitHint =>
      '内置密钥在所有用户间共享，有速率限制。为了获得最佳体验，请使用自己的密钥——免费且只需几分钟。';

  @override
  String get welcomeHowTitle => '工作原理';

  @override
  String get welcomeHowAppStructure => '应用结构';

  @override
  String get welcomeHowMainDesc => '所有收藏中的所有项目集中在一个视图中。按类型筛选，按评分排序。';

  @override
  String get welcomeHowCollectionsDesc => '您的收藏。创建、整理、管理。每个收藏可选网格或列表视图。';

  @override
  String get welcomeHowTierListsDesc => '使用可自定义的等级列表对跨收藏的项目进行排名和比较。';

  @override
  String get welcomeHowWishlistDesc => '快速列出稍后要查看的项目。无需 API。';

  @override
  String get welcomeHowSearchDesc => '通过 API 查找游戏、电影、电视剧、视觉小说和漫画。添加到任意收藏。';

  @override
  String get welcomeHowSettingsDesc => 'API 密钥、缓存、数据库导出/导入、调试工具。';

  @override
  String get welcomeHowPersonalizationDesc => '您的品味一目了然：喜爱类型的词云，加上根据评分挑选的推荐。';

  @override
  String get welcomeHowQuickStart => '快速开始';

  @override
  String get welcomeHowStep1 => '前往设置 → 凭证，输入 API 密钥';

  @override
  String get welcomeHowStep2 => '点击验证连接，等待平台同步';

  @override
  String get welcomeHowStep3 => '前往收藏 → + 新建收藏';

  @override
  String get welcomeHowStep4 => '命名后，添加项目 → 搜索 → 添加';

  @override
  String get welcomeHowStep5 => '评分、追踪进度、添加备注——完成！';

  @override
  String get welcomeHowSharing => '分享';

  @override
  String get welcomeHowSharingDesc1 => '将收藏导出为 ';

  @override
  String get welcomeHowSharingDesc2 => '（轻量，仅元数据）或 ';

  @override
  String get welcomeHowSharingDesc3 => '（完整，含图片和看板——可离线使用）。从朋友处导入——无需 API！';

  @override
  String get welcomeReadyTitle => '一切就绪！';

  @override
  String get welcomeReadyMessage => '前往设置 → 凭证输入您的 API 密钥，或从导入收藏开始。';

  @override
  String get welcomeReadySkip => '跳过——自行探索';

  @override
  String get welcomeReadyReturnHint => '您可以随时从设置返回此处';

  @override
  String get welcomeStepSources => '数据源';

  @override
  String get welcomeStepTour => '导览';

  @override
  String get welcomeChipBooks => '书籍（OpenLibrary、Fantlab）';

  @override
  String get welcomeSourcesTitle => '数据来源';

  @override
  String get welcomeSourcesSubtitle => '这些提供商为应用提供搜索支持。大多数可直接使用——只有少数需要免费密钥。';

  @override
  String get welcomeSourcesNoKeyNeeded => '无需密钥';

  @override
  String get welcomeSourcesKeySaved => '密钥已保存';

  @override
  String get welcomeSourcesGetKey => '获取密钥';

  @override
  String get welcomeSourcesKeyOptionalHint => '可选——使用自己的密钥可提高速率限制。无需密钥也可搜索。';

  @override
  String get welcomeSourcesTvdbKeyHint => '必填——没有密钥时 TheTVDB 搜索保持关闭。';

  @override
  String get welcomeSourcesHardcoverTokenHint =>
      '必填——没有令牌无法搜索和导入。令牌每年 1 月 1 日重置。';

  @override
  String get welcomeSourceDescTmdb => '电影、电视剧和动画。';

  @override
  String get welcomeSourceDescTvMaze => '电视剧。';

  @override
  String get welcomeSourceDescTvdb => '电影与剧集，自带分集数据。';

  @override
  String get welcomeSourceDescIgdb => '涵盖所有平台的电子游戏。';

  @override
  String get welcomeSourceDescAniList => '带有丰富元数据的动漫和漫画。';

  @override
  String get welcomeSourceDescMangaBaka => '漫画、韩漫、国漫和轻小说。';

  @override
  String get welcomeSourceDescMangaDex => '大型漫画目录，带本地化标题和章节数。';

  @override
  String get welcomeSourceDescKitsu => '独立的漫画目录，带评分和封面。';

  @override
  String get welcomeSourceDescVndb => '视觉小说数据库。';

  @override
  String get welcomeSourceDescOpenLibrary => '包含数百万本书的开放目录。';

  @override
  String get welcomeSourceDescFantlab => '带有评分、奖项和系列的详细图书目录。';

  @override
  String get welcomeSourceDescComicVine => '庞大的漫画和图像小说目录。';

  @override
  String get welcomeSourceDescGoogleBooks =>
      '来自 Google 图书目录的数百万版本，可按标题、作者或 ISBN 搜索。';

  @override
  String get welcomeSourceDescHardcover => '社区图书目录：系列、类型、氛围和评分。需要免费的个人令牌。';

  @override
  String get welcomeTourTitle => '了解菜单';

  @override
  String get welcomeTourSubtitle => '快速导览主要导航——点击下一步逐步查看。';

  @override
  String get welcomeTourStart => '开始探索';

  @override
  String get welcomeHowReleasesDesc => '您追踪的节目和游戏的新剧集和发布。';

  @override
  String updateAvailable(String version) {
    return '有可用更新：v$version';
  }

  @override
  String updateCurrent(String version) {
    return '当前版本：v$version';
  }

  @override
  String get updateWarningTitle => '更新前须知';

  @override
  String get updateWarningBody =>
      '此应用正在积极开发中。更新可能包含更改数据格式的数据库迁移。\n\n请在更新前创建备份（设置 → 备份）。这样如果出现问题，您可以恢复数据。';

  @override
  String get updateWarningProceed => '前往发布页';

  @override
  String get chooseCollection => '选择收藏';

  @override
  String get withoutCollection => '未分类';

  @override
  String get detailMyRating => '我的评分';

  @override
  String detailRatingValue(String rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => '活动和进度';

  @override
  String get detailAuthorReview => '作者评论';

  @override
  String get detailEditAuthorReview => '编辑作者评论';

  @override
  String get detailWriteReviewHint => '写下您的评论...';

  @override
  String get detailReviewVisibility => '分享时他人可见。您对这个标题的评论。';

  @override
  String get detailNoReviewEditable => '暂无评论。点击编辑添加。';

  @override
  String get detailNoReviewReadonly => '作者暂无评论。';

  @override
  String get detailMyNotes => '我的备注';

  @override
  String get detailEditMyNotes => '编辑我的备注';

  @override
  String get detailWriteNotesHint => '写下您的个人备注...';

  @override
  String get detailNoNotesYet => '暂无备注。点击编辑添加您的个人备注。';

  @override
  String get detailNoNotesReadonly => '作者暂无备注。';

  @override
  String get unknownGame => '未知游戏';

  @override
  String get unknownMovie => '未知电影';

  @override
  String get unknownTvShow => '未知电视剧';

  @override
  String get unknownAnimation => '未知动画';

  @override
  String get unknownVisualNovel => '未知视觉小说';

  @override
  String get unknownManga => '未知漫画';

  @override
  String get unknownCustom => '未知自定义项目';

  @override
  String get unknownPlatform => '未知平台';

  @override
  String get defaultAuthor => '用户';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String get allItemsRatingAsc => '评分 ↑';

  @override
  String get allItemsRatingDesc => '评分 ↓';

  @override
  String get allItemsNoItems => '暂无项目';

  @override
  String get allItemsNoMatch => '没有匹配筛选的项目';

  @override
  String get allItemsAddViaCollections =>
      '前往收藏 → 新建收藏 → 通过搜索添加项目。\n它们将自动出现在此处。';

  @override
  String get allItemsFailedToLoad => '加载项目失败';

  @override
  String get allPlatforms => '所有平台';

  @override
  String get allItemsFilterPlatformsTitle => '按平台筛选';

  @override
  String get debugIgdbMedia => 'IGDB 媒体';

  @override
  String get debugGamepad => '手柄';

  @override
  String get debugClearLogs => '清除日志';

  @override
  String get debugRawEvents => '原始事件（Gamepads.events）';

  @override
  String get debugServiceEvents => '服务事件（已过滤）';

  @override
  String debugEventsCount(int count) {
    return '$count 个事件';
  }

  @override
  String get debugPressButton => '请按下\n手柄上的任意按钮...';

  @override
  String get debugExportLog => '导出日志到文件';

  @override
  String debugLogExported(String path) {
    return '日志已导出到 $path';
  }

  @override
  String get debugLogEmpty => '无事件可导出';

  @override
  String get settingsGamepadDebug => '手柄调试';

  @override
  String get debugSearchGames => '搜索游戏';

  @override
  String get debugEnterGameName => '输入游戏名称';

  @override
  String get debugEnterGameNameHint => '输入游戏名称进行搜索';

  @override
  String get debugGameId => '游戏 ID';

  @override
  String get debugEnterGameId => '输入 SteamGridDB 游戏 ID';

  @override
  String debugLoadTab(String tabName) {
    return '加载 $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return '输入游戏 ID 并按加载 $tabName';
  }

  @override
  String get debugNoImagesFound => '未找到图片';

  @override
  String collectionTileStats(int count, String percent) {
    return '$count 个项目 · $percent% 已完成';
  }

  @override
  String get collectionTileError => '加载统计出错';

  @override
  String get activityDatesTitle => '活动日期';

  @override
  String get activityDatesAdded => '添加日期';

  @override
  String get activityDatesStarted => '开始日期';

  @override
  String get activityDatesCompleted => '完成日期';

  @override
  String get activityDatesSelectStart => '选择开始日期';

  @override
  String get activityDatesSelectCompletion => '选择完成日期';

  @override
  String get settingsDateFormat => '日期格式';

  @override
  String get settingsDateFormatSubtitle => '应用中日期的显示方式';

  @override
  String get settingsAnimeMangaTitleLanguage => '动漫和漫画标题语言';

  @override
  String get settingsAnimeMangaTitleLanguageSubtitle => '动漫和漫画显示的标题';

  @override
  String get settingsAnimeMangaTitleLanguageRomaji => '罗马字';

  @override
  String get settingsAnimeMangaTitleLanguageEnglish => '英文';

  @override
  String get settingsAnimeMangaTitleLanguageNative => '原生语言';

  @override
  String get dualDatePickerNoDate => '无日期';

  @override
  String get dualDatePickerErrorEmpty => '请输入日期';

  @override
  String get dualDatePickerErrorFormat => '请使用 yyyy-MM-dd 格式';

  @override
  String get dualDatePickerErrorRange => '日期超出范围';

  @override
  String activityDatesCompletionTime(String duration) {
    return '完成用时 $duration';
  }

  @override
  String get timeSpentTitle => '用时';

  @override
  String get timeSpentAdd => '添加时间';

  @override
  String get timeSpentEdit => '编辑时间';

  @override
  String get timeSpentHours => '小时';

  @override
  String get timeSpentMinutes => '分钟';

  @override
  String get durationLessThanDay => '不到一天';

  @override
  String get durationOneDay => '1 天';

  @override
  String durationDays(int count) {
    return '$count 天';
  }

  @override
  String durationWeeks(int count) {
    return '$count 周';
  }

  @override
  String durationMonths(int count) {
    return '$count 个月';
  }

  @override
  String durationYears(String count) {
    return '$count 年';
  }

  @override
  String get canvasFailedToLoad => '加载看板失败';

  @override
  String get canvasBoardEmpty => '看板为空';

  @override
  String get canvasBoardEmptyHint => '请先向收藏添加项目';

  @override
  String get canvasCenterView => '居中视图';

  @override
  String get canvasResetPositions => '重置位置';

  @override
  String get canvasVgmapsBrowser => 'VGMaps 浏览器';

  @override
  String get canvasSteamGridDbImages => 'SteamGridDB 图片';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get closePanel => '关闭面板';

  @override
  String get steamGridDbSearchHint => '搜索游戏...';

  @override
  String get steamGridDbNoApiKey => '未设置 SteamGridDB API 密钥。请在设置中配置。';

  @override
  String get steamGridDbBackToSearch => '返回搜索';

  @override
  String get steamGridDbGrids => '网格';

  @override
  String get steamGridDbHeroes => '横幅';

  @override
  String get steamGridDbLogos => '标志';

  @override
  String get steamGridDbIcons => '图标';

  @override
  String get steamGridDbSearchFirst => '请先搜索游戏';

  @override
  String get vgmapsBack => '后退';

  @override
  String get vgmapsForward => '前进';

  @override
  String get vgmapsHome => '主页';

  @override
  String get vgmapsReload => '刷新';

  @override
  String get vgmapsCaptureImage => '截取地图图片';

  @override
  String get vgmapsSearchHint => '在 VGMaps 上搜索游戏...';

  @override
  String get vgmapsDismiss => '关闭';

  @override
  String vgmapsFailedInit(String error) {
    return '初始化 WebView 失败：$error';
  }

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverCustomize => '自定义';

  @override
  String get discoverTrending => '本周热门';

  @override
  String get discoverTopRatedMovies => '高分电影';

  @override
  String get discoverTopRatedTvShows => '高分电视剧';

  @override
  String get discoverPopularTvShows => '热门电视剧';

  @override
  String get discoverUpcoming => '即将上映';

  @override
  String get discoverCustomizeTitle => '自定义发现';

  @override
  String get discoverCustomizeHint => '选择要显示的板块';

  @override
  String get discoverResetDefault => '重置为默认';

  @override
  String get discoverAlreadyInCollection => '已在收藏中';

  @override
  String get discoverShowWithBadge => '带标签显示';

  @override
  String get discoverHideCompletely => '完全隐藏';

  @override
  String get recommendationsTitle => '推荐';

  @override
  String get reviewsTitle => '评论';

  @override
  String reviewsShowAll(int count) {
    return '查看全部 $count 条评论';
  }

  @override
  String get reviewsReadMore => '阅读更多';

  @override
  String get reviewsInEnglish => '英文评论';

  @override
  String get settingsShowRecommendationsSubtitle => '详情页上相似的电影和电视剧';

  @override
  String get settingsHideEmptyMediaTypeChevrons => '隐藏空的媒体类型筛选';

  @override
  String get settingsHideEmptyMediaTypeChevronsSubtitle =>
      '当没有该类型的项目时，隐藏媒体类型筛选（游戏、电影等）';

  @override
  String get settingsAlwaysShowSubcategories => '始终显示子分类';

  @override
  String get settingsAlwaysShowSubcategoriesSubtitle =>
      '无需先选择媒体类型即可显示子分类筛选（游戏平台、动漫/漫画类型）';

  @override
  String get settingsShowPlatformOverlay => '游戏平台封面';

  @override
  String get settingsShowPlatformOverlaySubtitle =>
      '在游戏海报上显示平台标识（PS5、Switch 等）';

  @override
  String get settingsShowBlurayOverlay => '蓝光封面';

  @override
  String get settingsShowBlurayOverlaySubtitle => '在电影和电视剧海报上显示蓝光标识';

  @override
  String get settingsRichCollections => '富文本收藏视图';

  @override
  String get settingsRichCollectionsSubtitle => '使用封面图片和描述个性化收藏';

  @override
  String get settingsCardScale => '封面大小';

  @override
  String get settingsCardScaleSubtitle => '收藏网格中卡片的大小';

  @override
  String get collectionEditHeroImage => '封面图片';

  @override
  String get collectionEditHeroImageHint =>
      '推荐 2560×1080（21:9）。主体靠右——左侧被标题覆盖，底部融入背景';

  @override
  String get collectionEditHeroPick => '选择图片';

  @override
  String get collectionEditHeroReplace => '替换图片';

  @override
  String get collectionEditHeroRemove => '移除图片';

  @override
  String get collectionEditDescriptionHint => '显示在封面上的简短标语';

  @override
  String get collectionEditDialogTitle => '收藏设置';

  @override
  String get settingsDiscordRpc => 'Discord 丰富状态';

  @override
  String get settingsDiscordRpcSubtitle => '在 Discord 状态中显示当前查看的项目';

  @override
  String get settingsDiscordRaSync => '同步 RetroAchievements';

  @override
  String get settingsDiscordRaSyncSubtitle =>
      '在 Discord 中显示您的 RetroAchievements 活动';

  @override
  String get uncategorizedBanner => '添加到收藏以解锁看板和剧集追踪';

  @override
  String get uncategorizedDeprecationNotice => '此系统收藏即将被移除。请创建自己的收藏并将此处所有项目移入。';

  @override
  String get uncategorizedDeprecationBadge => '即将移除';

  @override
  String get browseFilterGenre => '类型';

  @override
  String get browseFilterLength => '篇幅';

  @override
  String get vndbLengthVeryShort => '极短';

  @override
  String get vndbLengthShort => '短篇';

  @override
  String get vndbLengthMedium => '中篇';

  @override
  String get vndbLengthLong => '长篇';

  @override
  String get vndbLengthVeryLong => '极长';

  @override
  String get browseFilterAnimeAdaptation => '动漫改编';

  @override
  String get vndbHasAnimeAdaptation => '有改编';

  @override
  String get tagPickerSearchHint => '搜索标签';

  @override
  String get tagPickerShowSpoilers => '显示剧透标签';

  @override
  String get tagPickerShowAdult => '显示 18+ 标签';

  @override
  String get tagPickerRefresh => '刷新目录';

  @override
  String get tagPickerEmpty => '未找到标签';

  @override
  String get clearAll => '清除全部';

  @override
  String get browseFilterSeason => '季度';

  @override
  String get browseFilterGameMode => '游戏模式';

  @override
  String get browseFilterMinRating => '最低评分';

  @override
  String get browseFilterMinVotes => '最低票数';

  @override
  String get seasonWinter => '冬季';

  @override
  String get seasonSpring => '春季';

  @override
  String get seasonSummer => '夏季';

  @override
  String get seasonFall => '秋季';

  @override
  String get animeFormatTv => 'TV';

  @override
  String get animeFormatMovie => '剧场版';

  @override
  String get animeFormatOva => 'OVA';

  @override
  String get animeFormatOna => 'ONA';

  @override
  String get animeFormatSpecial => '特别篇';

  @override
  String get animeFormatTvShort => 'TV 短篇';

  @override
  String get mangaStatusPublishing => '连载中';

  @override
  String get mangaStatusFinished => '已完结';

  @override
  String get mangaStatusNotYetPublished => '未开始连载';

  @override
  String get mangaStatusCancelled => '已停刊';

  @override
  String get mangaStatusHiatus => '休刊中';

  @override
  String get gameModeSinglePlayer => '单人';

  @override
  String get gameModeMultiplayer => '多人';

  @override
  String get gameModeCoOperative => '合作';

  @override
  String get gameModeSplitScreen => '分屏';

  @override
  String get gameModeMmo => 'MMO';

  @override
  String get gameModeBattleRoyale => '大逃杀';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageKorean => '韩语';

  @override
  String get languageChinese => '中文';

  @override
  String get languageFrench => '法语';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageGerman => '德语';

  @override
  String get languageRussian => '俄语';

  @override
  String get languageItalian => '意大利语';

  @override
  String get languagePortuguese => '葡萄牙语';

  @override
  String get mangaFormatManhwa => '韩漫';

  @override
  String get mangaFormatManhua => '国漫';

  @override
  String get mangaFormatOneShot => '单行本';

  @override
  String get mangaFormatNovel => '小说';

  @override
  String get mangaFormatLightNovel => '轻小说';

  @override
  String get browseFilterContentRating => '内容分级';

  @override
  String get browseFilterDemographic => '受众';

  @override
  String get contentRatingSafe => '全年龄';

  @override
  String get contentRatingSuggestive => '暗示性';

  @override
  String get contentRatingErotica => '情色';

  @override
  String get contentRatingPornographic => '色情';

  @override
  String get browseSortRelevance => '相关度';

  @override
  String get browseSortPopular => '热门';

  @override
  String get browseSortTopRated => '高分';

  @override
  String get browseSortNewest => '最新';

  @override
  String get browseSortMostVoted => '最多票数';

  @override
  String get browseSortMostRead => '最多阅读';

  @override
  String get browseSortTrending => '趋势';

  @override
  String get browseSortNameAsc => '名称（A–Z）';

  @override
  String get browseSortNameDesc => '名称（Z–A）';

  @override
  String get browseSortRecentlyUpdated => '最近更新';

  @override
  String get browseSortRecentlyAdded => '最近添加';

  @override
  String get browseAnimeTypeSeries => '系列';

  @override
  String get browseAnimeTypeMovies => '剧场版';

  @override
  String get browseEmptyFilters => '选择筛选条件或搜索';

  @override
  String get browseBackToBrowse => '返回浏览';

  @override
  String get browseSortDisabledHint => '文本搜索时无法排序';

  @override
  String get animeStatusAiring => '播出中';

  @override
  String get animeStatusFinished => '已完结';

  @override
  String get animeStatusNotYetAired => '未播出';

  @override
  String get animeStatusCancelled => '已取消';

  @override
  String get typeToFilterHint => '筛选...';

  @override
  String get appBarSearchHint => '输入以搜索';

  @override
  String get insertLink => '插入链接';

  @override
  String get linkText => '文字';

  @override
  String get linkHint => '指南';

  @override
  String get urlLabel => '链接';

  @override
  String get urlHint => 'https://example.com';

  @override
  String get markdownBold => '粗体';

  @override
  String get markdownItalic => '斜体';

  @override
  String get insert => '插入';

  @override
  String get navTierLists => '等级列表';

  @override
  String get tierListCreate => '新建等级列表';

  @override
  String get tierListCreateFromCollection => '创建等级列表';

  @override
  String get tierListNameHint => '等级列表名称';

  @override
  String get tierListScopeAll => '所有项目';

  @override
  String get tierListScopeCollection => '来自收藏';

  @override
  String tierListFromCollection(String name) {
    return '来自：$name';
  }

  @override
  String tierListRankedCount(int count) {
    return '已排名 $count 项';
  }

  @override
  String get tierListTitle => '等级列表';

  @override
  String get tierListUnranked => '未排名';

  @override
  String get exportAsImage => '导出为图片';

  @override
  String get tierListImageSaved => '等级列表已保存为图片';

  @override
  String get tierListRename => '重命名等级';

  @override
  String get tierListChangeColor => '更改颜色';

  @override
  String get tierListMoveUp => '上移';

  @override
  String get tierListMoveDown => '下移';

  @override
  String get tierListDeleteTier => '删除等级';

  @override
  String get tierListAddTier => '添加等级';

  @override
  String get tierListClearConfirm => '移除所有等级中的项目？它们将返回未排名。';

  @override
  String get tierListDeleteConfirm => '删除此等级列表？';

  @override
  String get tierListEmpty => '暂无等级列表';

  @override
  String get tierListEmptyHint => '点击 + 创建等级列表并对收藏中的项目进行排名。';

  @override
  String get tierListAllRanked => '所有项目已排名！';

  @override
  String get tierListErrorEmptyName => '请输入等级列表名称';

  @override
  String get tierListErrorNoCollection => '请选择收藏';

  @override
  String get collectionPickerFilter => '筛选收藏...';

  @override
  String get collectionPickerAlreadyAdded => '✓ 已添加';

  @override
  String collectionPickerAlreadyInCount(int count) {
    return '已在 $count 个收藏中';
  }

  @override
  String get settingsSteamImport => 'Steam 库';

  @override
  String get settingsSteamImportSubtitle => '通过 Steam Web API 导入游戏';

  @override
  String get settingsIgdbImport => 'IGDB 列表';

  @override
  String get settingsIgdbImportSubtitle => '导入从 IGDB 导出的游戏列表（CSV）';

  @override
  String get igdbImportTitle => '导入 IGDB 列表';

  @override
  String get igdbImportDescription =>
      '选择从 IGDB 导出的 CSV 列表。游戏通过 IGDB ID 匹配；IGDB 上不再存在的将加入愿望单。';

  @override
  String get igdbImportSelectCsvFile => '选择 CSV 文件';

  @override
  String get igdbImportSelectCsvExport => '选择 IGDB CSV 导出';

  @override
  String get igdbImportStatusLabel => '导入游戏的状态';

  @override
  String get igdbImportPlatformSelect => '选择平台';

  @override
  String get importIgdbRequired => '需要 IGDB 连接。请先在设置 → 凭证中设置 API 密钥。';

  @override
  String get importing => '导入中...';

  @override
  String get igdbReasonNotFound => '在 IGDB 上未找到';

  @override
  String get steamImportTitle => '导入 Steam 库';

  @override
  String get importIgdbMatchNote => '游戏将匹配到 IGDB 数据库';

  @override
  String get steamImportApiKey => 'Steam API 密钥';

  @override
  String get steamImportApiKeyHint => '在 steamcommunity.com/dev/apikey 获取免费密钥';

  @override
  String get steamImportSteamId => 'Steam ID（64 位）';

  @override
  String get steamImportSteamIdHint => '在 steamidfinder.com 查找';

  @override
  String get steamImportPublicWarning => '您的 Steam 个人资料必须设为公开';

  @override
  String get steamImportButton => '导入库';

  @override
  String get steamImportFetchingLibrary => '正在获取 Steam 库...';

  @override
  String get steamImportMatching => '正在 IGDB 中匹配游戏...';

  @override
  String steamImportLookingUp(String name) {
    return '正在查找：$name';
  }

  @override
  String steamImportImported(int count) {
    return '已导入：$count';
  }

  @override
  String steamImportWishlisted(int count) {
    return '已加入愿望单：$count';
  }

  @override
  String steamImportUpdated(int count) {
    return '已更新：$count';
  }

  @override
  String get importComplete => '导入完成！';

  @override
  String steamImportGamesImported(int count) {
    return '已导入 $count 款游戏';
  }

  @override
  String steamImportWishlistedInIgdb(int count) {
    return '已将 $count 个加入愿望单';
  }

  @override
  String steamImportUpdatedDuplicates(int count) {
    return '已更新 $count 个（已存在）';
  }

  @override
  String get steamImportPlayedStatus => '已玩游戏标记为「进行中」';

  @override
  String get steamImportPlaytimeComment => '游戏时间保存在评论中';

  @override
  String get openCollection => '打开收藏';

  @override
  String get steamImportRememberCredentials => '记住凭证';

  @override
  String get collectionListSortCreatedDate => '创建日期';

  @override
  String get collectionListSortAlphabeticalAZ => 'A 到 Z';

  @override
  String get collectionListSortAlphabeticalZA => 'Z 到 A';

  @override
  String get collectionListViewGrid => '网格视图';

  @override
  String get collectionListViewList => '列表视图';

  @override
  String get collectionListViewTable => '表格视图';

  @override
  String get collectionTableExternalRating => '外部';

  @override
  String get collectionCopyToCollection => '复制到收藏';

  @override
  String collectionItemCopiedTo(Object collection, Object name) {
    return '$name 已复制到 $collection';
  }

  @override
  String collectionItemAlreadyInTarget(Object collection, Object name) {
    return '$name 已在 $collection 中';
  }

  @override
  String get openInCollection => '在收藏中打开';

  @override
  String get importResultTitle => '导入结果';

  @override
  String importResultComplete(String source) {
    return '$source 导入完成！';
  }

  @override
  String importResultFailed(String source) {
    return '$source 导入失败';
  }

  @override
  String get importResultImported => '已导入';

  @override
  String get importResultWishlisted => '已加入愿望单';

  @override
  String get importResultUpdated => '已更新';

  @override
  String importResultErrors(int count) {
    return '错误（$count）';
  }

  @override
  String get importResultErrorsCopied => '错误已复制';

  @override
  String importResultSkipped(int count) {
    return '跳过 $count 个';
  }

  @override
  String get importResultOpenCollection => '打开收藏';

  @override
  String get importResultWishlistHint => '数据库中未找到的项目已保存到您的愿望单中。';

  @override
  String get importResultSourceCollectionFile => '收藏文件';

  @override
  String get settingsBrowseCollections => '浏览收藏';

  @override
  String get settingsBrowseCollectionsSubtitle => '下载现成的收藏';

  @override
  String browseCollectionsSummary(int count, int items) {
    return '$count 个收藏，$items 个项目';
  }

  @override
  String get browseCollectionsSearch => '搜索收藏...';

  @override
  String get browseCollectionsAllCategories => '所有分类';

  @override
  String browseCollectionsItems(int count) {
    return '$count 个项目';
  }

  @override
  String get browseCollectionsFormatLight => '轻量（需要 API 密钥）';

  @override
  String get browseCollectionsFormatFull => '完整（离线）';

  @override
  String get browseCollectionsDownloading => '下载中...';

  @override
  String browseCollectionsImportSuccess(String name) {
    return '收藏已导入：$name';
  }

  @override
  String get browseCollectionsEmpty => '未找到收藏';

  @override
  String get browseCollectionsLoadError => '加载收藏失败';

  @override
  String get browseCollectionsImportTarget => '导入到';

  @override
  String get browseCollectionsNewCollection => '新建收藏';

  @override
  String get browseCollectionsExistingCollection => '现有收藏';

  @override
  String get noCollectionsYet => '暂无收藏';

  @override
  String get settingsRaImport => 'RetroAchievements';

  @override
  String get settingsRaImportSubtitle => '从 RetroAchievements 导入游戏';

  @override
  String get raImportTitle => 'RetroAchievements 导入';

  @override
  String get raGetApiKey =>
      '在 retroachievements.org/controlpanel.php 获取您的 API 密钥';

  @override
  String get raImportOptionWishlist => '将未匹配的游戏加入愿望单';

  @override
  String get raImportFetchingLibrary => '正在获取 RA 库...';

  @override
  String get raImportSearchingIgdb => '正在 IGDB 上搜索游戏...';

  @override
  String raImportMatching(String title) {
    return '正在匹配：$title';
  }

  @override
  String raImportAdded(int count) {
    return '已添加 $count 款游戏';
  }

  @override
  String raImportUpdated(int count) {
    return '已更新 $count 款游戏';
  }

  @override
  String raImportToWishlist(int count) {
    return '已将 $count 个加入愿望单';
  }

  @override
  String raConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String raProfilePoints(int points) {
    return '$points 分';
  }

  @override
  String raProfileMemberSince(String date) {
    return '注册于 $date';
  }

  @override
  String get raRefresh => '刷新成就';

  @override
  String get raOpenOnRa => '在 RA 上打开 ↗';

  @override
  String get raHardcore => '硬核';

  @override
  String get raCompletion => '完成度';

  @override
  String get raRecentUnlocks => '最近解锁';

  @override
  String get raUpNext => '即将达成';

  @override
  String raViewAll(int count) {
    return '查看全部 $count 个成就 →';
  }

  @override
  String get raMastered => '精通';

  @override
  String get raHardcoreMastered => '硬核精通';

  @override
  String get raBeaten => '通关';

  @override
  String get raBeatenSoftcore => '软核通关';

  @override
  String get raHardcoreBeaten => '硬核通关';

  @override
  String get raYesterday => '昨天';

  @override
  String raDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get raPoints => '分';

  @override
  String get raAchievements => '成就';

  @override
  String get raMissable => '可错过';

  @override
  String get raFilterEarned => '已获得';

  @override
  String get raFilterLocked => '未解锁';

  @override
  String get raFilterMissable => '可错过';

  @override
  String get raFilterProgression => '进度';

  @override
  String get raFilterWinCondition => '通关条件';

  @override
  String get raBeatenProgress => '通关进度';

  @override
  String get raStatsAchievements => '个成就';

  @override
  String get raStatsWorth => '价值';

  @override
  String get raStatsPoints => '分';

  @override
  String get raStatsUnlocked => '已解锁';

  @override
  String get copyAsText => '复制为文本…';

  @override
  String copiedToClipboard(int count) {
    return '已复制 $count 个项目到剪贴板';
  }

  @override
  String get template => '模板';

  @override
  String get textExportTokens => '占位符';

  @override
  String get textExportSortBy => '排序方式';

  @override
  String get textExportSortCurrent => '当前顺序';

  @override
  String get textExportSortName => '名称 A→Z';

  @override
  String get textExportSortYear => '年份 ↓';

  @override
  String get textExportSortAdded => '添加日期 ↓';

  @override
  String get textExportEmptyTemplate => '模板为空';

  @override
  String get filtersClear => '清除';

  @override
  String get collectionTableColumns => '列';

  @override
  String get tableFilterHint => '所有规则同时生效（AND）。';

  @override
  String get tableFilterAddRule => '添加规则';

  @override
  String get tableFilterCondContains => '包含';

  @override
  String get tableFilterCondEquals => '等于';

  @override
  String get tableFilterCondStartsWith => '开头为';

  @override
  String get tableFilterCondEndsWith => '结尾为';

  @override
  String get tableFilterCondAtLeast => '至少（≥）';

  @override
  String get tableFilterCondAtMost => '至多（≤）';

  @override
  String get profiles => '应用配置';

  @override
  String currentProfile(String name) {
    return '当前：$name';
  }

  @override
  String get switchProfile => '切换配置';

  @override
  String get addProfile => '添加配置';

  @override
  String get createProfile => '创建配置';

  @override
  String get editProfile => '编辑配置';

  @override
  String get deleteProfile => '删除配置';

  @override
  String deleteProfileConfirm(String name) {
    return '删除配置 $name？这将删除所有收藏、愿望单和设置。此操作无法撤销。';
  }

  @override
  String get cannotDeleteLastProfile => '无法删除最后一个配置';

  @override
  String get profileName => '名称';

  @override
  String get whoIsPlayingToday => '今天谁在玩？';

  @override
  String get dontAskAgain => '不再询问';

  @override
  String profileStats(int collections, int items) {
    return '$collections 个收藏，$items 个项目';
  }

  @override
  String get switchingProfile => '正在切换配置…';

  @override
  String get appWillRestart => '应用将重启以应用更改。';

  @override
  String get profileCreated => '配置已创建';

  @override
  String get profileDeleted => '配置已删除';

  @override
  String get settingsIntegrations => '集成';

  @override
  String get settingsKodiSubtitle => '从 Kodi 媒体播放器同步观看记录';

  @override
  String get settingsOn => '开启';

  @override
  String get kodiConnectionTitle => '连接';

  @override
  String get kodiConnectionSubtitle => 'Kodi HTTP JSON-RPC（设置 → 服务 → 控制）';

  @override
  String get kodiHost => '主机';

  @override
  String get kodiPort => '端口';

  @override
  String get kodiPassword => '密码';

  @override
  String get kodiPasswordHint => '输入密码';

  @override
  String get kodiTestConnection => '测试连接';

  @override
  String get kodiConnecting => '连接中…';

  @override
  String get kodiPingFailed => 'Ping 失败——意外响应';

  @override
  String kodiConnectedTo(String version, String name) {
    return 'Kodi $version「$name」';
  }

  @override
  String get kodiSyncTitle => '同步';

  @override
  String get kodiTargetCollectionSubtitle => '所有 Kodi 电影同步到此处';

  @override
  String get kodiTargetNotSelected => '未选择';

  @override
  String kodiTargetDeletedLabel(int id) {
    return '已删除（#$id）';
  }

  @override
  String get kodiEnableSync => '启用 Kodi 同步';

  @override
  String get kodiEnableSyncActiveSubtitle => 'Tonkatsu 运行时活跃';

  @override
  String get kodiEnableSyncDisabledSubtitle => '请先选择目标收藏';

  @override
  String get kodiSyncInterval => '同步间隔';

  @override
  String get kodiCreateSubCollections => '从 Kodi 套装创建子收藏';

  @override
  String get kodiCreateSubCollectionsSubtitle => '例如「哈利波特收藏（kodi）」';

  @override
  String get kodiImportRatings => '从 Kodi 导入评分';

  @override
  String get kodiImportRatingsSubtitle => '复制 Kodi 用户评分（1–10）';

  @override
  String get kodiCollectionLibraryName => 'Kodi 库';

  @override
  String kodiCollectionCreated(String name) {
    return '已创建「$name」';
  }

  @override
  String get kodiTargetDeletedSnack => '目标收藏已删除——同步已停止';

  @override
  String get kodiSyncStatus => '同步状态';

  @override
  String get kodiSyncRunning => '运行中';

  @override
  String get kodiSyncStopped => '已停止';

  @override
  String get kodiLastSyncNever => '从未';

  @override
  String get kodiClearLastSync => '清除上次同步时间戳';

  @override
  String get kodiClearLastSyncSubtitle => '下次同步将获取所有已看项目';

  @override
  String get kodiLastSyncCleared => '上次同步时间戳已清除';

  @override
  String kodiRequestLog(int count) {
    return '请求日志（$count）';
  }

  @override
  String get kodiCopyLog => '复制日志';

  @override
  String get kodiLogCopied => '日志已复制';

  @override
  String get kodiClearLog => '清除日志';

  @override
  String get kodiNoRequests => '暂无请求';

  @override
  String get kodiRawJsonRpc => '原始 JSON-RPC';

  @override
  String get kodiMethod => '方法';

  @override
  String get kodiParams => '参数（JSON）';

  @override
  String get kodiSend => '发送';

  @override
  String get kodiCopyToClipboard => '复制到剪贴板';

  @override
  String get kodiCopiedToClipboard => '已复制到剪贴板';

  @override
  String get kodiParamsNotObject => '错误：参数必须是 JSON 对象';

  @override
  String kodiJsonParseError(String message) {
    return 'JSON 解析错误：$message';
  }

  @override
  String kodiRawError(String message) {
    return '错误：$message';
  }

  @override
  String get settingsMalImport => 'MyAnimeList';

  @override
  String get settingsMalImportSubtitle => '从 XML 导出导入动漫/漫画列表';

  @override
  String get malImportTitle => 'MyAnimeList 导入';

  @override
  String get malImportSubtitle => '动漫和漫画将匹配到 AniList';

  @override
  String get malImportPickFiles => '添加 XML 文件';

  @override
  String get malImportFilesHint =>
      '从 myanimelist.net/panel.php?go=export 导出 XML';

  @override
  String get importAnimeList => '动漫列表';

  @override
  String get importMangaList => '漫画列表';

  @override
  String malImportEntriesCount(int count) {
    return '$count 个条目';
  }

  @override
  String get malImportReadingFiles => '正在读取文件...';

  @override
  String get malImportResolvingAnime => '正在 AniList 上解析动漫';

  @override
  String get malImportResolvingManga => '正在 AniList 上解析漫画';

  @override
  String malImportWishlisted(int count) {
    return '已将 $count 个加入愿望单';
  }

  @override
  String get malImportOverwriteExisting => '覆盖现有条目';

  @override
  String get malImportOverwriteExistingHint =>
      '关闭时，收藏中已有的项目将保留您的本地状态、评分、进度、日期和备注。新项目仍会被导入。';

  @override
  String malImportFailedLookup(int count) {
    return '跳过 $count 个（AniList 不可达）';
  }

  @override
  String malImportRateLimitWait(int seconds, int attempt, int max) {
    return 'AniList 速率限制已达到——$seconds秒后重试（第 $attempt/$max 次）';
  }

  @override
  String malImportInvalidFile(String error) {
    return '无法解析 XML：$error';
  }

  @override
  String malImportFilePicked(String kind, int count) {
    return '已选择：$kind（$count 个条目）';
  }

  @override
  String get settingsAniListImport => 'AniList';

  @override
  String get settingsAniListImportSubtitle => '通过公开用户名导入动漫/漫画列表';

  @override
  String get settingsHardcoverImportSubtitle => '通过用户名从 hardcover.app 导入书库';

  @override
  String get hardcoverImportTitle => 'Hardcover 导入';

  @override
  String get hardcoverImportSubtitle =>
      '从 hardcover.app 获取用户书库——他人仅公开部分，自己的账户则全部获取';

  @override
  String get hardcoverImportTokenMissing =>
      '未设置 Hardcover API 令牌。请在设置 → API 凭据中添加。';

  @override
  String get aniListImportTitle => 'AniList 导入';

  @override
  String get aniListImportSubtitle => '从 anilist.co 获取公开列表——无需登录';

  @override
  String get aniListImportUsername => 'AniList 用户名';

  @override
  String get aniListImportInclude => '导入内容';

  @override
  String get aniListImportModeOverwriteSubtitle => '从 AniList 更新进度、状态和日期';

  @override
  String aniListImportNewCollectionDefault(String username) {
    return 'AniList 导入 — $username';
  }

  @override
  String get aniListImportFetchingAnime => '正在获取动漫列表...';

  @override
  String get aniListImportFetchingManga => '正在获取漫画列表...';

  @override
  String aniListImportUserNotFound(String username) {
    return '未找到 AniList 用户「$username」';
  }

  @override
  String aniListImportPrivateProfile(String username) {
    return 'AniList 个人资料「$username」为私密';
  }

  @override
  String get aniListImportEmptyUsername => '请输入您的 AniList 用户名';

  @override
  String get aniListImportSelectAtLeastOne => '请选择要导入的动漫或漫画';

  @override
  String get settingsCustomCardsImport => '自定义卡片';

  @override
  String get settingsCustomCardsImportSubtitle => '从 JSON 或 CSV 文件导入卡片';

  @override
  String get customImportTitle => '导入自定义卡片';

  @override
  String get customImportDescription =>
      '加载由您自己的脚本或解析器生成的 JSON 或 CSV 文件——每行将成为一张自定义卡片。下载模板以查看所有支持的字段和值。';

  @override
  String get customImportSelectFile => '选择 JSON/CSV 文件';

  @override
  String get customImportCsvTemplate => 'CSV 模板';

  @override
  String get customImportJsonTemplate => 'JSON 模板';

  @override
  String get customImportTemplateSaved => '模板已保存';

  @override
  String get customImportPreviewButton => '预览并导入';

  @override
  String get customImportPreviewTitle => '导入预览';

  @override
  String customImportSummary(int valid, int errors, int duplicates) {
    return '已识别 $valid · 错误 $errors · 重复 $duplicates';
  }

  @override
  String get customImportSelectNone => '取消全选';

  @override
  String customImportSelectedCount(int selected, int total) {
    return '已选 $selected/$total';
  }

  @override
  String get customImportDuplicate => '重复——已在收藏中';

  @override
  String customImportRowLabel(int index) {
    return '第 $index 行';
  }

  @override
  String get customImportStart => '导入选中项';

  @override
  String get customImportImporting => '正在导入自定义卡片...';

  @override
  String get customImportErrorEmptyFile => '文件为空';

  @override
  String get customImportErrorInvalidJson => 'JSON 格式错误——无法解析文件';

  @override
  String get customImportErrorMissingColumns => 'CSV 必须包含「title」和「type」列';

  @override
  String get customImportIssueNotAnObject => '不是 JSON 对象';

  @override
  String get customImportIssueMissingTitle => '缺少「title」';

  @override
  String get customImportIssueMissingType => '缺少「type」';

  @override
  String customImportIssueUnknownType(String value) {
    return '未知类型：$value';
  }

  @override
  String customImportIssueInvalidNumber(String field, String value) {
    return '「$field」中的值无效：$value';
  }

  @override
  String customImportIssueUnknownStatus(String value) {
    return '未知状态：$value';
  }

  @override
  String customImportIssueUnknownFormat(String value) {
    return '未知格式：$value';
  }

  @override
  String get customImportIssueFormatNotApplicable => '「format」仅适用于漫画和动漫';

  @override
  String get customImportIssueInvalidCover => '「cover」必须是 http(s) 链接';

  @override
  String customImportIssueInvalidDate(String field, String value) {
    return '「$field」中的日期无效：$value（预期格式 YYYY-MM-DD）';
  }

  @override
  String customImportIssueInvalidBool(String value) {
    return '「favorite」必须是 true/false：$value';
  }

  @override
  String get moodGridCreate => '创建心情格';

  @override
  String get moodGridCreateTitle => '新建心情格';

  @override
  String get moodGridPresetAboutMe => '关于我：Tonkatsu Box';

  @override
  String get moodGridPresetAboutMeSubtitle => '1×5 — 最喜欢的游戏、电影、电视剧、动漫、漫画';

  @override
  String get moodGridPresetBlank => '空白';

  @override
  String get moodGridPresetBlankSubtitle => '您选择大小的空白格';

  @override
  String get moodGridRows => '行数';

  @override
  String get moodGridBadge => '心情格';

  @override
  String get moodGridDeleteTitle => '删除此格？';

  @override
  String get moodGridDeleteMessage => '此格将被移除。此操作无法撤销。';

  @override
  String get moodGridAddRow => '添加行';

  @override
  String get moodGridRemoveRow => '删除行';

  @override
  String get moodGridAddCol => '添加列';

  @override
  String get moodGridRemoveCol => '删除列';

  @override
  String get moodGridShrinkTitle => '缩小格子？';

  @override
  String get moodGridShrinkMessage => '超出新边界的单元格将被删除。';

  @override
  String get moodGridShrinkConfirm => '缩小';

  @override
  String get moodGridEditLabel => '编辑标签';

  @override
  String get moodGridLabelHint => '分类名称';

  @override
  String get moodGridPickItem => '选择项目';

  @override
  String get moodGridReplaceItem => '替换项目';

  @override
  String get moodGridClearItem => '清除项目';

  @override
  String get moodGridCaptionTemplate => '行标题';

  @override
  String get moodGridCaptionTemplateHint =>
      '应用于每个单元格的模板。可用占位符：name、year、genre、rating。';

  @override
  String get moodGridCellLabelTemplate => '单元格标题';

  @override
  String get moodGridCellSize => '大小';

  @override
  String get collection => '收藏';

  @override
  String get moodGridPickerAllCollections => '所有收藏';

  @override
  String get moodGridPickerSearchHint => '按名称搜索';

  @override
  String get moodGridPickerEmpty => '无可选内容';

  @override
  String get screenScraperSection => 'ScreenScraper API';

  @override
  String get screenScraperSourceDesc => '游戏元数据 + 媒体（封面、截图、美术）';

  @override
  String get screenScraperUserCredsHint => '用户凭证（ssid / sspassword）。配额按用户分配。';

  @override
  String get screenScraperSsidLabel => 'ssid';

  @override
  String get screenScraperSsidPlaceholder => '您的 ScreenScraper 登录名';

  @override
  String get screenScraperSspasswordLabel => 'sspassword';

  @override
  String get screenScraperSspasswordPlaceholder => '您的 ScreenScraper 密码';

  @override
  String get screenScraperCheckQuota => '检查配额';

  @override
  String get screenScraperRequestsToday => '今日请求数';

  @override
  String get screenScraperPerMinLimit => '每分钟限制';

  @override
  String get screenScraperParallelThreads => '并行线程';

  @override
  String get screenScraperAccountLevel => '账户等级';

  @override
  String get screenScraperGalleryTitle => 'ScreenScraper 媒体';

  @override
  String get screenScraperScreenshotsTitle => '截图';

  @override
  String get screenScraperLoading => '正在加载 ScreenScraper 媒体…';

  @override
  String screenScraperError(String message) {
    return 'ScreenScraper 错误：$message';
  }

  @override
  String get screenScraperMediaBox => '盒装';

  @override
  String get screenScraperMediaBoxBack => '盒装（背面）';

  @override
  String get screenScraperMediaBox3D => '3D 盒装';

  @override
  String get screenScraperMediaWheel => '标志轮';

  @override
  String get screenScraperMediaMarquee => '招牌';

  @override
  String get screenScraperMediaTitle => '标题图';

  @override
  String get screenScraperMediaScreenshot => '截图';

  @override
  String get screenScraperMediaFanart => '同人图';

  @override
  String get screenScraperMediaMix => '混合';

  @override
  String get genreCloudTitle => '个性化';

  @override
  String get genreCloudEmpty => '暂无类型';

  @override
  String get genreCloudEmptyHint => '添加带有类型的项目以构建词云';

  @override
  String get genreCloudExportImage => '保存为图片';

  @override
  String get genreCloudExportFailed => '无法保存图片';

  @override
  String get genreCloudResetView => '重置视图';

  @override
  String genreCloudHidden(int count) {
    return '$count 个已隐藏（未容纳下）';
  }

  @override
  String get facetPlatform => '平台';

  @override
  String get facetDecade => '年代';

  @override
  String get personalizationTabCloud => '类型词云';

  @override
  String get recommendationsEmpty => '暂无推荐';

  @override
  String get recommendationsEmptyHint => '完成并评分一些电影或节目以获取个性化推荐';

  @override
  String get recommendationsNoCandidates => '没有新内容可推荐';

  @override
  String get recommendationsNoCandidatesHint => '目前无法找到新内容推荐。请稍后重试';

  @override
  String get recommendationsNoApiKey => '需要 TMDB API 密钥';

  @override
  String get recommendationsNoApiKeyHint => '请在设置中添加您的 TMDB API 密钥以获取推荐';

  @override
  String get recommendationsBecauseLabel => '因为您喜欢';

  @override
  String recommendationsCount(int count) {
    return '$count 个推荐';
  }

  @override
  String get itemMarkLike => '喜欢';

  @override
  String get itemMarkNote => '备注';

  @override
  String get itemMarkNoteHint => '写备注…';

  @override
  String get itemMarkSectionTitle => '备注和喜欢';

  @override
  String get itemMarkAdd => '添加标记';

  @override
  String get itemMarkEmpty => '暂无标记';

  @override
  String get itemMarkNumber => '编号';

  @override
  String get itemMarkNumberHint => '例如 12';

  @override
  String get itemMarkNumberHelper => '保存必填';

  @override
  String get itemMarkCustomType => '自定义类型';

  @override
  String get itemMarkFilterLiked => '已喜欢';

  @override
  String get itemMarkFilterCommented => '有备注';

  @override
  String itemMarkUnitLabel(String type, int number) {
    return '$type $number';
  }

  @override
  String itemMarkEpisodeShort(int season, int episode) {
    return 'S$season·E$episode';
  }

  @override
  String get unitEpisode => '集';

  @override
  String get unitSeason => '季';

  @override
  String get unitChapter => '章';

  @override
  String get unitVolume => '卷';

  @override
  String get unitPage => '页';

  @override
  String get unitPart => '部分';

  @override
  String get unitTrack => '曲目';

  @override
  String get cardLinkCopy => '复制卡片链接';

  @override
  String get cardLinkCopied => '卡片链接已复制';

  @override
  String get cardLinkNotFound => '未找到卡片';

  @override
  String get cardLinkSearchTitle => '链接卡片';

  @override
  String get cardLinkSearchHint => '搜索卡片';

  @override
  String get shortcutsDialogTitle => '键盘快捷键';

  @override
  String get shortcutsGroupNavigation => '导航';

  @override
  String get shortcutSwitchTab => '切换标签页';

  @override
  String get shortcutNextTab => '下一个标签页';

  @override
  String get shortcutPreviousTab => '上一个标签页';

  @override
  String get shortcutThisHelp => '此帮助';

  @override
  String get shortcutCreateCollection => '创建收藏';

  @override
  String get shortcutImportCollection => '导入收藏';

  @override
  String get shortcutToggleView => '切换视图';

  @override
  String get shortcutDeleteCollection => '删除收藏';

  @override
  String get shortcutRenameCollection => '重命名收藏';

  @override
  String get shortcutAddItems => '添加项目';

  @override
  String get shortcutExportCollection => '导出收藏';

  @override
  String get shortcutImportIntoCollection => '导入到收藏';

  @override
  String get shortcutToggleBoard => '切换看板/画布';

  @override
  String get shortcutDeleteItem => '删除项目';

  @override
  String get shortcutMoveItem => '移动项目';

  @override
  String get shortcutsGroupItemDetail => '项目详情';

  @override
  String get shortcutLockCanvas => '锁定/解锁画布';

  @override
  String get shortcutMoveToCollection => '移动到收藏';

  @override
  String get shortcutSetRating => '设置评分';

  @override
  String get shortcutResetRating => '重置评分';

  @override
  String get shortcutsGroupTierLists => '等级列表';

  @override
  String get shortcutCreateTierList => '创建等级列表';

  @override
  String get shortcutOpenTierList => '打开等级列表';

  @override
  String get shortcutDeleteTierList => '删除等级列表';

  @override
  String get shortcutsGroupTierList => '等级列表';

  @override
  String get shortcutAddItem => '添加项目';

  @override
  String get shortcutToggleCompleted => '显示/隐藏已完成';

  @override
  String get shortcutClearCompleted => '清除已完成';

  @override
  String get shortcutFocusSearchField => '聚焦搜索框';

  @override
  String get shortcutClearOrBack => '清除/返回';

  @override
  String get shortcutRunSearch => '执行搜索';

  @override
  String get debugKeyEvents => '按键事件';

  @override
  String get settingsGamepadDebugSubtitle => '捕获手柄按键代码';

  @override
  String get statsTabTitle => '统计';

  @override
  String get statsPeriodAllTime => '全部时间';

  @override
  String statsLede(String items) {
    return '收藏中共有 $items 个条目';
  }

  @override
  String get statsMetricMoviesWatched => '已看电影';

  @override
  String get statsMetricMangaChapters => '漫画章节';

  @override
  String get statsMetricBookPages => '书籍页数';

  @override
  String get statsMetricTracks => '已听曲目';

  @override
  String get statsMetricEpisodes => '集';

  @override
  String get statsMetricHours => '观看与游玩';

  @override
  String get statsMetricAvgRating => '平均评分';

  @override
  String get statsMetricReplays => '重刷';

  @override
  String get statsMetricLikedUnits => '点赞的剧集';

  @override
  String statsHoursShort(String hours) {
    return '$hours 小时';
  }

  @override
  String statsHoursBreakdown(int manual, int tracker, int estimated) {
    return '时长：手动 $manual 小时 · 追踪器 $tracker 小时 · 估算 $estimated 小时';
  }

  @override
  String get statsMonthsTitle => '逐月回顾';

  @override
  String get statsMonthsTitleAllTime => '今年逐月';

  @override
  String get statsMonthsHint => '封面为当月评分最高的作品';

  @override
  String get statsPeakLabel => '峰值';

  @override
  String statsMonthCounts(int items, int episodes) {
    return '新增 $items · $episodes 集';
  }

  @override
  String get statsVersusTitle => '最佳与最差';

  @override
  String get statsVersusHint => '按你自己的评分';

  @override
  String get statsBest => '最佳';

  @override
  String get statsWorst => '最差';

  @override
  String statsPlatformsSummary(String hours, int games) {
    return '$hours 小时 · $games 款游戏';
  }

  @override
  String get statsPlatformNone => '无平台';

  @override
  String statsPlatformsShowAll(int count) {
    return '显示全部（$count）';
  }

  @override
  String get statsPlatformsCollapse => '收起';

  @override
  String get statsHoursUnit => '小时';

  @override
  String get statsTypesTitle => '按媒体类型';

  @override
  String get statsTypesHint => '每种媒体类型的实时状态分布';

  @override
  String statsCompletedPercent(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get statsPlatformMostPlayed => '游玩最多';

  @override
  String get statsFormatsHint => '形式来自数据源';

  @override
  String get statsSubgenresTitle => '子类型与标签';

  @override
  String get statsSubgenresHint => '数据源标签按类型展示';

  @override
  String get statsCrowdTitle => '我 vs 大众';

  @override
  String get statsCrowdHint => '我的评分与来源差异最大的作品';

  @override
  String get statsCrowdHigher => '我评得更高';

  @override
  String get statsCrowdLower => '我评得更低';

  @override
  String get statsCrowdMyRating => '我的评分';

  @override
  String get statsCrowdSource => '来源';

  @override
  String get statsTopTitle => '评分最高';

  @override
  String statsTopHint(int count) {
    return '前 $count 名';
  }

  @override
  String get statsEmptyTitle => '暂无统计';

  @override
  String get statsEmptyBody => '向媒体库添加条目后，这里会显示数据。';

  @override
  String get statsExportTitle => '导出分享卡片';

  @override
  String get statsExportFailed => '无法保存图片';

  @override
  String statsShareTitleYear(int year) {
    return '我的 $year';
  }

  @override
  String get statsShareTitleAllTime => '我的媒体库';

  @override
  String statsShareLede(String items, String completed, String rating) {
    return '$items 个条目 · 已完成 $completed · 平均 $rating';
  }

  @override
  String statsShareBest(String title, String rating) {
    return '$title · $rating — 本期最佳';
  }

  @override
  String get simklImportTitle => 'Simkl 导入';

  @override
  String get settingsSimklImportSubtitle => '从 Simkl 账户导入电影、剧集和动画';

  @override
  String get simklImportSubtitle => '使用短代码连接 Simkl 账户——电影、剧集和动画一次导入，并附带剧集观看记录';

  @override
  String get simklClientIdLabel => 'Simkl 应用密钥（client_id）';

  @override
  String get simklGetClientId => '在 simkl.com 获取 client_id';

  @override
  String get simklRememberClientId => '记住应用密钥';

  @override
  String get simklGetPin => '获取代码';

  @override
  String get simklGetNewPin => '获取新代码';

  @override
  String get simklPinPrompt => '在 simkl.com/pin 输入此代码：';

  @override
  String get simklPinCopied => '代码已复制';

  @override
  String get simklOpenPinPage => '打开 simkl.com/pin';

  @override
  String get simklWaitingConfirmation => '等待确认…';

  @override
  String get simklPinExpired => '代码已过期。';

  @override
  String simklConnectedAs(String name) {
    return '已连接账户：$name';
  }

  @override
  String get simklCheckingAccount => '正在检查账户…';

  @override
  String get simklRememberToken => '在此设备上保持连接';

  @override
  String get simklRememberTokenSubtitle => '访问令牌将保存在设置中；取消勾选则下次需要重新输入代码';

  @override
  String get simklDisconnect => '断开连接';

  @override
  String get simklImportFetching => '正在获取 Simkl 媒体库…';

  @override
  String get simklImportFetchingDetails => '正在获取详情…';

  @override
  String get simklImportWatchHistory => '正在恢复观看记录…';

  @override
  String simklImportNewCollectionDefault(String name) {
    return 'Simkl：$name';
  }

  @override
  String get simklImportModeOverwriteSubtitle => '更新现有条目的状态、评分和备注';

  @override
  String get simklClientIdRequired => '导入需要 Simkl 应用密钥——请输入你的 client_id';

  @override
  String simklImportRateLimitWait(int seconds, int attempt, int max) {
    return '已达请求上限——$seconds 秒后重试（第 $attempt/$max 次）';
  }

  @override
  String get searchSourcePodcasts => '播客';

  @override
  String get searchHintPodcasts => '搜索播客...';

  @override
  String get podcastSheetEpisodes => '单集';

  @override
  String get podcastSheetNoEpisodes => '单集列表不可用';

  @override
  String podcastEpisodesCount(int count) {
    return '$count 集';
  }

  @override
  String get podcastDiscoverTrending => '热门播客';

  @override
  String get credentialsPodcastIndexSection => 'Podcast Index API';

  @override
  String get credentialsEnterPodcastIndexKey => '输入你的 Podcast Index API 密钥';

  @override
  String get credentialsEnterPodcastIndexSecret => '输入你的 Podcast Index API 密文';

  @override
  String get credentialsPodcastIndexKeyValid => 'Podcast Index 密钥有效';

  @override
  String get credentialsPodcastIndexKeyInvalid =>
      'Podcast Index 拒绝了密钥。请检查密钥对和系统时间';

  @override
  String get welcomeApiPodcastIndexDesc =>
      '播客搜索与单集追踪。使用 api.podcastindex.org 的免费密钥对。';

  @override
  String get welcomeSourceDescMusicBrainz => '开放的音乐百科：专辑、艺术家与版本。无需密钥。';

  @override
  String get welcomeSourceDescPodcastIndex => '开放的播客目录，支持按单集追踪。免费密钥对。';

  @override
  String get creditsPodcastIndexAttribution => '播客数据来自 Podcast Index。';

  @override
  String get credentialsApiSecret => 'API 密文';

  @override
  String get markAllListened => '全部标记为已收听';
}

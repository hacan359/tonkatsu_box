// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => 'Inicio';

  @override
  String get navCollections => 'Colecciones';

  @override
  String get navWishlist => 'Deseados';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navReleases => 'Lanzamientos';

  @override
  String get releasesEmpty => 'Aún no hay series seguidas';

  @override
  String get releasesEmptyHint =>
      'Toca la campana en una serie o anime para seguir los nuevos episodios.';

  @override
  String get releasesTrackShow => 'Seguir estrenos';

  @override
  String get releasesUntrackShow => 'Dejar de seguir';

  @override
  String get releasesViewDay => 'Día';

  @override
  String get releasesViewWeek => 'Semana';

  @override
  String get releasesViewMonth => 'Mes';

  @override
  String get releasesTabCalendar => 'Calendario';

  @override
  String get releasesTabAll => 'Todos los estrenos';

  @override
  String get releasesToday => 'Hoy';

  @override
  String get refresh => 'Actualizar';

  @override
  String get releasesNoEpisodes => 'Sin episodios';

  @override
  String releasesEpisode(int season, int episode) {
    return 'Temporada $season · Episodio $episode';
  }

  @override
  String get calendarAdd => 'Añadir al calendario';

  @override
  String get calendarRemove => 'Quitar del calendario';

  @override
  String get date => 'Fecha';

  @override
  String get calendarRepeat => 'Repetir';

  @override
  String get recurrenceOnce => 'Una vez';

  @override
  String get recurrenceWeekly => 'Cada semana';

  @override
  String get recurrenceMonthly => 'Cada mes';

  @override
  String get statusNotStarted => 'Sin empezar';

  @override
  String get statusPlaying => 'Jugando';

  @override
  String get statusWatching => 'Viendo';

  @override
  String get statusListening => 'Escuchando';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusDropped => 'Abandonado';

  @override
  String get statusPlanned => 'Planeado';

  @override
  String get statusReplay => 'Repitiendo';

  @override
  String get statusIgnored => 'Ignorado';

  @override
  String statusFilterSelected(int count) {
    return 'Estados: $count';
  }

  @override
  String get rewatchCountEdit => 'Número de repeticiones';

  @override
  String get rewatchCountHint => 'Vacío = sin seguimiento';

  @override
  String get statusReplaying => 'Rejugando';

  @override
  String get statusRewatching => 'Volviendo a ver';

  @override
  String get statusRereading => 'Releyendo';

  @override
  String get statusRelistening => 'Reescuchando';

  @override
  String get all => 'Todo';

  @override
  String get mediaTypeGame => 'Videojuego';

  @override
  String get mediaTypeMovie => 'Película';

  @override
  String get mediaTypeTvShow => 'Serie';

  @override
  String get mediaTypeAnimation => 'Animación';

  @override
  String get mediaTypeVisualNovel => 'Novela Visual';

  @override
  String get mediaTypeManga => 'Manga';

  @override
  String get mediaTypeAnime => 'Anime';

  @override
  String get mediaTypeBook => 'Libro';

  @override
  String get mediaTypeAudio => 'Audio';

  @override
  String get mediaTypeCustom => 'Personalizado';

  @override
  String get sortManualDisplay => 'Manual';

  @override
  String get sortManualDesc => 'Orden personalizado';

  @override
  String get sortDateDisplay => 'Fecha de adición';

  @override
  String get sortDateDesc => 'Más recientes primero';

  @override
  String get status => 'Estado';

  @override
  String get movieStatusReleased => 'Estrenada';

  @override
  String get movieStatusCompleted => 'Completada';

  @override
  String get movieStatusPostProduction => 'Rodaje / posproducción';

  @override
  String get movieStatusPreProduction => 'Preproducción';

  @override
  String get movieStatusAnnounced => 'Anunciada';

  @override
  String get sortStatusDesc => 'Activos primero';

  @override
  String get name => 'Nombre';

  @override
  String get sortNameShort => 'A-Z';

  @override
  String get rating => 'Valoración';

  @override
  String get sortRatingDesc => 'Mayor primero';

  @override
  String get sortFavoriteDesc => 'Favoritos primero';

  @override
  String get sortExternalRatingDisplay => 'Valoración externa';

  @override
  String get sortExternalRatingShort => 'IGDB/TMDB';

  @override
  String get sortLastActivityDisplay => 'Última actividad';

  @override
  String get sortLastActivityShort => 'Actividad';

  @override
  String get sortLastActivityDesc => 'Recientes primero';

  @override
  String get sortStartDateDisplay => 'Fecha de inicio';

  @override
  String get sortStartDateShort => 'Empezado';

  @override
  String get sortCompletionDateDisplay => 'Fecha de finalización';

  @override
  String get sortCompletionDateShort => 'Terminado';

  @override
  String get sortDateOldest => 'Más antiguos primero';

  @override
  String get sortStatusFinished => 'Terminados primero';

  @override
  String get sortRatingLowest => 'Menor primero';

  @override
  String get sortFavoriteLast => 'Favoritos al final';

  @override
  String get searchSortRelevanceShort => 'Rel.';

  @override
  String get searchSortRatingShort => 'Val';

  @override
  String get searchSortRatingDisplay => 'Valoración';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Aceptar';

  @override
  String get restore => 'Restaurar';

  @override
  String get create => 'Crear';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Hecho';

  @override
  String get clear => 'Limpiar';

  @override
  String get reset => 'Restablecer';

  @override
  String get search => 'Buscar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Quitar';

  @override
  String get moveToTop => 'Mover al principio';

  @override
  String get moveToBottom => 'Mover al final';

  @override
  String get favorite => 'Favorito';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String bulkSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get bulkClearSelection => 'Quitar selección';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get bulkMove => 'Mover seleccionados a colección';

  @override
  String get bulkCopy => 'Copiar selección a una colección';

  @override
  String get bulkChangeStatus => 'Cambiar estado';

  @override
  String bulkRemoveConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '¿Quitar $_temp0 de esta colección?';
  }

  @override
  String bulkResult(int done, int skipped) {
    return 'Hecho: $done • Duplicados: $skipped';
  }

  @override
  String bulkRemoved(int count) {
    return 'Quitados: $count';
  }

  @override
  String bulkStatusUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return 'Estado actualizado para $_temp0';
  }

  @override
  String get bulkAddTags => 'Añadir etiquetas';

  @override
  String get bulkRemoveTags => 'Quitar etiquetas';

  @override
  String bulkAddTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return 'Añadir etiquetas a $_temp0';
  }

  @override
  String bulkRemoveTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return 'Quitar etiquetas de $_temp0';
  }

  @override
  String bulkTagsAdded(int count) {
    return 'Etiquetas añadidas: $count';
  }

  @override
  String bulkTagsRemoved(int count) {
    return 'Etiquetas quitadas: $count';
  }

  @override
  String get bulkTagsUnchanged => 'Nada que cambiar';

  @override
  String get bulkExportPngTitle => 'Exportar como PNG';

  @override
  String get columnsCount => 'Columnas';

  @override
  String bulkExportPngItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String bulkExportPngItemsCountPreview(int total, int preview) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total elementos',
      one: '1 elemento',
    );
    return '$_temp0 ($preview en la vista previa)';
  }

  @override
  String bulkExportPngPreparing(int done, int total) {
    return 'Preparando portadas: $done / $total';
  }

  @override
  String get bulkExportPngSave => 'Guardar PNG';

  @override
  String get imageSaved => 'Imagen guardada';

  @override
  String get bulkExportPngFailed => 'No se pudo guardar la imagen';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Omitir';

  @override
  String get update => 'Actualizar';

  @override
  String get test => 'Probar';

  @override
  String get close => 'Cerrar';

  @override
  String get keep => 'Mantener';

  @override
  String get change => 'Cambiar';

  @override
  String get settingsProfile => 'Perfil de autor';

  @override
  String get settingsProfileSubtitle => 'Nombre del autor para tus colecciones';

  @override
  String get settingsAuthorName => 'Nombre del autor';

  @override
  String get settingsCredentialsSubtitle =>
      'Claves de API (IGDB, SteamGridDB, TMDB)';

  @override
  String get settingsCacheSubtitle =>
      'Modo sin conexión y almacenamiento de portadas';

  @override
  String get settingsDatabaseSubtitle => 'Exportar, importar, restablecer';

  @override
  String get settingsTraktImportSubtitle =>
      'Historial, valoraciones, lista de seguimiento';

  @override
  String get settingsKinoriumImport => 'Importar de Kinorium';

  @override
  String get settingsKinoriumImportSubtitle =>
      'Películas y series desde un CSV exportado';

  @override
  String get settingsDebug => 'Depuración';

  @override
  String get settingsDebugSubtitle => 'Herramientas de desarrollo';

  @override
  String get settingsDebugSubtitleNoKey =>
      'Configura primero la clave de SteamGridDB para algunas herramientas';

  @override
  String get settingsLaboratory => 'Laboratorio';

  @override
  String get settingsLaboratoryCardDesigns => 'Diseños del banner de tarjetas';

  @override
  String get settingsLaboratoryCardDesignsSubtitle =>
      'Diseños experimentales para las tarjetas de póster';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsWelcomeGuide => 'Guía de bienvenida';

  @override
  String get settingsWelcomeGuideSubtitle => 'Primeros pasos con Tonkatsu Box';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsCreditsLicenses => 'Créditos y licencias';

  @override
  String get settingsChangelog => 'Novedades';

  @override
  String get settingsChangelogEmpty => 'No hay notas de la versión';

  @override
  String get settingsCreditsLicensesSubtitle =>
      'TMDB, IGDB, SteamGridDB, licencias de código abierto';

  @override
  String get settingsError => 'Error';

  @override
  String get settingsAppLanguage => 'Idioma de la aplicación';

  @override
  String get settingsConnections => 'Conexiones';

  @override
  String get settingsApiKeys => 'Claves API';

  @override
  String get credentialsServerManagedTitle =>
      'Las claves se guardan en el servidor';

  @override
  String get credentialsServerManagedBody =>
      'Lo que introduzcas abajo se guarda en el servidor selfhost, no en este navegador: desde allí se hacen las peticiones a las API. También puedes cargarlas desde un archivo de configuración exportado en el escritorio.';

  @override
  String get credentialsUploadFromConfig =>
      'Cargar claves desde un archivo de configuración';

  @override
  String get credentialsUploadNoKeys => 'Ese archivo no contiene claves de API';

  @override
  String credentialsUploadDone(int count) {
    return '$count claves guardadas en el servidor';
  }

  @override
  String settingsApiKeysValue(int active, int total) {
    return '$active/$total';
  }

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAppearanceSubtitle => 'Idioma, visualización y contenido';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSubtitle => 'Tema de color de la aplicación';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSakura => 'Sakura';

  @override
  String get settingsAppLanguageSubtitle => 'Idioma de la interfaz';

  @override
  String get settingsContentLanguageSubtitle =>
      'Por ahora solo TMDB (películas y series)';

  @override
  String get settingsDataSources => 'Fuentes de datos';

  @override
  String get settingsDataSourcesSubtitle => 'IGDB, TMDB, SteamGridDB';

  @override
  String get settingsApiKeysSubtitle =>
      'Configura las conexiones a las bases de datos';

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String get settingsStorageSubtitle => 'Caché de imágenes y base de datos';

  @override
  String get settingsBackup => 'Copia de seguridad';

  @override
  String get settingsBackupSubtitle =>
      'Copia y restauración completa de los datos';

  @override
  String get settingsBackupAll => 'Copia de todos los datos';

  @override
  String get settingsBackupAllSubtitle =>
      'Todas las colecciones, la lista de deseos y los ajustes';

  @override
  String get settingsRestoreBackup => 'Restaurar desde copia';

  @override
  String get settingsRestoreBackupSubtitle =>
      'Importar archivo de copia de seguridad';

  @override
  String backupSuccess(int collections, int items) {
    return 'Copia guardada: $collections colecciones, $items elementos';
  }

  @override
  String get restoreConfirmTitle => '¿Restaurar la copia de seguridad?';

  @override
  String restoreConfirmBody(int collections, int items, int wishlist) {
    return '$collections colecciones, $items elementos, $wishlist entradas en la lista de deseos';
  }

  @override
  String get restoreConfirmHint =>
      'Las colecciones existentes no se verán afectadas';

  @override
  String get restoreSettings => 'Restaurar ajustes';

  @override
  String get restoreWishlist => 'Restaurar lista de deseos';

  @override
  String restoreSuccess(int collections, int items) {
    return 'Restauradas $collections colecciones, $items elementos';
  }

  @override
  String get restoreInvalidArchive => 'Archivo de copia de seguridad no válido';

  @override
  String get restoreProgressTitle => 'Restaurando la copia de seguridad';

  @override
  String get restoreProgressWarning =>
      'No cierres la aplicación. Puede tardar varios minutos con copias grandes.';

  @override
  String get restoreStageReading => 'Leyendo el archivo…';

  @override
  String restoreStageCollections(int current, int total) {
    return 'Restaurando colecciones… ($current/$total)';
  }

  @override
  String get restoreStageWishlist => 'Restaurando la lista de deseos…';

  @override
  String get restoreStageSettings => 'Restaurando ajustes…';

  @override
  String get restoreStageFinalizing => 'Terminando…';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportSubtitle =>
      'Importa colecciones desde servicios externos';

  @override
  String get settingsContentLanguage => 'Idioma del contenido';

  @override
  String get settingsData => 'Datos';

  @override
  String settingsCacheValue(String size) {
    return '$size';
  }

  @override
  String get credentialsTitle => 'Credenciales';

  @override
  String get credentialsWelcome => '¡Te damos la bienvenida a Tonkatsu Box!';

  @override
  String get credentialsWelcomeHint =>
      'Para empezar, configura tus credenciales de la API de IGDB. Obtén el Client ID y el Client Secret en la consola de desarrollador de Twitch.';

  @override
  String get credentialsCopyTwitchUrl => 'Copiar URL de la consola de Twitch';

  @override
  String credentialsUrlCopied(String url) {
    return 'URL copiada: $url';
  }

  @override
  String get credentialsIgdbSection => 'Credenciales de la API de IGDB';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Introduce tu Client ID de Twitch';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint =>
      'Introduce tu Client Secret de Twitch';

  @override
  String get credentialsConnectionStatus => 'Estado de la conexión';

  @override
  String get credentialsPlatformsSynced => 'Plataformas sincronizadas';

  @override
  String get credentialsPlatformsAvailable => 'Plataformas disponibles';

  @override
  String get credentialsLastSync => 'Última sincronización';

  @override
  String get credentialsVerifyConnection => 'Verificar conexión';

  @override
  String get credentialsRefreshPlatforms => 'Actualizar plataformas';

  @override
  String get credentialsSteamGridDbSection => 'API de SteamGridDB';

  @override
  String get credentialsApiKey => 'Clave API';

  @override
  String get credentialsUsingBuiltInKey => 'Usando la clave integrada';

  @override
  String get credentialsEnterSteamGridDbKey =>
      'Introduce tu clave API de SteamGridDB';

  @override
  String get credentialsTmdbSection => 'API de TMDB (películas y series)';

  @override
  String get credentialsTvdbSection => 'API de TheTVDB (películas y series)';

  @override
  String get credentialsEnterTmdbKey => 'Introduce tu clave API de TMDB (v3)';

  @override
  String get credentialsEnterTvdbKey =>
      'Introduce tu clave de API de TheTVDB (v4)';

  @override
  String get credentialsComicVineSection => 'API de ComicVine (cómics)';

  @override
  String get credentialsEnterComicVineKey =>
      'Introduce tu clave API de ComicVine';

  @override
  String get credentialsGoogleBooksSection => 'API de Google Books (libros)';

  @override
  String get credentialsEnterGoogleBooksKey =>
      'Introduce tu clave API de Google Books (opcional)';

  @override
  String get credentialsHardcoverSection => 'API de Hardcover (libros)';

  @override
  String get credentialsEnterHardcoverKey =>
      'Introduce tu token de la API de Hardcover';

  @override
  String get credentialsOwnKeyHint =>
      'Para mejores límites de uso recomendamos usar tu propia clave API.';

  @override
  String get credentialsConnected => 'Conectado';

  @override
  String get credentialsConnectionError => 'Error de conexión';

  @override
  String get credentialsChecking => 'Comprobando...';

  @override
  String get credentialsNotConnected => 'No conectado';

  @override
  String get credentialsEnterBoth =>
      'Introduce el Client ID y el Client Secret';

  @override
  String get credentialsConnectedSynced =>
      '¡Conectado y plataformas sincronizadas!';

  @override
  String get credentialsConnectedSyncFailed =>
      'Conectado, pero falló la sincronización de plataformas';

  @override
  String get credentialsPlatformsSyncedOk =>
      '¡Plataformas sincronizadas correctamente!';

  @override
  String get credentialsDownloadingLogos =>
      'Descargando logotipos de plataformas...';

  @override
  String credentialsDownloadedLogos(int count) {
    return 'Descargados $count logotipos';
  }

  @override
  String get credentialsFailedDownloadLogos =>
      'No se pudieron descargar los logotipos';

  @override
  String get credentialsApiKeySaved => 'Clave API guardada';

  @override
  String get credentialsNoApiKey => 'Sin clave API';

  @override
  String get credentialsResetToBuiltIn => 'Volver a la clave integrada';

  @override
  String get credentialsSteamGridDbKeyValid =>
      'La clave API de SteamGridDB es válida';

  @override
  String get credentialsSteamGridDbKeyInvalid =>
      'La clave API de SteamGridDB no es válida';

  @override
  String get credentialsTmdbKeyValid => 'La clave API de TMDB es válida';

  @override
  String get credentialsTmdbKeyInvalid => 'La clave API de TMDB no es válida';

  @override
  String get credentialsTvdbKeyValid => 'La clave de API de TheTVDB es válida';

  @override
  String get credentialsTvdbKeyInvalid =>
      'La clave de API de TheTVDB no es válida';

  @override
  String get credentialsComicVineKeyValid =>
      'La clave API de ComicVine es válida';

  @override
  String get credentialsComicVineKeyInvalid =>
      'La clave API de ComicVine no es válida';

  @override
  String get credentialsGoogleBooksKeyValid =>
      'La clave API de Google Books es válida';

  @override
  String get credentialsGoogleBooksKeyInvalid =>
      'La clave API de Google Books no es válida';

  @override
  String get credentialsHardcoverKeyValid =>
      'El token de la API de Hardcover es válido';

  @override
  String get credentialsHardcoverKeyInvalid =>
      'El token de la API de Hardcover no es válido o ha caducado';

  @override
  String get credentialsEnterSteamGridDbKeyError =>
      'Introduce una clave API de SteamGridDB';

  @override
  String get credentialsEnterTmdbKeyError => 'Introduce una clave API de TMDB';

  @override
  String get credentialsTmdbKeySaved => 'Clave API de TMDB guardada';

  @override
  String timeAgo(int value, String unit) {
    return 'hace $value $unit';
  }

  @override
  String timeUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días',
      one: 'día',
    );
    return '$_temp0';
  }

  @override
  String timeUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'horas',
      one: 'hora',
    );
    return '$_temp0';
  }

  @override
  String timeUnitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutos',
      one: 'minuto',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'Ahora mismo';

  @override
  String get cacheTitle => 'Caché';

  @override
  String get cacheImageCache => 'Caché de imágenes';

  @override
  String get cacheOfflineMode => 'Modo sin conexión';

  @override
  String get cacheOfflineModeSubtitle =>
      'Guarda las imágenes localmente para usarlas sin conexión';

  @override
  String get cacheCacheFolder => 'Carpeta de caché';

  @override
  String get cacheSelectFolder => 'Seleccionar carpeta';

  @override
  String get cacheCacheSize => 'Tamaño de la caché';

  @override
  String get cacheClearCache => 'Eliminar imágenes sin uso';

  @override
  String get cacheClearCacheTitle => '¿Eliminar las imágenes sin uso?';

  @override
  String get cacheClearCacheMessage =>
      'Elimina las portadas descargadas de medios que ya no están en ninguna colección. Tus portadas personalizadas y las imágenes del tablero se conservan.';

  @override
  String get cacheFolderUpdated => 'Carpeta de caché actualizada';

  @override
  String cacheOrphansRemoved(int count) {
    return 'Imágenes sin uso eliminadas: $count';
  }

  @override
  String get cacheSelectFolderDialog =>
      'Selecciona la carpeta de caché para las imágenes';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count archivos, $size';
  }

  @override
  String get databaseTitle => 'Base de datos';

  @override
  String get databaseConfiguration => 'Configuración';

  @override
  String get databaseConfigSubtitle =>
      'Exporta o importa tus claves API y ajustes.';

  @override
  String get databaseExportConfig => 'Exportar configuración';

  @override
  String get databaseImportConfig => 'Importar configuración';

  @override
  String get databaseDangerZone => 'Zona de peligro';

  @override
  String get databaseDangerZoneMessage =>
      'Borra todas las colecciones, juegos, películas, series y datos del tablero. Los ajustes y las claves API se conservarán.';

  @override
  String get databaseResetDatabase => 'Restablecer base de datos';

  @override
  String get databaseResetTitle => '¿Restablecer la base de datos?';

  @override
  String get databaseResetMessage =>
      'Esto eliminará permanentemente todas tus colecciones, juegos, películas, series, progreso de episodios y datos del tablero.\n\nTus claves API y ajustes se conservarán.\n\nEsta acción no se puede deshacer.';

  @override
  String databaseConfigExported(String path) {
    return 'Configuración exportada a $path';
  }

  @override
  String get databaseConfigImported => 'Configuración importada correctamente';

  @override
  String get databaseReset => 'La base de datos se ha restablecido';

  @override
  String get storageLocationTitle => 'Ubicación de los datos';

  @override
  String get storageLocationSubtitle =>
      'Carpeta que almacena la base de datos y los perfiles. Evita carpetas que un servicio en la nube sincroniza en vivo (OneDrive, Syncthing): la base de datos puede corromperse a mitad de escritura. Para mover datos entre dispositivos, usa la exportación.';

  @override
  String get storageLocationDangerWarning =>
      'Atención: cambiar la carpeta de datos puede provocar pérdida de datos. Lo haces bajo tu propia responsabilidad.';

  @override
  String get storageLocationFolder => 'Carpeta de datos';

  @override
  String get storageLocationFallbackWarning =>
      'La carpeta seleccionada no está disponible; se usa la predeterminada';

  @override
  String get storageLocationChange => 'Cambiar carpeta';

  @override
  String get storageLocationReset => 'Volver a la predeterminada';

  @override
  String get storageLocationSelectDialog => 'Selecciona la carpeta de datos';

  @override
  String storageLocationNotWritable(String path) {
    return 'Sin acceso de escritura: $path';
  }

  @override
  String get storageLocationPermissionTitle =>
      'Se necesita acceso al almacenamiento';

  @override
  String get storageLocationPermissionMessage =>
      'Android requiere el permiso \"Acceso a todos los archivos\" para usar una carpeta de datos personalizada. En la lista que se abre, busca Tonkatsu Box, activa el acceso y vuelve a elegir la carpeta.';

  @override
  String get storageLocationLegacyPermissionMessage =>
      'Una carpeta de datos personalizada necesita el permiso de almacenamiento. Actívalo en los ajustes de la aplicación y vuelve a elegir la carpeta.';

  @override
  String get storageLocationOpenSettings => 'Abrir ajustes';

  @override
  String get storageLocationDbTooNew =>
      'La base de datos de esta carpeta fue creada por una versión más reciente de la aplicación. Actualiza primero la aplicación en este dispositivo.';

  @override
  String get storageLocationDbCorrupted =>
      'La base de datos de esta carpeta está corrupta o incompleta. Si una herramienta de sincronización todavía la está copiando, inténtalo más tarde.';

  @override
  String get storageLocationUseExistingTitle =>
      'Se encontraron datos existentes';

  @override
  String get storageLocationUseExistingMessage =>
      'La carpeta seleccionada ya contiene una base de datos. La aplicación usará esos datos tras reiniciar.';

  @override
  String get storageLocationUseExistingConfirm => 'Usarla';

  @override
  String get storageLocationCopyTitle => '¿Copiar los datos actuales?';

  @override
  String get storageLocationCopyMessage =>
      'La carpeta seleccionada está vacía. Tus colecciones se copiarán allí; las imágenes guardadas se descargarán de nuevo cuando haga falta. Los datos de la carpeta anterior quedan intactos.';

  @override
  String get copy => 'Copiar';

  @override
  String get storageLocationCopyImages => 'Copiar también la caché de imágenes';

  @override
  String get storageLocationCopyImagesHint =>
      'Banners y portadas guardadas: ocupa más, pero la nueva carpeta funciona sin conexión y sin volver a descargar';

  @override
  String get storageLocationCopyError =>
      'No se pudieron copiar los datos a la carpeta seleccionada';

  @override
  String get storageLocationResetTitle => '¿Restablecer la carpeta de datos?';

  @override
  String get storageLocationResetMessage =>
      'La aplicación volverá a la carpeta de datos predeterminada tras reiniciar. Los datos de la carpeta personalizada quedan intactos.';

  @override
  String get storageLocationRestartTitle => 'Reinicio necesario';

  @override
  String get storageLocationRestartMessage =>
      'La nueva carpeta de datos se usará tras reiniciar. ¿Reiniciar ahora?';

  @override
  String get storageLocationRestartNow => 'Reiniciar';

  @override
  String get storageLocationRestartLater =>
      'El cambio se aplicará tras reiniciar';

  @override
  String get backupRestoreTile => 'Restaurar la base de datos anterior';

  @override
  String get backupNone => 'Aún no hay copia';

  @override
  String get backupRestoreConfirmTitle =>
      '¿Restaurar la base de datos anterior?';

  @override
  String backupRestoreConfirmMessage(String date) {
    return 'Los datos actuales se sustituirán por la copia del $date. Los datos sustituidos pasan a ser la nueva copia, así que restaurar de nuevo deshace este cambio.';
  }

  @override
  String get backupRestored => 'Base de datos restaurada';

  @override
  String get backupRestoreError => 'No se pudo restaurar la copia';

  @override
  String get backupRestartMessage =>
      'Los datos restaurados se usarán tras reiniciar. ¿Reiniciar ahora?';

  @override
  String get lanSyncTitle => 'Sincronización en red';

  @override
  String get lanSyncOpenTile => 'Dispositivos cercanos';

  @override
  String get lanSyncTileSubtitle =>
      'Transfiere datos directamente entre dispositivos en la misma red Wi-Fi';

  @override
  String lanSyncVisibleAs(String name) {
    return 'Este dispositivo es visible como $name';
  }

  @override
  String get lanSyncNoDevices =>
      'No se encontraron dispositivos. Abre esta pantalla en ambos dispositivos conectados a la misma red Wi-Fi. El aislamiento del punto de acceso y las VPN bloquean la detección.';

  @override
  String get lanSyncPull => 'Toca para obtener sus datos';

  @override
  String get lanSyncReceiveTitle => '¿Sustituir los datos?';

  @override
  String lanSyncReceiveMessage(
    String device,
    String date,
    int collections,
    int items,
  ) {
    return 'Datos de $device, $date: $collections colecciones, $items elementos.\n\nLos datos actuales serán SUSTITUIDOS. Una copia de seguridad queda junto a la base de datos.';
  }

  @override
  String get lanSyncReplace => 'Sustituir';

  @override
  String lanSyncWaiting(String name) {
    return 'Confirma la solicitud en $name...';
  }

  @override
  String get lanSyncIncomingTitle => 'Solicitud de datos';

  @override
  String lanSyncIncomingMessage(String name) {
    return '$name quiere obtener una copia de tus datos. ¿Permitir?';
  }

  @override
  String get lanSyncAllow => 'Permitir';

  @override
  String get lanSyncDenied => 'El otro dispositivo rechazó la solicitud';

  @override
  String get lanSyncManifestError => 'El dispositivo no respondió';

  @override
  String get lanSyncStartError =>
      'No se pudo iniciar el uso compartido en red. Comprueba la conexión de red y vuelve a abrir esta pantalla.';

  @override
  String get lanSyncReceiveError => 'No se pudieron obtener los datos';

  @override
  String get lanSyncTooNew =>
      'Los datos de ese dispositivo fueron creados por una versión más reciente de la aplicación. Actualiza primero la aplicación en este dispositivo.';

  @override
  String get lanSyncCorrupted =>
      'La transferencia llegó dañada. Inténtalo de nuevo.';

  @override
  String get lanSyncReceived => 'Datos recibidos';

  @override
  String get lanSyncReceivingImages => 'Transfiriendo imágenes...';

  @override
  String get lanSyncReceivingSettings => 'Transfiriendo ajustes...';

  @override
  String get lanSyncImportConfig => 'Transferir también los ajustes';

  @override
  String get lanSyncImportConfigSubtitle =>
      'Incluye las claves API. Todo o nada.';

  @override
  String get lanSyncImagesWarning =>
      'Base de datos recibida, pero no se pudieron transferir las imágenes';

  @override
  String get lanSyncRestartMessage =>
      'Los datos recibidos se usarán tras reiniciar. ¿Reiniciar ahora?';

  @override
  String get lanSyncFirewallNote =>
      'Windows puede pedir permiso del cortafuegos en el primer inicio: permite el acceso en redes privadas.';

  @override
  String get folderPickerNewFolder => 'Nueva carpeta';

  @override
  String get folderPickerVolumeList => 'Dispositivos de almacenamiento';

  @override
  String get folderPickerInternalStorage => 'Almacenamiento interno';

  @override
  String get folderPickerSelect => 'Seleccionar';

  @override
  String get folderPickerFolderName => 'Nombre de la carpeta';

  @override
  String get folderPickerInvalidName => 'Nombre de carpeta no válido';

  @override
  String get folderPickerEmpty => 'Sin subcarpetas';

  @override
  String get folderPickerReadError => 'No se puede leer esta carpeta';

  @override
  String get folderPickerCreateError => 'No se pudo crear la carpeta';

  @override
  String get traktTitle => 'Importación de Trakt';

  @override
  String get traktImportFrom => 'Importar desde Trakt.tv';

  @override
  String get traktImportDescription =>
      'Descarga tus datos desde trakt.tv/users/YOU/data y selecciona el archivo ZIP abajo.';

  @override
  String get traktZipFile => 'Archivo ZIP';

  @override
  String get traktSelectZipFile => 'Seleccionar archivo ZIP';

  @override
  String get traktSelectZipExport => 'Selecciona el ZIP exportado de Trakt';

  @override
  String get preview => 'Vista previa';

  @override
  String traktUser(String username) {
    return 'Usuario de Trakt: $username';
  }

  @override
  String get traktWatchedMovies => 'Películas vistas';

  @override
  String get traktWatchedShows => 'Series vistas';

  @override
  String get traktRatedMovies => 'Películas valoradas';

  @override
  String get traktRatedShows => 'Series valoradas';

  @override
  String get traktWatchlist => 'Lista de seguimiento';

  @override
  String get importOptions => 'Opciones';

  @override
  String get traktImportWatched => 'Importar elementos vistos';

  @override
  String get traktImportWatchedDesc => 'Películas y series como completadas';

  @override
  String get traktImportRatings => 'Importar valoraciones';

  @override
  String get traktImportRatingsDesc => 'Aplicar tus valoraciones (1-10)';

  @override
  String get traktImportWatchlist => 'Importar lista de seguimiento';

  @override
  String get traktImportWatchlistDesc =>
      'Añadir como planeado o a la lista de deseos';

  @override
  String get importTargetCollection => 'Colección de destino';

  @override
  String get importUseExistingCollection => 'Usar una colección existente';

  @override
  String get importStart => 'Iniciar importación';

  @override
  String get traktRequiresOwnTmdbKey =>
      'La importación de Trakt requiere tu propia clave API de TMDB. Añádela en Ajustes → Credenciales.';

  @override
  String get traktInvalidExport => 'Exportación de Trakt no válida';

  @override
  String get kinoriumImportFrom => 'Importar de Kinorium';

  @override
  String get kinoriumImportDescription =>
      'Exporta tu lista desde Kinorium (llega por correo como CSV) y selecciona el archivo abajo.';

  @override
  String get kinoriumSelectCsvFile => 'Seleccionar archivo CSV';

  @override
  String get kinoriumSelectCsvExport =>
      'Selecciona el CSV exportado de Kinorium';

  @override
  String get kinoriumIsWatchlist => 'Este archivo es una \"Watchlist\"';

  @override
  String get kinoriumIsWatchlistDesc =>
      'Importar todos los títulos como planeados en lugar de vistos';

  @override
  String get kinoriumImportNotes => 'Importar reparto y equipo';

  @override
  String get kinoriumImportNotesDesc =>
      'Añade directores y actores a la nota del elemento';

  @override
  String get kinoriumImporting => 'Importando desde Kinorium...';

  @override
  String get kinoriumRecommendOwnTmdbKey =>
      'Consejo: para importaciones grandes se recomienda una clave API de TMDB personal (Ajustes → Claves API), pero es opcional: la clave integrada también funciona.';

  @override
  String get kinoriumReasonNotFound => 'No encontrado en TMDB';

  @override
  String get kinoriumReasonApiError =>
      'Error de TMDB o límite alcanzado; inténtalo más tarde';

  @override
  String kinoriumReasonUnsupportedType(String type) {
    return 'Tipo no compatible: $type';
  }

  @override
  String kinoriumReasonDuplicate(String title) {
    return 'Duplicado de \"$title\"';
  }

  @override
  String traktImportedItems(int count) {
    return 'Importados $count elementos';
  }

  @override
  String get traktImporting => 'Importando desde Trakt';

  @override
  String get creditsTitle => 'Créditos';

  @override
  String get creditsDataProviders => 'Proveedores de datos';

  @override
  String get creditsTmdbAttribution =>
      'Este producto usa la API de TMDB, pero no está avalado ni certificado por TMDB.';

  @override
  String get creditsTvdbAttribution =>
      'Metadatos proporcionados por TheTVDB. Considera completar datos o suscribirte.';

  @override
  String get creditsTvMazeAttribution =>
      'Datos de series proporcionados por TVmaze.';

  @override
  String get creditsIgdbAttribution =>
      'Datos de juegos proporcionados por IGDB.';

  @override
  String get creditsSteamGridDbAttribution =>
      'Ilustraciones proporcionadas por SteamGridDB.';

  @override
  String get creditsVndbAttribution =>
      'Datos de novelas visuales proporcionados por VNDB.';

  @override
  String get creditsAniListAttribution =>
      'Datos de manga proporcionados por AniList.';

  @override
  String get creditsMangaBakaAttribution =>
      'Datos de manga proporcionados por MangaBaka.';

  @override
  String get creditsMangaDexAttribution =>
      'Datos de manga proporcionados por MangaDex.';

  @override
  String get creditsKitsuAttribution =>
      'Datos de manga proporcionados por Kitsu.';

  @override
  String get creditsOpenLibraryAttribution =>
      'Datos de libros de Open Library (CC0 / ODbL).';

  @override
  String get creditsFantlabAttribution => 'Datos de libros de Fantlab.';

  @override
  String get creditsComicVineAttribution =>
      'Datos de cómics de ComicVine (uso no comercial).';

  @override
  String get creditsMusicBrainzAttribution =>
      'Datos musicales de MusicBrainz, portadas de Cover Art Archive, escuchas de ListenBrainz.';

  @override
  String get creditsGoogleBooksAttribution =>
      'Datos de libros de Google Books.';

  @override
  String get creditsHardcoverAttribution => 'Datos de libros de Hardcover.';

  @override
  String get creditsOpenSource => 'Código abierto';

  @override
  String get creditsOpenSourceDesc =>
      'Tonkatsu Box es software libre y de código abierto, publicado bajo la licencia MIT.';

  @override
  String get creditsViewLicenses => 'Ver licencias de código abierto';

  @override
  String get creditsDiscord => 'Unirse al Discord';

  @override
  String get collectionsImportCollection => 'Importar colección';

  @override
  String get collectionsNoCollectionsYet => 'Aún no hay colecciones';

  @override
  String get collectionsNoCollectionsHint =>
      'Toca + para crear tu primera colección y empezar\na organizar tu biblioteca.';

  @override
  String get collectionsFailedToLoad => 'No se pudieron cargar las colecciones';

  @override
  String collectionsCount(int count) {
    return 'Colecciones ($count)';
  }

  @override
  String get collectionsUncategorized => 'Sin categoría';

  @override
  String collectionsUncategorizedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String get editCollection => 'Editar colección';

  @override
  String get collectionsRenamed => 'Colección actualizada';

  @override
  String collectionsFailedToRename(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get collectionsDeleted => 'Colección eliminada';

  @override
  String collectionsFailedToDelete(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return 'No se pudo crear la colección: $error';
  }

  @override
  String collectionsImported(String name, int count) {
    return 'Importada \"$name\" con $count elementos';
  }

  @override
  String get collectionsImporting => 'Importando colección';

  @override
  String get importTargetTitle => 'Importar en...';

  @override
  String get importCreateNew => 'Crear nueva colección';

  @override
  String get importUseExisting => 'Añadir a una colección existente';

  @override
  String get importNoCollections => 'No hay colecciones disponibles';

  @override
  String get importSelectCollection => 'Seleccionar colección';

  @override
  String get importErrorLoadingCollections => 'Error al cargar las colecciones';

  @override
  String get importStartButton => 'Importar';

  @override
  String get importUsername => 'Nombre de usuario';

  @override
  String get importUsernameHint => 'p. ej. tunombre';

  @override
  String get importMode => 'Modo';

  @override
  String get importModeNewOnly => 'Añadir solo nuevos';

  @override
  String get importModeNewOnlySubtitle =>
      'Omitir elementos que ya están en la colección';

  @override
  String get importModeOverwrite => 'Sobrescribir existentes';

  @override
  String get importModeOverwriteSubtitle =>
      'Actualizar progreso, estado y fechas desde la fuente';

  @override
  String get importNewCollectionName => 'Nombre de la colección';

  @override
  String importNewCollectionDefault(String source, String username) {
    return 'Importación de $source — $username';
  }

  @override
  String get importFetchingBooks => 'Obteniendo la biblioteca de libros...';

  @override
  String get importAddingItems => 'Importando entradas';

  @override
  String importProcessingItem(String title) {
    return 'Procesando: $title';
  }

  @override
  String importImportedCount(int count) {
    return '$count importados';
  }

  @override
  String importUpdatedCount(int count) {
    return '$count actualizados';
  }

  @override
  String importUserNotFound(String username) {
    return 'No se encontró al usuario \"$username\"';
  }

  @override
  String get importEmptyUsername => 'Introduce un nombre de usuario';

  @override
  String importFailed(String error) {
    return 'La importación falló: $error';
  }

  @override
  String get collectionNotFound => 'Colección no encontrada';

  @override
  String get collectionAddItems => 'Añadir elementos';

  @override
  String get collectionSwitchToList => 'Cambiar a lista';

  @override
  String get collectionSwitchToBoard => 'Cambiar a tablero';

  @override
  String get collectionUnlockBoard => 'Desbloquear tablero';

  @override
  String get collectionLockBoard => 'Bloquear tablero';

  @override
  String get collectionExport => 'Exportar';

  @override
  String get collectionNoItemsYet => 'Aún no hay elementos';

  @override
  String get collectionEmpty => 'Colección vacía';

  @override
  String get collectionEmptyAddHint =>
      'Añade elementos para empezar a construir tu colección.';

  @override
  String get collectionEmptyReadonly => 'Esta colección está vacía.';

  @override
  String get collectionDeleteEmptyPrompt =>
      'Esta colección ahora está vacía. ¿Eliminarla?';

  @override
  String get collectionRemoveItemTitle => '¿Quitar el elemento?';

  @override
  String collectionRemoveItemMessage(String name) {
    return '¿Quitar $name de esta colección?';
  }

  @override
  String get collectionMoveToCollection => 'Mover a colección';

  @override
  String get collectionExportFormat => 'Formato de exportación';

  @override
  String get collectionChooseExportFormat => 'Elige el formato de exportación:';

  @override
  String get collectionExportLight => 'Ligero (.xcoll)';

  @override
  String get collectionExportLightDesc => 'Solo elementos, archivo más pequeño';

  @override
  String get collectionExportFull => 'Completo (.xcollx)';

  @override
  String get collectionExportFullDesc =>
      'Con imágenes y tablero — funciona sin conexión';

  @override
  String get collectionExportIncludeUserData => 'Incluir datos personales';

  @override
  String get collectionExportIncludeUserDataDesc =>
      'Estado, fechas, notas, progreso de episodios';

  @override
  String get customItemCreate => 'Crear elemento personalizado';

  @override
  String get title => 'Título';

  @override
  String get customItemTitleHint => 'p. ej. Mi juego homebrew';

  @override
  String get customItemAltTitle => 'Título alternativo';

  @override
  String get customItemAltTitleHint => 'Nombre en el idioma original';

  @override
  String get customItemCoverUrl => 'URL de la portada';

  @override
  String get year => 'Año';

  @override
  String get genres => 'Géneros';

  @override
  String get customItemGenresHint => 'p. ej. RPG, acción, puzle';

  @override
  String get platform => 'Plataforma';

  @override
  String get customItemPlatformHint => 'p. ej. PC, SNES, personalizada';

  @override
  String get format => 'Formato';

  @override
  String get progress => 'Progreso';

  @override
  String get customMarkCompleted => 'Marcar como completado';

  @override
  String get customUnitParts => 'Partes';

  @override
  String get customUnitEpisodes => 'Episodios';

  @override
  String get customUnitChapters => 'Capítulos';

  @override
  String get customUnitPages => 'Páginas';

  @override
  String get customUnitVolumes => 'Volúmenes';

  @override
  String get customUnitSeasons => 'Temporadas';

  @override
  String get description => 'Descripción';

  @override
  String get customItemDescriptionHint => 'Breve descripción o notas';

  @override
  String get customItemMyNoteHint => 'Tu nota sobre este elemento';

  @override
  String get customItemTagsHint =>
      'Separadas por comas, p. ej. Pendientes, Favoritos';

  @override
  String get customItemOptionalFields => 'Más campos';

  @override
  String get customItemEdit => 'Editar elemento personalizado';

  @override
  String get customItemFillFromFile => 'Rellenar desde archivo';

  @override
  String customItemFileMultipleRows(int count) {
    return '$count entradas en el archivo — se usó la primera';
  }

  @override
  String get customItemFileNoValidRows =>
      'No hay entradas válidas en este archivo';

  @override
  String get customItemAddCover => 'Añadir portada';

  @override
  String get customItemCoverSource => 'Origen de la portada';

  @override
  String get customItemCoverRatio =>
      'Relación de aspecto recomendada: 2:3 (p. ej. 600×900)';

  @override
  String get customItemCoverFromFile => 'Desde archivo';

  @override
  String get customItemSearchHint => 'Busca o escribe un valor propio...';

  @override
  String get customItemUseCustom => 'Usar valor personalizado';

  @override
  String get customItemExternalUrl => 'URL externa';

  @override
  String get customItemErrorEmptyTitle => 'El título es obligatorio';

  @override
  String get customItemCreated => 'Elemento personalizado creado';

  @override
  String get customItemUpdated => 'Elemento personalizado actualizado';

  @override
  String get tagLabel => 'Etiqueta';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get tagCreate => 'Nueva etiqueta';

  @override
  String get tagCreateHint => 'Nombre de la etiqueta';

  @override
  String tagCreateNamed(String name) {
    return 'Crear \"$name\"';
  }

  @override
  String get tagRename => 'Renombrar etiqueta';

  @override
  String get tagDelete => 'Eliminar etiqueta';

  @override
  String tagDeleteConfirm(String name) {
    return '¿Eliminar la etiqueta \"$name\"? Los elementos quedarán sin ella.';
  }

  @override
  String get tagManage => 'Gestionar etiquetas';

  @override
  String get tagSortTooltip => 'Orden';

  @override
  String get tagSortManual => 'Manual';

  @override
  String get tagSortAlphaAsc => 'Alfabético (A–Z)';

  @override
  String get tagSortAlphaDesc => 'Alfabético (Z–A)';

  @override
  String get tagAssign => 'Asignar etiquetas';

  @override
  String get tagNone => 'Sin etiquetas';

  @override
  String get tagTextColor => 'Color del texto';

  @override
  String get tagCreated => 'Etiqueta creada';

  @override
  String get tagRenamed => 'Etiqueta renombrada';

  @override
  String get tagDeleted => 'Etiqueta eliminada';

  @override
  String get tagUpdateFailed => 'No se pudo actualizar la etiqueta';

  @override
  String get refreshItemFromApi => 'Actualizar desde la fuente';

  @override
  String get refreshItemSuccess => 'Elemento actualizado desde la fuente';

  @override
  String get refreshItemNotFound => 'La fuente ya no tiene este elemento';

  @override
  String get refreshItemUnsupported =>
      'Los elementos personalizados no tienen fuente externa';

  @override
  String refreshItemFailed(String error) {
    return 'La actualización falló: $error';
  }

  @override
  String get renameDialogHint => 'Nombre para mostrar';

  @override
  String renameOriginalLabel(String name) {
    return 'Original: $name';
  }

  @override
  String get renameResetToOriginal => 'Restablecer el original';

  @override
  String get renameSaved => 'Renombrado';

  @override
  String get tierListExportFailed => 'No se pudo exportar la imagen';

  @override
  String get browseCollectionsDownloadFailedGeneric =>
      'No se pudo descargar la colección';

  @override
  String get tagFilterAll => 'Todas las etiquetas';

  @override
  String get tagSidebarGroup => 'Grupo';

  @override
  String get colorPickerTitle => 'Color';

  @override
  String get colorPickerNoColor => 'Sin color';

  @override
  String get raLinkButton => 'Vincular RetroAchievements';

  @override
  String get raLinkTitle => 'Buscar el juego en RetroAchievements';

  @override
  String get raLinkSearchHint => 'Buscar por nombre...';

  @override
  String raLinkLoading(String platform) {
    return 'Cargando juegos de $platform...';
  }

  @override
  String get raLinkNotFound => 'Sin coincidencias';

  @override
  String get raLinkSuccess => 'Juego vinculado a RetroAchievements';

  @override
  String raLinkAchievements(int count) {
    return '$count logros';
  }

  @override
  String get raUnlinkButton => 'Desvincular';

  @override
  String get raUnlinkTitle => 'Desvincular RetroAchievements';

  @override
  String get raUnlinkConfirm =>
      '¿Quitar el vínculo con RetroAchievements y los datos de logros de este juego?';

  @override
  String get collectionFilterByType => 'Filtrar por tipo';

  @override
  String get collectionFilterGames => 'Juegos';

  @override
  String get collectionFilterMovies => 'Películas';

  @override
  String get collectionFilterTvShows => 'Series';

  @override
  String get collectionFilterVisualNovels => 'Novelas visuales';

  @override
  String get collectionFilterBooks => 'Libros';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get sort => 'Ordenar';

  @override
  String get collectionFilterAscending => 'Ascendente';

  @override
  String get collectionFilterDescending => 'Descendente';

  @override
  String get collectionFilterFilters => 'Filtros';

  @override
  String get collectionFilterClearAll => 'Limpiar todo';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name movido a $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name ya existe en $collection';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name quitado';
  }

  @override
  String get boardTab => 'Tablero';

  @override
  String get imageAddedToBoard => 'Imagen añadida al tablero';

  @override
  String get mapAddedToBoard => 'Mapa añadido al tablero';

  @override
  String get loading => 'Cargando...';

  @override
  String get gameNotFound => 'Juego no encontrado';

  @override
  String get movieNotFound => 'Película no encontrada';

  @override
  String get tvShowNotFound => 'Serie no encontrada';

  @override
  String get animationNotFound => 'Animación no encontrada';

  @override
  String get visualNovelNotFound => 'Novela visual no encontrada';

  @override
  String get mangaNotFound => 'Manga no encontrado';

  @override
  String get readingProgress => 'Progreso de lectura';

  @override
  String get mangaChapters => 'Capítulos';

  @override
  String get mangaVolumes => 'Volúmenes';

  @override
  String get mangaMarkCompleted => 'Marcar como completado';

  @override
  String get animeProgress => 'Progreso de visionado';

  @override
  String get animeEpisodes => 'Episodios';

  @override
  String get animeMarkCompleted => 'Marcar como completado';

  @override
  String get bookPages => 'Páginas';

  @override
  String get bookIssues => 'Números';

  @override
  String get bookMarkCompleted => 'Marcar como completado';

  @override
  String animeNextEpisode(int episode) {
    return 'El ep. $episode se emite pronto';
  }

  @override
  String get animatedMovie => 'Película animada';

  @override
  String get animatedSeries => 'Serie animada';

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
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String totalEpisodes(int count) {
    return '$count ep';
  }

  @override
  String seasonName(int number) {
    return 'Temporada $number';
  }

  @override
  String get episodeProgress => 'Progreso de episodios';

  @override
  String episodesWatchedOf(int watched, int total) {
    return '$watched/$total vistos';
  }

  @override
  String episodesWatched(int count) {
    return '$count vistos';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total episodios';
  }

  @override
  String get noSeasonData => 'No hay datos de temporadas';

  @override
  String get refreshFromTmdb => 'Actualizar desde TMDB';

  @override
  String get markAllWatched => 'Marcar todo como visto';

  @override
  String get markNextWatched => 'Marcar siguiente episodio';

  @override
  String get unmarkAll => 'Desmarcar todo';

  @override
  String get noEpisodesFound => 'No se encontraron episodios';

  @override
  String episodeWatchedDate(String date) {
    return 'visto el $date';
  }

  @override
  String get createCollectionTitle => 'Nueva colección';

  @override
  String get createCollectionNameLabel => 'Nombre de la colección';

  @override
  String get createCollectionNameHint => 'p. ej. Clásicos de SNES';

  @override
  String get createCollectionEnterName => 'Introduce un nombre';

  @override
  String get createCollectionNameTooShort =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get createCollectionHiddenLabel => 'Colección oculta';

  @override
  String get createCollectionHiddenHint =>
      'Sin portadas en la tarjeta, y sus elementos quedan fuera de Todos los elementos';

  @override
  String get collectionHide => 'Ocultar colección';

  @override
  String get collectionUnhide => 'Mostrar colección';

  @override
  String get renameCollectionTitle => 'Renombrar colección';

  @override
  String get deleteCollectionTitle => '¿Eliminar la colección?';

  @override
  String deleteCollectionMessage(String name) {
    return '¿Seguro que quieres eliminar $name?\n\nEsta acción no se puede deshacer.';
  }

  @override
  String get canvasAddText => 'Añadir texto';

  @override
  String get canvasAddImage => 'Añadir imagen';

  @override
  String get canvasAddLink => 'Añadir enlace';

  @override
  String get canvasFindImages => 'Buscar imágenes...';

  @override
  String get canvasBrowseMaps => 'Explorar mapas...';

  @override
  String get canvasConnect => 'Conectar';

  @override
  String get canvasBringToFront => 'Traer al frente';

  @override
  String get canvasSendToBack => 'Enviar al fondo';

  @override
  String get canvasEditConnection => 'Editar conexión';

  @override
  String get canvasDeleteConnection => 'Eliminar conexión';

  @override
  String get canvasDeleteElement => 'Eliminar elemento';

  @override
  String get canvasDeleteElementMessage =>
      '¿Seguro que quieres eliminar este elemento?';

  @override
  String get canvasAddToBoard => 'Añadir al tablero';

  @override
  String get editTextTitle => 'Editar texto';

  @override
  String get textContentLabel => 'Contenido del texto';

  @override
  String get fontSizeLabel => 'Tamaño de fuente';

  @override
  String get fontSizeSmall => 'Pequeño';

  @override
  String get fontSizeMedium => 'Mediano';

  @override
  String get fontSizeLarge => 'Grande';

  @override
  String get fontSizeTitle => 'Título';

  @override
  String get editImageTitle => 'Editar imagen';

  @override
  String get imageFromUrl => 'Desde URL';

  @override
  String get imageFromFile => 'Desde archivo';

  @override
  String get imageUrlLabel => 'URL de la imagen';

  @override
  String get imageUrlHint => 'https://example.com/image.png';

  @override
  String get imageChooseFile => 'Elegir archivo';

  @override
  String get imageChooseAnother => 'Elegir otra';

  @override
  String get editLinkTitle => 'Editar enlace';

  @override
  String get linkLabelOptional => 'Etiqueta (opcional)';

  @override
  String get linkLabelHint => 'Mi enlace';

  @override
  String get connectionLabelHint => 'p. ej. depende de, relacionado con...';

  @override
  String get connectionStyleLabel => 'Estilo';

  @override
  String get connectionStyleSolid => 'Continua';

  @override
  String get connectionStyleDashed => 'Discontinua';

  @override
  String get connectionStyleArrow => 'Flecha';

  @override
  String get searchTabTv => 'TV';

  @override
  String get searchHintMovies => 'Buscar películas...';

  @override
  String get searchHintTv => 'Buscar series...';

  @override
  String get searchHintAnime => 'Buscar anime...';

  @override
  String get searchHintGames => 'Buscar juegos...';

  @override
  String get searchHintVisualNovels => 'Buscar novelas visuales...';

  @override
  String get searchSourceVisualNovels => 'N. visuales';

  @override
  String get searchSourceOpenLibrary => 'OpenLibrary';

  @override
  String get searchSourceFantlab => 'Fantlab';

  @override
  String get searchSourceComics => 'Cómics';

  @override
  String get searchHintManga => 'Buscar manga...';

  @override
  String get searchHintBooks => 'Buscar libros...';

  @override
  String get searchHintComics => 'Buscar cómics...';

  @override
  String get searchSourceMusic => 'Música';

  @override
  String get searchHintMusic => 'Buscar álbumes...';

  @override
  String get musicFilterAlbumsDefault => 'Álbumes';

  @override
  String get musicFilterAllTypes => 'Todos los tipos';

  @override
  String get musicFilterTypeEp => 'EP';

  @override
  String get musicFilterTypeSingle => 'Sencillo';

  @override
  String get musicFilterTypeBroadcast => 'Emisión';

  @override
  String get musicFilterTypeOther => 'Otro';

  @override
  String get musicFilterEdition => 'Ediciones';

  @override
  String get musicFilterStudioOnly => 'Solo de estudio';

  @override
  String get musicSheetEditions => 'Ediciones';

  @override
  String get musicSheetTracks => 'Pistas';

  @override
  String musicSheetDisc(int number) {
    return 'Disco $number';
  }

  @override
  String get musicSheetEditionsUnavailable => 'Ediciones no disponibles';

  @override
  String musicTracksCount(int count) {
    return '$count pistas';
  }

  @override
  String get musicTrackerNoTracks => 'Sin lista de pistas';

  @override
  String get musicDiscoverFreshReleases => 'Nuevos lanzamientos';

  @override
  String get musicDiscoverUnavailable => 'Discover no disponible';

  @override
  String get musicSearchArtist => 'Artista';

  @override
  String get language => 'Idioma';

  @override
  String get bookFilterSearchBy => 'Buscar por';

  @override
  String get type => 'Tipo';

  @override
  String get bookSearchAuthor => 'Autor';

  @override
  String get bookSearchSubject => 'Tema';

  @override
  String get bookSimilarTitle => 'Libros similares';

  @override
  String get bookMoreByAuthorTitle => 'Más de este autor';

  @override
  String get bookTitleCopied => 'Título copiado';

  @override
  String get editionPickerTitle => 'Elegir edición';

  @override
  String get editionPickerEmpty => 'No se encontraron ediciones';

  @override
  String get fantlabTypeNovel => 'Novela';

  @override
  String get fantlabTypeNovella => 'Novela corta';

  @override
  String get fantlabTypeShortStory => 'Relato';

  @override
  String get fantlabTypeCycle => 'Ciclo';

  @override
  String get searchSelectPlatform => 'Seleccionar plataforma';

  @override
  String get searchAddToCollection => 'Añadir a colección';

  @override
  String searchAddedToCollection(String name) {
    return '$name añadido a la colección';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name añadido a $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name ya está en la colección';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name ya está en $collection';
  }

  @override
  String searchAddedToCollections(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colecciones',
      one: '1 colección',
    );
    return '$name añadido a $_temp0';
  }

  @override
  String searchAlreadyInCollections(String name) {
    return '$name ya está en las colecciones seleccionadas';
  }

  @override
  String get goToSettings => 'Ir a Ajustes';

  @override
  String get searchMinCharsHint =>
      'Escribe al menos 2 caracteres y pulsa Intro';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get searchWhatToFind => 'Qué buscar';

  @override
  String get searchSortNeedsSingleSource =>
      'La ordenación está disponible con una sola fuente';

  @override
  String get searchSortUnavailableInSearch =>
      'Esta fuente no ordena los resultados de búsqueda';

  @override
  String get searchSourcesLabel => 'Fuentes';

  @override
  String get searchTextOnlyHint => 'Solo búsqueda por texto';

  @override
  String get searchSourceNoResponse => 'no respondió';

  @override
  String get searchCommonFilters => 'Comunes';

  @override
  String get searchShowAll => 'todos';

  @override
  String get searchNarrowedBySource => 'limitado por el filtro de esta fuente';

  @override
  String get searchSourceLacksValue => 'no admite el valor seleccionado';

  @override
  String searchNothingFoundFor(String query) {
    return 'No se encontró nada para \"$query\"';
  }

  @override
  String get searchNoInternet => 'Sin conexión a internet';

  @override
  String get searchFailed => 'La búsqueda falló';

  @override
  String get searchCheckConnection =>
      'Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get copyErrorDetails => 'Copiar detalles del error';

  @override
  String get errorDetailsCopied => 'Detalles del error copiados';

  @override
  String get errorDetailsTitle => 'Detalles del error';

  @override
  String get errorDetailsShow => 'Detalles';

  @override
  String get showMore => 'Más…';

  @override
  String get showLess => 'Contraer';

  @override
  String get platformFilterTitle => 'Seleccionar plataformas';

  @override
  String get platformFilterClearAll => 'Limpiar todo';

  @override
  String get platformFilterSearchHint => 'Buscar plataformas...';

  @override
  String selectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String platformFilterCount(int count) {
    return '$count plataformas';
  }

  @override
  String get platformFilterShowAll => 'Mostrar todas';

  @override
  String platformFilterApply(int count) {
    return 'Aplicar ($count)';
  }

  @override
  String get platformFilterNone => 'No se encontraron plataformas';

  @override
  String get platformFilterTryDifferent =>
      'Prueba con otro término de búsqueda';

  @override
  String get wishlistHideResolved => 'Ocultar resueltos';

  @override
  String get wishlistShowResolved => 'Mostrar resueltos';

  @override
  String get wishlistClearResolved => 'Borrar resueltos';

  @override
  String get wishlistEmpty => 'Aún no hay deseos';

  @override
  String get wishlistEmptyHint =>
      'Toca + para añadir algo que buscar más tarde';

  @override
  String get wishlistDeleteItem => 'Eliminar elemento';

  @override
  String wishlistDeletePrompt(String name) {
    return '¿Eliminar \"$name\" de la lista de deseos?';
  }

  @override
  String wishlistClearResolvedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count elementos resueltos?',
      one: '¿Eliminar 1 elemento resuelto?',
    );
    return '$_temp0';
  }

  @override
  String get wishlistMarkResolved => 'Marcar como resuelto';

  @override
  String get wishlistUnresolve => 'Marcar como no resuelto';

  @override
  String get wishlistTitleHint => 'Nombre del juego, película o serie...';

  @override
  String get wishlistTitleMinChars => 'Al menos 2 caracteres';

  @override
  String get wishlistTypeOptional => 'Tipo (opcional)';

  @override
  String get any => 'Cualquiera';

  @override
  String get wishlistNoteOptional => 'Nota (opcional)';

  @override
  String get wishlistNoteHint => 'Plataforma, año, quién lo recomendó...';

  @override
  String get wishlistTagOptional => 'Etiqueta (opcional)';

  @override
  String get wishlistTagHint =>
      'Agrupa entradas — p. ej. un lote de importación o una fuente';

  @override
  String get wishlistTagUntagged => 'Sin etiqueta';

  @override
  String get wishlistTagFilterLabel => 'Lista';

  @override
  String get wishlistTagManage => 'Gestionar etiqueta';

  @override
  String get wishlistTagDelete => 'Eliminar la etiqueta y todas las entradas';

  @override
  String wishlistTagDeleteConfirm(String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '¿Eliminar la etiqueta \"$tag\" y $_temp0?';
  }

  @override
  String wishlistBulkActionsButton(int count) {
    return '$count coincidencias';
  }

  @override
  String get wishlistBulkApplyTag => 'Aplicar etiqueta a los visibles';

  @override
  String wishlistBulkApplyTagHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Etiquetar las $count entradas visibles como',
      one: 'Etiquetar la 1 entrada visible como',
    );
    return '$_temp0';
  }

  @override
  String get wishlistBulkRemoveTag => 'Quitar la etiqueta de los visibles';

  @override
  String get wishlistBulkDelete => 'Eliminar visibles';

  @override
  String wishlistBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count entradas visibles?',
      one: '¿Eliminar 1 entrada visible?',
    );
    return '$_temp0';
  }

  @override
  String get apply => 'Aplicar';

  @override
  String get welcomeStepWelcome => 'Bienvenida';

  @override
  String get welcomeStepReady => '¡Listo!';

  @override
  String get welcomeNameTitle => '¿Cómo te llamas?';

  @override
  String get welcomeNameSubtitle =>
      'Este nombre aparecerá como autor en las colecciones que crees';

  @override
  String get welcomeChangeLaterHint => 'Puedes cambiarlo más tarde en Ajustes';

  @override
  String get welcomeLanguageTitle => 'Elige tu idioma';

  @override
  String get welcomeLanguageSubtitle => 'Selecciona el idioma de la interfaz';

  @override
  String get welcomeTitle => 'Te damos la bienvenida a Tonkatsu Box';

  @override
  String get welcomeSubtitle =>
      'Organiza tus colecciones de juegos, películas,\nseries, anime, novelas visuales, manga y libros';

  @override
  String get welcomeWhatYouCanDo => 'Qué puedes hacer';

  @override
  String get welcomeFeatureCollections =>
      'Crea colecciones por plataforma, género o cualquier tema';

  @override
  String get welcomeFeatureSearch =>
      'Busca juegos, películas, series, anime, novelas visuales, manga y libros vía API';

  @override
  String get welcomeFeatureTracking =>
      'Registra el progreso, valora del 1 al 10, añade notas';

  @override
  String get welcomeFeatureBoards => 'Tableros visuales con ilustraciones';

  @override
  String get welcomeFeatureExport =>
      'Exporta e importa — comparte colecciones con amigos';

  @override
  String get welcomeWorksWithoutKeys => 'Funciona sin claves API';

  @override
  String get welcomeChipImport => 'Importar .xcoll';

  @override
  String get welcomeChipCanvas => 'Tableros';

  @override
  String get welcomeChipRatings => 'Valoraciones y notas';

  @override
  String get welcomeApiKeysHint =>
      'Las claves API solo se necesitan para buscar nuevos juegos, películas y series. Puedes importar colecciones y trabajar con ellas sin conexión.';

  @override
  String get welcomeChipGames => 'Juegos (IGDB)';

  @override
  String get welcomeChipMovies => 'Películas (TMDB)';

  @override
  String get welcomeChipTvShows => 'Series (TMDB)';

  @override
  String get welcomeChipAnime => 'Anime (TMDB)';

  @override
  String get welcomeChipVisualNovels => 'Novelas visuales (VNDB)';

  @override
  String get welcomeChipManga => 'Manga (AniList)';

  @override
  String get welcomeApiTitle => 'Obtener claves API';

  @override
  String get welcomeApiFreeHint => 'Registro gratuito, 2-3 minutos cada una';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => 'Búsqueda de juegos';

  @override
  String get welcomeApiRequired => 'OBLIGATORIA';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => 'Películas, series y anime';

  @override
  String get welcomeApiTvdbDesc => 'Películas y series, episodios propios';

  @override
  String get welcomeApiComicVineDesc => 'Cómics y novelas gráficas';

  @override
  String get welcomeApiGoogleBooksDesc => 'Catálogo global de libros de Google';

  @override
  String get welcomeApiHardcoverDesc =>
      'Catálogo comunitario de libros, requiere un token personal';

  @override
  String get welcomeApiRecommended => 'RECOMENDADA';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => 'Ilustraciones de juegos para los tableros';

  @override
  String get welcomeApiOptional => 'OPCIONAL';

  @override
  String get welcomeApiBuiltInKey => 'CLAVE INTEGRADA';

  @override
  String get welcomeApiOwnKeyHint =>
      'Puedes añadir tu propia clave más tarde en Ajustes para límites más altos';

  @override
  String get welcomeApiEnterKeysHint =>
      'Introduce las claves en Ajustes → Credenciales tras la configuración';

  @override
  String get welcomeApiRateLimitHint =>
      'Las claves integradas se comparten entre todos los usuarios y tienen límites de uso. Para la mejor experiencia usa tus propias claves: es gratis y solo tarda unos minutos.';

  @override
  String get welcomeHowTitle => 'Cómo funciona';

  @override
  String get welcomeHowAppStructure => 'Estructura de la aplicación';

  @override
  String get welcomeHowMainDesc =>
      'Todos los elementos de todas las colecciones en una vista. Filtra por tipo, ordena por valoración.';

  @override
  String get welcomeHowCollectionsDesc =>
      'Tus colecciones. Crea, organiza, gestiona. Vista de cuadrícula o lista por colección.';

  @override
  String get welcomeHowTierListsDesc =>
      'Clasifica y compara elementos de tus colecciones con tier lists personalizables.';

  @override
  String get welcomeHowWishlistDesc =>
      'Lista rápida de cosas para revisar más tarde. Sin API.';

  @override
  String get welcomeHowSearchDesc =>
      'Encuentra juegos, películas, series, novelas visuales y manga vía API. Añádelos a cualquier colección.';

  @override
  String get welcomeHowSettingsDesc =>
      'Claves API, caché, exportación/importación de la base de datos, herramientas de depuración.';

  @override
  String get welcomeHowPersonalizationDesc =>
      'Tu gusto en un solo lugar: una nube con tus géneros favoritos y recomendaciones basadas en lo que has valorado.';

  @override
  String get welcomeHowQuickStart => 'Inicio rápido';

  @override
  String get welcomeHowStep1 =>
      'Ve a Ajustes → Credenciales e introduce las claves API';

  @override
  String get welcomeHowStep2 =>
      'Pulsa Verificar conexión y espera la sincronización de plataformas';

  @override
  String get welcomeHowStep3 => 'Ve a Colecciones → + Nueva colección';

  @override
  String get welcomeHowStep4 =>
      'Ponle nombre y luego Añadir elementos → Buscar → Añadir';

  @override
  String get welcomeHowStep5 =>
      'Valora, registra el progreso, añade notas — ¡listo!';

  @override
  String get welcomeHowSharing => 'Compartir';

  @override
  String get welcomeHowSharingDesc1 => 'Exporta colecciones como ';

  @override
  String get welcomeHowSharingDesc2 => ' (ligero, solo metadatos) o ';

  @override
  String get welcomeHowSharingDesc3 =>
      ' (completo, con imágenes y tablero — funciona sin conexión). Importa de amigos — ¡sin API!';

  @override
  String get welcomeReadyTitle => '¡Todo listo!';

  @override
  String get welcomeReadyMessage =>
      'Ve a Ajustes → Credenciales para introducir tus claves API, o empieza importando una colección.';

  @override
  String get welcomeReadySkip => 'Omitir — exploraré por mi cuenta';

  @override
  String get welcomeReadyReturnHint =>
      'Siempre puedes volver aquí desde Ajustes';

  @override
  String get welcomeStepSources => 'Fuentes';

  @override
  String get welcomeStepTour => 'Recorrido';

  @override
  String get welcomeChipBooks => 'Libros (OpenLibrary, Fantlab)';

  @override
  String get welcomeSourcesTitle => 'De dónde vienen los datos';

  @override
  String get welcomeSourcesSubtitle =>
      'Estos proveedores alimentan la búsqueda en toda la aplicación. La mayoría funciona de inmediato — solo un par pide una clave gratuita.';

  @override
  String get welcomeSourcesNoKeyNeeded => 'SIN CLAVE';

  @override
  String get welcomeSourcesKeySaved => 'Clave guardada';

  @override
  String get welcomeSourcesGetKey => 'Obtener clave';

  @override
  String get welcomeSourcesKeyOptionalHint =>
      'Opcional — tu propia clave sube los límites de uso. La búsqueda funciona sin ella.';

  @override
  String get welcomeSourcesTvdbKeyHint =>
      'Obligatoria — sin clave, la búsqueda en TheTVDB permanece desactivada.';

  @override
  String get welcomeSourcesHardcoverTokenHint =>
      'Obligatorio — sin él la búsqueda y la importación quedan deshabilitadas. Los tokens caducan cada 1 de enero.';

  @override
  String get welcomeSourceDescTmdb => 'Películas, series y animación.';

  @override
  String get welcomeSourceDescTvMaze => 'Series de TV.';

  @override
  String get welcomeSourceDescTvdb =>
      'Películas y series, con sus propios episodios.';

  @override
  String get welcomeSourceDescIgdb => 'Videojuegos de todas las plataformas.';

  @override
  String get welcomeSourceDescAniList =>
      'Anime y manga con metadatos completos.';

  @override
  String get welcomeSourceDescMangaBaka =>
      'Manga, manhwa, manhua y novelas ligeras.';

  @override
  String get welcomeSourceDescMangaDex =>
      'Un amplio catálogo de manga con títulos localizados y recuento de capítulos.';

  @override
  String get welcomeSourceDescKitsu =>
      'Un catálogo independiente de manga con valoraciones y portadas.';

  @override
  String get welcomeSourceDescVndb => 'La base de datos de novelas visuales.';

  @override
  String get welcomeSourceDescOpenLibrary =>
      'Un catálogo abierto con millones de libros.';

  @override
  String get welcomeSourceDescFantlab =>
      'Un catálogo de libros detallado con valoraciones, premios y series.';

  @override
  String get welcomeSourceDescComicVine =>
      'Un enorme catálogo de cómics y novelas gráficas.';

  @override
  String get welcomeSourceDescGoogleBooks =>
      'Millones de ediciones del catálogo de libros de Google, con búsqueda por título, autor o ISBN.';

  @override
  String get welcomeSourceDescHardcover =>
      'Catálogo comunitario de libros con series, géneros, estados de ánimo y valoraciones. Requiere un token personal gratuito.';

  @override
  String get welcomeTourTitle => 'Conoce el menú';

  @override
  String get welcomeTourSubtitle =>
      'Un recorrido rápido por la navegación principal — toca Siguiente para avanzar.';

  @override
  String get welcomeTourStart => 'Empezar a explorar';

  @override
  String get welcomeHowReleasesDesc =>
      'Nuevos episodios y lanzamientos de las series y juegos que sigues.';

  @override
  String updateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String updateCurrent(String version) {
    return 'Actual: v$version';
  }

  @override
  String get updateWarningTitle => 'Antes de actualizar';

  @override
  String get updateWarningBody =>
      'Esta aplicación está en desarrollo activo. Las actualizaciones pueden incluir migraciones de la base de datos que cambian el formato de los datos.\n\nCrea una copia de seguridad antes de actualizar (Ajustes → Copia de seguridad). Así podrás restaurar tus datos si algo sale mal.';

  @override
  String get updateWarningProceed => 'Ir a la nueva versión';

  @override
  String get chooseCollection => 'Elegir colección';

  @override
  String get withoutCollection => 'Sin colección';

  @override
  String get detailMyRating => 'Mi valoración';

  @override
  String detailRatingValue(String rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => 'Actividad y progreso';

  @override
  String get detailAuthorReview => 'Reseña del autor';

  @override
  String get detailEditAuthorReview => 'Editar la reseña del autor';

  @override
  String get detailWriteReviewHint => 'Escribe tu reseña...';

  @override
  String get detailReviewVisibility =>
      'Visible para otros al compartir. Tu reseña de este título.';

  @override
  String get detailNoReviewEditable =>
      'Aún no hay reseña. Toca Editar para añadirla.';

  @override
  String get detailNoReviewReadonly => 'No hay reseña del autor.';

  @override
  String get detailMyNotes => 'Mis notas';

  @override
  String get detailEditMyNotes => 'Editar mis notas';

  @override
  String get detailWriteNotesHint => 'Escribe tus notas personales...';

  @override
  String get detailNoNotesYet =>
      'Aún no hay notas. Toca Editar para añadir tus notas personales.';

  @override
  String get detailNoNotesReadonly => 'No hay notas del autor.';

  @override
  String get unknownGame => 'Juego desconocido';

  @override
  String get unknownMovie => 'Película desconocida';

  @override
  String get unknownTvShow => 'Serie desconocida';

  @override
  String get unknownAnimation => 'Animación desconocida';

  @override
  String get unknownVisualNovel => 'Novela visual desconocida';

  @override
  String get unknownManga => 'Manga desconocido';

  @override
  String get unknownCustom => 'Elemento personalizado desconocido';

  @override
  String get unknownPlatform => 'Plataforma desconocida';

  @override
  String get defaultAuthor => 'Usuario';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get allItemsRatingAsc => 'Valoración ↑';

  @override
  String get allItemsRatingDesc => 'Valoración ↓';

  @override
  String get allItemsNoItems => 'Aún no hay elementos';

  @override
  String get allItemsNoMatch => 'Ningún elemento coincide con el filtro';

  @override
  String get allItemsAddViaCollections =>
      'Ve a Colecciones → crea una colección → añade elementos\ndesde Buscar. Aparecerán aquí automáticamente.';

  @override
  String get allItemsFailedToLoad => 'No se pudieron cargar los elementos';

  @override
  String get allPlatforms => 'Todas las plataformas';

  @override
  String get allItemsFilterPlatformsTitle => 'Filtrar por plataforma';

  @override
  String get debugIgdbMedia => 'IGDB Media';

  @override
  String get debugGamepad => 'Mando';

  @override
  String get debugClearLogs => 'Borrar registros';

  @override
  String get debugRawEvents => 'Eventos sin procesar (Gamepads.events)';

  @override
  String get debugServiceEvents => 'Eventos del servicio (filtrados)';

  @override
  String debugEventsCount(int count) {
    return '$count eventos';
  }

  @override
  String get debugPressButton => 'Pulsa cualquier botón\ndel mando...';

  @override
  String get debugExportLog => 'Exportar registro a archivo';

  @override
  String debugLogExported(String path) {
    return 'Registro exportado a $path';
  }

  @override
  String get debugLogEmpty => 'No hay eventos para exportar';

  @override
  String get settingsGamepadDebug => 'Depuración del mando';

  @override
  String get debugSearchGames => 'Buscar juegos';

  @override
  String get debugEnterGameName => 'Introduce el nombre del juego';

  @override
  String get debugEnterGameNameHint =>
      'Introduce un nombre de juego para buscar';

  @override
  String get debugGameId => 'ID del juego';

  @override
  String get debugEnterGameId => 'Introduce el ID de juego de SteamGridDB';

  @override
  String debugLoadTab(String tabName) {
    return 'Cargar $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return 'Introduce un ID de juego y pulsa Cargar $tabName';
  }

  @override
  String get debugNoImagesFound => 'No se encontraron imágenes';

  @override
  String collectionTileStats(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0 · $percent completado';
  }

  @override
  String get collectionTileError => 'Error al cargar las estadísticas';

  @override
  String get activityDatesTitle => 'Fechas de actividad';

  @override
  String get activityDatesAdded => 'Añadido';

  @override
  String get activityDatesStarted => 'Empezado';

  @override
  String get activityDatesCompleted => 'Completado';

  @override
  String get activityDatesSelectStart => 'Selecciona la fecha de inicio';

  @override
  String get activityDatesSelectCompletion =>
      'Selecciona la fecha de finalización';

  @override
  String get settingsDateFormat => 'Formato de fecha';

  @override
  String get settingsDateFormatSubtitle =>
      'Cómo se muestran las fechas en la aplicación';

  @override
  String get settingsAnimeMangaTitleLanguage =>
      'Idioma de los títulos de anime y manga';

  @override
  String get settingsAnimeMangaTitleLanguageSubtitle =>
      'Título mostrado para anime y manga';

  @override
  String get settingsAnimeMangaTitleLanguageRomaji => 'Romaji';

  @override
  String get settingsAnimeMangaTitleLanguageEnglish => 'Inglés';

  @override
  String get settingsAnimeMangaTitleLanguageNative => 'Nativo';

  @override
  String get dualDatePickerNoDate => 'Sin fecha';

  @override
  String get dualDatePickerErrorEmpty => 'Introduce una fecha';

  @override
  String get dualDatePickerErrorFormat => 'Usa el formato yyyy-MM-dd';

  @override
  String get dualDatePickerErrorRange => 'La fecha está fuera de rango';

  @override
  String activityDatesCompletionTime(String duration) {
    return 'Completado en $duration';
  }

  @override
  String get timeSpentTitle => 'Tiempo dedicado';

  @override
  String get timeSpentAdd => 'Añadir tiempo';

  @override
  String get timeSpentEdit => 'Editar tiempo';

  @override
  String get timeSpentHours => 'Horas';

  @override
  String get timeSpentMinutes => 'Minutos';

  @override
  String get durationLessThanDay => 'menos de un día';

  @override
  String get durationOneDay => '1 día';

  @override
  String durationDays(int count) {
    return '$count días';
  }

  @override
  String durationWeeks(int count) {
    return '$count semanas';
  }

  @override
  String durationMonths(int count) {
    return '$count meses';
  }

  @override
  String durationYears(String count) {
    return '$count años';
  }

  @override
  String get canvasFailedToLoad => 'No se pudo cargar el tablero';

  @override
  String get canvasBoardEmpty => 'El tablero está vacío';

  @override
  String get canvasBoardEmptyHint => 'Añade primero elementos a la colección';

  @override
  String get canvasCenterView => 'Centrar vista';

  @override
  String get canvasResetPositions => 'Restablecer posiciones';

  @override
  String get canvasVgmapsBrowser => 'Navegador VGMaps';

  @override
  String get canvasSteamGridDbImages => 'Imágenes de SteamGridDB';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get closePanel => 'Cerrar panel';

  @override
  String get steamGridDbSearchHint => 'Buscar juego...';

  @override
  String get steamGridDbNoApiKey =>
      'La clave API de SteamGridDB no está configurada. Configúrala en Ajustes.';

  @override
  String get steamGridDbBackToSearch => 'Volver a la búsqueda';

  @override
  String get steamGridDbGrids => 'Grids';

  @override
  String get steamGridDbHeroes => 'Heroes';

  @override
  String get steamGridDbLogos => 'Logos';

  @override
  String get steamGridDbIcons => 'Iconos';

  @override
  String get steamGridDbSearchFirst => 'Busca primero un juego';

  @override
  String get vgmapsBack => 'Atrás';

  @override
  String get vgmapsForward => 'Adelante';

  @override
  String get vgmapsHome => 'Inicio';

  @override
  String get vgmapsReload => 'Recargar';

  @override
  String get vgmapsCaptureImage => 'Capturar imagen del mapa';

  @override
  String get vgmapsSearchHint => 'Buscar juego en VGMaps...';

  @override
  String get vgmapsDismiss => 'Descartar';

  @override
  String vgmapsFailedInit(String error) {
    return 'No se pudo inicializar WebView: $error';
  }

  @override
  String get discoverTitle => 'Descubrir';

  @override
  String get discoverCustomize => 'Personalizar';

  @override
  String get discoverTrending => 'Tendencias de la semana';

  @override
  String get discoverTopRatedMovies => 'Películas mejor valoradas';

  @override
  String get discoverTopRatedTvShows => 'Series mejor valoradas';

  @override
  String get discoverPopularTvShows => 'Series populares';

  @override
  String get discoverUpcoming => 'Próximamente';

  @override
  String get discoverCustomizeTitle => 'Personalizar Descubrir';

  @override
  String get discoverCustomizeHint => 'Elige qué secciones mostrar';

  @override
  String get discoverResetDefault => 'Restablecer valores predeterminados';

  @override
  String get discoverAlreadyInCollection => 'Ya en la colección';

  @override
  String get discoverShowWithBadge => 'Mostrar con insignia';

  @override
  String get discoverHideCompletely => 'Ocultar por completo';

  @override
  String get recommendationsTitle => 'Recomendaciones';

  @override
  String get reviewsTitle => 'Reseñas';

  @override
  String reviewsShowAll(int count) {
    return 'Mostrar las $count reseñas';
  }

  @override
  String get reviewsReadMore => 'Leer más';

  @override
  String get reviewsInEnglish => 'Reseñas en inglés';

  @override
  String get settingsShowRecommendationsSubtitle =>
      'Películas y series similares en las páginas de detalle';

  @override
  String get settingsHideEmptyMediaTypeChevrons =>
      'Ocultar filtros de tipos vacíos';

  @override
  String get settingsHideEmptyMediaTypeChevronsSubtitle =>
      'Oculta los selectores de tipo de medio (Juegos, Películas, etc.) cuando no hay elementos de ese tipo';

  @override
  String get settingsAlwaysShowSubcategories =>
      'Mostrar siempre las subcategorías';

  @override
  String get settingsAlwaysShowSubcategoriesSubtitle =>
      'Muestra los filtros de subcategoría (plataformas de juego, tipos de anime/manga) sin seleccionar antes su tipo de medio';

  @override
  String get settingsShowPlatformOverlay => 'Portadas con plataforma';

  @override
  String get settingsShowPlatformOverlaySubtitle =>
      'Muestra la plataforma sobre los pósteres de juegos (PS5, Switch, etc.)';

  @override
  String get settingsShowBlurayOverlay => 'Portadas Blu-ray';

  @override
  String get settingsShowBlurayOverlaySubtitle =>
      'Muestra el marco Blu-ray en los pósteres de películas y series';

  @override
  String get settingsRichCollections => 'Vista enriquecida de colecciones';

  @override
  String get settingsRichCollectionsSubtitle =>
      'Personaliza las colecciones con una imagen de portada y una descripción';

  @override
  String get settingsRichHeroStyle => 'Estilo del banner de colección';

  @override
  String get settingsRichHeroStyleSubtitle =>
      'Aspecto de la cabecera de colección enriquecida';

  @override
  String get settingsRichHeroStyleClassic => 'Clásico';

  @override
  String get settingsRichHeroStyleComic => 'Cómic';

  @override
  String get settingsRichHeroStyleStickers => 'Álbum de pegatinas';

  @override
  String get settingsRichHeroStyleBrutalist => 'Brutalista';

  @override
  String get settingsRichHeroStyleSlats => 'Tiras';

  @override
  String get settingsCardScale => 'Tamaño de portada';

  @override
  String get settingsCardScaleSubtitle =>
      'Tamaño de las tarjetas en las cuadrículas de colecciones';

  @override
  String get collectionEditHeroImage => 'Imagen de portada';

  @override
  String get collectionEditHeroImageHint =>
      'Recomendado 2560×1080 (21:9). El sujeto principal a la derecha — el lado izquierdo lo cubre el título y la parte inferior se funde con el fondo';

  @override
  String get collectionEditHeroPick => 'Elegir imagen';

  @override
  String get collectionEditHeroReplace => 'Sustituir imagen';

  @override
  String get collectionEditHeroRemove => 'Quitar imagen';

  @override
  String get collectionEditDescriptionHint =>
      'Lema corto mostrado sobre la portada';

  @override
  String get collectionEditDialogTitle => 'Ajustes de la colección';

  @override
  String get settingsDiscordRpc => 'Discord Rich Presence';

  @override
  String get settingsDiscordRpcSubtitle =>
      'Muestra el elemento que estás viendo en tu estado de Discord';

  @override
  String get settingsDiscordRaSync => 'Sincronizar RetroAchievements';

  @override
  String get settingsDiscordRaSyncSubtitle =>
      'Muestra en su lugar tu actividad de RetroAchievements en Discord';

  @override
  String get uncategorizedBanner =>
      'Añádelo a una colección para desbloquear el tablero y el seguimiento de episodios';

  @override
  String get uncategorizedDeprecationNotice =>
      'Esta colección del sistema se eliminará pronto. Crea tu propia colección y mueve a ella todos los elementos de esta.';

  @override
  String get uncategorizedDeprecationBadge => 'Se eliminará';

  @override
  String get browseFilterGenre => 'Género';

  @override
  String get browseFilterLength => 'Duración';

  @override
  String get vndbLengthVeryShort => 'Muy corta';

  @override
  String get vndbLengthShort => 'Corta';

  @override
  String get vndbLengthMedium => 'Media';

  @override
  String get vndbLengthLong => 'Larga';

  @override
  String get vndbLengthVeryLong => 'Muy larga';

  @override
  String get browseFilterAnimeAdaptation => 'Adaptación al anime';

  @override
  String get vndbHasAnimeAdaptation => 'Con adaptación';

  @override
  String get tagPickerTitle => 'Seleccionar etiquetas';

  @override
  String get tagPickerSearchHint => 'Buscar etiquetas';

  @override
  String get tagPickerShowSpoilers => 'Mostrar etiquetas con spoilers';

  @override
  String get tagPickerShowAdult => 'Mostrar etiquetas +18';

  @override
  String get tagPickerRefresh => 'Actualizar catálogo';

  @override
  String get tagPickerEmpty => 'No se encontraron etiquetas';

  @override
  String get studioLabel => 'Estudio';

  @override
  String get studioPickerTitle => 'Seleccionar estudio';

  @override
  String get studioPickerSearchHint => 'Buscar estudios';

  @override
  String get studioPickerTypeToSearch => 'Escribe el nombre del estudio';

  @override
  String get studioPickerEmpty => 'No se encontraron estudios';

  @override
  String get studioFilterExclusiveHint =>
      'Mientras haya un estudio seleccionado, los demás filtros y el texto de búsqueda se ignoran';

  @override
  String filterBlockedBy(String filter) {
    return 'No disponible mientras $filter esté activo';
  }

  @override
  String get clearAll => 'Limpiar todo';

  @override
  String get browseFilterSeason => 'Temporada';

  @override
  String get browseFilterGameMode => 'Modo de juego';

  @override
  String get browseFilterMinRating => 'Valoración mín.';

  @override
  String get browseFilterMinVotes => 'Votos mín.';

  @override
  String get seasonWinter => 'Invierno';

  @override
  String get seasonSpring => 'Primavera';

  @override
  String get seasonSummer => 'Verano';

  @override
  String get seasonFall => 'Otoño';

  @override
  String get animeFormatTv => 'TV';

  @override
  String get animeFormatMovie => 'Película';

  @override
  String get animeFormatOva => 'OVA';

  @override
  String get animeFormatOna => 'ONA';

  @override
  String get animeFormatSpecial => 'Especial';

  @override
  String get animeFormatTvShort => 'Corto de TV';

  @override
  String get mangaStatusPublishing => 'En publicación';

  @override
  String get mangaStatusFinished => 'Finalizado';

  @override
  String get mangaStatusNotYetPublished => 'Aún sin publicar';

  @override
  String get mangaStatusCancelled => 'Cancelado';

  @override
  String get mangaStatusHiatus => 'En pausa';

  @override
  String get gameModeSinglePlayer => 'Un jugador';

  @override
  String get gameModeMultiplayer => 'Multijugador';

  @override
  String get gameModeCoOperative => 'Cooperativo';

  @override
  String get gameModeSplitScreen => 'Pantalla dividida';

  @override
  String get gameModeMmo => 'MMO';

  @override
  String get gameModeBattleRoyale => 'Battle Royale';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageJapanese => 'Japonés';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageChinese => 'Chino';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languageRussian => 'Ruso';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get mangaFormatManhwa => 'Manhwa';

  @override
  String get mangaFormatManhua => 'Manhua';

  @override
  String get mangaFormatOneShot => 'One-shot';

  @override
  String get mangaFormatNovel => 'Novela';

  @override
  String get mangaFormatLightNovel => 'Novela ligera';

  @override
  String get browseFilterContentRating => 'Clasificación de contenido';

  @override
  String get browseFilterDemographic => 'Demografía';

  @override
  String get contentRatingSafe => 'Seguro';

  @override
  String get contentRatingSuggestive => 'Sugerente';

  @override
  String get contentRatingErotica => 'Erótico';

  @override
  String get contentRatingPornographic => 'Pornográfico';

  @override
  String get browseSortRelevance => 'Relevancia';

  @override
  String get browseSortPopular => 'Popular';

  @override
  String get browseSortTopRated => 'Mejor valorados';

  @override
  String get browseSortNewest => 'Más recientes';

  @override
  String get browseSortMostVoted => 'Más votados';

  @override
  String get browseSortMostRead => 'Más leídos';

  @override
  String get browseSortTrending => 'Tendencias';

  @override
  String get browseSortNameAsc => 'Nombre (A–Z)';

  @override
  String get browseSortNameDesc => 'Nombre (Z–A)';

  @override
  String get browseSortRecentlyUpdated => 'Actualizados recientemente';

  @override
  String get browseSortRecentlyAdded => 'Añadidos recientemente';

  @override
  String get browseAnimeTypeSeries => 'Series';

  @override
  String get browseAnimeTypeMovies => 'Películas';

  @override
  String get browseEmptyFilters => 'Elige un filtro o busca';

  @override
  String get browseBackToBrowse => 'Volver a explorar';

  @override
  String get browseSortDisabledHint =>
      'Orden no disponible durante la búsqueda de texto';

  @override
  String get animeStatusAiring => 'En emisión';

  @override
  String get animeStatusFinished => 'Finalizado';

  @override
  String get animeStatusNotYetAired => 'Aún sin emitir';

  @override
  String get animeStatusCancelled => 'Cancelado';

  @override
  String get typeToFilterHint => 'Filtrar...';

  @override
  String get appBarSearchHint => 'Empieza a escribir para buscar';

  @override
  String get insertLink => 'Insertar enlace';

  @override
  String get linkText => 'Texto';

  @override
  String get linkHint => 'Guía';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'https://example.com';

  @override
  String get markdownBold => 'Negrita';

  @override
  String get markdownItalic => 'Cursiva';

  @override
  String get insert => 'Insertar';

  @override
  String get navTierLists => 'Tier Lists';

  @override
  String get tierListCreate => 'Nueva tier list';

  @override
  String get tierListCreateFromCollection => 'Crear tier list';

  @override
  String get tierListNameHint => 'Nombre de la tier list';

  @override
  String get tierListScopeAll => 'Todos los elementos';

  @override
  String get tierListScopeCollection => 'De una colección';

  @override
  String tierListFromCollection(String name) {
    return 'De: $name';
  }

  @override
  String tierListRankedCount(int count) {
    return '$count clasificados';
  }

  @override
  String get tierListTitle => 'Tier List';

  @override
  String get tierListUnranked => 'Sin clasificar';

  @override
  String get exportAsImage => 'Exportar como imagen';

  @override
  String get tierListImageSaved => 'Tier list guardada como imagen';

  @override
  String get tierListRename => 'Renombrar nivel';

  @override
  String get tierListChangeColor => 'Cambiar color';

  @override
  String get tierListMoveUp => 'Subir';

  @override
  String get tierListMoveDown => 'Bajar';

  @override
  String get tierListDeleteTier => 'Eliminar nivel';

  @override
  String get tierListAddTier => 'Añadir nivel';

  @override
  String get tierListClearConfirm =>
      '¿Quitar todos los elementos de los niveles? Volverán a Sin clasificar.';

  @override
  String get tierListDeleteConfirm => '¿Eliminar esta tier list?';

  @override
  String get tierListEmpty => 'Aún no hay tier lists';

  @override
  String get tierListEmptyHint =>
      'Toca + para crear una tier list y clasificar elementos\nde tus colecciones.';

  @override
  String get tierListAllRanked => '¡Todos los elementos clasificados!';

  @override
  String get tierListErrorEmptyName => 'Introduce un nombre para la tier list';

  @override
  String get tierListErrorNoCollection => 'Selecciona una colección';

  @override
  String get collectionPickerFilter => 'Filtrar colecciones...';

  @override
  String get collectionPickerAlreadyAdded => '✓ Añadido';

  @override
  String collectionPickerAlreadyInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ya está en $count colecciones',
      one: 'Ya está en $count colección',
    );
    return '$_temp0';
  }

  @override
  String get settingsSteamImport => 'Biblioteca de Steam';

  @override
  String get settingsSteamImportSubtitle => 'Importa juegos vía Steam Web API';

  @override
  String get settingsIgdbImport => 'Lista de IGDB';

  @override
  String get settingsIgdbImportSubtitle =>
      'Importa una lista de juegos exportada de IGDB (CSV)';

  @override
  String get igdbImportTitle => 'Importar lista de IGDB';

  @override
  String get igdbImportDescription =>
      'Elige una lista CSV exportada de IGDB. Los juegos se emparejan por su id de IGDB; lo que IGDB ya no tiene va a la lista de deseos.';

  @override
  String get igdbImportSelectCsvFile => 'Seleccionar archivo CSV';

  @override
  String get igdbImportSelectCsvExport => 'Selecciona el CSV exportado de IGDB';

  @override
  String get igdbImportStatusLabel => 'Estado para los juegos importados';

  @override
  String get igdbImportPlatformSelect => 'Seleccionar plataforma';

  @override
  String get importIgdbRequired =>
      'Se requiere conexión con IGDB. Configura primero las claves API en Ajustes → Credenciales.';

  @override
  String get importing => 'Importando...';

  @override
  String get igdbReasonNotFound => 'No encontrado en IGDB';

  @override
  String get steamImportTitle => 'Importar biblioteca de Steam';

  @override
  String get importIgdbMatchNote =>
      'Los juegos se emparejarán con la base de datos de IGDB';

  @override
  String get steamImportApiKey => 'Clave API de Steam';

  @override
  String get steamImportApiKeyHint =>
      'Obtén una clave gratis en steamcommunity.com/dev/apikey';

  @override
  String get steamImportSteamId => 'Steam ID (64 bits)';

  @override
  String get steamImportSteamIdHint => 'Encuéntralo en steamidfinder.com';

  @override
  String get steamImportPublicWarning => 'Tu perfil de Steam debe ser público';

  @override
  String get steamImportButton => 'Importar biblioteca';

  @override
  String get steamImportFetchingLibrary =>
      'Obteniendo la biblioteca de Steam...';

  @override
  String get steamImportMatching => 'Emparejando juegos en IGDB...';

  @override
  String steamImportLookingUp(String name) {
    return 'Buscando: $name';
  }

  @override
  String steamImportImported(int count) {
    return 'Importados: $count';
  }

  @override
  String steamImportWishlisted(int count) {
    return 'Añadidos a la lista de deseos: $count';
  }

  @override
  String steamImportUpdated(int count) {
    return 'Actualizados: $count';
  }

  @override
  String get importComplete => '¡Importación completada!';

  @override
  String steamImportGamesImported(int count) {
    return '$count juegos importados';
  }

  @override
  String steamImportWishlistedInIgdb(int count) {
    return '$count añadidos a la lista de deseos';
  }

  @override
  String steamImportUpdatedDuplicates(int count) {
    return '$count actualizados (existentes)';
  }

  @override
  String get steamImportPlayedStatus =>
      'Los juegos jugados se marcan como \"En curso\"';

  @override
  String get steamImportPlaytimeComment =>
      'El tiempo de juego se guarda en los comentarios';

  @override
  String get openCollection => 'Abrir colección';

  @override
  String get steamImportRememberCredentials => 'Recordar credenciales';

  @override
  String get collectionListSortCreatedDate => 'Fecha de creación';

  @override
  String get collectionListSortAlphabeticalAZ => 'De la A a la Z';

  @override
  String get collectionListSortAlphabeticalZA => 'De la Z a la A';

  @override
  String get collectionListViewGrid => 'Vista de cuadrícula';

  @override
  String get collectionListViewList => 'Vista de lista';

  @override
  String get collectionListViewTable => 'Vista de tabla';

  @override
  String get collectionTableExternalRating => 'Externa';

  @override
  String get collectionCopyToCollection => 'Copiar a colección';

  @override
  String collectionItemCopiedTo(Object collection, Object name) {
    return '$name copiado a $collection';
  }

  @override
  String collectionItemAlreadyInTarget(Object collection, Object name) {
    return '$name ya está en $collection';
  }

  @override
  String get openInCollection => 'Abrir en la colección';

  @override
  String get importResultTitle => 'Resultados de la importación';

  @override
  String importResultComplete(String source) {
    return '¡Importación de $source completada!';
  }

  @override
  String importResultFailed(String source) {
    return 'La importación de $source falló';
  }

  @override
  String get importResultImported => 'Importados';

  @override
  String get importResultWishlisted => 'Añadidos a la lista de deseos';

  @override
  String get importResultUpdated => 'Actualizados';

  @override
  String importResultErrors(int count) {
    return 'Errores ($count)';
  }

  @override
  String get importResultErrorsCopied => 'Errores copiados';

  @override
  String importResultSkipped(int count) {
    return '$count omitidos';
  }

  @override
  String get importResultOpenCollection => 'Abrir colección';

  @override
  String get importResultWishlistHint =>
      'Los elementos no encontrados en la base de datos se guardaron en tu lista de deseos.';

  @override
  String get importResultSourceCollectionFile => 'Archivo de colección';

  @override
  String get settingsBrowseCollections => 'Explorar colecciones';

  @override
  String get settingsBrowseCollectionsSubtitle =>
      'Descarga colecciones ya preparadas';

  @override
  String browseCollectionsSummary(int count, int items) {
    return '$count colecciones, $items elementos';
  }

  @override
  String get browseCollectionsSearch => 'Buscar colecciones...';

  @override
  String get browseCollectionsAllCategories => 'Todas las categorías';

  @override
  String browseCollectionsItems(int count) {
    return '$count elementos';
  }

  @override
  String get browseCollectionsFormatLight => 'Ligera (requiere claves API)';

  @override
  String get browseCollectionsFormatFull => 'Completa (sin conexión)';

  @override
  String get browseCollectionsDownloading => 'Descargando...';

  @override
  String browseCollectionsImportSuccess(String name) {
    return 'Colección importada: $name';
  }

  @override
  String get browseCollectionsEmpty => 'No se encontraron colecciones';

  @override
  String get browseCollectionsLoadError =>
      'No se pudieron cargar las colecciones';

  @override
  String get browseCollectionsImportTarget => 'Importar a';

  @override
  String get browseCollectionsNewCollection => 'Nueva colección';

  @override
  String get browseCollectionsExistingCollection => 'Colección existente';

  @override
  String get noCollectionsYet => 'Aún no hay colecciones';

  @override
  String get settingsRaImport => 'RetroAchievements';

  @override
  String get settingsRaImportSubtitle => 'Importa juegos de RetroAchievements';

  @override
  String get raImportTitle => 'Importación de RetroAchievements';

  @override
  String get raGetApiKey =>
      'Obtén tu clave API en retroachievements.org/controlpanel.php';

  @override
  String get raImportOptionWishlist =>
      'Añadir juegos sin coincidencia a la lista de deseos';

  @override
  String get raImportFetchingLibrary => 'Obteniendo la biblioteca de RA...';

  @override
  String get raImportSearchingIgdb => 'Buscando juegos en IGDB...';

  @override
  String raImportMatching(String title) {
    return 'Emparejando: $title';
  }

  @override
  String raImportAdded(int count) {
    return '$count juegos añadidos';
  }

  @override
  String raImportUpdated(int count) {
    return '$count juegos actualizados';
  }

  @override
  String raImportToWishlist(int count) {
    return '$count añadidos a la lista de deseos';
  }

  @override
  String raConnectionFailed(String error) {
    return 'Fallo de conexión: $error';
  }

  @override
  String raProfilePoints(int points) {
    return '$points puntos';
  }

  @override
  String raProfileMemberSince(String date) {
    return 'Miembro desde $date';
  }

  @override
  String get raRefresh => 'Actualizar logros';

  @override
  String get raOpenOnRa => 'Abrir en RA ↗';

  @override
  String get raHardcore => 'Hardcore';

  @override
  String get raCompletion => 'Completado';

  @override
  String get raRecentUnlocks => 'Desbloqueos recientes';

  @override
  String get raUpNext => 'A continuación';

  @override
  String raViewAll(int count) {
    return 'Ver los $count logros →';
  }

  @override
  String get raMastered => 'Dominado';

  @override
  String get raHardcoreMastered => 'Dominado en Hardcore';

  @override
  String get raBeaten => 'Superado';

  @override
  String get raBeatenSoftcore => 'Superado en Softcore';

  @override
  String get raHardcoreBeaten => 'Superado en Hardcore';

  @override
  String get raYesterday => 'Ayer';

  @override
  String raDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String get raPoints => 'pts';

  @override
  String get raAchievements => 'logros';

  @override
  String get raMissable => 'PERDIBLE';

  @override
  String get raFilterEarned => 'Obtenidos';

  @override
  String get raFilterLocked => 'Bloqueados';

  @override
  String get raFilterMissable => 'Perdibles';

  @override
  String get raFilterProgression => 'Progresión';

  @override
  String get raFilterWinCondition => 'Condición de victoria';

  @override
  String get raBeatenProgress => 'Progreso de superación';

  @override
  String get raStatsAchievements => 'logros';

  @override
  String get raStatsWorth => 'por valor de';

  @override
  String get raStatsPoints => 'puntos';

  @override
  String get raStatsUnlocked => 'Desbloqueados';

  @override
  String get copyAsText => 'Copiar como texto…';

  @override
  String copiedToClipboard(int count) {
    return '$count elementos copiados al portapapeles';
  }

  @override
  String get template => 'Plantilla';

  @override
  String get textExportTokens => 'Tokens';

  @override
  String get textExportSortBy => 'Ordenar por';

  @override
  String get textExportSortCurrent => 'Orden actual';

  @override
  String get textExportSortName => 'Nombre A→Z';

  @override
  String get textExportSortYear => 'Año ↓';

  @override
  String get textExportSortAdded => 'Fecha de adición ↓';

  @override
  String get textExportEmptyTemplate => 'La plantilla está vacía';

  @override
  String get filtersClear => 'Limpiar';

  @override
  String get collectionTableColumns => 'Columnas';

  @override
  String get tableFilterHint => 'Todas las reglas se aplican juntas (AND).';

  @override
  String get tableFilterAddRule => 'Añadir regla';

  @override
  String get tableFilterCondContains => 'Contiene';

  @override
  String get tableFilterCondEquals => 'Es igual a';

  @override
  String get tableFilterCondStartsWith => 'Empieza por';

  @override
  String get tableFilterCondEndsWith => 'Termina en';

  @override
  String get tableFilterCondAtLeast => 'Al menos (≥)';

  @override
  String get tableFilterCondAtMost => 'Como máximo (≤)';

  @override
  String get profiles => 'Perfiles de la aplicación';

  @override
  String currentProfile(String name) {
    return 'Actual: $name';
  }

  @override
  String get switchProfile => 'Cambiar de perfil';

  @override
  String get addProfile => 'Añadir perfil';

  @override
  String get createProfile => 'Crear perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get deleteProfile => 'Eliminar perfil';

  @override
  String deleteProfileConfirm(String name) {
    return '¿Eliminar el perfil $name? Se eliminarán todas las colecciones, la lista de deseos y los ajustes. Esto no se puede deshacer.';
  }

  @override
  String get cannotDeleteLastProfile => 'No se puede eliminar el último perfil';

  @override
  String get profileName => 'Nombre';

  @override
  String get whoIsPlayingToday => '¿Quién juega hoy?';

  @override
  String get dontAskAgain => 'No volver a preguntar';

  @override
  String profileStats(int collections, int items) {
    return '$collections colecciones, $items elementos';
  }

  @override
  String get switchingProfile => 'Cambiando de perfil…';

  @override
  String get appWillRestart =>
      'La aplicación se reiniciará para aplicar los cambios.';

  @override
  String get profileCreated => 'Perfil creado';

  @override
  String get profileDeleted => 'Perfil eliminado';

  @override
  String get settingsIntegrations => 'Integraciones';

  @override
  String get settingsKodiSubtitle =>
      'Sincronización de visionados desde el reproductor Kodi';

  @override
  String get settingsOn => 'Activado';

  @override
  String get kodiConnectionTitle => 'Conexión';

  @override
  String get kodiConnectionSubtitle =>
      'Kodi HTTP JSON-RPC (Ajustes → Servicios → Control)';

  @override
  String get kodiHost => 'Host';

  @override
  String get kodiPort => 'Puerto';

  @override
  String get kodiPassword => 'Contraseña';

  @override
  String get kodiPasswordHint => 'Introduce la contraseña';

  @override
  String get kodiTestConnection => 'Probar conexión';

  @override
  String get kodiConnecting => 'Conectando…';

  @override
  String get kodiPingFailed => 'Ping fallido — respuesta inesperada';

  @override
  String kodiConnectedTo(String version, String name) {
    return 'Kodi $version \"$name\"';
  }

  @override
  String get kodiSyncTitle => 'Sincronización';

  @override
  String get kodiTargetCollectionSubtitle =>
      'Todas las películas de Kodi se sincronizan aquí';

  @override
  String get kodiTargetNotSelected => 'Sin seleccionar';

  @override
  String kodiTargetDeletedLabel(int id) {
    return 'Eliminada (#$id)';
  }

  @override
  String get kodiEnableSync => 'Activar la sincronización con Kodi';

  @override
  String get kodiEnableSyncActiveSubtitle =>
      'Activa mientras Tonkatsu está en ejecución';

  @override
  String get kodiEnableSyncDisabledSubtitle =>
      'Selecciona primero una colección de destino';

  @override
  String get kodiSyncInterval => 'Intervalo de sincronización';

  @override
  String get kodiCreateSubCollections =>
      'Crear subcolecciones a partir de las sagas de Kodi';

  @override
  String get kodiCreateSubCollectionsSubtitle =>
      'P. ej. \"Harry Potter Collection (kodi)\"';

  @override
  String get kodiImportRatings => 'Importar valoraciones de Kodi';

  @override
  String get kodiImportRatingsSubtitle => 'Copia el userrating de Kodi (1–10)';

  @override
  String get kodiCollectionLibraryName => 'Biblioteca de Kodi';

  @override
  String kodiCollectionCreated(String name) {
    return 'Creada \"$name\"';
  }

  @override
  String get kodiTargetDeletedSnack =>
      'Colección de destino eliminada — sincronización detenida';

  @override
  String get kodiSyncStatus => 'Estado de la sincronización';

  @override
  String get kodiSyncRunning => 'En ejecución';

  @override
  String get kodiSyncStopped => 'Detenida';

  @override
  String get kodiLastSyncNever => 'Nunca';

  @override
  String get kodiClearLastSync => 'Borrar la marca de última sincronización';

  @override
  String get kodiClearLastSyncSubtitle =>
      'La próxima sincronización obtendrá todos los elementos vistos';

  @override
  String get kodiLastSyncCleared => 'Marca de última sincronización borrada';

  @override
  String kodiRequestLog(int count) {
    return 'Registro de solicitudes ($count)';
  }

  @override
  String get kodiCopyLog => 'Copiar registro';

  @override
  String get kodiLogCopied => 'Registro copiado';

  @override
  String get kodiClearLog => 'Borrar registro';

  @override
  String get kodiNoRequests => 'Aún no hay solicitudes';

  @override
  String get kodiRawJsonRpc => 'JSON-RPC directo';

  @override
  String get kodiMethod => 'Método';

  @override
  String get kodiParams => 'Parámetros (JSON)';

  @override
  String get kodiSend => 'Enviar';

  @override
  String get kodiCopyToClipboard => 'Copiar al portapapeles';

  @override
  String get kodiCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get kodiParamsNotObject => 'Error: params debe ser un objeto JSON';

  @override
  String kodiJsonParseError(String message) {
    return 'Error al analizar JSON: $message';
  }

  @override
  String kodiRawError(String message) {
    return 'Error: $message';
  }

  @override
  String get settingsMalImport => 'MyAnimeList';

  @override
  String get settingsMalImportSubtitle =>
      'Importa listas de anime/manga desde una exportación XML';

  @override
  String get malImportTitle => 'Importación de MyAnimeList';

  @override
  String get malImportSubtitle =>
      'El anime y el manga se emparejarán con AniList';

  @override
  String get malImportPickFiles => 'Añadir archivo XML';

  @override
  String get malImportFilesHint =>
      'Exporta el XML desde myanimelist.net/panel.php?go=export';

  @override
  String get importAnimeList => 'Lista de anime';

  @override
  String get importMangaList => 'Lista de manga';

  @override
  String malImportEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '$_temp0';
  }

  @override
  String get malImportReadingFiles => 'Leyendo archivos...';

  @override
  String get malImportResolvingAnime => 'Resolviendo anime en AniList';

  @override
  String get malImportResolvingManga => 'Resolviendo manga en AniList';

  @override
  String malImportWishlisted(int count) {
    return '$count a la lista de deseos';
  }

  @override
  String get malImportOverwriteExisting => 'Sobrescribir entradas existentes';

  @override
  String get malImportOverwriteExistingHint =>
      'Si está desactivado, los elementos que ya están en la colección conservan tu estado, valoración, progreso, fechas y notas locales. Los elementos nuevos se importan igualmente.';

  @override
  String malImportFailedLookup(int count) {
    return '$count omitidos (AniList inaccesible)';
  }

  @override
  String malImportRateLimitWait(int seconds, int attempt, int max) {
    return 'Límite de AniList alcanzado — reintentando en ${seconds}s (intento $attempt/$max)';
  }

  @override
  String malImportInvalidFile(String error) {
    return 'No se pudo analizar el XML: $error';
  }

  @override
  String malImportFilePicked(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return 'Elegido: $kind ($_temp0)';
  }

  @override
  String get settingsAniListImport => 'AniList';

  @override
  String get settingsAniListImportSubtitle =>
      'Importa listas de anime/manga por nombre de usuario público';

  @override
  String get settingsHardcoverImportSubtitle =>
      'Importa una biblioteca de libros de hardcover.app por nombre de usuario';

  @override
  String get hardcoverImportTitle => 'Importación de Hardcover';

  @override
  String get hardcoverImportSubtitle =>
      'Obtiene la biblioteca de un usuario de hardcover.app — la parte pública para otros usuarios, todo para tu propia cuenta';

  @override
  String get hardcoverImportTokenMissing =>
      'El token de la API de Hardcover no está configurado. Añádelo en Ajustes → Credenciales de API.';

  @override
  String get aniListImportTitle => 'Importación de AniList';

  @override
  String get aniListImportSubtitle =>
      'Obtiene listas públicas de anilist.co — sin iniciar sesión';

  @override
  String get aniListImportUsername => 'Nombre de usuario de AniList';

  @override
  String get aniListImportInclude => 'Qué importar';

  @override
  String get aniListImportModeOverwriteSubtitle =>
      'Actualizar progreso, estado y fechas desde AniList';

  @override
  String aniListImportNewCollectionDefault(String username) {
    return 'Importación de AniList — $username';
  }

  @override
  String get aniListImportFetchingAnime => 'Obteniendo la lista de anime...';

  @override
  String get aniListImportFetchingManga => 'Obteniendo la lista de manga...';

  @override
  String aniListImportUserNotFound(String username) {
    return 'No se encontró al usuario de AniList \"$username\"';
  }

  @override
  String aniListImportPrivateProfile(String username) {
    return 'El perfil de AniList \"$username\" es privado';
  }

  @override
  String get aniListImportEmptyUsername =>
      'Introduce tu nombre de usuario de AniList';

  @override
  String get aniListImportSelectAtLeastOne =>
      'Selecciona anime o manga para importar';

  @override
  String get settingsCustomCardsImport => 'Tarjetas personalizadas';

  @override
  String get settingsCustomCardsImportSubtitle =>
      'Importa tarjetas desde un archivo JSON o CSV';

  @override
  String get customImportTitle => 'Importar tarjetas personalizadas';

  @override
  String get customImportDescription =>
      'Carga un archivo JSON o CSV generado por tu propio script o parser — cada fila se convierte en una tarjeta personalizada. Descarga una plantilla para ver todos los campos y valores admitidos.';

  @override
  String get customImportSelectFile => 'Seleccionar archivo JSON/CSV';

  @override
  String get customImportCsvTemplate => 'Plantilla CSV';

  @override
  String get customImportJsonTemplate => 'Plantilla JSON';

  @override
  String get customImportTemplateSaved => 'Plantilla guardada';

  @override
  String get customImportPreviewButton => 'Vista previa e importar';

  @override
  String get customImportPreviewTitle => 'Vista previa de la importación';

  @override
  String customImportSummary(int valid, int errors, int duplicates) {
    return 'Reconocidos $valid · Errores $errors · Duplicados $duplicates';
  }

  @override
  String get customImportSelectNone => 'Deseleccionar todo';

  @override
  String customImportSelectedCount(int selected, int total) {
    return '$selected de $total seleccionados';
  }

  @override
  String get customImportDuplicate => 'Duplicado — ya está en la colección';

  @override
  String customImportRowLabel(int index) {
    return 'Fila $index';
  }

  @override
  String get customImportStart => 'Importar seleccionados';

  @override
  String get customImportImporting => 'Importando tarjetas personalizadas...';

  @override
  String get customImportErrorEmptyFile => 'El archivo está vacío';

  @override
  String get customImportErrorInvalidJson =>
      'JSON no válido — no se pudo analizar el archivo';

  @override
  String get customImportErrorMissingColumns =>
      'El CSV debe tener las columnas \"title\" y \"type\"';

  @override
  String get customImportIssueNotAnObject => 'No es un objeto JSON';

  @override
  String get customImportIssueMissingTitle => 'Falta \"title\"';

  @override
  String get customImportIssueMissingType => 'Falta \"type\"';

  @override
  String customImportIssueUnknownType(String value) {
    return 'Tipo desconocido: $value';
  }

  @override
  String customImportIssueInvalidNumber(String field, String value) {
    return 'Valor no válido en \"$field\": $value';
  }

  @override
  String customImportIssueUnknownStatus(String value) {
    return 'Estado desconocido: $value';
  }

  @override
  String customImportIssueUnknownFormat(String value) {
    return 'Formato desconocido: $value';
  }

  @override
  String get customImportIssueFormatNotApplicable =>
      '\"format\" es solo para manga y anime';

  @override
  String get customImportIssueInvalidCover =>
      '\"cover\" debe ser una URL http(s)';

  @override
  String customImportIssueInvalidDate(String field, String value) {
    return 'Fecha no válida en \"$field\": $value (se espera YYYY-MM-DD)';
  }

  @override
  String customImportIssueInvalidBool(String value) {
    return '\"favorite\" debe ser true/false: $value';
  }

  @override
  String get moodGridCreate => 'Crear Mood Grid';

  @override
  String get moodGridCreateTitle => 'Nuevo Mood Grid';

  @override
  String get moodGridPresetAboutMe => 'Sobre mí: Tonkatsu Box';

  @override
  String get moodGridPresetAboutMeSubtitle =>
      '1×5 — juego, película, serie, anime y manga favoritos';

  @override
  String get moodGridPresetBlank => 'En blanco';

  @override
  String get moodGridPresetBlankSubtitle =>
      'Cuadrícula vacía con el tamaño que elijas';

  @override
  String get moodGridRows => 'Filas';

  @override
  String get moodGridBadge => 'Mood Grid';

  @override
  String get moodGridDeleteTitle => '¿Eliminar esta cuadrícula?';

  @override
  String get moodGridDeleteMessage =>
      'La cuadrícula se eliminará. Esto no se puede deshacer.';

  @override
  String get moodGridAddRow => 'Añadir fila';

  @override
  String get moodGridRemoveRow => 'Quitar fila';

  @override
  String get moodGridAddCol => 'Añadir columna';

  @override
  String get moodGridRemoveCol => 'Quitar columna';

  @override
  String get moodGridShrinkTitle => '¿Reducir la cuadrícula?';

  @override
  String get moodGridShrinkMessage =>
      'Las celdas fuera de los nuevos límites se eliminarán.';

  @override
  String get moodGridShrinkConfirm => 'Reducir';

  @override
  String get moodGridEditLabel => 'Editar etiqueta';

  @override
  String get moodGridLabelHint => 'Nombre de la categoría';

  @override
  String get moodGridPickItem => 'Elegir elemento';

  @override
  String get moodGridReplaceItem => 'Sustituir elemento';

  @override
  String get moodGridClearItem => 'Vaciar celda';

  @override
  String get moodGridCaptionTemplate => 'Leyendas de fila';

  @override
  String get moodGridCaptionTemplateHint =>
      'Plantilla aplicada por celda. Tokens disponibles: name, year, genre, rating.';

  @override
  String get moodGridCellLabelTemplate => 'Etiquetas de celda';

  @override
  String get moodGridCellSize => 'Tamaño';

  @override
  String get collection => 'Colección';

  @override
  String get moodGridPickerAllCollections => 'Todas las colecciones';

  @override
  String get moodGridPickerSearchHint => 'Buscar por nombre';

  @override
  String get moodGridPickerEmpty => 'Nada que elegir';

  @override
  String get screenScraperSection => 'API de ScreenScraper';

  @override
  String get screenScraperSourceDesc =>
      'Metadatos de juegos + medios (portadas, capturas, arte)';

  @override
  String get screenScraperDevCredsHint =>
      'Credenciales de desarrollador (devid / devpassword). El servidor firma cada solicitud con ellas; sin ellas ScreenScraper rechaza.';

  @override
  String get screenScraperDevIdLabel => 'devid';

  @override
  String get screenScraperDevIdPlaceholder =>
      'ID de desarrollador de ScreenScraper';

  @override
  String get screenScraperDevPasswordLabel => 'devpassword';

  @override
  String get screenScraperDevPasswordPlaceholder =>
      'Contraseña de desarrollador de ScreenScraper';

  @override
  String get screenScraperUserCredsHint =>
      'Credenciales de usuario (ssid / sspassword). La cuota es por usuario.';

  @override
  String get screenScraperSsidLabel => 'ssid';

  @override
  String get screenScraperSsidPlaceholder => 'Tu usuario de ScreenScraper';

  @override
  String get screenScraperSspasswordLabel => 'sspassword';

  @override
  String get screenScraperSspasswordPlaceholder =>
      'Tu contraseña de ScreenScraper';

  @override
  String get screenScraperCheckQuota => 'Comprobar cuota';

  @override
  String get screenScraperRequestsToday => 'Solicitudes hoy';

  @override
  String get screenScraperPerMinLimit => 'Límite por minuto';

  @override
  String get screenScraperParallelThreads => 'Hilos en paralelo';

  @override
  String get screenScraperAccountLevel => 'Nivel de cuenta';

  @override
  String get screenScraperGalleryTitle => 'Medios de ScreenScraper';

  @override
  String get screenScraperScreenshotsTitle => 'Capturas de pantalla';

  @override
  String get screenScraperLoading => 'Cargando medios de ScreenScraper…';

  @override
  String screenScraperError(String message) {
    return 'Error de ScreenScraper: $message';
  }

  @override
  String get screenScraperMediaBox => 'Caja';

  @override
  String get screenScraperMediaBoxBack => 'Caja (trasera)';

  @override
  String get screenScraperMediaBox3D => 'Caja 3D';

  @override
  String get screenScraperMediaWheel => 'Wheel';

  @override
  String get screenScraperMediaMarquee => 'Marquesina';

  @override
  String get screenScraperMediaTitle => 'Título';

  @override
  String get screenScraperMediaScreenshot => 'Captura';

  @override
  String get screenScraperMediaFanart => 'Fanart';

  @override
  String get screenScraperMediaMix => 'Mix';

  @override
  String get genreCloudTitle => 'Personalización';

  @override
  String get genreCloudEmpty => 'Aún no hay géneros';

  @override
  String get genreCloudEmptyHint =>
      'Añade elementos con géneros para construir la nube';

  @override
  String get genreCloudExportImage => 'Guardar como imagen';

  @override
  String get genreCloudExportFailed => 'No se pudo guardar la imagen';

  @override
  String get genreCloudResetView => 'Restablecer vista';

  @override
  String genreCloudHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocultos (no cupieron)',
      one: '1 oculto (no cupo)',
    );
    return '$_temp0';
  }

  @override
  String get facetPlatform => 'Plataformas';

  @override
  String get facetDecade => 'Décadas';

  @override
  String get personalizationTabCloud => 'Nube de géneros';

  @override
  String get recommendationsEmpty => 'Aún no hay recomendaciones';

  @override
  String get recommendationsEmptyHint =>
      'Completa y valora algunas películas o series para recibir sugerencias personalizadas';

  @override
  String get recommendationsNoCandidates => 'Nada nuevo que sugerir';

  @override
  String get recommendationsNoCandidatesHint =>
      'No pudimos encontrar nada nuevo que sugerir por ahora. Inténtalo más tarde';

  @override
  String get recommendationsNoApiKey => 'Se requiere la clave API de TMDB';

  @override
  String get recommendationsNoApiKeyHint =>
      'Añade tu clave API de TMDB en Ajustes para recibir recomendaciones';

  @override
  String get recommendationsBecauseLabel => 'Porque te gustó';

  @override
  String recommendationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recomendaciones',
      one: '1 recomendación',
    );
    return '$_temp0';
  }

  @override
  String get itemMarkLike => 'Me gusta';

  @override
  String get itemMarkNote => 'Nota';

  @override
  String get itemMarkNoteHint => 'Escribe una nota…';

  @override
  String get itemMarkSectionTitle => 'Notas y me gusta';

  @override
  String get itemMarkAdd => 'Añadir marca';

  @override
  String get itemMarkEmpty => 'Aún no hay marcas';

  @override
  String get itemMarkNumber => 'Número';

  @override
  String get itemMarkNumberHint => 'p. ej. 12';

  @override
  String get itemMarkNumberHelper => 'Obligatorio para guardar';

  @override
  String get itemMarkCustomType => 'Tipo personalizado';

  @override
  String get itemMarkFilterLiked => 'Con me gusta';

  @override
  String get itemMarkFilterCommented => 'Con notas';

  @override
  String itemMarkUnitLabel(String type, int number) {
    return '$type $number';
  }

  @override
  String itemMarkEpisodeShort(int season, int episode) {
    return 'T$season·E$episode';
  }

  @override
  String get unitEpisode => 'Episodio';

  @override
  String get unitSeason => 'Temporada';

  @override
  String get unitChapter => 'Capítulo';

  @override
  String get unitVolume => 'Volumen';

  @override
  String get unitPage => 'Página';

  @override
  String get unitPart => 'Parte';

  @override
  String get unitTrack => 'Pista';

  @override
  String get cardLinkCopy => 'Copiar enlace de la tarjeta';

  @override
  String get cardLinkCopied => 'Enlace de la tarjeta copiado';

  @override
  String get cardLinkNotFound => 'Tarjeta no encontrada';

  @override
  String get cardLinkSearchTitle => 'Vincular una tarjeta';

  @override
  String get cardLinkSearchHint => 'Buscar tarjetas';

  @override
  String get shortcutsDialogTitle => 'Atajos de teclado';

  @override
  String get shortcutsGroupNavigation => 'Navegación';

  @override
  String get shortcutSwitchTab => 'Cambiar de pestaña';

  @override
  String get shortcutNextTab => 'Pestaña siguiente';

  @override
  String get shortcutPreviousTab => 'Pestaña anterior';

  @override
  String get shortcutThisHelp => 'Esta ayuda';

  @override
  String get shortcutCreateCollection => 'Crear colección';

  @override
  String get shortcutImportCollection => 'Importar colección';

  @override
  String get shortcutToggleView => 'Cambiar vista';

  @override
  String get shortcutDeleteCollection => 'Eliminar colección';

  @override
  String get shortcutRenameCollection => 'Renombrar colección';

  @override
  String get shortcutAddItems => 'Añadir elementos';

  @override
  String get shortcutExportCollection => 'Exportar colección';

  @override
  String get shortcutImportIntoCollection => 'Importar a la colección';

  @override
  String get shortcutToggleBoard => 'Alternar tablero';

  @override
  String get shortcutDeleteItem => 'Eliminar elemento';

  @override
  String get shortcutMoveItem => 'Mover elemento';

  @override
  String get shortcutsGroupItemDetail => 'Detalle del elemento';

  @override
  String get shortcutLockCanvas => 'Bloquear/desbloquear el tablero';

  @override
  String get shortcutMoveToCollection => 'Mover a colección';

  @override
  String get shortcutSetRating => 'Asignar valoración';

  @override
  String get shortcutResetRating => 'Quitar valoración';

  @override
  String get shortcutsGroupTierLists => 'Tier lists';

  @override
  String get shortcutCreateTierList => 'Crear tier list';

  @override
  String get shortcutOpenTierList => 'Abrir tier list';

  @override
  String get shortcutDeleteTierList => 'Eliminar tier list';

  @override
  String get shortcutsGroupTierList => 'Tier list';

  @override
  String get shortcutAddItem => 'Añadir elemento';

  @override
  String get shortcutToggleCompleted => 'Mostrar/ocultar completados';

  @override
  String get shortcutClearCompleted => 'Borrar completados';

  @override
  String get shortcutFocusSearchField => 'Ir al campo de búsqueda';

  @override
  String get shortcutClearOrBack => 'Limpiar / atrás';

  @override
  String get shortcutRunSearch => 'Ejecutar búsqueda';

  @override
  String get debugKeyEvents => 'Eventos de los botones';

  @override
  String get settingsGamepadDebugSubtitle =>
      'Captura los códigos de los botones del mando';

  @override
  String get statsTabTitle => 'Estadísticas';

  @override
  String get statsPeriodAllTime => 'Todo el tiempo';

  @override
  String statsLede(String items) {
    return 'Un total de $items elementos en tu colección';
  }

  @override
  String get statsMetricMoviesWatched => 'películas vistas';

  @override
  String get statsMetricMangaChapters => 'capítulos de manga';

  @override
  String get statsMetricBookPages => 'páginas de libros';

  @override
  String get statsMetricTracks => 'pistas escuchadas';

  @override
  String get statsMetricEpisodes => 'episodios';

  @override
  String get statsMetricHours => 'vistos y jugados';

  @override
  String get statsMetricAvgRating => 'nota media';

  @override
  String get statsMetricReplays => 'repeticiones';

  @override
  String get statsMetricLikedUnits => 'episodios con me gusta';

  @override
  String statsHoursShort(String hours) {
    return '$hours h';
  }

  @override
  String statsHoursBreakdown(int manual, int tracker, int estimated) {
    return 'horas: manual $manual h · trackers $tracker h · estimado $estimated h';
  }

  @override
  String get statsMonthsTitle => 'Tu año, mes a mes';

  @override
  String get statsMonthsTitleAllTime => 'Este año, mes a mes';

  @override
  String get statsMonthsHint => 'portada: el título mejor valorado del mes';

  @override
  String get statsPeakLabel => 'pico';

  @override
  String statsMonthCounts(int items, int episodes) {
    return '$items añadidos · $episodes ep.';
  }

  @override
  String get statsVersusTitle => 'Lo mejor y lo peor';

  @override
  String get statsVersusHint => 'según tus propias notas';

  @override
  String get statsBest => 'Mejor';

  @override
  String get statsWorst => 'Peor';

  @override
  String statsPlatformsSummary(String hours, int games) {
    return '$hours h · $games juegos';
  }

  @override
  String get statsPlatformNone => 'Sin plataforma';

  @override
  String statsPlatformsShowAll(int count) {
    return 'Mostrar todas ($count)';
  }

  @override
  String get statsPlatformsCollapse => 'Contraer';

  @override
  String get statsHoursUnit => 'h';

  @override
  String get statsTypesTitle => 'Biblioteca por tipo';

  @override
  String get statsTypesHint => 'desglose por estado para cada tipo de medio';

  @override
  String statsCompletedPercent(int percent) {
    return '$percent% completado';
  }

  @override
  String get statsPlatformMostPlayed => 'más jugados';

  @override
  String get statsFormatsHint =>
      'el formato proviene de los datos de la fuente';

  @override
  String get statsSubgenresTitle => 'Subgéneros y etiquetas';

  @override
  String get statsSubgenresHint =>
      'las etiquetas de la fuente se muestran por tipo';

  @override
  String get statsCrowdTitle => 'Yo contra todos';

  @override
  String get statsCrowdHint => 'donde mi nota difiere más de la fuente';

  @override
  String get statsCrowdHigher => 'Yo puntúo más alto';

  @override
  String get statsCrowdLower => 'Yo puntúo más bajo';

  @override
  String get statsCrowdMyRating => 'mi nota';

  @override
  String get statsCrowdSource => 'fuente';

  @override
  String get statsTopTitle => 'Mejor valorados';

  @override
  String statsTopHint(int count) {
    return 'los $count mejores';
  }

  @override
  String get statsEmptyTitle => 'Aún no hay estadísticas';

  @override
  String get statsEmptyBody =>
      'Añade elementos a tu biblioteca y aparecerán aquí en cifras.';

  @override
  String get statsExportTitle => 'Exportar tarjeta';

  @override
  String get statsExportFailed => 'No se pudo guardar la imagen';

  @override
  String statsShareTitleYear(int year) {
    return 'Mi $year';
  }

  @override
  String get statsShareTitleAllTime => 'Mi biblioteca';

  @override
  String statsShareLede(String items, String completed, String rating) {
    return '$items elementos · $completed completados · $rating de media';
  }

  @override
  String statsShareBest(String title, String rating) {
    return '$title · $rating — lo mejor del periodo';
  }

  @override
  String get simklImportTitle => 'Importación de Simkl';

  @override
  String get settingsSimklImportSubtitle =>
      'Películas, series y anime desde tu cuenta de Simkl';

  @override
  String get simklImportSubtitle =>
      'Conecta tu cuenta de Simkl con un código corto: películas, series y anime llegan en una sola importación, junto con el historial de episodios';

  @override
  String get simklClientIdLabel => 'Clave de la app de Simkl (client_id)';

  @override
  String get simklGetClientId => 'Obtener un client_id en simkl.com';

  @override
  String get simklRememberClientId => 'Recordar la clave de la app';

  @override
  String get simklGetPin => 'Obtener código';

  @override
  String get simklGetNewPin => 'Obtener un código nuevo';

  @override
  String get simklPinPrompt => 'Introduce este código en simkl.com/pin:';

  @override
  String get simklPinCopied => 'Código copiado';

  @override
  String get simklOpenPinPage => 'Abrir simkl.com/pin';

  @override
  String get simklWaitingConfirmation => 'Esperando confirmación…';

  @override
  String get simklPinExpired => 'El código ha caducado.';

  @override
  String simklConnectedAs(String name) {
    return 'Cuenta conectada: $name';
  }

  @override
  String get simklCheckingAccount => 'Comprobando la cuenta…';

  @override
  String get simklRememberToken => 'Mantener la conexión en este dispositivo';

  @override
  String get simklRememberTokenSubtitle =>
      'El token de acceso se guarda en los ajustes; sin la casilla se pedirá el código de nuevo';

  @override
  String get simklDisconnect => 'Desconectar';

  @override
  String get simklImportFetching => 'Obteniendo la biblioteca de Simkl…';

  @override
  String get simklImportFetchingDetails => 'Obteniendo fichas…';

  @override
  String get simklImportWatchHistory =>
      'Restaurando el historial de visualización…';

  @override
  String simklImportNewCollectionDefault(String name) {
    return 'Simkl: $name';
  }

  @override
  String get simklImportModeOverwriteSubtitle =>
      'Actualizar estado, nota y comentario de los existentes';

  @override
  String get simklClientIdRequired =>
      'La importación necesita una clave de la app de Simkl: introduce tu client_id';

  @override
  String simklImportRateLimitWait(int seconds, int attempt, int max) {
    return 'Límite de peticiones alcanzado: reintento en $seconds s (intento $attempt/$max)';
  }

  @override
  String get searchSourcePodcasts => 'Pódcasts';

  @override
  String get searchHintPodcasts => 'Buscar pódcasts...';

  @override
  String get podcastSheetEpisodes => 'Episodios';

  @override
  String get podcastSheetNoEpisodes => 'Lista de episodios no disponible';

  @override
  String podcastEpisodesCount(int count) {
    return '$count episodios';
  }

  @override
  String get podcastDiscoverTrending => 'Pódcasts en tendencia';

  @override
  String get credentialsPodcastIndexSection => 'API de Podcast Index';

  @override
  String get credentialsEnterPodcastIndexKey =>
      'Introduce tu clave de API de Podcast Index';

  @override
  String get credentialsEnterPodcastIndexSecret =>
      'Introduce tu secreto de API de Podcast Index';

  @override
  String get credentialsPodcastIndexKeyValid =>
      'Las claves de Podcast Index son válidas';

  @override
  String get credentialsPodcastIndexKeyInvalid =>
      'Podcast Index rechazó las claves. Comprueba el par y el reloj del sistema';

  @override
  String get welcomeApiPodcastIndexDesc =>
      'Búsqueda de pódcasts y seguimiento de episodios. Par clave/secreto gratuito de api.podcastindex.org.';

  @override
  String get welcomeSourceDescMusicBrainz =>
      'Enciclopedia musical abierta: álbumes, artistas y ediciones. No requiere clave.';

  @override
  String get welcomeSourceDescPodcastIndex =>
      'Catálogo abierto de pódcasts con seguimiento por episodios. Par clave/secreto gratuito.';

  @override
  String get creditsPodcastIndexAttribution =>
      'Datos de pódcasts de Podcast Index.';

  @override
  String get credentialsApiSecret => 'Secreto de API';

  @override
  String get markAllListened => 'Marcar todo como escuchado';
}

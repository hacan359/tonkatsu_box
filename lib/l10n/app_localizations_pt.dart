// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class SPt extends S {
  SPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Tonkatsu Box';

  @override
  String get navMain => 'Início';

  @override
  String get navCollections => 'Coleções';

  @override
  String get navWishlist => 'Lista de desejos';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navReleases => 'Lançamentos';

  @override
  String get releasesEmpty => 'Nenhuma série acompanhada ainda';

  @override
  String get releasesEmptyHint =>
      'Toque no sino em uma série ou anime para acompanhar novos episódios.';

  @override
  String get releasesTrackShow => 'Acompanhar lançamentos';

  @override
  String get releasesUntrackShow => 'Parar de acompanhar';

  @override
  String get releasesViewDay => 'Dia';

  @override
  String get releasesViewWeek => 'Semana';

  @override
  String get releasesViewMonth => 'Mês';

  @override
  String get releasesTabCalendar => 'Calendário';

  @override
  String get releasesTabAll => 'Todos os lançamentos';

  @override
  String get releasesToday => 'Hoje';

  @override
  String get refresh => 'Atualizar';

  @override
  String get releasesNoEpisodes => 'Sem episódios';

  @override
  String releasesEpisode(int season, int episode) {
    return 'Temporada $season · Episódio $episode';
  }

  @override
  String get calendarAdd => 'Adicionar ao calendário';

  @override
  String get calendarRemove => 'Remover do calendário';

  @override
  String get date => 'Data';

  @override
  String get calendarRepeat => 'Repetir';

  @override
  String get recurrenceOnce => 'Uma vez';

  @override
  String get recurrenceWeekly => 'Semanalmente';

  @override
  String get recurrenceMonthly => 'Mensalmente';

  @override
  String get statusNotStarted => 'Não iniciado';

  @override
  String get statusPlaying => 'Jogando';

  @override
  String get statusWatching => 'Assistindo';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusDropped => 'Abandonado';

  @override
  String get statusPlanned => 'Planejado';

  @override
  String get statusReplay => 'Repetindo';

  @override
  String get rewatchCountEdit => 'Contagem de reassistências';

  @override
  String get rewatchCountHint => 'Vazio = sem acompanhamento';

  @override
  String get statusReplaying => 'Rejogando';

  @override
  String get statusRewatching => 'Reassistindo';

  @override
  String get statusRereading => 'Relendo';

  @override
  String get all => 'Todos';

  @override
  String get mediaTypeGame => 'Jogo';

  @override
  String get mediaTypeMovie => 'Filme';

  @override
  String get mediaTypeTvShow => 'Série';

  @override
  String get mediaTypeAnimation => 'Animação';

  @override
  String get mediaTypeVisualNovel => 'Novela visual';

  @override
  String get mediaTypeManga => 'Manga';

  @override
  String get mediaTypeAnime => 'Anime';

  @override
  String get mediaTypeBook => 'Livro';

  @override
  String get mediaTypeCustom => 'Personalizado';

  @override
  String get sortManualDisplay => 'Manual';

  @override
  String get sortManualDesc => 'Ordem personalizada';

  @override
  String get sortDateDisplay => 'Data de adição';

  @override
  String get sortDateDesc => 'Mais recentes primeiro';

  @override
  String get status => 'Status';

  @override
  String get sortStatusDesc => 'Ativos primeiro';

  @override
  String get name => 'Nome';

  @override
  String get sortNameShort => 'A-Z';

  @override
  String get rating => 'Avaliação';

  @override
  String get sortRatingDesc => 'Maior primeiro';

  @override
  String get sortFavoriteDesc => 'Favoritos primeiro';

  @override
  String get sortExternalRatingDisplay => 'Avaliação externa';

  @override
  String get sortExternalRatingShort => 'IGDB/TMDB';

  @override
  String get sortLastActivityDisplay => 'Última atividade';

  @override
  String get sortLastActivityShort => 'Atividade';

  @override
  String get sortLastActivityDesc => 'Recentes primeiro';

  @override
  String get sortStartDateDisplay => 'Data de início';

  @override
  String get sortStartDateShort => 'Iniciado';

  @override
  String get sortCompletionDateDisplay => 'Data de conclusão';

  @override
  String get sortCompletionDateShort => 'Concluído';

  @override
  String get sortDateOldest => 'Mais antigos primeiro';

  @override
  String get sortStatusFinished => 'Concluídos primeiro';

  @override
  String get sortRatingLowest => 'Menor primeiro';

  @override
  String get sortFavoriteLast => 'Favoritos por último';

  @override
  String get searchSortRelevanceShort => 'Rel.';

  @override
  String get searchSortRatingShort => 'Nota';

  @override
  String get searchSortRatingDisplay => 'Avaliação';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'OK';

  @override
  String get restore => 'Restaurar';

  @override
  String get create => 'Criar';

  @override
  String get save => 'Salvar';

  @override
  String get add => 'Adicionar';

  @override
  String get delete => 'Excluir';

  @override
  String get rename => 'Renomear';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Concluído';

  @override
  String get clear => 'Limpar';

  @override
  String get reset => 'Redefinir';

  @override
  String get search => 'Buscar';

  @override
  String get open => 'Abrir';

  @override
  String get remove => 'Remover';

  @override
  String get moveToTop => 'Mover para o topo';

  @override
  String get moveToBottom => 'Mover para o final';

  @override
  String get favorite => 'Favorito';

  @override
  String get addToFavorites => 'Adicionar aos favoritos';

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String bulkSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get bulkClearSelection => 'Limpar seleção';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get bulkMove => 'Mover selecionados para coleção';

  @override
  String get bulkCopy => 'Copiar selecionados para coleção';

  @override
  String get bulkChangeStatus => 'Alterar status';

  @override
  String bulkRemoveConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Remover $_temp0 desta coleção?';
  }

  @override
  String bulkResult(int done, int skipped) {
    return 'Concluído: $done • Duplicados: $skipped';
  }

  @override
  String bulkRemoved(int count) {
    return 'Removidos: $count';
  }

  @override
  String bulkStatusUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Status atualizado para $_temp0';
  }

  @override
  String get bulkAddTags => 'Adicionar tags';

  @override
  String get bulkRemoveTags => 'Remover tags';

  @override
  String bulkAddTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Adicionar tags a $_temp0';
  }

  @override
  String bulkRemoveTagsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Remover tags de $_temp0';
  }

  @override
  String bulkTagsAdded(int count) {
    return 'Tags adicionadas: $count';
  }

  @override
  String bulkTagsRemoved(int count) {
    return 'Tags removidas: $count';
  }

  @override
  String get bulkTagsUnchanged => 'Nada a alterar';

  @override
  String get bulkExportPngTitle => 'Exportar como PNG';

  @override
  String get columnsCount => 'Colunas';

  @override
  String bulkExportPngItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String bulkExportPngItemsCountPreview(int total, int preview) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total itens',
      one: '1 item',
    );
    return '$_temp0 ($preview na pré-visualização)';
  }

  @override
  String bulkExportPngPreparing(int done, int total) {
    return 'Preparando capas: $done / $total';
  }

  @override
  String get bulkExportPngSave => 'Salvar PNG';

  @override
  String get imageSaved => 'Imagem salva';

  @override
  String get bulkExportPngFailed => 'Falha ao salvar imagem';

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Próximo';

  @override
  String get skip => 'Pular';

  @override
  String get update => 'Atualizar';

  @override
  String get test => 'Testar';

  @override
  String get close => 'Fechar';

  @override
  String get keep => 'Manter';

  @override
  String get change => 'Alterar';

  @override
  String get settingsProfile => 'Autor da coleção';

  @override
  String get settingsProfileSubtitle => 'Nome do autor para suas coleções';

  @override
  String get settingsAuthorName => 'Nome do autor';

  @override
  String get settingsCredentialsSubtitle =>
      'Chaves de API do IGDB, SteamGridDB e TMDB';

  @override
  String get settingsCacheSubtitle => 'Modo offline e armazenamento de capas';

  @override
  String get settingsDatabaseSubtitle => 'Exportar, importar, redefinir';

  @override
  String get settingsTraktImportSubtitle =>
      'Histórico, avaliações, lista de desejos';

  @override
  String get settingsKinoriumImport => 'Importar do Kinorium';

  @override
  String get settingsKinoriumImportSubtitle =>
      'Filmes e séries a partir de uma exportação CSV';

  @override
  String get settingsDebug => 'Depuração';

  @override
  String get settingsDebugSubtitle => 'Ferramentas de desenvolvedor';

  @override
  String get settingsDebugSubtitleNoKey =>
      'Configure a chave do SteamGridDB primeiro para algumas ferramentas';

  @override
  String get settingsLaboratory => 'Laboratório';

  @override
  String get settingsLaboratoryCardDesigns => 'Designs de banner dos cards';

  @override
  String get settingsLaboratoryCardDesignsSubtitle =>
      'Layouts experimentais de cards de pôster';

  @override
  String get settingsHelp => 'Ajuda';

  @override
  String get settingsWelcomeGuide => 'Guia de boas-vindas';

  @override
  String get settingsWelcomeGuideSubtitle =>
      'Primeiros passos com o Tonkatsu Box';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsCreditsLicenses => 'Créditos e licenças';

  @override
  String get settingsChangelog => 'Novidades';

  @override
  String get settingsChangelogEmpty => 'Nenhuma nota de versão disponível';

  @override
  String get settingsCreditsLicensesSubtitle =>
      'TMDB, IGDB, SteamGridDB, licenças de código aberto';

  @override
  String get settingsError => 'Erro';

  @override
  String get settingsAppLanguage => 'Idioma do app';

  @override
  String get settingsConnections => 'Conexões';

  @override
  String get settingsApiKeys => 'Chaves de API';

  @override
  String settingsApiKeysValue(int active, int total) {
    return '$active/$total';
  }

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsAppearanceSubtitle => 'Idioma, exibição e conteúdo';

  @override
  String get settingsAppLanguageSubtitle => 'Idioma da interface';

  @override
  String get settingsContentLanguageSubtitle =>
      'Por enquanto, apenas TMDB (filmes e séries)';

  @override
  String get settingsDataSources => 'Fontes de dados';

  @override
  String get settingsDataSourcesSubtitle => 'IGDB, TMDB, SteamGridDB';

  @override
  String get settingsApiKeysSubtitle =>
      'Configure conexões com bancos de dados';

  @override
  String get settingsStorage => 'Armazenamento';

  @override
  String get settingsStorageSubtitle => 'Cache de imagens e banco de dados';

  @override
  String get settingsBackup => 'Cópia de segurança';

  @override
  String get settingsBackupSubtitle =>
      'Backup e restauração completa dos dados';

  @override
  String get settingsBackupAll => 'Fazer backup de todos os dados';

  @override
  String get settingsBackupAllSubtitle =>
      'Todas as coleções, lista de desejos e configurações';

  @override
  String get settingsRestoreBackup => 'Restaurar do backup';

  @override
  String get settingsRestoreBackupSubtitle => 'Importar arquivo de backup';

  @override
  String backupSuccess(int collections, int items) {
    return 'Backup salvo: $collections coleções, $items itens';
  }

  @override
  String get restoreConfirmTitle => 'Restaurar backup?';

  @override
  String restoreConfirmBody(int collections, int items, int wishlist) {
    return '$collections coleções, $items itens, $wishlist entradas na lista de desejos';
  }

  @override
  String get restoreConfirmHint => 'As coleções existentes não serão afetadas';

  @override
  String get restoreSettings => 'Restaurar configurações';

  @override
  String get restoreWishlist => 'Restaurar lista de desejos';

  @override
  String restoreSuccess(int collections, int items) {
    return 'Restauradas $collections coleções, $items itens';
  }

  @override
  String get restoreInvalidArchive => 'Arquivo de backup inválido';

  @override
  String get restoreProgressTitle => 'Restaurando backup';

  @override
  String get restoreProgressWarning =>
      'Não feche o app. Isso pode levar vários minutos para backups grandes.';

  @override
  String get restoreStageReading => 'Lendo arquivo…';

  @override
  String restoreStageCollections(int current, int total) {
    return 'Restaurando coleções… ($current/$total)';
  }

  @override
  String get restoreStageWishlist => 'Restaurando lista de desejos…';

  @override
  String get restoreStageSettings => 'Restaurando configurações…';

  @override
  String get restoreStageFinalizing => 'Finalizando…';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportSubtitle => 'Importe coleções de serviços externos';

  @override
  String get settingsContentLanguage => 'Idioma do conteúdo';

  @override
  String get settingsData => 'Dados';

  @override
  String settingsCacheValue(String size) {
    return '$size';
  }

  @override
  String get credentialsTitle => 'Credenciais';

  @override
  String get credentialsWelcome => 'Bem-vindo ao Tonkatsu Box!';

  @override
  String get credentialsWelcomeHint =>
      'Para começar, você precisa configurar suas credenciais da API do IGDB. Obtenha seu Client ID e Client Secret no Console de Desenvolvedor da Twitch.';

  @override
  String get credentialsCopyTwitchUrl => 'Copiar URL do Console da Twitch';

  @override
  String credentialsUrlCopied(String url) {
    return 'URL copiada: $url';
  }

  @override
  String get credentialsIgdbSection => 'Credenciais da API do IGDB';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Digite seu Client ID da Twitch';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint =>
      'Digite seu Client Secret da Twitch';

  @override
  String get credentialsConnectionStatus => 'Status da conexão';

  @override
  String get credentialsPlatformsSynced => 'Plataformas sincronizadas';

  @override
  String get credentialsPlatformsAvailable => 'Plataformas disponíveis';

  @override
  String get credentialsLastSync => 'Última sincronização';

  @override
  String get credentialsVerifyConnection => 'Verificar conexão';

  @override
  String get credentialsRefreshPlatforms => 'Atualizar plataformas';

  @override
  String get credentialsSteamGridDbSection => 'API do SteamGridDB';

  @override
  String get credentialsApiKey => 'Chave de API';

  @override
  String get credentialsUsingBuiltInKey => 'Usando chave integrada';

  @override
  String get credentialsEnterSteamGridDbKey =>
      'Digite sua chave de API do SteamGridDB';

  @override
  String get credentialsTmdbSection => 'API do TMDB (Filmes e séries)';

  @override
  String get credentialsEnterTmdbKey => 'Digite sua chave de API do TMDB (v3)';

  @override
  String get credentialsComicVineSection => 'API do ComicVine (Quadrinhos)';

  @override
  String get credentialsEnterComicVineKey =>
      'Digite sua chave de API do ComicVine';

  @override
  String get credentialsGoogleBooksSection => 'API do Google Books (Livros)';

  @override
  String get credentialsEnterGoogleBooksKey =>
      'Digite sua chave de API do Google Books (opcional)';

  @override
  String get credentialsHardcoverSection => 'API do Hardcover (Livros)';

  @override
  String get credentialsEnterHardcoverKey =>
      'Digite seu token da API do Hardcover';

  @override
  String get credentialsOwnKeyHint =>
      'Para limites de uso melhores, recomendamos usar sua própria chave de API.';

  @override
  String get credentialsConnected => 'Conectado';

  @override
  String get credentialsConnectionError => 'Erro de conexão';

  @override
  String get credentialsChecking => 'Verificando...';

  @override
  String get credentialsNotConnected => 'Não conectado';

  @override
  String get credentialsEnterBoth => 'Digite o Client ID e o Client Secret';

  @override
  String get credentialsConnectedSynced =>
      'Conectado e plataformas sincronizadas!';

  @override
  String get credentialsConnectedSyncFailed =>
      'Conectado, mas a sincronização de plataformas falhou';

  @override
  String get credentialsPlatformsSyncedOk =>
      'Plataformas sincronizadas com sucesso!';

  @override
  String get credentialsDownloadingLogos => 'Baixando logos das plataformas...';

  @override
  String credentialsDownloadedLogos(int count) {
    return 'Baixados $count logos';
  }

  @override
  String get credentialsFailedDownloadLogos => 'Falha ao baixar logos';

  @override
  String get credentialsApiKeySaved => 'Chave de API salva';

  @override
  String get credentialsNoApiKey => 'Sem chave de API';

  @override
  String get credentialsResetToBuiltIn => 'Restaurar chave integrada';

  @override
  String get credentialsSteamGridDbKeyValid =>
      'A chave de API do SteamGridDB é válida';

  @override
  String get credentialsSteamGridDbKeyInvalid =>
      'A chave de API do SteamGridDB é inválida';

  @override
  String get credentialsTmdbKeyValid => 'A chave de API do TMDB é válida';

  @override
  String get credentialsTmdbKeyInvalid => 'A chave de API do TMDB é inválida';

  @override
  String get credentialsComicVineKeyValid =>
      'A chave de API do ComicVine é válida';

  @override
  String get credentialsComicVineKeyInvalid =>
      'A chave de API do ComicVine é inválida';

  @override
  String get credentialsGoogleBooksKeyValid =>
      'A chave de API do Google Books é válida';

  @override
  String get credentialsGoogleBooksKeyInvalid =>
      'A chave de API do Google Books é inválida';

  @override
  String get credentialsHardcoverKeyValid =>
      'O token da API do Hardcover é válido';

  @override
  String get credentialsHardcoverKeyInvalid =>
      'O token da API do Hardcover é inválido ou expirou';

  @override
  String get credentialsEnterSteamGridDbKeyError =>
      'Digite uma chave de API do SteamGridDB';

  @override
  String get credentialsEnterTmdbKeyError => 'Digite uma chave de API do TMDB';

  @override
  String get credentialsTmdbKeySaved => 'Chave de API do TMDB salva';

  @override
  String timeAgo(int value, String unit) {
    return 'há $value $unit';
  }

  @override
  String timeUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dias',
      one: 'dia',
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
  String get timeJustNow => 'Agora mesmo';

  @override
  String get cacheTitle => 'Cache';

  @override
  String get cacheImageCache => 'Cache de imagens';

  @override
  String get cacheOfflineMode => 'Modo offline';

  @override
  String get cacheOfflineModeSubtitle =>
      'Salvar imagens localmente para uso offline';

  @override
  String get cacheCacheFolder => 'Pasta do cache';

  @override
  String get cacheSelectFolder => 'Selecionar pasta';

  @override
  String get cacheCacheSize => 'Tamanho do cache';

  @override
  String get cacheClearCache => 'Remover imagens não usadas';

  @override
  String get cacheClearCacheTitle => 'Remover imagens não usadas?';

  @override
  String get cacheClearCacheMessage =>
      'Exclui capas baixadas de mídias que não estão mais em nenhuma coleção. Suas capas personalizadas e imagens do board são mantidas.';

  @override
  String get cacheFolderUpdated => 'Pasta do cache atualizada';

  @override
  String cacheOrphansRemoved(int count) {
    return 'Imagens não usadas removidas: $count';
  }

  @override
  String get cacheSelectFolderDialog =>
      'Selecionar pasta de cache para imagens';

  @override
  String cacheCacheStats(int count, String size) {
    return '$count arquivos, $size';
  }

  @override
  String get databaseTitle => 'Banco de dados';

  @override
  String get databaseConfiguration => 'Configuração';

  @override
  String get databaseConfigSubtitle =>
      'Exporte ou importe suas chaves de API e configurações.';

  @override
  String get databaseExportConfig => 'Exportar configuração';

  @override
  String get databaseImportConfig => 'Importar configuração';

  @override
  String get databaseDangerZone => 'Zona de perigo';

  @override
  String get databaseDangerZoneMessage =>
      'Apaga todas as coleções, jogos, filmes, séries e dados do quadro. As configurações e as chaves de API serão preservadas.';

  @override
  String get databaseResetDatabase => 'Redefinir banco de dados';

  @override
  String get databaseResetTitle => 'Redefinir banco de dados?';

  @override
  String get databaseResetMessage =>
      'Isso excluirá permanentemente todas as suas coleções, jogos, filmes, séries, progresso de episódios e dados do quadro.\n\nSuas chaves de API e configurações serão preservadas.\n\nEsta ação não pode ser desfeita.';

  @override
  String databaseConfigExported(String path) {
    return 'Configuração exportada para $path';
  }

  @override
  String get databaseConfigImported => 'Configuração importada com sucesso';

  @override
  String get databaseReset => 'O banco de dados foi redefinido';

  @override
  String get storageLocationTitle => 'Local dos dados';

  @override
  String get storageLocationSubtitle =>
      'Pasta que armazena o banco de dados e os perfis. Evite pastas sincronizadas em tempo real por serviços na nuvem (OneDrive, Syncthing): o banco de dados pode corromper durante a gravação. Para mover dados entre dispositivos, use a exportação.';

  @override
  String get storageLocationDangerWarning =>
      'Atenção: alterar a pasta de dados pode causar perda de dados. Você faz isso por sua conta e risco.';

  @override
  String get storageLocationFolder => 'Pasta de dados';

  @override
  String get storageLocationFallbackWarning =>
      'A pasta selecionada não está disponível; usando a padrão';

  @override
  String get storageLocationChange => 'Alterar pasta';

  @override
  String get storageLocationReset => 'Restaurar padrão';

  @override
  String get storageLocationSelectDialog => 'Selecionar pasta de dados';

  @override
  String storageLocationNotWritable(String path) {
    return 'Sem permissão de gravação: $path';
  }

  @override
  String get storageLocationPermissionTitle =>
      'Acesso ao armazenamento necessário';

  @override
  String get storageLocationPermissionMessage =>
      'O Android exige a permissão \"Acesso a todos os arquivos\" para uma pasta de dados personalizada. Na lista que abrir, encontre o Tonkatsu Box, ative o acesso e volte para escolher a pasta novamente.';

  @override
  String get storageLocationLegacyPermissionMessage =>
      'Uma pasta de dados personalizada precisa da permissão de Armazenamento. Ative-a nas configurações do app e volte para escolher a pasta novamente.';

  @override
  String get storageLocationOpenSettings => 'Abrir configurações';

  @override
  String get storageLocationDbTooNew =>
      'O banco de dados nesta pasta foi criado por uma versão mais recente do app. Atualize o app neste dispositivo primeiro.';

  @override
  String get storageLocationDbCorrupted =>
      'O banco de dados nesta pasta está corrompido ou incompleto. Se uma ferramenta de sincronização ainda estiver copiando, tente novamente mais tarde.';

  @override
  String get storageLocationUseExistingTitle => 'Dados existentes encontrados';

  @override
  String get storageLocationUseExistingMessage =>
      'A pasta selecionada já contém um banco de dados. O app passará a usar esses dados após reiniciar.';

  @override
  String get storageLocationUseExistingConfirm => 'Usar';

  @override
  String get storageLocationCopyTitle => 'Copiar dados atuais?';

  @override
  String get storageLocationCopyMessage =>
      'A pasta selecionada está vazia. Suas coleções serão copiadas para lá; imagens salvas serão baixadas novamente conforme necessário. Os dados na pasta antiga permanecem intactos.';

  @override
  String get copy => 'Copiar';

  @override
  String get storageLocationCopyImages => 'Copiar o cache de imagens também';

  @override
  String get storageLocationCopyImagesHint =>
      'Banners e capas salvas — ocupa mais espaço, mas a nova pasta funciona offline sem precisar baixar de novo';

  @override
  String get storageLocationCopyError =>
      'Falha ao copiar os dados para a pasta selecionada';

  @override
  String get storageLocationResetTitle => 'Restaurar pasta de dados?';

  @override
  String get storageLocationResetMessage =>
      'O app voltará à pasta de dados padrão após reiniciar. Os dados na pasta personalizada permanecem intactos.';

  @override
  String get storageLocationRestartTitle => 'Reinício necessário';

  @override
  String get storageLocationRestartMessage =>
      'A nova pasta de dados será usada após reiniciar. Reiniciar agora?';

  @override
  String get storageLocationRestartNow => 'Reiniciar';

  @override
  String get storageLocationRestartLater =>
      'A alteração entrará em vigor após reiniciar';

  @override
  String get backupRestoreTile => 'Restaurar banco de dados anterior';

  @override
  String get backupNone => 'Nenhum backup ainda';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar banco de dados anterior?';

  @override
  String backupRestoreConfirmMessage(String date) {
    return 'Os dados atuais serão substituídos pelo backup de $date. Os dados substituídos passam a ser o novo backup, então restaurar novamente desfaz isso.';
  }

  @override
  String get backupRestored => 'Banco de dados restaurado';

  @override
  String get backupRestoreError => 'Falha ao restaurar o backup';

  @override
  String get backupRestartMessage =>
      'Os dados restaurados serão usados após reiniciar. Reiniciar agora?';

  @override
  String get lanSyncTitle => 'Sincronização em rede';

  @override
  String get lanSyncOpenTile => 'Dispositivos próximos';

  @override
  String get lanSyncTileSubtitle =>
      'Transfira dados diretamente entre dispositivos na mesma rede Wi-Fi';

  @override
  String lanSyncVisibleAs(String name) {
    return 'Este dispositivo está visível como $name';
  }

  @override
  String get lanSyncNoDevices =>
      'Nenhum dispositivo encontrado. Abra esta tela nos dois dispositivos conectados à mesma rede Wi-Fi. Isolamento de ponto de acesso e VPNs bloqueiam a descoberta.';

  @override
  String get lanSyncPull => 'Toque para obter os dados';

  @override
  String get lanSyncReceiveTitle => 'Substituir dados?';

  @override
  String lanSyncReceiveMessage(
    String device,
    String date,
    int collections,
    int items,
  ) {
    return 'Dados de $device, $date: $collections coleções, $items itens.\n\nOs dados atuais serão SUBSTITUÍDOS. Uma cópia de backup fica ao lado do banco de dados.';
  }

  @override
  String get lanSyncReplace => 'Substituir';

  @override
  String lanSyncWaiting(String name) {
    return 'Confirme a solicitação em $name...';
  }

  @override
  String get lanSyncIncomingTitle => 'Solicitação de dados';

  @override
  String lanSyncIncomingMessage(String name) {
    return '$name quer obter uma cópia dos seus dados. Permitir?';
  }

  @override
  String get lanSyncAllow => 'Permitir';

  @override
  String get lanSyncDenied => 'O outro dispositivo recusou a solicitação';

  @override
  String get lanSyncManifestError => 'O dispositivo não respondeu';

  @override
  String get lanSyncStartError =>
      'Não foi possível iniciar o compartilhamento em rede. Verifique a conexão de rede e abra esta tela novamente.';

  @override
  String get lanSyncReceiveError => 'Falha ao obter os dados';

  @override
  String get lanSyncTooNew =>
      'Os dados naquele dispositivo foram criados por uma versão mais recente do app. Atualize o app neste dispositivo primeiro.';

  @override
  String get lanSyncCorrupted =>
      'A transferência chegou danificada. Tente novamente.';

  @override
  String get lanSyncReceived => 'Dados recebidos';

  @override
  String get lanSyncReceivingImages => 'Transferindo imagens...';

  @override
  String get lanSyncReceivingSettings => 'Transferindo configurações...';

  @override
  String get lanSyncImportConfig => 'Transferir configurações também';

  @override
  String get lanSyncImportConfigSubtitle =>
      'Inclui chaves de API. Tudo ou nada.';

  @override
  String get lanSyncImagesWarning =>
      'Banco de dados recebido, mas as imagens não puderam ser transferidas';

  @override
  String get lanSyncRestartMessage =>
      'Os dados recebidos serão usados após reiniciar. Reiniciar agora?';

  @override
  String get lanSyncFirewallNote =>
      'O Windows pode pedir permissão do firewall na primeira execução — permita o acesso em redes privadas.';

  @override
  String get folderPickerNewFolder => 'Nova pasta';

  @override
  String get folderPickerVolumeList => 'Dispositivos de armazenamento';

  @override
  String get folderPickerInternalStorage => 'Armazenamento interno';

  @override
  String get folderPickerSelect => 'Selecionar';

  @override
  String get folderPickerFolderName => 'Nome da pasta';

  @override
  String get folderPickerInvalidName => 'Nome de pasta inválido';

  @override
  String get folderPickerEmpty => 'Nenhuma subpasta';

  @override
  String get folderPickerReadError => 'Não é possível ler esta pasta';

  @override
  String get folderPickerCreateError => 'Não foi possível criar a pasta';

  @override
  String get traktTitle => 'Importação do Trakt';

  @override
  String get traktImportFrom => 'Importar do Trakt.tv';

  @override
  String get traktImportDescription =>
      'Baixe seus dados em trakt.tv/users/YOU/data e selecione o arquivo ZIP abaixo.';

  @override
  String get traktZipFile => 'Arquivo ZIP';

  @override
  String get traktSelectZipFile => 'Selecionar arquivo ZIP';

  @override
  String get traktSelectZipExport => 'Selecionar exportação ZIP do Trakt';

  @override
  String get preview => 'Pré-visualização';

  @override
  String traktUser(String username) {
    return 'Usuário do Trakt: $username';
  }

  @override
  String get traktWatchedMovies => 'Filmes assistidos';

  @override
  String get traktWatchedShows => 'Séries assistidas';

  @override
  String get traktRatedMovies => 'Filmes avaliados';

  @override
  String get traktRatedShows => 'Séries avaliadas';

  @override
  String get traktWatchlist => 'Lista de acompanhamento';

  @override
  String get importOptions => 'Opções';

  @override
  String get traktImportWatched => 'Importar itens assistidos';

  @override
  String get traktImportWatchedDesc => 'Filmes e séries como concluídos';

  @override
  String get traktImportRatings => 'Importar avaliações';

  @override
  String get traktImportRatingsDesc => 'Aplicar suas avaliações (1-10)';

  @override
  String get traktImportWatchlist => 'Importar lista de acompanhamento';

  @override
  String get traktImportWatchlistDesc =>
      'Adicionar como planejado ou à lista de desejos';

  @override
  String get importTargetCollection => 'Coleção de destino';

  @override
  String get importUseExistingCollection => 'Usar coleção existente';

  @override
  String get importStart => 'Iniciar importação';

  @override
  String get traktRequiresOwnTmdbKey =>
      'A importação do Trakt exige sua própria chave de API do TMDB. Adicione-a em Configurações → Credenciais.';

  @override
  String get traktInvalidExport => 'Exportação do Trakt inválida';

  @override
  String get kinoriumImportFrom => 'Importar do Kinorium';

  @override
  String get kinoriumImportDescription =>
      'Exporte sua lista do Kinorium (chega por e-mail como CSV) e selecione o arquivo abaixo.';

  @override
  String get kinoriumSelectCsvFile => 'Selecionar arquivo CSV';

  @override
  String get kinoriumSelectCsvExport => 'Selecionar exportação CSV do Kinorium';

  @override
  String get kinoriumIsWatchlist => 'Este é um arquivo \"Watchlist\"';

  @override
  String get kinoriumIsWatchlistDesc =>
      'Importar todos os títulos como planejados em vez de assistidos';

  @override
  String get kinoriumImportNotes => 'Importar elenco e equipe';

  @override
  String get kinoriumImportNotesDesc =>
      'Adicionar diretores e atores à nota do item';

  @override
  String get kinoriumImporting => 'Importando do Kinorium...';

  @override
  String get kinoriumRecommendOwnTmdbKey =>
      'Dica: para importações grandes, recomendamos uma chave de API do TMDB pessoal (Configurações → Chaves de API), mas é opcional — a chave integrada também funciona.';

  @override
  String get kinoriumReasonNotFound => 'Não encontrado no TMDB';

  @override
  String get kinoriumReasonApiError =>
      'Erro do TMDB ou limite atingido — tente novamente mais tarde';

  @override
  String kinoriumReasonUnsupportedType(String type) {
    return 'Tipo não suportado: $type';
  }

  @override
  String kinoriumReasonDuplicate(String title) {
    return 'Duplicata de \"$title\"';
  }

  @override
  String traktImportedItems(int count) {
    return '$count itens importados';
  }

  @override
  String get traktImporting => 'Importando do Trakt';

  @override
  String get creditsTitle => 'Créditos';

  @override
  String get creditsDataProviders => 'Provedores de dados';

  @override
  String get creditsTmdbAttribution =>
      'Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.';

  @override
  String get creditsTvMazeAttribution =>
      'Dados de séries fornecidos pelo TVmaze.';

  @override
  String get creditsIgdbAttribution => 'Dados de jogos fornecidos pelo IGDB.';

  @override
  String get creditsSteamGridDbAttribution =>
      'Artes fornecidas pelo SteamGridDB.';

  @override
  String get creditsVndbAttribution =>
      'Dados de visual novels fornecidos pelo VNDB.';

  @override
  String get creditsAniListAttribution =>
      'Dados de mangá fornecidos pelo AniList.';

  @override
  String get creditsMangaBakaAttribution =>
      'Dados de mangá fornecidos pelo MangaBaka.';

  @override
  String get creditsMangaDexAttribution =>
      'Dados de mangá fornecidos pelo MangaDex.';

  @override
  String get creditsKitsuAttribution => 'Dados de mangá fornecidos pelo Kitsu.';

  @override
  String get creditsOpenLibraryAttribution =>
      'Dados de livros da Open Library (CC0 / ODbL).';

  @override
  String get creditsFantlabAttribution => 'Dados de livros do Fantlab.';

  @override
  String get creditsComicVineAttribution =>
      'Dados de quadrinhos do ComicVine (uso não comercial).';

  @override
  String get creditsGoogleBooksAttribution =>
      'Dados de livros do Google Books.';

  @override
  String get creditsHardcoverAttribution => 'Dados de livros do Hardcover.';

  @override
  String get creditsOpenSource => 'Código aberto';

  @override
  String get creditsOpenSourceDesc =>
      'Tonkatsu Box é software livre e de código aberto, publicado sob a licença MIT.';

  @override
  String get creditsViewLicenses => 'Ver licenças de código aberto';

  @override
  String get creditsDiscord => 'Entrar no Discord';

  @override
  String get collectionsImportCollection => 'Importar coleção';

  @override
  String get collectionsNoCollectionsYet => 'Nenhuma coleção ainda';

  @override
  String get collectionsNoCollectionsHint =>
      'Toque em + para criar sua primeira coleção e começar\na organizar sua biblioteca.';

  @override
  String get collectionsFailedToLoad => 'Falha ao carregar coleções';

  @override
  String collectionsCount(int count) {
    return 'Coleções ($count)';
  }

  @override
  String get collectionsUncategorized => 'Sem categoria';

  @override
  String collectionsUncategorizedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get editCollection => 'Editar coleção';

  @override
  String get collectionsRenamed => 'Coleção atualizada';

  @override
  String collectionsFailedToRename(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get collectionsDeleted => 'Coleção excluída';

  @override
  String collectionsFailedToDelete(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String collectionsFailedToCreate(String error) {
    return 'Falha ao criar coleção: $error';
  }

  @override
  String collectionsImported(String name, int count) {
    return 'Importada \"$name\" com $count itens';
  }

  @override
  String get collectionsImporting => 'Importando coleção';

  @override
  String get importTargetTitle => 'Importar para...';

  @override
  String get importCreateNew => 'Criar nova coleção';

  @override
  String get importUseExisting => 'Adicionar à coleção existente';

  @override
  String get importNoCollections => 'Nenhuma coleção disponível';

  @override
  String get importSelectCollection => 'Selecionar coleção';

  @override
  String get importErrorLoadingCollections => 'Erro ao carregar coleções';

  @override
  String get importStartButton => 'Importar';

  @override
  String get importUsername => 'Nome de usuário';

  @override
  String get importUsernameHint => 'ex.: seunome';

  @override
  String get importMode => 'Modo';

  @override
  String get importModeNewOnly => 'Adicionar apenas novos';

  @override
  String get importModeNewOnlySubtitle =>
      'Ignorar itens que já estão na coleção';

  @override
  String get importModeOverwrite => 'Substituir existentes';

  @override
  String get importModeOverwriteSubtitle =>
      'Atualizar progresso, status e datas da origem';

  @override
  String get importNewCollectionName => 'Nome da coleção';

  @override
  String importNewCollectionDefault(String source, String username) {
    return 'Importação $source — $username';
  }

  @override
  String get importFetchingBooks => 'Buscando biblioteca de livros...';

  @override
  String get importAddingItems => 'Importando entradas';

  @override
  String importProcessingItem(String title) {
    return 'Processando: $title';
  }

  @override
  String importImportedCount(int count) {
    return '$count importados';
  }

  @override
  String importUpdatedCount(int count) {
    return '$count atualizados';
  }

  @override
  String importUserNotFound(String username) {
    return 'Usuário \"$username\" não encontrado';
  }

  @override
  String get importEmptyUsername => 'Informe um nome de usuário';

  @override
  String importFailed(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get collectionNotFound => 'Coleção não encontrada';

  @override
  String get collectionAddItems => 'Adicionar itens';

  @override
  String get collectionSwitchToList => 'Alternar para lista';

  @override
  String get collectionSwitchToBoard => 'Alternar para quadro';

  @override
  String get collectionUnlockBoard => 'Desbloquear quadro';

  @override
  String get collectionLockBoard => 'Bloquear quadro';

  @override
  String get collectionExport => 'Exportar';

  @override
  String get collectionNoItemsYet => 'Nenhum item ainda';

  @override
  String get collectionEmpty => 'Coleção vazia';

  @override
  String get collectionEmptyAddHint =>
      'Adicione itens para começar a montar sua coleção.';

  @override
  String get collectionEmptyReadonly => 'Esta coleção está vazia.';

  @override
  String get collectionDeleteEmptyPrompt =>
      'Esta coleção ficou vazia. Excluir?';

  @override
  String get collectionRemoveItemTitle => 'Remover item?';

  @override
  String collectionRemoveItemMessage(String name) {
    return 'Remover $name desta coleção?';
  }

  @override
  String get collectionMoveToCollection => 'Mover para coleção';

  @override
  String get collectionExportFormat => 'Formato de exportação';

  @override
  String get collectionChooseExportFormat => 'Escolha o formato de exportação:';

  @override
  String get collectionExportLight => 'Leve (.xcoll)';

  @override
  String get collectionExportLightDesc => 'Apenas itens, arquivo menor';

  @override
  String get collectionExportFull => 'Completo (.xcollx)';

  @override
  String get collectionExportFullDesc =>
      'Com imagens e quadro — funciona offline';

  @override
  String get collectionExportIncludeUserData => 'Incluir dados pessoais';

  @override
  String get collectionExportIncludeUserDataDesc =>
      'Status, datas, notas, progresso de episódios';

  @override
  String get customItemCreate => 'Criar item personalizado';

  @override
  String get title => 'Título';

  @override
  String get customItemTitleHint => 'ex.: Meu jogo homebrew';

  @override
  String get customItemAltTitle => 'Título alternativo';

  @override
  String get customItemAltTitleHint => 'Nome no idioma original';

  @override
  String get customItemCoverUrl => 'URL da capa';

  @override
  String get year => 'Ano';

  @override
  String get genres => 'Gêneros';

  @override
  String get customItemGenresHint => 'ex.: RPG, Ação, Puzzle';

  @override
  String get platform => 'Plataforma';

  @override
  String get customItemPlatformHint => 'ex.: PC, SNES, Personalizada';

  @override
  String get format => 'Formato';

  @override
  String get progress => 'Progresso';

  @override
  String get customMarkCompleted => 'Marcar como concluído';

  @override
  String get customUnitParts => 'Partes';

  @override
  String get customUnitEpisodes => 'Episódios';

  @override
  String get customUnitChapters => 'Capítulos';

  @override
  String get customUnitPages => 'Páginas';

  @override
  String get customUnitVolumes => 'Volumes';

  @override
  String get customUnitSeasons => 'Temporadas';

  @override
  String get description => 'Descrição';

  @override
  String get customItemDescriptionHint => 'Breve descrição ou notas';

  @override
  String get customItemMyNoteHint => 'Sua anotação sobre este item';

  @override
  String get customItemTagsHint =>
      'Separadas por vírgula, ex.: Backlog, Favoritos';

  @override
  String get customItemOptionalFields => 'Mais campos';

  @override
  String get customItemEdit => 'Editar item personalizado';

  @override
  String get customItemFillFromFile => 'Preencher a partir de arquivo';

  @override
  String customItemFileMultipleRows(int count) {
    return '$count entradas no arquivo — a primeira foi usada';
  }

  @override
  String get customItemFileNoValidRows =>
      'Nenhuma entrada válida neste arquivo';

  @override
  String get customItemAddCover => 'Adicionar capa';

  @override
  String get customItemCoverSource => 'Origem da capa';

  @override
  String get customItemCoverRatio =>
      'Proporção recomendada: 2:3 (ex.: 600×900)';

  @override
  String get customItemCoverFromFile => 'Do arquivo';

  @override
  String get customItemSearchHint => 'Buscar ou digitar personalizado...';

  @override
  String get customItemUseCustom => 'Usar valor personalizado';

  @override
  String get customItemExternalUrl => 'URL externa';

  @override
  String get customItemErrorEmptyTitle => 'O título é obrigatório';

  @override
  String get customItemCreated => 'Item personalizado criado';

  @override
  String get customItemUpdated => 'Item personalizado atualizado';

  @override
  String get tagLabel => 'Tag';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagCreate => 'Nova tag';

  @override
  String get tagCreateHint => 'Nome da tag';

  @override
  String tagCreateNamed(String name) {
    return 'Criar \"$name\"';
  }

  @override
  String get tagRename => 'Renomear tag';

  @override
  String get tagDelete => 'Excluir tag';

  @override
  String tagDeleteConfirm(String name) {
    return 'Excluir a tag \"$name\"? Os itens ficarão sem tag.';
  }

  @override
  String get tagManage => 'Gerenciar tags';

  @override
  String get tagAssign => 'Atribuir tags';

  @override
  String get tagNone => 'Sem tags';

  @override
  String get tagPickerTitle => 'Selecionar tags';

  @override
  String get tagTextColor => 'Cor do texto';

  @override
  String get tagCreated => 'Tag criada';

  @override
  String get tagRenamed => 'Tag renomeada';

  @override
  String get tagDeleted => 'Tag excluída';

  @override
  String get tagUpdateFailed => 'Falha ao atualizar a tag';

  @override
  String get refreshItemFromApi => 'Atualizar da fonte';

  @override
  String get refreshItemSuccess => 'Item atualizado da fonte';

  @override
  String get refreshItemNotFound => 'A fonte não tem mais este item';

  @override
  String get refreshItemUnsupported =>
      'Itens personalizados não têm fonte externa';

  @override
  String refreshItemFailed(String error) {
    return 'Falha ao atualizar: $error';
  }

  @override
  String get renameDialogHint => 'Nome de exibição';

  @override
  String renameOriginalLabel(String name) {
    return 'Original: $name';
  }

  @override
  String get renameResetToOriginal => 'Restaurar original';

  @override
  String get renameSaved => 'Renomeado';

  @override
  String get tierListExportFailed => 'Falha ao exportar imagem';

  @override
  String get browseCollectionsDownloadFailedGeneric =>
      'Falha ao baixar a coleção';

  @override
  String get tagFilterAll => 'Todas as tags';

  @override
  String get tagSidebarGroup => 'Grupo';

  @override
  String get colorPickerTitle => 'Cor';

  @override
  String get colorPickerNoColor => 'Sem cor';

  @override
  String get raLinkButton => 'Vincular RetroAchievements';

  @override
  String get raLinkTitle => 'Encontrar jogo no RetroAchievements';

  @override
  String get raLinkSearchHint => 'Buscar por nome...';

  @override
  String raLinkLoading(String platform) {
    return 'Carregando jogos de $platform...';
  }

  @override
  String get raLinkNotFound => 'Nenhuma correspondência encontrada';

  @override
  String get raLinkSuccess => 'Jogo vinculado ao RetroAchievements';

  @override
  String raLinkAchievements(int count) {
    return '$count conquistas';
  }

  @override
  String get raUnlinkButton => 'Desvincular';

  @override
  String get raUnlinkTitle => 'Desvincular RetroAchievements';

  @override
  String get raUnlinkConfirm =>
      'Remover o vínculo com RetroAchievements e os dados de conquistas deste jogo?';

  @override
  String get collectionFilterByType => 'Filtrar por tipo';

  @override
  String get collectionFilterGames => 'Jogos';

  @override
  String get collectionFilterMovies => 'Filmes';

  @override
  String get collectionFilterTvShows => 'Séries';

  @override
  String get collectionFilterVisualNovels => 'Novelas visuais';

  @override
  String get collectionFilterBooks => 'Livros';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get sort => 'Ordenar';

  @override
  String get collectionFilterAscending => 'Crescente';

  @override
  String get collectionFilterDescending => 'Decrescente';

  @override
  String get collectionFilterFilters => 'Filtros';

  @override
  String get collectionFilterClearAll => 'Limpar tudo';

  @override
  String collectionItemMovedTo(String name, String collection) {
    return '$name movido para $collection';
  }

  @override
  String collectionItemAlreadyExists(String name, String collection) {
    return '$name já existe em $collection';
  }

  @override
  String collectionItemRemoved(String name) {
    return '$name removido';
  }

  @override
  String get boardTab => 'Quadro';

  @override
  String get imageAddedToBoard => 'Imagem adicionada ao quadro';

  @override
  String get mapAddedToBoard => 'Mapa adicionado ao quadro';

  @override
  String get loading => 'Carregando...';

  @override
  String get gameNotFound => 'Jogo não encontrado';

  @override
  String get movieNotFound => 'Filme não encontrado';

  @override
  String get tvShowNotFound => 'Série não encontrada';

  @override
  String get animationNotFound => 'Animação não encontrada';

  @override
  String get visualNovelNotFound => 'Visual novel não encontrada';

  @override
  String get mangaNotFound => 'Manga não encontrado';

  @override
  String get readingProgress => 'Progresso de leitura';

  @override
  String get mangaChapters => 'Capítulos';

  @override
  String get mangaVolumes => 'Volumes';

  @override
  String get mangaMarkCompleted => 'Marcar como concluído';

  @override
  String get animeProgress => 'Progresso de exibição';

  @override
  String get animeEpisodes => 'Episódios';

  @override
  String get animeMarkCompleted => 'Marcar como concluído';

  @override
  String get bookPages => 'Páginas';

  @override
  String get bookIssues => 'Edições';

  @override
  String get bookMarkCompleted => 'Marcar como concluído';

  @override
  String animeNextEpisode(int episode) {
    return 'Ep. $episode estreia em breve';
  }

  @override
  String get animatedMovie => 'Filme animado';

  @override
  String get animatedSeries => 'Série animada';

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
  String get episodeProgress => 'Progresso de episódios';

  @override
  String episodesWatchedOf(int watched, int total) {
    return '$watched/$total assistidos';
  }

  @override
  String episodesWatched(int count) {
    return '$count assistidos';
  }

  @override
  String seasonEpisodesProgress(int watched, int total) {
    return '$watched/$total episódios';
  }

  @override
  String get noSeasonData => 'Nenhum dado de temporada disponível';

  @override
  String get refreshFromTmdb => 'Atualizar do TMDB';

  @override
  String get markAllWatched => 'Marcar tudo como assistido';

  @override
  String get markNextWatched => 'Marcar próximo episódio';

  @override
  String get unmarkAll => 'Desmarcar tudo';

  @override
  String get noEpisodesFound => 'Nenhum episódio encontrado';

  @override
  String episodeWatchedDate(String date) {
    return 'assistido em $date';
  }

  @override
  String get createCollectionTitle => 'Nova coleção';

  @override
  String get createCollectionNameLabel => 'Nome da coleção';

  @override
  String get createCollectionNameHint => 'ex.: Clássicos do SNES';

  @override
  String get createCollectionEnterName => 'Digite um nome';

  @override
  String get createCollectionNameTooShort =>
      'O nome deve ter pelo menos 2 caracteres';

  @override
  String get renameCollectionTitle => 'Renomear coleção';

  @override
  String get deleteCollectionTitle => 'Excluir coleção?';

  @override
  String deleteCollectionMessage(String name) {
    return 'Tem certeza de que deseja excluir $name?\n\nEsta ação não pode ser desfeita.';
  }

  @override
  String get canvasAddText => 'Adicionar texto';

  @override
  String get canvasAddImage => 'Adicionar imagem';

  @override
  String get canvasAddLink => 'Adicionar link';

  @override
  String get canvasFindImages => 'Buscar imagens...';

  @override
  String get canvasBrowseMaps => 'Explorar mapas...';

  @override
  String get canvasConnect => 'Conectar';

  @override
  String get canvasBringToFront => 'Trazer para frente';

  @override
  String get canvasSendToBack => 'Enviar para trás';

  @override
  String get canvasEditConnection => 'Editar conexão';

  @override
  String get canvasDeleteConnection => 'Excluir conexão';

  @override
  String get canvasDeleteElement => 'Excluir elemento';

  @override
  String get canvasDeleteElementMessage =>
      'Tem certeza de que deseja excluir este elemento?';

  @override
  String get canvasAddToBoard => 'Adicionar ao quadro';

  @override
  String get editTextTitle => 'Editar texto';

  @override
  String get textContentLabel => 'Conteúdo do texto';

  @override
  String get fontSizeLabel => 'Tamanho da fonte';

  @override
  String get fontSizeSmall => 'Pequeno';

  @override
  String get fontSizeMedium => 'Médio';

  @override
  String get fontSizeLarge => 'Grande';

  @override
  String get fontSizeTitle => 'Título';

  @override
  String get editImageTitle => 'Editar imagem';

  @override
  String get imageFromUrl => 'Da URL';

  @override
  String get imageFromFile => 'Do arquivo';

  @override
  String get imageUrlLabel => 'URL da imagem';

  @override
  String get imageUrlHint => 'https://example.com/image.png';

  @override
  String get imageChooseFile => 'Escolher arquivo';

  @override
  String get imageChooseAnother => 'Escolher outro';

  @override
  String get editLinkTitle => 'Editar link';

  @override
  String get linkLabelOptional => 'Rótulo (opcional)';

  @override
  String get linkLabelHint => 'Meu link';

  @override
  String get connectionLabelHint => 'ex.: depende de, relacionado a...';

  @override
  String get connectionStyleLabel => 'Estilo';

  @override
  String get connectionStyleSolid => 'Contínua';

  @override
  String get connectionStyleDashed => 'Tracejada';

  @override
  String get connectionStyleArrow => 'Seta';

  @override
  String get searchTabTv => 'TV';

  @override
  String get searchHintMovies => 'Buscar filmes...';

  @override
  String get searchHintTv => 'Buscar séries...';

  @override
  String get searchHintAnime => 'Buscar anime...';

  @override
  String get searchHintGames => 'Buscar jogos...';

  @override
  String get searchHintVisualNovels => 'Buscar visual novels...';

  @override
  String get searchSourceVisualNovels => 'N. visuais';

  @override
  String get searchSourceOpenLibrary => 'OpenLibrary';

  @override
  String get searchSourceFantlab => 'Fantlab';

  @override
  String get searchSourceComics => 'Quadrinhos';

  @override
  String get searchHintManga => 'Buscar manga...';

  @override
  String get searchHintBooks => 'Buscar livros...';

  @override
  String get searchHintComics => 'Buscar quadrinhos...';

  @override
  String get language => 'Idioma';

  @override
  String get bookFilterSearchBy => 'Buscar por';

  @override
  String get type => 'Tipo';

  @override
  String get bookSearchAuthor => 'Autor';

  @override
  String get bookSearchSubject => 'Assunto';

  @override
  String get bookSimilarTitle => 'Livros similares';

  @override
  String get bookMoreByAuthorTitle => 'Mais deste autor';

  @override
  String get bookTitleCopied => 'Título copiado';

  @override
  String get editionPickerTitle => 'Escolher edição';

  @override
  String get editionPickerEmpty => 'Nenhuma edição encontrada';

  @override
  String get fantlabTypeNovel => 'Romance';

  @override
  String get fantlabTypeNovella => 'Novela';

  @override
  String get fantlabTypeShortStory => 'Conto';

  @override
  String get fantlabTypeCycle => 'Ciclo';

  @override
  String get searchSelectPlatform => 'Selecionar plataforma';

  @override
  String get searchAddToCollection => 'Adicionar à coleção';

  @override
  String searchAddedToCollection(String name) {
    return '$name adicionado à coleção';
  }

  @override
  String searchAddedToNamed(String name, String collection) {
    return '$name adicionado a $collection';
  }

  @override
  String searchAlreadyInCollection(String name) {
    return '$name já está na coleção';
  }

  @override
  String searchAlreadyInNamed(String name, String collection) {
    return '$name já está em $collection';
  }

  @override
  String searchAddedToCollections(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coleções',
      one: '1 coleção',
    );
    return '$name adicionado a $_temp0';
  }

  @override
  String searchAlreadyInCollections(String name) {
    return '$name já está nas coleções selecionadas';
  }

  @override
  String get goToSettings => 'Ir para Configurações';

  @override
  String get searchMinCharsHint =>
      'Digite pelo menos 2 caracteres e pressione Enter';

  @override
  String get searchNoResults => 'Nenhum resultado encontrado';

  @override
  String searchNothingFoundFor(String query) {
    return 'Nada encontrado para \"$query\"';
  }

  @override
  String get searchNoInternet => 'Sem conexão com a internet';

  @override
  String get searchFailed => 'Falha na busca';

  @override
  String get searchCheckConnection =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get copyErrorDetails => 'Copiar detalhes do erro';

  @override
  String get errorDetailsCopied => 'Detalhes do erro copiados';

  @override
  String get errorDetailsTitle => 'Detalhes do erro';

  @override
  String get errorDetailsShow => 'Detalhes';

  @override
  String get showMore => 'Mais…';

  @override
  String get showLess => 'Recolher';

  @override
  String get platformFilterTitle => 'Selecionar plataformas';

  @override
  String get platformFilterClearAll => 'Limpar tudo';

  @override
  String get platformFilterSearchHint => 'Buscar plataformas...';

  @override
  String selectedCount(int count) {
    return '$count selecionadas';
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
  String get platformFilterNone => 'Nenhuma plataforma encontrada';

  @override
  String get platformFilterTryDifferent => 'Tente outro termo de busca';

  @override
  String get wishlistHideResolved => 'Ocultar resolvidos';

  @override
  String get wishlistShowResolved => 'Mostrar resolvidos';

  @override
  String get wishlistClearResolved => 'Limpar resolvidos';

  @override
  String get wishlistEmpty => 'Nenhum item na lista de desejos ainda';

  @override
  String get wishlistEmptyHint =>
      'Toque + para adicionar algo para buscar depois';

  @override
  String get wishlistDeleteItem => 'Excluir item';

  @override
  String wishlistDeletePrompt(String name) {
    return 'Excluir \"$name\" da lista de desejos?';
  }

  @override
  String wishlistClearResolvedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count itens resolvidos?',
      one: 'Excluir 1 item resolvido?',
    );
    return '$_temp0';
  }

  @override
  String get wishlistMarkResolved => 'Marcar como resolvido';

  @override
  String get wishlistUnresolve => 'Marcar como não resolvido';

  @override
  String get wishlistTitleHint => 'Nome do jogo, filme ou série...';

  @override
  String get wishlistTitleMinChars => 'Pelo menos 2 caracteres';

  @override
  String get wishlistTypeOptional => 'Tipo (opcional)';

  @override
  String get any => 'Qualquer';

  @override
  String get wishlistNoteOptional => 'Nota (opcional)';

  @override
  String get wishlistNoteHint => 'Plataforma, ano, quem recomendou...';

  @override
  String get wishlistTagOptional => 'Tag (opcional)';

  @override
  String get wishlistTagHint =>
      'Agrupe entradas — ex.: um lote de importação ou uma fonte';

  @override
  String get wishlistTagUntagged => 'Sem tag';

  @override
  String get wishlistTagFilterLabel => 'Lista';

  @override
  String get wishlistTagManage => 'Gerenciar tag';

  @override
  String get wishlistTagDelete => 'Excluir tag e todos os itens';

  @override
  String wishlistTagDeleteConfirm(String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Excluir a tag \"$tag\" e $_temp0?';
  }

  @override
  String wishlistBulkActionsButton(int count) {
    return '$count coincidências';
  }

  @override
  String get wishlistBulkApplyTag => 'Aplicar tag aos visíveis';

  @override
  String wishlistBulkApplyTagHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marcar as $count entradas visíveis como',
      one: 'Marcar a 1 entrada visível como',
    );
    return '$_temp0';
  }

  @override
  String get wishlistBulkRemoveTag => 'Remover tag dos visíveis';

  @override
  String get wishlistBulkDelete => 'Excluir visíveis';

  @override
  String wishlistBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count entradas visíveis?',
      one: 'Excluir 1 entrada visível?',
    );
    return '$_temp0';
  }

  @override
  String get apply => 'Aplicar';

  @override
  String get welcomeStepWelcome => 'Boas-vindas';

  @override
  String get welcomeStepReady => 'Pronto!';

  @override
  String get welcomeNameTitle => 'Qual é o seu nome?';

  @override
  String get welcomeNameSubtitle =>
      'Este nome aparecerá como autor nas coleções que você criar';

  @override
  String get welcomeChangeLaterHint =>
      'Você pode alterar isso depois em Configurações';

  @override
  String get welcomeLanguageTitle => 'Escolha seu idioma';

  @override
  String get welcomeLanguageSubtitle =>
      'Selecione o idioma da interface do app';

  @override
  String get welcomeTitle => 'Bem-vindo ao Tonkatsu Box';

  @override
  String get welcomeSubtitle =>
      'Organize suas coleções de jogos, filmes,\nséries, anime, visual novels, mangás e livros';

  @override
  String get welcomeWhatYouCanDo => 'O que você pode fazer';

  @override
  String get welcomeFeatureCollections =>
      'Crie coleções por plataforma, gênero ou qualquer tema';

  @override
  String get welcomeFeatureSearch =>
      'Busque jogos, filmes, séries, anime, visual novels, mangás e livros via APIs';

  @override
  String get welcomeFeatureTracking =>
      'Acompanhe o progresso, avalie de 1 a 10, adicione notas';

  @override
  String get welcomeFeatureBoards => 'Quadros visuais com artwork';

  @override
  String get welcomeFeatureExport =>
      'Exporte e importe — compartilhe coleções com amigos';

  @override
  String get welcomeWorksWithoutKeys => 'Funciona sem chaves de API';

  @override
  String get welcomeChipImport => 'Importar .xcoll';

  @override
  String get welcomeChipCanvas => 'Quadros';

  @override
  String get welcomeChipRatings => 'Avaliações e notas';

  @override
  String get welcomeApiKeysHint =>
      'Chaves de API só são necessárias para buscar novos jogos, filmes e séries. Você pode importar coleções e usá-las offline.';

  @override
  String get welcomeChipGames => 'Jogos (IGDB)';

  @override
  String get welcomeChipMovies => 'Filmes (TMDB)';

  @override
  String get welcomeChipTvShows => 'Séries (TMDB)';

  @override
  String get welcomeChipAnime => 'Anime (TMDB)';

  @override
  String get welcomeChipVisualNovels => 'Novelas visuais (VNDB)';

  @override
  String get welcomeChipManga => 'Manga (AniList)';

  @override
  String get welcomeApiTitle => 'Obtendo chaves de API';

  @override
  String get welcomeApiFreeHint => 'Cadastro gratuito, leva 2-3 minutos cada';

  @override
  String get welcomeApiIgdbTag => 'IGDB';

  @override
  String get welcomeApiIgdbDesc => 'Busca de jogos';

  @override
  String get welcomeApiRequired => 'OBRIGATÓRIA';

  @override
  String get welcomeApiTmdbTag => 'TMDB';

  @override
  String get welcomeApiTmdbDesc => 'Filmes, séries e anime';

  @override
  String get welcomeApiComicVineDesc => 'Quadrinhos e graphic novels';

  @override
  String get welcomeApiGoogleBooksDesc => 'Catálogo global de livros do Google';

  @override
  String get welcomeApiHardcoverDesc =>
      'Catálogo comunitário de livros, requer um token pessoal';

  @override
  String get welcomeApiRecommended => 'RECOMENDADA';

  @override
  String get welcomeApiSgdbTag => 'SGDB';

  @override
  String get welcomeApiSgdbDesc => 'Artwork de jogos para quadros';

  @override
  String get welcomeApiOptional => 'OPCIONAL';

  @override
  String get welcomeApiBuiltInKey => 'CHAVE INTEGRADA';

  @override
  String get welcomeApiOwnKeyHint =>
      'Você pode adicionar sua própria chave depois em Configurações para limites maiores';

  @override
  String get welcomeApiEnterKeysHint =>
      'Insira as chaves em Configurações → Credenciais após a configuração';

  @override
  String get welcomeApiRateLimitHint =>
      'As chaves integradas são compartilhadas entre todos os usuários e têm limites de uso. Para a melhor experiência, use suas próprias chaves — é gratuito e leva apenas alguns minutos.';

  @override
  String get welcomeHowTitle => 'Como funciona';

  @override
  String get welcomeHowAppStructure => 'Estrutura do app';

  @override
  String get welcomeHowMainDesc =>
      'Todos os itens de todas as coleções em uma visão. Filtre por tipo, ordene por avaliação.';

  @override
  String get welcomeHowCollectionsDesc =>
      'Suas coleções. Crie, organize, gerencie. Visualização em grade ou lista por coleção.';

  @override
  String get welcomeHowTierListsDesc =>
      'Classifique e compare itens entre coleções com tier lists personalizáveis.';

  @override
  String get welcomeHowWishlistDesc =>
      'Lista rápida de itens para conferir depois. Sem necessidade de API.';

  @override
  String get welcomeHowSearchDesc =>
      'Encontre jogos, filmes, séries, visual novels e mangás via API. Adicione a qualquer coleção.';

  @override
  String get welcomeHowSettingsDesc =>
      'Chaves de API, cache, exportação/importação do banco de dados, ferramentas de depuração.';

  @override
  String get welcomeHowPersonalizationDesc =>
      'Seu gosto em um só lugar: uma nuvem dos seus gêneros favoritos mais recomendações baseadas no que você avaliou.';

  @override
  String get welcomeHowQuickStart => 'Início rápido';

  @override
  String get welcomeHowStep1 =>
      'Vá em Configurações → Credenciais e insira as chaves de API';

  @override
  String get welcomeHowStep2 =>
      'Clique em Verificar conexão e aguarde a sincronização das plataformas';

  @override
  String get welcomeHowStep3 => 'Vá em Coleções → + Nova coleção';

  @override
  String get welcomeHowStep4 =>
      'Dê um nome e depois Adicionar itens → Buscar → Adicionar';

  @override
  String get welcomeHowStep5 =>
      'Avalie, acompanhe o progresso, adicione notas — pronto!';

  @override
  String get welcomeHowSharing => 'Compartilhamento';

  @override
  String get welcomeHowSharingDesc1 => 'Exporte coleções como ';

  @override
  String get welcomeHowSharingDesc2 => ' (leve, só metadados) ou ';

  @override
  String get welcomeHowSharingDesc3 =>
      ' (completo, com imagens e quadro — funciona offline). Importe de amigos — sem necessidade de API!';

  @override
  String get welcomeReadyTitle => 'Tudo pronto!';

  @override
  String get welcomeReadyMessage =>
      'Vá em Configurações → Credenciais para inserir suas chaves de API, ou comece importando uma coleção.';

  @override
  String get welcomeReadySkip => 'Pular — explorar por conta própria';

  @override
  String get welcomeReadyReturnHint =>
      'Você sempre pode voltar aqui em Configurações';

  @override
  String get welcomeStepSources => 'Fontes';

  @override
  String get welcomeStepTour => 'Visita guiada';

  @override
  String get welcomeChipBooks => 'Livros (OpenLibrary, Fantlab)';

  @override
  String get welcomeSourcesTitle => 'De onde vêm os dados';

  @override
  String get welcomeSourcesSubtitle =>
      'Esses provedores alimentam a busca no app. A maioria funciona imediatamente — apenas alguns pedem uma chave gratuita.';

  @override
  String get welcomeSourcesNoKeyNeeded => 'SEM CHAVE';

  @override
  String get welcomeSourcesKeySaved => 'Chave salva';

  @override
  String get welcomeSourcesGetKey => 'Obter chave';

  @override
  String get welcomeSourcesKeyOptionalHint =>
      'Opcional — sua própria chave aumenta os limites de uso. A busca funciona sem ela.';

  @override
  String get welcomeSourcesHardcoverTokenHint =>
      'Obrigatório — busca e importação ficam desabilitadas sem ele. Tokens expiram todo 1º de janeiro.';

  @override
  String get welcomeSourceDescTmdb => 'Filmes, séries e animação.';

  @override
  String get welcomeSourceDescTvMaze => 'Séries de TV.';

  @override
  String get welcomeSourceDescIgdb => 'Jogos de todas as plataformas.';

  @override
  String get welcomeSourceDescAniList =>
      'Anime e manga com metadados completos.';

  @override
  String get welcomeSourceDescMangaBaka =>
      'Manga, manhwa, manhua e light novels.';

  @override
  String get welcomeSourceDescMangaDex =>
      'Um grande catálogo de mangá com títulos localizados e contagem de capítulos.';

  @override
  String get welcomeSourceDescKitsu =>
      'Um catálogo independente de mangá com avaliações e capas.';

  @override
  String get welcomeSourceDescVndb => 'O banco de dados de visual novels.';

  @override
  String get welcomeSourceDescOpenLibrary =>
      'Um catálogo aberto com milhões de livros.';

  @override
  String get welcomeSourceDescFantlab =>
      'Um catálogo detalhado de livros com avaliações, prêmios e séries.';

  @override
  String get welcomeSourceDescComicVine =>
      'Um vasto catálogo de quadrinhos e graphic novels.';

  @override
  String get welcomeSourceDescGoogleBooks =>
      'Milhões de edições do catálogo de livros do Google, pesquisáveis por título, autor ou ISBN.';

  @override
  String get welcomeSourceDescHardcover =>
      'Catálogo comunitário de livros com séries, gêneros, moods e avaliações. Requer um token pessoal gratuito.';

  @override
  String get welcomeTourTitle => 'Conheça o menu';

  @override
  String get welcomeTourSubtitle =>
      'Um tour rápido pela navegação principal — toque em Próximo para avançar.';

  @override
  String get welcomeTourStart => 'Começar a explorar';

  @override
  String get welcomeHowReleasesDesc =>
      'Novos episódios e lançamentos das séries e jogos que você acompanha.';

  @override
  String updateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String updateCurrent(String version) {
    return 'Atual: v$version';
  }

  @override
  String get updateWarningTitle => 'Antes de atualizar';

  @override
  String get updateWarningBody =>
      'Este app está em desenvolvimento ativo. Atualizações podem incluir migrações de banco de dados que alteram o formato dos dados.\n\nCrie um backup antes de atualizar (Configurações → Backup). Assim você pode restaurar seus dados se algo der errado.';

  @override
  String get updateWarningProceed => 'Ir para a versão';

  @override
  String get chooseCollection => 'Escolher coleção';

  @override
  String get withoutCollection => 'Sem coleção';

  @override
  String get detailMyRating => 'Minha avaliação';

  @override
  String detailRatingValue(String rating) {
    return '$rating/10';
  }

  @override
  String get detailActivityProgress => 'Atividade e progresso';

  @override
  String get detailAuthorReview => 'Resenha do autor';

  @override
  String get detailEditAuthorReview => 'Editar resenha do autor';

  @override
  String get detailWriteReviewHint => 'Escreva sua resenha...';

  @override
  String get detailReviewVisibility =>
      'Visível para outros quando compartilhado. Sua resenha deste título.';

  @override
  String get detailNoReviewEditable =>
      'Ainda sem resenha. Toque em Editar para adicionar uma.';

  @override
  String get detailNoReviewReadonly => 'Sem resenha do autor.';

  @override
  String get detailMyNotes => 'Minhas notas';

  @override
  String get detailEditMyNotes => 'Editar minhas notas';

  @override
  String get detailWriteNotesHint => 'Escreva suas notas pessoais...';

  @override
  String get detailNoNotesYet =>
      'Ainda sem notas. Toque em Editar para adicionar suas notas pessoais.';

  @override
  String get detailNoNotesReadonly => 'Sem notas do autor.';

  @override
  String get unknownGame => 'Jogo desconhecido';

  @override
  String get unknownMovie => 'Filme desconhecido';

  @override
  String get unknownTvShow => 'Série desconhecida';

  @override
  String get unknownAnimation => 'Animação desconhecida';

  @override
  String get unknownVisualNovel => 'Visual Novel desconhecida';

  @override
  String get unknownManga => 'Manga desconhecido';

  @override
  String get unknownCustom => 'Item personalizado desconhecido';

  @override
  String get unknownPlatform => 'Plataforma desconhecida';

  @override
  String get defaultAuthor => 'Usuário';

  @override
  String errorPrefix(String error) {
    return 'Erro: $error';
  }

  @override
  String get allItemsRatingAsc => 'Avaliação ↑';

  @override
  String get allItemsRatingDesc => 'Avaliação ↓';

  @override
  String get allItemsNoItems => 'Ainda sem itens';

  @override
  String get allItemsNoMatch => 'Nenhum item corresponde ao filtro';

  @override
  String get allItemsAddViaCollections =>
      'Vá em Coleções → crie uma coleção → adicione itens\nvia Busca. Eles aparecerão aqui automaticamente.';

  @override
  String get allItemsFailedToLoad => 'Falha ao carregar itens';

  @override
  String get allPlatforms => 'Todas as plataformas';

  @override
  String get allItemsFilterPlatformsTitle => 'Filtrar por plataforma';

  @override
  String get debugIgdbMedia => 'IGDB Media';

  @override
  String get debugGamepad => 'Controle';

  @override
  String get debugClearLogs => 'Limpar logs';

  @override
  String get debugRawEvents => 'Eventos brutos (Gamepads.events)';

  @override
  String get debugServiceEvents => 'Eventos do serviço (filtrados)';

  @override
  String debugEventsCount(int count) {
    return '$count eventos';
  }

  @override
  String get debugPressButton => 'Pressione qualquer botão\nno controle...';

  @override
  String get debugExportLog => 'Exportar log para arquivo';

  @override
  String debugLogExported(String path) {
    return 'Log exportado para $path';
  }

  @override
  String get debugLogEmpty => 'Nenhum evento para exportar';

  @override
  String get settingsGamepadDebug => 'Depuração de controle';

  @override
  String get debugSearchGames => 'Buscar jogos';

  @override
  String get debugEnterGameName => 'Digite o nome do jogo';

  @override
  String get debugEnterGameNameHint => 'Digite um nome de jogo para buscar';

  @override
  String get debugGameId => 'ID do jogo';

  @override
  String get debugEnterGameId => 'Digite o ID do jogo no SteamGridDB';

  @override
  String debugLoadTab(String tabName) {
    return 'Carregar $tabName';
  }

  @override
  String debugEnterGameIdHint(String tabName) {
    return 'Digite um ID de jogo e pressione Carregar $tabName';
  }

  @override
  String get debugNoImagesFound => 'Nenhuma imagem encontrada';

  @override
  String collectionTileStats(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0 · $percent concluído';
  }

  @override
  String get collectionTileError => 'Erro ao carregar estatísticas';

  @override
  String get activityDatesTitle => 'Datas de atividade';

  @override
  String get activityDatesAdded => 'Adicionado';

  @override
  String get activityDatesStarted => 'Iniciado';

  @override
  String get activityDatesCompleted => 'Concluído';

  @override
  String get activityDatesSelectStart => 'Selecionar data de início';

  @override
  String get activityDatesSelectCompletion => 'Selecionar data de conclusão';

  @override
  String get settingsDateFormat => 'Formato de data';

  @override
  String get settingsDateFormatSubtitle => 'Como as datas são exibidas no app';

  @override
  String get settingsAnimeMangaTitleLanguage =>
      'Idioma dos títulos de anime e manga';

  @override
  String get settingsAnimeMangaTitleLanguageSubtitle =>
      'Título exibido para anime e manga';

  @override
  String get settingsAnimeMangaTitleLanguageRomaji => 'Romaji';

  @override
  String get settingsAnimeMangaTitleLanguageEnglish => 'Inglês';

  @override
  String get settingsAnimeMangaTitleLanguageNative => 'Nativo';

  @override
  String get dualDatePickerErrorEmpty => 'Digite uma data';

  @override
  String get dualDatePickerErrorFormat => 'Use o formato yyyy-MM-dd';

  @override
  String get dualDatePickerErrorRange => 'Data fora do intervalo';

  @override
  String activityDatesCompletionTime(String duration) {
    return 'Concluído em $duration';
  }

  @override
  String get timeSpentTitle => 'Tempo gasto';

  @override
  String get timeSpentAdd => 'Adicionar tempo';

  @override
  String get timeSpentEdit => 'Editar tempo';

  @override
  String get timeSpentHours => 'Horas';

  @override
  String get timeSpentMinutes => 'Minutos';

  @override
  String get durationLessThanDay => 'menos de um dia';

  @override
  String get durationOneDay => '1 dia';

  @override
  String durationDays(int count) {
    return '$count dias';
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
    return '$count anos';
  }

  @override
  String get canvasFailedToLoad => 'Falha ao carregar o quadro';

  @override
  String get canvasBoardEmpty => 'O quadro está vazio';

  @override
  String get canvasBoardEmptyHint => 'Adicione itens à coleção primeiro';

  @override
  String get canvasCenterView => 'Centralizar visualização';

  @override
  String get canvasResetPositions => 'Redefinir posições';

  @override
  String get canvasVgmapsBrowser => 'Navegador VGMaps';

  @override
  String get canvasSteamGridDbImages => 'Imagens do SteamGridDB';

  @override
  String get steamGridDbPanelTitle => 'SteamGridDB';

  @override
  String get closePanel => 'Fechar painel';

  @override
  String get steamGridDbSearchHint => 'Buscar jogo...';

  @override
  String get steamGridDbNoApiKey =>
      'Chave de API do SteamGridDB não configurada. Configure em Configurações.';

  @override
  String get steamGridDbBackToSearch => 'Voltar à busca';

  @override
  String get steamGridDbGrids => 'Grids';

  @override
  String get steamGridDbHeroes => 'Heroes';

  @override
  String get steamGridDbLogos => 'Logos';

  @override
  String get steamGridDbIcons => 'Ícones';

  @override
  String get steamGridDbSearchFirst => 'Busque um jogo primeiro';

  @override
  String get vgmapsBack => 'Voltar';

  @override
  String get vgmapsForward => 'Avançar';

  @override
  String get vgmapsHome => 'Início';

  @override
  String get vgmapsReload => 'Recarregar';

  @override
  String get vgmapsCaptureImage => 'Capturar imagem do mapa';

  @override
  String get vgmapsSearchHint => 'Buscar jogo no VGMaps...';

  @override
  String get vgmapsDismiss => 'Dispensar';

  @override
  String vgmapsFailedInit(String error) {
    return 'Falha ao inicializar WebView: $error';
  }

  @override
  String get discoverTitle => 'Descobrir';

  @override
  String get discoverCustomize => 'Personalizar';

  @override
  String get discoverTrending => 'Em alta esta semana';

  @override
  String get discoverTopRatedMovies => 'Filmes mais bem avaliados';

  @override
  String get discoverTopRatedTvShows => 'Séries mais bem avaliadas';

  @override
  String get discoverPopularTvShows => 'Séries populares';

  @override
  String get discoverUpcoming => 'Em breve';

  @override
  String get discoverCustomizeTitle => 'Personalizar Descobrir';

  @override
  String get discoverCustomizeHint => 'Escolha quais seções exibir';

  @override
  String get discoverResetDefault => 'Restaurar padrão';

  @override
  String get discoverAlreadyInCollection => 'Já na coleção';

  @override
  String get discoverShowWithBadge => 'Mostrar com selo';

  @override
  String get discoverHideCompletely => 'Ocultar completamente';

  @override
  String get recommendationsTitle => 'Recomendações';

  @override
  String get reviewsTitle => 'Resenhas';

  @override
  String reviewsShowAll(int count) {
    return 'Mostrar todas as $count resenhas';
  }

  @override
  String get reviewsReadMore => 'Ler mais';

  @override
  String get reviewsInEnglish => 'Resenhas em inglês';

  @override
  String get settingsShowRecommendationsSubtitle =>
      'Filmes e séries similares nas páginas de detalhes';

  @override
  String get settingsHideEmptyMediaTypeChevrons =>
      'Ocultar filtros de tipo vazios';

  @override
  String get settingsHideEmptyMediaTypeChevronsSubtitle =>
      'Oculta os seletores de tipo de mídia (Jogos, Filmes, etc.) quando não há itens desse tipo';

  @override
  String get settingsAlwaysShowSubcategories => 'Sempre mostrar subcategorias';

  @override
  String get settingsAlwaysShowSubcategoriesSubtitle =>
      'Mostra filtros de subcategoria (plataformas de jogos, tipos de anime/manga) sem selecionar o tipo de mídia primeiro';

  @override
  String get settingsShowPlatformOverlay => 'Capas com plataforma';

  @override
  String get settingsShowPlatformOverlaySubtitle =>
      'Mostra overlay de plataforma nos pôsteres de jogos (PS5, Switch, etc.)';

  @override
  String get settingsShowBlurayOverlay => 'Capas Blu-ray';

  @override
  String get settingsShowBlurayOverlaySubtitle =>
      'Mostra overlay Blu-ray nos pôsteres de filmes e séries';

  @override
  String get settingsRichCollections => 'Visualização enriquecida de coleções';

  @override
  String get settingsRichCollectionsSubtitle =>
      'Personalize coleções com imagem de capa e descrição';

  @override
  String get settingsCardScale => 'Tamanho da capa';

  @override
  String get settingsCardScaleSubtitle =>
      'Tamanho dos cards nas grades de coleções';

  @override
  String get collectionEditHeroImage => 'Imagem de capa';

  @override
  String get collectionEditHeroImageHint =>
      'Recomendado 2560×1080 (21:9). Assunto principal à direita — o lado esquerdo é coberto pelo título, a parte inferior se funde com o fundo';

  @override
  String get collectionEditHeroPick => 'Escolher imagem';

  @override
  String get collectionEditHeroReplace => 'Substituir imagem';

  @override
  String get collectionEditHeroRemove => 'Remover imagem';

  @override
  String get collectionEditDescriptionHint =>
      'Tagline curta exibida sobre a capa';

  @override
  String get collectionEditDialogTitle => 'Configurações da coleção';

  @override
  String get settingsDiscordRpc => 'Discord Rich Presence';

  @override
  String get settingsDiscordRpcSubtitle =>
      'Mostra o item visualizado no seu status do Discord';

  @override
  String get settingsDiscordRaSync => 'Sincronizar RetroAchievements';

  @override
  String get settingsDiscordRaSyncSubtitle =>
      'Mostra sua atividade do RetroAchievements no Discord em vez disso';

  @override
  String get uncategorizedBanner =>
      'Adicione a uma coleção para desbloquear Quadro e acompanhamento de episódios';

  @override
  String get uncategorizedDeprecationNotice =>
      'Esta coleção do sistema será removida em breve. Crie sua própria coleção e mova todos os itens daqui para ela.';

  @override
  String get uncategorizedDeprecationBadge => 'Será removida';

  @override
  String get browseFilterGenre => 'Gênero';

  @override
  String get browseFilterLength => 'Duração';

  @override
  String get vndbLengthVeryShort => 'Muito curta';

  @override
  String get vndbLengthShort => 'Curta';

  @override
  String get vndbLengthMedium => 'Média';

  @override
  String get vndbLengthLong => 'Longa';

  @override
  String get vndbLengthVeryLong => 'Muito longa';

  @override
  String get browseFilterAnimeAdaptation => 'Adaptação para anime';

  @override
  String get vndbHasAnimeAdaptation => 'Tem adaptação';

  @override
  String get tagPickerSearchHint => 'Buscar tags';

  @override
  String get tagPickerShowSpoilers => 'Mostrar tags de spoiler';

  @override
  String get tagPickerShowAdult => 'Mostrar tags +18';

  @override
  String get tagPickerRefresh => 'Atualizar catálogo';

  @override
  String get tagPickerEmpty => 'Nenhuma tag encontrada';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get browseFilterSeason => 'Temporada';

  @override
  String get browseFilterGameMode => 'Modo de jogo';

  @override
  String get browseFilterMinRating => 'Nota mín.';

  @override
  String get browseFilterMinVotes => 'Votos mín.';

  @override
  String get seasonWinter => 'Inverno';

  @override
  String get seasonSpring => 'Primavera';

  @override
  String get seasonSummer => 'Verão';

  @override
  String get seasonFall => 'Outono';

  @override
  String get animeFormatTv => 'TV';

  @override
  String get animeFormatMovie => 'Filme';

  @override
  String get animeFormatOva => 'OVA';

  @override
  String get animeFormatOna => 'ONA';

  @override
  String get animeFormatSpecial => 'Especial';

  @override
  String get animeFormatTvShort => 'Curta de TV';

  @override
  String get mangaStatusPublishing => 'Em publicação';

  @override
  String get mangaStatusFinished => 'Finalizado';

  @override
  String get mangaStatusNotYetPublished => 'Ainda não publicado';

  @override
  String get mangaStatusCancelled => 'Cancelado';

  @override
  String get mangaStatusHiatus => 'Em hiato';

  @override
  String get gameModeSinglePlayer => 'Um jogador';

  @override
  String get gameModeMultiplayer => 'Multijogador';

  @override
  String get gameModeCoOperative => 'Cooperativo';

  @override
  String get gameModeSplitScreen => 'Tela dividida';

  @override
  String get gameModeMmo => 'MMO';

  @override
  String get gameModeBattleRoyale => 'Battle Royale';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageJapanese => 'Japonês';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageChinese => 'Chinês';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageGerman => 'Alemão';

  @override
  String get languageRussian => 'Russo';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get mangaFormatManhwa => 'Manhwa';

  @override
  String get mangaFormatManhua => 'Manhua';

  @override
  String get mangaFormatOneShot => 'One-shot';

  @override
  String get mangaFormatNovel => 'Romance';

  @override
  String get mangaFormatLightNovel => 'Light novel';

  @override
  String get browseFilterContentRating => 'Classificação de conteúdo';

  @override
  String get browseFilterDemographic => 'Demografia';

  @override
  String get contentRatingSafe => 'Seguro';

  @override
  String get contentRatingSuggestive => 'Sugestivo';

  @override
  String get contentRatingErotica => 'Erótico';

  @override
  String get contentRatingPornographic => 'Pornográfico';

  @override
  String get browseSortRelevance => 'Relevância';

  @override
  String get browseSortPopular => 'Popular';

  @override
  String get browseSortTopRated => 'Mais bem avaliados';

  @override
  String get browseSortNewest => 'Mais recentes';

  @override
  String get browseSortMostVoted => 'Mais votados';

  @override
  String get browseSortMostRead => 'Mais lidos';

  @override
  String get browseSortTrending => 'Em alta';

  @override
  String get browseSortNameAsc => 'Nome (A–Z)';

  @override
  String get browseSortNameDesc => 'Nome (Z–A)';

  @override
  String get browseSortRecentlyUpdated => 'Atualizados recentemente';

  @override
  String get browseSortRecentlyAdded => 'Adicionados recentemente';

  @override
  String get browseAnimeTypeSeries => 'Séries';

  @override
  String get browseAnimeTypeMovies => 'Filmes';

  @override
  String get browseEmptyFilters => 'Escolha um filtro ou busque';

  @override
  String get browseBackToBrowse => 'Voltar à navegação';

  @override
  String get browseSortDisabledHint =>
      'Ordenação indisponível durante busca por texto';

  @override
  String get animeStatusAiring => 'Em exibição';

  @override
  String get animeStatusFinished => 'Finalizado';

  @override
  String get animeStatusNotYetAired => 'Ainda não exibido';

  @override
  String get animeStatusCancelled => 'Cancelado';

  @override
  String get typeToFilterHint => 'Filtrar...';

  @override
  String get appBarSearchHint => 'Comece a digitar para buscar';

  @override
  String get insertLink => 'Inserir link';

  @override
  String get linkText => 'Texto';

  @override
  String get linkHint => 'Guia';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'https://example.com';

  @override
  String get markdownBold => 'Negrito';

  @override
  String get markdownItalic => 'Itálico';

  @override
  String get insert => 'Inserir';

  @override
  String get navTierLists => 'Tier Lists';

  @override
  String get tierListCreate => 'Nova tier list';

  @override
  String get tierListCreateFromCollection => 'Criar tier list';

  @override
  String get tierListNameHint => 'Nome da tier list';

  @override
  String get tierListScopeAll => 'Todos os itens';

  @override
  String get tierListScopeCollection => 'De uma coleção';

  @override
  String tierListFromCollection(String name) {
    return 'De: $name';
  }

  @override
  String tierListRankedCount(int count) {
    return '$count classificados';
  }

  @override
  String get tierListTitle => 'Tier List';

  @override
  String get tierListUnranked => 'Sem classificar';

  @override
  String get exportAsImage => 'Exportar como imagem';

  @override
  String get tierListImageSaved => 'Tier list salva como imagem';

  @override
  String get tierListRename => 'Renomear nível';

  @override
  String get tierListChangeColor => 'Alterar cor';

  @override
  String get tierListMoveUp => 'Mover para cima';

  @override
  String get tierListMoveDown => 'Mover para baixo';

  @override
  String get tierListDeleteTier => 'Excluir nível';

  @override
  String get tierListAddTier => 'Adicionar nível';

  @override
  String get tierListClearConfirm =>
      'Remover todos os itens dos níveis? Eles voltarão para Sem classificar.';

  @override
  String get tierListDeleteConfirm => 'Excluir esta tier list?';

  @override
  String get tierListEmpty => 'Ainda sem tier lists';

  @override
  String get tierListEmptyHint =>
      'Toque em + para criar uma tier list e classificar itens\ndas suas coleções.';

  @override
  String get tierListAllRanked => 'Todos os itens classificados!';

  @override
  String get tierListErrorEmptyName => 'Digite um nome para a tier list';

  @override
  String get tierListErrorNoCollection => 'Selecione uma coleção';

  @override
  String get collectionPickerFilter => 'Filtrar coleções...';

  @override
  String get collectionPickerAlreadyAdded => '✓ Adicionado';

  @override
  String collectionPickerAlreadyInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Já está em $count coleções',
      one: 'Já está em $count coleção',
    );
    return '$_temp0';
  }

  @override
  String get settingsSteamImport => 'Biblioteca Steam';

  @override
  String get settingsSteamImportSubtitle => 'Importar jogos via Steam Web API';

  @override
  String get settingsIgdbImport => 'Lista IGDB';

  @override
  String get settingsIgdbImportSubtitle =>
      'Importar uma lista de jogos exportada do IGDB (CSV)';

  @override
  String get igdbImportTitle => 'Importar lista IGDB';

  @override
  String get igdbImportDescription =>
      'Escolha uma lista CSV exportada do IGDB. Os jogos são correspondidos pelo id do IGDB; o que o IGDB não tiver mais vai para a lista de desejos.';

  @override
  String get igdbImportSelectCsvFile => 'Selecionar arquivo CSV';

  @override
  String get igdbImportSelectCsvExport => 'Selecionar exportação CSV do IGDB';

  @override
  String get igdbImportStatusLabel => 'Status para jogos importados';

  @override
  String get igdbImportPlatformSelect => 'Selecionar plataforma';

  @override
  String get importIgdbRequired =>
      'Conexão com IGDB necessária. Configure as chaves de API em Configurações → Credenciais primeiro.';

  @override
  String get importing => 'Importando...';

  @override
  String get igdbReasonNotFound => 'Não encontrado no IGDB';

  @override
  String get steamImportTitle => 'Importar biblioteca Steam';

  @override
  String get importIgdbMatchNote =>
      'Os jogos serão correspondidos ao banco de dados IGDB';

  @override
  String get steamImportApiKey => 'Chave de API Steam';

  @override
  String get steamImportApiKeyHint =>
      'Obtenha uma chave gratuita em steamcommunity.com/dev/apikey';

  @override
  String get steamImportSteamId => 'Steam ID (64 bits)';

  @override
  String get steamImportSteamIdHint => 'Encontre em steamidfinder.com';

  @override
  String get steamImportPublicWarning => 'Seu perfil Steam deve ser público';

  @override
  String get steamImportButton => 'Importar biblioteca';

  @override
  String get steamImportFetchingLibrary => 'Obtendo biblioteca Steam...';

  @override
  String get steamImportMatching => 'Correspondendo jogos no IGDB...';

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
    return 'Adicionados à lista de desejos: $count';
  }

  @override
  String steamImportUpdated(int count) {
    return 'Atualizados: $count';
  }

  @override
  String get importComplete => 'Importação concluída!';

  @override
  String steamImportGamesImported(int count) {
    return '$count jogos importados';
  }

  @override
  String steamImportWishlistedInIgdb(int count) {
    return '$count adicionados à lista de desejos';
  }

  @override
  String steamImportUpdatedDuplicates(int count) {
    return '$count atualizados (existentes)';
  }

  @override
  String get steamImportPlayedStatus =>
      'Jogos jogados marcados como \"Em andamento\"';

  @override
  String get steamImportPlaytimeComment =>
      'Tempo de jogo salvo nos comentários';

  @override
  String get openCollection => 'Abrir coleção';

  @override
  String get steamImportRememberCredentials => 'Lembrar credenciais';

  @override
  String get collectionListSortCreatedDate => 'Data de criação';

  @override
  String get collectionListSortAlphabeticalAZ => 'A a Z';

  @override
  String get collectionListSortAlphabeticalZA => 'Z a A';

  @override
  String get collectionListViewGrid => 'Visualização em grade';

  @override
  String get collectionListViewList => 'Visualização em lista';

  @override
  String get collectionListViewTable => 'Visualização em tabela';

  @override
  String get collectionTableExternalRating => 'Externa';

  @override
  String get collectionCopyToCollection => 'Copiar para coleção';

  @override
  String collectionItemCopiedTo(Object collection, Object name) {
    return '$name copiado para $collection';
  }

  @override
  String collectionItemAlreadyInTarget(Object collection, Object name) {
    return '$name já está em $collection';
  }

  @override
  String get openInCollection => 'Abrir na coleção';

  @override
  String get importResultTitle => 'Resultados da importação';

  @override
  String importResultComplete(String source) {
    return 'Importação de $source concluída!';
  }

  @override
  String importResultFailed(String source) {
    return 'Falha na importação de $source';
  }

  @override
  String get importResultImported => 'Importados';

  @override
  String get importResultWishlisted => 'Adicionados à lista de desejos';

  @override
  String get importResultUpdated => 'Atualizados';

  @override
  String importResultErrors(int count) {
    return 'Erros ($count)';
  }

  @override
  String get importResultErrorsCopied => 'Erros copiados';

  @override
  String importResultSkipped(int count) {
    return '$count ignorados';
  }

  @override
  String get importResultOpenCollection => 'Abrir coleção';

  @override
  String get importResultWishlistHint =>
      'Itens não encontrados no banco de dados foram salvos na sua lista de desejos para depois.';

  @override
  String get importResultSourceCollectionFile => 'Arquivo de coleção';

  @override
  String get settingsBrowseCollections => 'Explorar coleções';

  @override
  String get settingsBrowseCollectionsSubtitle => 'Baixar coleções prontas';

  @override
  String browseCollectionsSummary(int count, int items) {
    return '$count coleções, $items itens';
  }

  @override
  String get browseCollectionsSearch => 'Buscar coleções...';

  @override
  String get browseCollectionsAllCategories => 'Todas as categorias';

  @override
  String browseCollectionsItems(int count) {
    return '$count itens';
  }

  @override
  String get browseCollectionsFormatLight => 'Leve (requer chaves de API)';

  @override
  String get browseCollectionsFormatFull => 'Completa (offline)';

  @override
  String get browseCollectionsDownloading => 'Baixando...';

  @override
  String browseCollectionsImportSuccess(String name) {
    return 'Coleção importada: $name';
  }

  @override
  String get browseCollectionsEmpty => 'Nenhuma coleção encontrada';

  @override
  String get browseCollectionsLoadError => 'Falha ao carregar coleções';

  @override
  String get browseCollectionsImportTarget => 'Importar para';

  @override
  String get browseCollectionsNewCollection => 'Nova coleção';

  @override
  String get browseCollectionsExistingCollection => 'Coleção existente';

  @override
  String get noCollectionsYet => 'Ainda sem coleções';

  @override
  String get settingsRaImport => 'RetroAchievements';

  @override
  String get settingsRaImportSubtitle => 'Importar jogos do RetroAchievements';

  @override
  String get raImportTitle => 'Importação RetroAchievements';

  @override
  String get raGetApiKey =>
      'Obtenha sua chave de API em retroachievements.org/controlpanel.php';

  @override
  String get raImportOptionWishlist =>
      'Adicionar jogos sem correspondência à lista de desejos';

  @override
  String get raImportFetchingLibrary => 'Obtendo biblioteca RA...';

  @override
  String get raImportSearchingIgdb => 'Buscando jogos no IGDB...';

  @override
  String raImportMatching(String title) {
    return 'Correspondendo: $title';
  }

  @override
  String raImportAdded(int count) {
    return '$count jogos adicionados';
  }

  @override
  String raImportUpdated(int count) {
    return '$count jogos atualizados';
  }

  @override
  String raImportToWishlist(int count) {
    return '$count adicionados à lista de desejos';
  }

  @override
  String raConnectionFailed(String error) {
    return 'Falha na conexão: $error';
  }

  @override
  String raProfilePoints(int points) {
    return '$points pontos';
  }

  @override
  String raProfileMemberSince(String date) {
    return 'Membro desde $date';
  }

  @override
  String get raRefresh => 'Atualizar conquistas';

  @override
  String get raOpenOnRa => 'Abrir no RA ↗';

  @override
  String get raHardcore => 'Hardcore';

  @override
  String get raCompletion => 'Conclusão';

  @override
  String get raRecentUnlocks => 'Desbloqueios recentes';

  @override
  String get raUpNext => 'Próximos';

  @override
  String raViewAll(int count) {
    return 'Ver todas as $count conquistas →';
  }

  @override
  String get raMastered => 'Dominado';

  @override
  String get raHardcoreMastered => 'Dominado Hardcore';

  @override
  String get raBeaten => 'Vencido';

  @override
  String get raBeatenSoftcore => 'Vencido Softcore';

  @override
  String get raHardcoreBeaten => 'Vencido Hardcore';

  @override
  String get raYesterday => 'Ontem';

  @override
  String raDaysAgo(int days) {
    return 'há $days d';
  }

  @override
  String get raPoints => 'pts';

  @override
  String get raAchievements => 'conq.';

  @override
  String get raMissable => 'PERDÍVEL';

  @override
  String get raFilterEarned => 'Conquistadas';

  @override
  String get raFilterLocked => 'Bloqueadas';

  @override
  String get raFilterMissable => 'Perdíveis';

  @override
  String get raFilterProgression => 'Progressão';

  @override
  String get raFilterWinCondition => 'Condição de vitória';

  @override
  String get raBeatenProgress => 'Progresso de conclusão';

  @override
  String get raStatsAchievements => 'conquistas';

  @override
  String get raStatsWorth => 'valendo';

  @override
  String get raStatsPoints => 'pontos';

  @override
  String get raStatsUnlocked => 'Desbloqueadas';

  @override
  String get copyAsText => 'Copiar como texto…';

  @override
  String copiedToClipboard(int count) {
    return '$count itens copiados para a área de transferência';
  }

  @override
  String get template => 'Modelo';

  @override
  String get textExportTokens => 'Tokens';

  @override
  String get textExportSortBy => 'Ordenar por';

  @override
  String get textExportSortCurrent => 'Ordem atual';

  @override
  String get textExportSortName => 'Nome A→Z';

  @override
  String get textExportSortYear => 'Ano ↓';

  @override
  String get textExportSortAdded => 'Data de adição ↓';

  @override
  String get textExportEmptyTemplate => 'O modelo está vazio';

  @override
  String get filtersClear => 'Limpar';

  @override
  String get collectionTableColumns => 'Colunas';

  @override
  String get tableFilterHint => 'Todas as regras se aplicam juntas (AND).';

  @override
  String get tableFilterAddRule => 'Adicionar regra';

  @override
  String get tableFilterCondContains => 'Contém';

  @override
  String get tableFilterCondEquals => 'Igual a';

  @override
  String get tableFilterCondStartsWith => 'Começa com';

  @override
  String get tableFilterCondEndsWith => 'Termina com';

  @override
  String get tableFilterCondAtLeast => 'No mínimo (≥)';

  @override
  String get tableFilterCondAtMost => 'No máximo (≤)';

  @override
  String get profiles => 'Perfis do app';

  @override
  String currentProfile(String name) {
    return 'Atual: $name';
  }

  @override
  String get switchProfile => 'Trocar perfil';

  @override
  String get addProfile => 'Adicionar perfil';

  @override
  String get createProfile => 'Criar perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get deleteProfile => 'Excluir perfil';

  @override
  String deleteProfileConfirm(String name) {
    return 'Excluir perfil $name? Isso excluirá todas as coleções, a lista de desejos e as configurações. Isso não pode ser desfeito.';
  }

  @override
  String get cannotDeleteLastProfile =>
      'Não é possível excluir o último perfil';

  @override
  String get profileName => 'Nome';

  @override
  String get whoIsPlayingToday => 'Quem está jogando hoje?';

  @override
  String get dontAskAgain => 'Não perguntar novamente';

  @override
  String profileStats(int collections, int items) {
    return '$collections coleções, $items itens';
  }

  @override
  String get switchingProfile => 'Trocando perfil…';

  @override
  String get appWillRestart =>
      'O app será reiniciado para aplicar as alterações.';

  @override
  String get profileCreated => 'Perfil criado';

  @override
  String get profileDeleted => 'Perfil excluído';

  @override
  String get settingsIntegrations => 'Integrações';

  @override
  String get settingsKodiSubtitle =>
      'Sincronização de visualizações do reprodutor Kodi';

  @override
  String get settingsOn => 'Ativado';

  @override
  String get kodiConnectionTitle => 'Conexão';

  @override
  String get kodiConnectionSubtitle =>
      'Kodi HTTP JSON-RPC (Configurações → Serviços → Controle)';

  @override
  String get kodiHost => 'Host';

  @override
  String get kodiPort => 'Porta';

  @override
  String get kodiPassword => 'Senha';

  @override
  String get kodiPasswordHint => 'Digite a senha';

  @override
  String get kodiTestConnection => 'Testar conexão';

  @override
  String get kodiConnecting => 'Conectando…';

  @override
  String get kodiPingFailed => 'Ping falhou — resposta inesperada';

  @override
  String kodiConnectedTo(String version, String name) {
    return 'Kodi $version \"$name\"';
  }

  @override
  String get kodiSyncTitle => 'Sincronização';

  @override
  String get kodiTargetCollectionSubtitle =>
      'Todos os filmes do Kodi sincronizam aqui';

  @override
  String get kodiTargetNotSelected => 'Não selecionada';

  @override
  String kodiTargetDeletedLabel(int id) {
    return 'Excluída (#$id)';
  }

  @override
  String get kodiEnableSync => 'Ativar sincronização Kodi';

  @override
  String get kodiEnableSyncActiveSubtitle =>
      'Ativa enquanto o Tonkatsu estiver em execução';

  @override
  String get kodiEnableSyncDisabledSubtitle =>
      'Selecione uma coleção de destino primeiro';

  @override
  String get kodiSyncInterval => 'Intervalo de sincronização';

  @override
  String get kodiCreateSubCollections =>
      'Criar subcoleções a partir dos conjuntos Kodi';

  @override
  String get kodiCreateSubCollectionsSubtitle =>
      'Ex.: \"Harry Potter Collection (kodi)\"';

  @override
  String get kodiImportRatings => 'Importar avaliações do Kodi';

  @override
  String get kodiImportRatingsSubtitle => 'Copiar userrating do Kodi (1–10)';

  @override
  String get kodiCollectionLibraryName => 'Biblioteca Kodi';

  @override
  String kodiCollectionCreated(String name) {
    return 'Criada \"$name\"';
  }

  @override
  String get kodiTargetDeletedSnack =>
      'Coleção de destino excluída — sincronização interrompida';

  @override
  String get kodiSyncStatus => 'Status da sincronização';

  @override
  String get kodiSyncRunning => 'Em execução';

  @override
  String get kodiSyncStopped => 'Parada';

  @override
  String get kodiLastSyncNever => 'Nunca';

  @override
  String get kodiClearLastSync => 'Limpar marca de última sincronização';

  @override
  String get kodiClearLastSyncSubtitle =>
      'A próxima sincronização buscará todos os itens assistidos';

  @override
  String get kodiLastSyncCleared => 'Marca de última sincronização limpa';

  @override
  String kodiRequestLog(int count) {
    return 'Log de requisições ($count)';
  }

  @override
  String get kodiCopyLog => 'Copiar log';

  @override
  String get kodiLogCopied => 'Log copiado';

  @override
  String get kodiClearLog => 'Limpar log';

  @override
  String get kodiNoRequests => 'Ainda sem requisições';

  @override
  String get kodiRawJsonRpc => 'JSON-RPC bruto';

  @override
  String get kodiMethod => 'Método';

  @override
  String get kodiParams => 'Parâmetros (JSON)';

  @override
  String get kodiSend => 'Enviar';

  @override
  String get kodiCopyToClipboard => 'Copiar para a área de transferência';

  @override
  String get kodiCopiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get kodiParamsNotObject => 'Erro: params deve ser um objeto JSON';

  @override
  String kodiJsonParseError(String message) {
    return 'Erro ao analisar JSON: $message';
  }

  @override
  String kodiRawError(String message) {
    return 'Erro: $message';
  }

  @override
  String get settingsMalImport => 'MyAnimeList';

  @override
  String get settingsMalImportSubtitle =>
      'Importar listas de anime/manga de exportação XML';

  @override
  String get malImportTitle => 'Importação MyAnimeList';

  @override
  String get malImportSubtitle =>
      'Anime e manga serão correspondidos ao AniList';

  @override
  String get malImportPickFiles => 'Adicionar arquivo XML';

  @override
  String get malImportFilesHint =>
      'Exporte XML de myanimelist.net/panel.php?go=export';

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
  String get malImportReadingFiles => 'Lendo arquivos...';

  @override
  String get malImportResolvingAnime => 'Resolvendo anime no AniList';

  @override
  String get malImportResolvingManga => 'Resolvendo manga no AniList';

  @override
  String malImportWishlisted(int count) {
    return '$count para a lista de desejos';
  }

  @override
  String get malImportOverwriteExisting => 'Sobrescrever entradas existentes';

  @override
  String get malImportOverwriteExistingHint =>
      'Quando desativado, itens já na coleção mantêm seu status, avaliação, progresso, datas e notas locais. Novos itens ainda são importados.';

  @override
  String malImportFailedLookup(int count) {
    return '$count ignorados (AniList inacessível)';
  }

  @override
  String malImportRateLimitWait(int seconds, int attempt, int max) {
    return 'Limite do AniList atingido — tentando novamente em ${seconds}s (tentativa $attempt/$max)';
  }

  @override
  String malImportInvalidFile(String error) {
    return 'Não foi possível analisar o XML: $error';
  }

  @override
  String malImportFilePicked(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return 'Selecionado: $kind ($_temp0)';
  }

  @override
  String get settingsAniListImport => 'AniList';

  @override
  String get settingsAniListImportSubtitle =>
      'Importar listas de anime/manga por nome de usuário público';

  @override
  String get settingsHardcoverImportSubtitle =>
      'Importar biblioteca de livros do hardcover.app por nome de usuário';

  @override
  String get hardcoverImportTitle => 'Importação Hardcover';

  @override
  String get hardcoverImportSubtitle =>
      'Obtém a biblioteca de um usuário do hardcover.app — parte pública para outros usuários, tudo para sua própria conta';

  @override
  String get hardcoverImportTokenMissing =>
      'Token da API Hardcover não configurado. Adicione em Configurações → Credenciais de API.';

  @override
  String get aniListImportTitle => 'Importação AniList';

  @override
  String get aniListImportSubtitle =>
      'Obtém listas públicas do anilist.co — sem login';

  @override
  String get aniListImportUsername => 'Nome de usuário AniList';

  @override
  String get aniListImportInclude => 'O que importar';

  @override
  String get aniListImportModeOverwriteSubtitle =>
      'Atualizar progresso, status e datas do AniList';

  @override
  String aniListImportNewCollectionDefault(String username) {
    return 'Importação AniList — $username';
  }

  @override
  String get aniListImportFetchingAnime => 'Obtendo lista de anime...';

  @override
  String get aniListImportFetchingManga => 'Obtendo lista de manga...';

  @override
  String aniListImportUserNotFound(String username) {
    return 'Usuário AniList \"$username\" não encontrado';
  }

  @override
  String aniListImportPrivateProfile(String username) {
    return 'Perfil AniList \"$username\" é privado';
  }

  @override
  String get aniListImportEmptyUsername => 'Digite seu nome de usuário AniList';

  @override
  String get aniListImportSelectAtLeastOne =>
      'Selecione anime ou manga para importar';

  @override
  String get settingsCustomCardsImport => 'Cards personalizados';

  @override
  String get settingsCustomCardsImportSubtitle =>
      'Importar cards de um arquivo JSON ou CSV';

  @override
  String get customImportTitle => 'Importar cards personalizados';

  @override
  String get customImportDescription =>
      'Carregue um arquivo JSON ou CSV produzido pelo seu próprio script ou parser — cada linha vira um card personalizado. Baixe um modelo para ver todos os campos e valores suportados.';

  @override
  String get customImportSelectFile => 'Selecionar arquivo JSON/CSV';

  @override
  String get customImportCsvTemplate => 'Modelo CSV';

  @override
  String get customImportJsonTemplate => 'Modelo JSON';

  @override
  String get customImportTemplateSaved => 'Modelo salvo';

  @override
  String get customImportPreviewButton => 'Pré-visualizar e importar';

  @override
  String get customImportPreviewTitle => 'Pré-visualização da importação';

  @override
  String customImportSummary(int valid, int errors, int duplicates) {
    return 'Reconhecidos $valid · Erros $errors · Duplicados $duplicates';
  }

  @override
  String get customImportSelectNone => 'Desmarcar todos';

  @override
  String customImportSelectedCount(int selected, int total) {
    return '$selected de $total selecionados';
  }

  @override
  String get customImportDuplicate => 'Duplicado — já está na coleção';

  @override
  String customImportRowLabel(int index) {
    return 'Linha $index';
  }

  @override
  String get customImportStart => 'Importar selecionados';

  @override
  String get customImportImporting => 'Importando cards personalizados...';

  @override
  String get customImportErrorEmptyFile => 'O arquivo está vazio';

  @override
  String get customImportErrorInvalidJson =>
      'JSON inválido — não foi possível analisar o arquivo';

  @override
  String get customImportErrorMissingColumns =>
      'CSV deve ter colunas \"title\" e \"type\"';

  @override
  String get customImportIssueNotAnObject => 'Não é um objeto JSON';

  @override
  String get customImportIssueMissingTitle => 'Falta \"title\"';

  @override
  String get customImportIssueMissingType => 'Falta \"type\"';

  @override
  String customImportIssueUnknownType(String value) {
    return 'Tipo desconhecido: $value';
  }

  @override
  String customImportIssueInvalidNumber(String field, String value) {
    return 'Valor inválido em \"$field\": $value';
  }

  @override
  String customImportIssueUnknownStatus(String value) {
    return 'Status desconhecido: $value';
  }

  @override
  String customImportIssueUnknownFormat(String value) {
    return 'Formato desconhecido: $value';
  }

  @override
  String get customImportIssueFormatNotApplicable =>
      '\"format\" é apenas para manga e anime';

  @override
  String get customImportIssueInvalidCover =>
      '\"cover\" deve ser uma URL http(s)';

  @override
  String customImportIssueInvalidDate(String field, String value) {
    return 'Data inválida em \"$field\": $value (esperado YYYY-MM-DD)';
  }

  @override
  String customImportIssueInvalidBool(String value) {
    return '\"favorite\" deve ser true/false: $value';
  }

  @override
  String get moodGridCreate => 'Criar Mood Grid';

  @override
  String get moodGridCreateTitle => 'Novo Mood Grid';

  @override
  String get moodGridPresetAboutMe => 'Sobre mim: Tonkatsu Box';

  @override
  String get moodGridPresetAboutMeSubtitle =>
      '1×5 — jogo, filme, série, anime e manga favoritos';

  @override
  String get moodGridPresetBlank => 'Em branco';

  @override
  String get moodGridPresetBlankSubtitle =>
      'Grade vazia com o tamanho que você escolher';

  @override
  String get moodGridRows => 'Linhas';

  @override
  String get moodGridBadge => 'Mood Grid';

  @override
  String get moodGridDeleteTitle => 'Excluir esta grade?';

  @override
  String get moodGridDeleteMessage =>
      'A grade será removida. Isso não pode ser desfeito.';

  @override
  String get moodGridAddRow => 'Adicionar linha';

  @override
  String get moodGridRemoveRow => 'Remover linha';

  @override
  String get moodGridAddCol => 'Adicionar coluna';

  @override
  String get moodGridRemoveCol => 'Remover coluna';

  @override
  String get moodGridShrinkTitle => 'Reduzir grade?';

  @override
  String get moodGridShrinkMessage =>
      'Células fora dos novos limites serão excluídas.';

  @override
  String get moodGridShrinkConfirm => 'Reduzir';

  @override
  String get moodGridEditLabel => 'Editar rótulo';

  @override
  String get moodGridLabelHint => 'Nome da categoria';

  @override
  String get moodGridPickItem => 'Escolher item';

  @override
  String get moodGridReplaceItem => 'Substituir item';

  @override
  String get moodGridClearItem => 'Limpar item';

  @override
  String get moodGridCaptionTemplate => 'Legendas das linhas';

  @override
  String get moodGridCaptionTemplateHint =>
      'Modelo aplicado por célula. Tokens disponíveis: name, year, genre, rating.';

  @override
  String get moodGridCellLabelTemplate => 'Legendas das células';

  @override
  String get moodGridCellSize => 'Tamanho';

  @override
  String get collection => 'Coleção';

  @override
  String get moodGridPickerAllCollections => 'Todas as coleções';

  @override
  String get moodGridPickerSearchHint => 'Buscar por nome';

  @override
  String get moodGridPickerEmpty => 'Nada para escolher';

  @override
  String get screenScraperSection => 'API ScreenScraper';

  @override
  String get screenScraperSourceDesc =>
      'Metadados de jogos + mídia (capas, capturas, arte)';

  @override
  String get screenScraperUserCredsHint =>
      'Credenciais de usuário (ssid / sspassword). Cota é por usuário.';

  @override
  String get screenScraperSsidLabel => 'ssid';

  @override
  String get screenScraperSsidPlaceholder => 'Seu login ScreenScraper';

  @override
  String get screenScraperSspasswordLabel => 'sspassword';

  @override
  String get screenScraperSspasswordPlaceholder => 'Sua senha ScreenScraper';

  @override
  String get screenScraperCheckQuota => 'Verificar cota';

  @override
  String get screenScraperRequestsToday => 'Requisições hoje';

  @override
  String get screenScraperPerMinLimit => 'Limite por minuto';

  @override
  String get screenScraperParallelThreads => 'Threads paralelas';

  @override
  String get screenScraperAccountLevel => 'Nível da conta';

  @override
  String get screenScraperGalleryTitle => 'Mídia ScreenScraper';

  @override
  String get screenScraperScreenshotsTitle => 'Capturas de tela';

  @override
  String get screenScraperLoading => 'Carregando mídia ScreenScraper…';

  @override
  String screenScraperError(String message) {
    return 'Erro ScreenScraper: $message';
  }

  @override
  String get screenScraperMediaBox => 'Caixa';

  @override
  String get screenScraperMediaBoxBack => 'Caixa (verso)';

  @override
  String get screenScraperMediaBox3D => 'Caixa 3D';

  @override
  String get screenScraperMediaWheel => 'Wheel';

  @override
  String get screenScraperMediaMarquee => 'Letreiro';

  @override
  String get screenScraperMediaTitle => 'Título';

  @override
  String get screenScraperMediaScreenshot => 'Captura';

  @override
  String get screenScraperMediaFanart => 'Fanart';

  @override
  String get screenScraperMediaMix => 'Mix';

  @override
  String get genreCloudTitle => 'Personalização';

  @override
  String get genreCloudEmpty => 'Ainda sem gêneros';

  @override
  String get genreCloudEmptyHint =>
      'Adicione itens com gêneros para construir a nuvem';

  @override
  String get genreCloudExportImage => 'Salvar como imagem';

  @override
  String get genreCloudExportFailed => 'Não foi possível salvar a imagem';

  @override
  String get genreCloudResetView => 'Redefinir visualização';

  @override
  String genreCloudHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocultos (não couberam)',
      one: '1 oculto (não coube)',
    );
    return '$_temp0';
  }

  @override
  String get facetPlatform => 'Plataformas';

  @override
  String get facetDecade => 'Décadas';

  @override
  String get personalizationTabCloud => 'Nuvem de gêneros';

  @override
  String get recommendationsEmpty => 'Ainda sem recomendações';

  @override
  String get recommendationsEmptyHint =>
      'Conclua e avalie alguns filmes ou séries para receber sugestões personalizadas';

  @override
  String get recommendationsNoCandidates => 'Nada novo para sugerir';

  @override
  String get recommendationsNoCandidatesHint =>
      'Não encontramos nada novo para sugerir agora. Tente novamente mais tarde';

  @override
  String get recommendationsNoApiKey => 'Chave de API TMDB necessária';

  @override
  String get recommendationsNoApiKeyHint =>
      'Adicione sua chave de API TMDB em Configurações para receber recomendações';

  @override
  String get recommendationsBecauseLabel => 'Porque você gostou de';

  @override
  String recommendationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recomendações',
      one: '1 recomendação',
    );
    return '$_temp0';
  }

  @override
  String get itemMarkLike => 'Curtir';

  @override
  String get itemMarkNote => 'Nota';

  @override
  String get itemMarkNoteHint => 'Escreva uma nota…';

  @override
  String get itemMarkSectionTitle => 'Notas e curtidas';

  @override
  String get itemMarkAdd => 'Adicionar marca';

  @override
  String get itemMarkEmpty => 'Ainda sem marcas';

  @override
  String get itemMarkNumber => 'Número';

  @override
  String get itemMarkNumberHint => 'ex.: 12';

  @override
  String get itemMarkNumberHelper => 'Obrigatório para salvar';

  @override
  String get itemMarkCustomType => 'Tipo personalizado';

  @override
  String get itemMarkFilterLiked => 'Curtidos';

  @override
  String get itemMarkFilterCommented => 'Com notas';

  @override
  String itemMarkUnitLabel(String type, int number) {
    return '$type $number';
  }

  @override
  String itemMarkEpisodeShort(int season, int episode) {
    return 'T$season·E$episode';
  }

  @override
  String get unitEpisode => 'Episódio';

  @override
  String get unitSeason => 'Temporada';

  @override
  String get unitChapter => 'Capítulo';

  @override
  String get unitVolume => 'Volume';

  @override
  String get unitPage => 'Página';

  @override
  String get unitPart => 'Parte';

  @override
  String get cardLinkCopy => 'Copiar link do card';

  @override
  String get cardLinkCopied => 'Link do card copiado';

  @override
  String get cardLinkNotFound => 'Card não encontrado';

  @override
  String get cardLinkSearchTitle => 'Vincular um card';

  @override
  String get cardLinkSearchHint => 'Buscar cards';

  @override
  String get shortcutsDialogTitle => 'Atalhos de teclado';

  @override
  String get shortcutsGroupNavigation => 'Navegação';

  @override
  String get shortcutSwitchTab => 'Trocar aba';

  @override
  String get shortcutNextTab => 'Próxima aba';

  @override
  String get shortcutPreviousTab => 'Aba anterior';

  @override
  String get shortcutThisHelp => 'Esta ajuda';

  @override
  String get shortcutCreateCollection => 'Criar coleção';

  @override
  String get shortcutImportCollection => 'Importar coleção';

  @override
  String get shortcutToggleView => 'Alternar visualização';

  @override
  String get shortcutDeleteCollection => 'Excluir coleção';

  @override
  String get shortcutRenameCollection => 'Renomear coleção';

  @override
  String get shortcutAddItems => 'Adicionar itens';

  @override
  String get shortcutExportCollection => 'Exportar coleção';

  @override
  String get shortcutImportIntoCollection => 'Importar na coleção';

  @override
  String get shortcutToggleBoard => 'Alternar Quadro/Canvas';

  @override
  String get shortcutDeleteItem => 'Excluir item';

  @override
  String get shortcutMoveItem => 'Mover item';

  @override
  String get shortcutsGroupItemDetail => 'Detalhe do item';

  @override
  String get shortcutLockCanvas => 'Bloquear/desbloquear canvas';

  @override
  String get shortcutMoveToCollection => 'Mover para coleção';

  @override
  String get shortcutSetRating => 'Definir avaliação';

  @override
  String get shortcutResetRating => 'Redefinir avaliação';

  @override
  String get shortcutsGroupTierLists => 'Tier lists';

  @override
  String get shortcutCreateTierList => 'Criar tier list';

  @override
  String get shortcutOpenTierList => 'Abrir tier list';

  @override
  String get shortcutDeleteTierList => 'Excluir tier list';

  @override
  String get shortcutsGroupTierList => 'Tier list';

  @override
  String get shortcutAddItem => 'Adicionar item';

  @override
  String get shortcutToggleCompleted => 'Mostrar/ocultar concluídos';

  @override
  String get shortcutClearCompleted => 'Limpar concluídos';

  @override
  String get shortcutFocusSearchField => 'Focar campo de busca';

  @override
  String get shortcutClearOrBack => 'Limpar / voltar';

  @override
  String get shortcutRunSearch => 'Executar busca';

  @override
  String get debugKeyEvents => 'Eventos de teclas do botão';

  @override
  String get settingsGamepadDebugSubtitle =>
      'Capturar códigos de botões do controle';

  @override
  String get statsTabTitle => 'Estatísticas';

  @override
  String get statsPeriodAllTime => 'Todo o período';

  @override
  String statsLede(String items) {
    return 'No total, $items itens na sua coleção';
  }

  @override
  String get statsMetricMoviesWatched => 'filmes assistidos';

  @override
  String get statsMetricMangaChapters => 'capítulos de mangá';

  @override
  String get statsMetricBookPages => 'páginas de livros';

  @override
  String get statsMetricEpisodes => 'episódios';

  @override
  String get statsMetricHours => 'assistidos e jogados';

  @override
  String get statsMetricAvgRating => 'nota média';

  @override
  String get statsMetricReplays => 'rejogadas';

  @override
  String get statsMetricLikedUnits => 'episódios curtidos';

  @override
  String statsHoursShort(String hours) {
    return '$hours h';
  }

  @override
  String statsHoursBreakdown(int manual, int tracker, int estimated) {
    return 'horas: manual $manual h · trackers $tracker h · estimado $estimated h';
  }

  @override
  String get statsMonthsTitle => 'Seu ano, mês a mês';

  @override
  String get statsMonthsTitleAllTime => 'Este ano, mês a mês';

  @override
  String get statsMonthsHint => 'capa: o título mais bem avaliado do mês';

  @override
  String get statsPeakLabel => 'pico';

  @override
  String statsMonthCounts(int items, int episodes) {
    return '$items adicionados · $episodes ep.';
  }

  @override
  String get statsVersusTitle => 'O melhor e o pior';

  @override
  String get statsVersusHint => 'pelas suas próprias notas';

  @override
  String get statsBest => 'Melhor';

  @override
  String get statsWorst => 'Pior';

  @override
  String statsPlatformsSummary(String hours, int games) {
    return '$hours h · $games jogos';
  }

  @override
  String get statsPlatformNone => 'Sem plataforma';

  @override
  String statsPlatformsShowAll(int count) {
    return 'Mostrar todas ($count)';
  }

  @override
  String get statsPlatformsCollapse => 'Recolher';

  @override
  String get statsHoursUnit => 'h';

  @override
  String get statsTypesTitle => 'Biblioteca por tipo';

  @override
  String get statsTypesHint =>
      'distribuição por status para cada tipo de mídia';

  @override
  String statsCompletedPercent(int percent) {
    return '$percent% concluídos';
  }

  @override
  String get statsPlatformMostPlayed => 'mais jogados';

  @override
  String get statsFormatsHint => 'o formato vem dos dados da fonte';

  @override
  String get statsSubgenresTitle => 'Subgêneros e tags';

  @override
  String get statsSubgenresHint => 'as tags da fonte são exibidas por tipo';

  @override
  String get statsCrowdTitle => 'Eu contra todos';

  @override
  String get statsCrowdHint => 'onde minha nota mais difere da fonte';

  @override
  String get statsCrowdHigher => 'Eu avalio mais alto';

  @override
  String get statsCrowdLower => 'Eu avalio mais baixo';

  @override
  String get statsCrowdMyRating => 'minha nota';

  @override
  String get statsCrowdSource => 'fonte';

  @override
  String get statsTopTitle => 'Mais bem avaliados';

  @override
  String statsTopHint(int count) {
    return 'os $count melhores';
  }

  @override
  String get statsEmptyTitle => 'Ainda sem estatísticas';

  @override
  String get statsEmptyBody =>
      'Adicione itens à sua biblioteca e os números aparecerão aqui.';

  @override
  String get statsExportTitle => 'Exportar cartão';

  @override
  String get statsExportFailed => 'Não foi possível salvar a imagem';

  @override
  String statsShareTitleYear(int year) {
    return 'Meu $year';
  }

  @override
  String get statsShareTitleAllTime => 'Minha biblioteca';

  @override
  String statsShareLede(String items, String completed, String rating) {
    return '$items itens · $completed concluídos · $rating de média';
  }

  @override
  String statsShareBest(String title, String rating) {
    return '$title · $rating — o melhor do período';
  }

  @override
  String get simklImportTitle => 'Importação do Simkl';

  @override
  String get settingsSimklImportSubtitle =>
      'Filmes, séries e anime da sua conta Simkl';

  @override
  String get simklImportSubtitle =>
      'Conecte sua conta Simkl com um código curto — filmes, séries e anime chegam em uma única importação, junto com o histórico de episódios';

  @override
  String get simklClientIdLabel => 'Chave do app Simkl (client_id)';

  @override
  String get simklGetClientId => 'Obter um client_id em simkl.com';

  @override
  String get simklRememberClientId => 'Lembrar a chave do app';

  @override
  String get simklGetPin => 'Obter código';

  @override
  String get simklGetNewPin => 'Obter um novo código';

  @override
  String get simklPinPrompt => 'Digite este código em simkl.com/pin:';

  @override
  String get simklOpenPinPage => 'Abrir simkl.com/pin';

  @override
  String get simklWaitingConfirmation => 'Aguardando confirmação…';

  @override
  String get simklPinExpired => 'O código expirou.';

  @override
  String simklConnectedAs(String name) {
    return 'Conta conectada: $name';
  }

  @override
  String get simklCheckingAccount => 'Verificando a conta…';

  @override
  String get simklRememberToken => 'Manter conectado neste dispositivo';

  @override
  String get simklRememberTokenSubtitle =>
      'O token de acesso fica salvo nas configurações; sem a opção, o código será pedido novamente';

  @override
  String get simklDisconnect => 'Desconectar';

  @override
  String get simklImportFetching => 'Obtendo a biblioteca do Simkl…';

  @override
  String get simklImportFetchingDetails => 'Obtendo as fichas…';

  @override
  String get simklImportWatchHistory => 'Restaurando o histórico de exibição…';

  @override
  String simklImportNewCollectionDefault(String name) {
    return 'Simkl: $name';
  }

  @override
  String get simklImportModeOverwriteSubtitle =>
      'Atualizar status, nota e comentário dos itens existentes';

  @override
  String get simklClientIdRequired =>
      'A importação precisa de uma chave do app Simkl — informe seu client_id';

  @override
  String simklImportRateLimitWait(int seconds, int attempt, int max) {
    return 'Limite de requisições atingido — tentando de novo em ${seconds}s (tentativa $attempt/$max)';
  }
}

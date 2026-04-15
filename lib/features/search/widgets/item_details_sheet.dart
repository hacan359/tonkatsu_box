// Универсальный bottom sheet с деталями элемента для всех типов медиа.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/copyable_text.dart';
import '../../../shared/widgets/gyroscope_parallax_image.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_badge.dart';

/// Универсальный bottom sheet с деталями элемента.
///
/// Заменяет GameDetailsSheet, MediaDetailsSheet, MangaDetailsSheet,
/// VnDetailsSheet одним модульным виджетом.
class ItemDetailsSheet extends StatelessWidget {
  /// Создаёт [ItemDetailsSheet].
  const ItemDetailsSheet({
    required this.title,
    required this.icon,
    this.onAddToCollection,
    this.overview,
    this.year,
    this.rating,
    this.genres,
    this.maxGenres,
    this.extraInfo,
    this.extraInfoIcon,
    this.subtitle,
    this.infoChips,
    this.posterUrl,
    this.cacheImageType,
    this.cacheImageId,
    this.externalUrl,
    this.dataSource,
    this.backdropUrl,
    this.coverHeight = 150,
    super.key,
  });

  /// Создаёт sheet для фильма.
  factory ItemDetailsSheet.movie(
    Movie movie, {
    VoidCallback? onAddToCollection,
    bool isAnimation = false,
  }) {
    final IconData icon =
        isAnimation ? Icons.animation : Icons.movie_outlined;
    return ItemDetailsSheet(
      title: movie.title,
      icon: icon,
      overview: movie.overview,
      year: movie.releaseYear,
      rating: movie.formattedRating,
      genres: movie.genres,
      extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
      extraInfoIcon: icon,
      posterUrl: movie.posterUrl,
      cacheImageType: ImageType.moviePoster,
      cacheImageId: movie.tmdbId.toString(),
      externalUrl: movie.externalUrl,
      backdropUrl: movie.backdropUrl,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для сериала.
  factory ItemDetailsSheet.tvShow(
    TvShow tvShow, {
    VoidCallback? onAddToCollection,
    bool isAnimation = false,
  }) {
    final IconData icon =
        isAnimation ? Icons.animation : Icons.tv_outlined;
    return ItemDetailsSheet(
      title: tvShow.title,
      icon: icon,
      overview: tvShow.overview,
      year: tvShow.firstAirYear,
      rating: tvShow.formattedRating,
      genres: tvShow.genres,
      extraInfo: tvShow.status,
      extraInfoIcon: icon,
      posterUrl: tvShow.posterUrl,
      cacheImageType: ImageType.tvShowPoster,
      cacheImageId: tvShow.tmdbId.toString(),
      externalUrl: tvShow.externalUrl,
      backdropUrl: tvShow.backdropUrl,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для игры.
  factory ItemDetailsSheet.game(
    Game game, {
    required VoidCallback onAddToCollection,
  }) {
    return ItemDetailsSheet(
      title: game.name,
      icon: Icons.videogame_asset,
      overview: game.summary,
      year: game.releaseYear,
      rating: game.formattedRating,
      genres: game.genres,
      posterUrl: game.coverUrl,
      cacheImageType: ImageType.gameCover,
      cacheImageId: game.id.toString(),
      externalUrl: game.externalUrl,
      dataSource: DataSource.igdb,
      backdropUrl: game.artworkUrl,
      coverHeight: 133,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для манги.
  factory ItemDetailsSheet.manga(
    Manga manga, {
    required VoidCallback onAddToCollection,
  }) {
    return ItemDetailsSheet(
      title: manga.title,
      icon: Icons.auto_stories,
      overview: manga.description,
      year: manga.releaseYear,
      rating: manga.formattedRating,
      genres: manga.genres,
      maxGenres: _defaultMaxChips,
      subtitle: manga.titleEnglish != manga.title
          ? manga.titleEnglish
          : null,
      infoChips: <(IconData, String)>[
        if (manga.authorsString != null)
          (Icons.person_outline, manga.authorsString!),
        (Icons.menu_book, manga.progressString),
      ],
      extraInfo: manga.formatLabel,
      posterUrl: manga.coverUrl,
      cacheImageType: ImageType.mangaCover,
      cacheImageId: manga.id.toString(),
      externalUrl: manga.externalUrl,
      dataSource: DataSource.anilist,
      backdropUrl: manga.bannerUrl,
      coverHeight: 142,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для аниме.
  factory ItemDetailsSheet.anime(
    Anime anime, {
    required VoidCallback onAddToCollection,
  }) {
    return ItemDetailsSheet(
      title: anime.title,
      icon: Icons.play_circle_outline,
      overview: anime.description,
      year: anime.releaseYear,
      rating: anime.formattedRating,
      genres: anime.genres,
      maxGenres: _defaultMaxChips,
      subtitle: anime.titleEnglish != anime.title ? anime.titleEnglish : null,
      infoChips: <(IconData, String)>[
        if (anime.studiosString != null)
          (Icons.business, anime.studiosString!),
        (Icons.play_circle_outline, anime.episodesString),
        if (anime.durationString != null)
          (Icons.timer_outlined, anime.durationString!),
      ],
      extraInfo: anime.formatLabel,
      posterUrl: anime.coverUrl,
      cacheImageType: ImageType.animeCover,
      cacheImageId: anime.id.toString(),
      externalUrl: anime.externalUrl,
      dataSource: DataSource.anilist,
      backdropUrl: anime.bannerUrl,
      coverHeight: 142,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Создаёт sheet для визуальной новеллы.
  factory ItemDetailsSheet.visualNovel(
    VisualNovel vn, {
    required VoidCallback onAddToCollection,
  }) {
    return ItemDetailsSheet(
      title: vn.title,
      icon: Icons.menu_book,
      overview: vn.description,
      year: vn.releaseYear,
      rating: vn.formattedRating,
      genres: vn.tags,
      maxGenres: _defaultMaxChips,
      subtitle: vn.altTitle,
      infoChips: <(IconData, String)>[
        if (vn.developersString != null)
          (Icons.business, vn.developersString!),
        if (vn.platformsString != null)
          (Icons.devices, vn.platformsString!),
      ],
      extraInfo: vn.lengthLabel,
      extraInfoIcon: Icons.timer_outlined,
      posterUrl: vn.imageUrl,
      cacheImageType: ImageType.vnCover,
      cacheImageId: vn.id,
      externalUrl: vn.externalUrl,
      dataSource: DataSource.vndb,
      coverHeight: 142,
      onAddToCollection: onAddToCollection,
    );
  }

  /// Максимальное количество чипов по умолчанию (для манги и VN).
  static const int _defaultMaxChips = 8;

  /// Название.
  final String title;

  /// Иконка типа медиа (используется для fallback обложки).
  final IconData icon;

  /// Callback добавления в коллекцию (если null — кнопка не показывается).
  final VoidCallback? onAddToCollection;

  /// Описание / summary.
  final String? overview;

  /// Год выпуска.
  final int? year;

  /// Рейтинг (форматированный).
  final String? rating;

  /// Список жанров / тегов.
  final List<String>? genres;

  /// Максимум отображаемых жанров (null = все).
  final int? maxGenres;

  /// Дополнительная информация (длительность, статус, формат).
  final String? extraInfo;

  /// Иконка для extraInfo (если null — текст без иконки).
  final IconData? extraInfoIcon;

  /// Альтернативное название (english title, alt title).
  final String? subtitle;

  /// Информационные чипы (иконка + текст): авторы, платформы и т.д.
  final List<(IconData, String)>? infoChips;

  /// URL постера / обложки.
  final String? posterUrl;

  /// Тип изображения для кэша.
  final ImageType? cacheImageType;

  /// ID изображения для кэша.
  final String? cacheImageId;

  /// URL внешней страницы.
  final String? externalUrl;

  /// Источник данных (по умолчанию TMDB).
  final DataSource? dataSource;

  /// URL фонового изображения (backdrop / artwork / banner).
  final String? backdropUrl;

  /// Высота обложки (ширина всегда 100).
  final double coverHeight;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Material(
          color: AppColors.background,
          elevation: 16,
          shadowColor: Colors.black,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.backgroundTile),
                repeat: ImageRepeat.repeat,
                opacity: 0.03,
                scale: 0.667,
              ),
            ),
            child: Stack(
              children: <Widget>[
              // Backdrop — на весь фон.
              // Если backdrop отсутствует, fallback'ом используем постер
              // с сильным blur (паттерн «амбиентный фон из обложки»).
              if (backdropUrl != null || posterUrl != null) ...<Widget>[
                Positioned.fill(
                  child: backdropUrl != null
                      ? GyroscopeParallaxImage(
                          imageUrl: backdropUrl!,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        )
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 40,
                            sigmaY: 40,
                            tileMode: TileMode.decal,
                          ),
                          child: GyroscopeParallaxImage(
                            imageUrl: posterUrl!,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                ),
                // Верх: затемнение для читаемости. В fallback-режиме
                // (постер вместо backdrop) делаем градиент плотнее, чтобы
                // фон не конкурировал с контентом.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          AppColors.background.withAlpha(
                            backdropUrl != null ? 120 : 160,
                          ),
                          AppColors.background.withAlpha(
                            backdropUrl != null ? 200 : 220,
                          ),
                          AppColors.background,
                        ],
                        stops: const <double>[0.0, 0.35, 0.6],
                      ),
                    ),
                  ),
                ),
              ],
              // Контент — единая лёгкая подложка
              SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(80),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.surfaceBorder.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeader(context),
                      if (overview != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0,
                            AppSpacing.lg, AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                S.of(context).searchDescription,
                                style: AppTypography.h3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(overview!,
                                  style: AppTypography.body),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Порог ширины, ниже которого header переключается на stacked layout
  /// (постер сверху по центру, информация полной шириной снизу).
  static const double _stackedLayoutBreakpoint = 500;

  /// Множитель размера постера в stacked layout (постер играет роль hero).
  static const double _stackedPosterScale = 1.3;

  /// Ширина резерва под кнопку + справа от инфо-колонки (44px кнопка + gap).
  static const double _addButtonReservedWidth = 48;

  /// Header: постер + информация + кнопка добавления.
  ///
  /// Контент (drag handle + poster/info) лежит в обычном Column,
  /// а кнопка + — `Positioned` поверх (HTML-аналог: `position: absolute`),
  /// поэтому не занимает собственной высоты и сохраняет позицию в правом
  /// верхнем углу.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // Drag handle (тонкая полоска).
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Poster + info: row на широком, column на узком (<500px).
              LayoutBuilder(
                builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final bool stacked =
                      constraints.maxWidth < _stackedLayoutBreakpoint;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (posterUrl != null) ...<Widget>[
                          Center(
                            child: _buildPoster(scale: _stackedPosterScale),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _buildInfoColumn(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (posterUrl != null) ...<Widget>[
                        _buildPoster(),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        // Резервируем место справа под кнопку +: в row-mode
                        // она лежит `Positioned(top:0, right:0)` и иначе
                        // перекрыла бы первую строку заголовка.
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: onAddToCollection != null
                                ? _addButtonReservedWidth
                                : 0,
                          ),
                          child: _buildInfoColumn(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          // Кнопка + позиционируется поверх — высоту не занимает.
          if (onAddToCollection != null)
            Positioned(
              top: 0,
              right: 0,
              child: _AddButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAddToCollection!();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Постер с placeholder/error fallback. [scale] масштабирует обе стороны.
  Widget _buildPoster({double scale = 1.0}) {
    final double width = 100 * scale;
    final double height = coverHeight * scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: CachedImage(
        imageType: cacheImageType ?? ImageType.moviePoster,
        imageId: cacheImageId ?? posterUrl!,
        remoteUrl: posterUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: Container(
          width: width,
          height: height,
          color: AppColors.surfaceLight,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: Container(
          width: width,
          height: height,
          color: AppColors.surfaceLight,
          child: Icon(icon, color: AppColors.textSecondary, size: 32),
        ),
      ),
    );
  }

  /// Колонка с заголовком, alt-title, source/rating/extraInfo, чипами и жанрами.
  Widget _buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Название + год (нажатие копирует название)
        CopyableText(
          text: title,
          iconSize: 16,
          child: Text.rich(
            TextSpan(children: <InlineSpan>[
              TextSpan(
                text: title,
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (year != null)
                TextSpan(
                  text: '  $year',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ]),
          ),
        ),
        // Подзаголовок (alt title)
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Source badge + rating + extra info
        Row(
          children: <Widget>[
            SourceBadge(
              source: dataSource ?? DataSource.tmdb,
              onTap: externalUrl != null
                  ? () => _launchUrl(externalUrl!)
                  : null,
            ),
            if (rating != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.star,
                  size: 14, color: AppColors.ratingStar),
              const SizedBox(width: 2),
              Text(rating!, style: AppTypography.bodySmall),
            ],
            if (extraInfo != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              if (extraInfoIcon != null) ...<Widget>[
                Icon(extraInfoIcon,
                    size: 14, color: AppColors.brand),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  extraInfo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: extraInfoIcon == null
                        ? AppColors.textSecondary
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Info chips (авторы, платформы и т.д.)
        if (infoChips != null && infoChips!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ...infoChips!.map(
            ((IconData, String) chip) => _buildInfoChip(
              chip.$1,
              chip.$2,
            ),
          ),
        ],
        // Жанры / теги
        if (genres != null && genres!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (maxGenres != null
                    ? genres!.take(maxGenres!)
                    : genres!)
                .map(_buildGenreChip)
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData chipIcon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(chipIcon, size: 14, color: AppColors.brand),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        genre,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Круглая парящая кнопка добавления в коллекцию.
class _AddButton extends StatefulWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: _hovered
              ? AppColors.brand.withAlpha(240)
              : AppColors.brand,
          shape: const CircleBorder(),
          elevation: _hovered ? 8 : 4,
          shadowColor: AppColors.brand.withAlpha(100),
          child: InkWell(
            onTap: widget.onPressed,
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withAlpha(40),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

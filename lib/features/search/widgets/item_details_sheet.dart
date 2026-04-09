// Универсальный bottom sheet с деталями элемента для всех типов медиа.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
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
              // Backdrop — на весь фон
              if (backdropUrl != null) ...<Widget>[
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: backdropUrl!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorWidget: (BuildContext context, String url,
                            Object error) =>
                        const SizedBox.shrink(),
                  ),
                ),
                // Верх: лёгкое затемнение для читаемости
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          AppColors.background.withAlpha(120),
                          AppColors.background.withAlpha(200),
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

  /// Header: backdrop (опционально) поверх постера + информация.
  Widget _buildHeader(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Drag handle + кнопка добавления
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (onAddToCollection != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _AddButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAddToCollection!();
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Poster + info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (posterUrl != null) ...<Widget>[
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedImage(
                    imageType: cacheImageType ?? ImageType.moviePoster,
                    imageId: cacheImageId ?? posterUrl!,
                    remoteUrl: posterUrl!,
                    width: 100,
                    height: coverHeight,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 100,
                      height: coverHeight,
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: Container(
                      width: 100,
                      height: coverHeight,
                      color: AppColors.surfaceLight,
                      child: Icon(icon,
                          color: AppColors.textSecondary, size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Название + год
                    Text.rich(
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
                          Text(
                            extraInfo!,
                            style: AppTypography.bodySmall.copyWith(
                              color: extraInfoIcon == null
                                  ? AppColors.textSecondary
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Info chips (авторы, платформы и т.д.)
                    if (infoChips != null &&
                        infoChips!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      ...infoChips!.map(
                        ((IconData, String) chip) => _buildInfoChip(
                          chip.$1,
                          chip.$2,
                        ),
                      ),
                    ],
                    // Жанры / теги
                    if (genres != null &&
                        genres!.isNotEmpty) ...<Widget>[
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
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return content;
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

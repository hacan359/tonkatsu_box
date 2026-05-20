import '../../../../shared/models/media_type.dart';

/// Result of the create / edit custom item form.
class CustomItemData {
  const CustomItemData({
    required this.title,
    required this.mediaType,
    this.altTitle,
    this.description,
    this.year,
    this.coverUrl,
    this.localCoverPath,
    this.genres,
    this.platform,
    this.externalUrl,
  });

  final String title;
  final String? altTitle;
  final MediaType mediaType;
  final String? description;
  final int? year;
  final String? coverUrl;
  final String? localCoverPath;
  final String? genres;
  final String? platform;
  final String? externalUrl;
}

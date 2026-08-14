import '../models/image_type.dart';

/// Where the server's image cache lives, so both ends spell the prefix once.
const String kImagePathPrefix = '/img';

/// The source URL travels with the request: the browser already holds it, and
/// deriving it server-side would mean teaching the server every provider.
const String kImageSourceParam = 'src';

/// `/img/<folder>/<id>?src=…` — a cache the server fills on the first miss.
/// Without [sourceUrl] the path only addresses what the cache already holds.
String imageProxyPath({
  required ImageType type,
  required String imageId,
  String? sourceUrl,
}) {
  return Uri(
    path: '$kImagePathPrefix/${type.folder}/$imageId',
    queryParameters: sourceUrl == null
        ? null
        : <String, String>{kImageSourceParam: sourceUrl},
  ).toString();
}

/// [imageProxyPath] prefixed with the server origin — the form every
/// client-side fetch and upload uses.
String imageProxyUrl({
  required String baseUrl,
  required ImageType type,
  required String imageId,
  String? sourceUrl,
}) {
  return '$baseUrl'
      '${imageProxyPath(type: type, imageId: imageId, sourceUrl: sourceUrl)}';
}

ImageType? imageTypeForFolder(String folder) => _byFolder[folder];

final Map<String, ImageType> _byFolder = <String, ImageType>{
  for (final ImageType t in ImageType.values) t.folder: t,
};

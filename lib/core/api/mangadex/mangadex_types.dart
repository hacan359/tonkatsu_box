/// The MangaDex UUID folded into a manga `externalUrl` (`.../title/{uuid}`);
/// empty when [url] is null or has no path segment.
String mangaDexUuidFromUrl(String? url) {
  if (url == null) return '';
  final List<String> segments = Uri.parse(url).pathSegments;
  return segments.isEmpty ? '' : segments.last;
}

/// Error from the MangaDex API. [detail] is a redacted, copyable debug
/// string (request + status + body) consumed by `extractApiError`.
class MangaDexApiException implements Exception {
  const MangaDexApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'MangaDexApiException: $message (status: $statusCode)';
}

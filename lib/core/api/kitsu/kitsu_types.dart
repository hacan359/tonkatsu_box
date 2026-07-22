/// Error from the Kitsu API. [detail] is a redacted, copyable debug string
/// (request + status + body) consumed by `extractApiError`.
class KitsuApiException implements Exception {
  const KitsuApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'KitsuApiException: $message (status: $statusCode)';
}

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

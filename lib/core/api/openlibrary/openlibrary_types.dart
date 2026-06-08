/// Error from the OpenLibrary API. [detail] is a redacted, copyable debug
/// string (request + status + body) consumed by `extractApiError`.
class OpenLibraryApiException implements Exception {
  const OpenLibraryApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() =>
      'OpenLibraryApiException: $message (status: $statusCode)';
}

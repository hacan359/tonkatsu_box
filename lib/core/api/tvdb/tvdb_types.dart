/// Error raised by the TheTVDB client.
class TvdbApiException implements Exception {
  const TvdbApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'TvdbApiException: $message (status: $statusCode)';
}

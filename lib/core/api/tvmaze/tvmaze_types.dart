/// Error raised by the TVmaze client.
class TvMazeApiException implements Exception {
  const TvMazeApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'TvMazeApiException: $message (status: $statusCode)';
}

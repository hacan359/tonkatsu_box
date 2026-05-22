class TwitchAuthResult {
  const TwitchAuthResult({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory TwitchAuthResult.fromJson(Map<String, dynamic> json) {
    return TwitchAuthResult(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
    );
  }

  final String accessToken;
  final int expiresIn;
  final String tokenType;

  /// Unix timestamp when the token expires.
  int get expiresAt {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
  }
}

class IgdbApiException implements Exception {
  const IgdbApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'IgdbApiException: $message (status: $statusCode)';
}

typedef IgdbTokenRefreshedCallback = void Function(
  String accessToken,
  int expiresAt,
);

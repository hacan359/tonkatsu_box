/// Error raised by the MusicBrainz client.
class MusicBrainzApiException implements Exception {
  const MusicBrainzApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() =>
      'MusicBrainzApiException: $message (status: $statusCode)';
}

/// One release (edition) of a release-group, for the edition strip / picker.
class MusicBrainzRelease {
  const MusicBrainzRelease({
    required this.mbid,
    required this.title,
    this.status,
    this.date,
    this.country,
    this.label,
    this.format,
    this.trackCount,
    this.discCount,
  });

  factory MusicBrainzRelease.fromJson(Map<String, dynamic> json) {
    final List<dynamic> media =
        json['media'] as List<dynamic>? ?? <dynamic>[];
    int trackCount = 0;
    String? format;
    for (final Object? m in media) {
      if (m is! Map<String, dynamic>) continue;
      trackCount += (m['track-count'] as num?)?.toInt() ?? 0;
      format ??= m['format'] as String?;
    }
    final List<dynamic> labelInfo =
        json['label-info'] as List<dynamic>? ?? <dynamic>[];
    String? label;
    for (final Object? li in labelInfo) {
      if (li is! Map<String, dynamic>) continue;
      final Object? l = li['label'];
      if (l is Map<String, dynamic>) {
        label = l['name'] as String?;
        if (label != null) break;
      }
    }

    return MusicBrainzRelease(
      mbid: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String?,
      date: json['date'] as String?,
      country: json['country'] as String?,
      label: label,
      format: format,
      trackCount: trackCount > 0 ? trackCount : null,
      discCount: media.isNotEmpty ? media.length : null,
    );
  }

  final String mbid;
  final String title;

  /// Official / Promotion / Bootleg / …
  final String? status;

  /// "YYYY-MM-DD", possibly truncated.
  final String? date;

  final String? country;
  final String? label;
  final String? format;
  final int? trackCount;
  final int? discCount;
}

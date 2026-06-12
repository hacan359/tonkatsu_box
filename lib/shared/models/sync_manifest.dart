import 'dart:convert';

/// Metadata written next to a database snapshot in the sync folder.
class SyncManifest {
  /// Creates a [SyncManifest].
  const SyncManifest({
    required this.deviceName,
    required this.createdAt,
    required this.schemaVersion,
    required this.appVersion,
    required this.collections,
    required this.items,
    this.profileName,
  });

  /// Parses a manifest; throws [FormatException] on malformed JSON.
  factory SyncManifest.fromJsonString(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifest is not a JSON object');
    }
    return SyncManifest(
      deviceName: decoded['device_name'] as String? ?? '',
      createdAt: DateTime.tryParse(decoded['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion: decoded['schema_version'] as int? ?? 0,
      appVersion: decoded['app_version'] as String? ?? '',
      collections: decoded['collections'] as int? ?? 0,
      items: decoded['items'] as int? ?? 0,
      profileName: decoded['profile_name'] as String?,
    );
  }

  /// Name of the device that produced the snapshot.
  final String deviceName;

  /// Snapshot creation time.
  final DateTime createdAt;

  /// `PRAGMA user_version` of the snapshot.
  final int schemaVersion;

  /// App version that produced the snapshot.
  final String appVersion;

  /// Collections count at snapshot time.
  final int collections;

  /// Collection items count at snapshot time.
  final int items;

  /// Active profile name at snapshot time, when profiles are in use.
  final String? profileName;

  /// Serialises to pretty-printed JSON.
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'device_name': deviceName,
      'created_at': createdAt.toIso8601String(),
      'schema_version': schemaVersion,
      'app_version': appVersion,
      'collections': collections,
      'items': items,
      if (profileName != null) 'profile_name': profileName,
    });
  }
}

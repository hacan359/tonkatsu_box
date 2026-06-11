import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// A mounted storage volume usable as a folder-picker root.
class StorageVolume {
  /// Creates a [StorageVolume].
  const StorageVolume({required this.path, required this.isPrimary});

  /// Volume root directory.
  final String path;

  /// Whether this is the built-in internal storage.
  final bool isPrimary;
}

/// Detects mounted storage volumes on Android.
class StorageVolumes {
  StorageVolumes._();

  /// Test seam: real volume mounts live under `/storage`.
  @visibleForTesting
  static String storageRoot = '/storage';

  /// Canonical primary (internal) storage path.
  static String get primaryPath => p.join(storageRoot, 'emulated', '0');

  /// Internal storage plus mounted removable volumes (SD card, USB OTG).
  ///
  /// Removable volumes mount under `/storage/<VOLUME-ID>`; `emulated`
  /// (covered by the primary entry) and `self` (a bind-mount alias of
  /// the primary) are skipped.
  static List<StorageVolume> detect() {
    final List<StorageVolume> volumes = <StorageVolume>[];

    final String primary = primaryPath;
    if (Directory(primary).existsSync()) {
      volumes.add(StorageVolume(path: primary, isPrimary: true));
    }

    final Directory root = Directory(storageRoot);
    if (!root.existsSync()) return volumes;

    final List<StorageVolume> removable = <StorageVolume>[];
    for (final FileSystemEntity entity in root.listSync()) {
      if (entity is! Directory) continue;
      final String name = p.basename(entity.path);
      if (name == 'emulated' || name == 'self') continue;
      removable.add(StorageVolume(path: entity.path, isPrimary: false));
    }
    removable.sort(
      (StorageVolume a, StorageVolume b) => a.path.compareTo(b.path),
    );
    return volumes..addAll(removable);
  }
}

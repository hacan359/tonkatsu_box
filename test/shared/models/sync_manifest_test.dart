import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/sync_manifest.dart';

void main() {
  group('SyncManifest', () {
    SyncManifest sample({bool supportsSettingsTransfer = true}) => SyncManifest(
          deviceName: 'PC',
          createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
          schemaVersion: 7,
          appVersion: '1.2.3',
          collections: 4,
          items: 9,
          supportsSettingsTransfer: supportsSettingsTransfer,
        );

    group('supportsSettingsTransfer', () {
      test('round-trips through toJsonString/fromJsonString', () {
        final SyncManifest restored =
            SyncManifest.fromJsonString(sample().toJsonString());

        expect(restored.supportsSettingsTransfer, isTrue);
      });

      test('defaults to false when supports_settings is absent', () {
        // Manifests written by peers from before settings transfer existed
        // carry no capability flag; the receiver must treat them as opt-out.
        const String legacy = '{"device_name":"OLD","created_at":'
            '"2026-01-01T00:00:00.000","schema_version":1,'
            '"app_version":"0.1.0","collections":0,"items":0}';

        expect(
          SyncManifest.fromJsonString(legacy).supportsSettingsTransfer,
          isFalse,
        );
      });
    });

    test('preserves the other fields through a round-trip', () {
      final SyncManifest restored =
          SyncManifest.fromJsonString(sample().toJsonString());

      expect(restored.deviceName, 'PC');
      expect(restored.schemaVersion, 7);
      expect(restored.appVersion, '1.2.3');
      expect(restored.collections, 4);
      expect(restored.items, 9);
    });
  });
}

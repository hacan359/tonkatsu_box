import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/config_service.dart';
import 'package:tonkatsu_box/core/services/db_sync_service.dart';
import 'package:tonkatsu_box/core/services/lan_sync_service.dart';
import 'package:tonkatsu_box/core/services/storage_root.dart';
import 'package:tonkatsu_box/shared/models/sync_manifest.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LanSyncService', () {
    group('parseAnnouncement', () {
      final InternetAddress sender = InternetAddress('192.168.1.20');

      List<int> packet(Map<String, Object?> json) =>
          utf8.encode(jsonEncode(json));

      test('parses a valid announcement', () {
        final LanPeer? peer = LanSyncService.parseAnnouncement(
          packet(<String, Object?>{
            'app': 'tonkatsubox-sync',
            'id': 'abc',
            'name': 'DESKTOP-X',
            'port': 4242,
          }),
          sender,
        );

        expect(peer, isNotNull);
        expect(peer!.id, 'abc');
        expect(peer.name, 'DESKTOP-X');
        expect(peer.port, 4242);
        expect(peer.address, sender);
      });

      test('rejects packets from other apps', () {
        expect(
          LanSyncService.parseAnnouncement(
            packet(<String, Object?>{'app': 'other', 'id': 'a', 'port': 1}),
            sender,
          ),
          isNull,
        );
      });

      test('rejects malformed packets', () {
        expect(
          LanSyncService.parseAnnouncement(
            utf8.encode('definitely not json'),
            sender,
          ),
          isNull,
        );
        expect(
          LanSyncService.parseAnnouncement(
            packet(<String, Object?>{'app': 'tonkatsubox-sync'}),
            sender,
          ),
          isNull,
        );
        expect(
          LanSyncService.parseAnnouncement(
            packet(<String, Object?>{
              'app': 'tonkatsubox-sync',
              'id': 'a',
              'name': 'b',
              'port': 99999,
            }),
            sender,
          ),
          isNull,
        );
      });
    });

    group('HTTP transfer over loopback', () {
      late Directory tempDir;
      late DatabaseService dbService;
      late DbSyncService dbSync;
      late LanSyncService lan;

      Future<SyncDeviceMeta> testMeta() async =>
          const SyncDeviceMeta(deviceName: 'SERVER', appVersion: '1.0.0');

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('lan_sync_test');
        final String dataDir = p.join(tempDir.path, 'data');
        await Directory(dataDir).create(recursive: true);
        StorageRoot.defaultPathProvider = () async => dataDir;
        StorageRoot.resetSessionCache();
        SharedPreferences.setMockInitialValues(<String, Object>{});

        dbService = DatabaseService();
        dbSync = DbSyncService(database: dbService, metaProvider: testMeta);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        lan = LanSyncService(
          sync: dbSync,
          config: ConfigService(prefs: prefs),
        );
      });

      tearDown(() async {
        await lan.stop();
        await dbService.close();
        StorageRoot.defaultPathProvider = null;
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      LanPeer self() => LanPeer(
            id: 'srv',
            name: 'SERVER',
            address: InternetAddress.loopbackIPv4,
            port: lan.port!,
          );

      test('serves the manifest', () async {
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );

        final SyncManifest? manifest = await lan.fetchManifest(self());

        expect(manifest, isNotNull);
        expect(manifest!.deviceName, 'SERVER');
        expect(manifest.appVersion, '1.0.0');
      });

      test('advertises settings transfer in the manifest', () async {
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );

        final SyncManifest? manifest = await lan.fetchManifest(self());

        expect(manifest?.supportsSettingsTransfer, isTrue);
      });

      test('serves the settings bundle over /config', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('tmdb_api_key', 'CONFIG-TMDB');
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );

        final HttpClient client = HttpClient();
        try {
          final HttpClientRequest request = await client.getUrl(
            Uri.http(
              '${InternetAddress.loopbackIPv4.address}:${lan.port}',
              '/config',
            ),
          );
          final HttpClientResponse response = await request.close();
          final String body = await response.transform(utf8.decoder).join();
          final Map<String, dynamic> config =
              jsonDecode(body) as Map<String, dynamic>;

          expect(config['tmdb_api_key'], 'CONFIG-TMDB');
          expect(config['tonkatsu_box_config_version'], isNotNull);
        } finally {
          client.close(force: true);
        }
      });

      test('downloadConfig applies the served bundle', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', 'ru');
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );

        expect(await lan.downloadConfig(self()), greaterThan(0));
      });

      test('serves a receivable snapshot when approved', () async {
        final Database db = await dbService.database;
        await db.insert('collections', <String, Object?>{
          'name': 'From server',
          'author': 'tester',
          'created_at': 1700000000,
        });
        String? requesterSeen;
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (String requester) async {
            requesterSeen = requester;
            return true;
          },
        );
        final String intoDir = p.join(tempDir.path, 'incoming');

        await lan.downloadSnapshot(
          self(),
          intoDir,
          requesterName: 'PHONE',
        );

        expect(requesterSeen, 'PHONE');
        final SyncSnapshotInfo info = await dbSync.inspectSnapshot(intoDir);
        expect(info.receivable, isTrue);
      });

      test('refuses the snapshot when the user declines', () async {
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => false,
        );

        expect(
          () => lan.downloadSnapshot(
            self(),
            p.join(tempDir.path, 'incoming'),
            requesterName: 'PHONE',
          ),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              LanSyncService.deniedMessage,
            ),
          ),
        );
      });

      test('returns null manifest when the peer is gone', () async {
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );
        final LanPeer peer = self();
        await lan.stop();

        expect(await lan.fetchManifest(peer), isNull);
      });

      test('stop clears the peer list and the port', () async {
        await lan.start(
          deviceName: 'SERVER',
          onSnapshotRequest: (_) async => true,
        );
        expect(lan.isRunning, isTrue);

        await lan.stop();

        expect(lan.isRunning, isFalse);
        expect(lan.port, isNull);
        expect(lan.peers.value, isEmpty);
      });
    });
  });
}

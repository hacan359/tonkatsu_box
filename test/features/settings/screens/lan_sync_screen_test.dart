import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/db_sync_service.dart';
import 'package:tonkatsu_box/core/services/lan_sync_service.dart';
import 'package:tonkatsu_box/features/settings/screens/lan_sync_screen.dart';

import '../../../helpers/test_helpers.dart';

/// Real sockets never complete inside FakeAsync; stub the network out.
class _FakeLanSyncService extends LanSyncService {
  _FakeLanSyncService({required super.sync});

  bool started = false;

  @override
  Future<void> start({
    required String deviceName,
    required Future<bool> Function(String requesterName) onSnapshotRequest,
  }) async {
    started = true;
  }

  @override
  Future<void> stop() async {
    started = false;
  }
}

void main() {
  late DbSyncService dbSync;
  late _FakeLanSyncService fakeLan;

  setUp(() {
    dbSync = DbSyncService(
      database: DatabaseService(),
      metaProvider: () async =>
          const SyncDeviceMeta(deviceName: 'TEST-DEVICE', appVersion: '1.0'),
    );
    fakeLan = _FakeLanSyncService(sync: dbSync);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      const LanSyncScreen(),
      overrides: <Override>[
        dbSyncServiceProvider.overrideWithValue(dbSync),
        lanSyncServiceProvider.overrideWithValue(fakeLan),
      ],
      wrapInScaffold: true,
      settle: false,
    );
    await tester.pump();
    await tester.pump();
  }

  group('LanSyncScreen', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('starts the service and shows this device name',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      expect(fakeLan.started, isTrue);
      expect(find.textContaining('TEST-DEVICE'), findsOneWidget);
    });

    testWidgets('lists discovered peers', (WidgetTester tester) async {
      await pumpScreen(tester);

      fakeLan.peers.value = <LanPeer>[
        LanPeer(
          id: 'a',
          name: 'DESKTOP-REMOTE',
          address: InternetAddress.loopbackIPv4,
          port: 4242,
        ),
      ];
      await tester.pump();

      expect(find.text('DESKTOP-REMOTE'), findsOneWidget);
    });

    testWidgets('stops the service when the screen is disposed',
        (WidgetTester tester) async {
      await pumpScreen(tester);
      expect(fakeLan.started, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(fakeLan.started, isFalse);
    });
  });
}

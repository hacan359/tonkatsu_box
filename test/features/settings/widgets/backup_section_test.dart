import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/storage_root.dart';
import 'package:tonkatsu_box/features/settings/widgets/backup_section.dart';
import 'package:tonkatsu_box/features/settings/widgets/settings_tile.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_section_test');
    StorageRoot.defaultPathProvider = () async => tempDir.path;
    StorageRoot.resetSessionCache();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    StorageRoot.defaultPathProvider = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  SettingsTile tile(WidgetTester tester) =>
      tester.widget<SettingsTile>(find.byType(SettingsTile));

  group('BackupSection', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await tester.pumpApp(const BackupSection(), wrapInScaffold: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(const BackupSection(), wrapInScaffold: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('is disabled while no backup exists',
        (WidgetTester tester) async {
      await tester.pumpApp(const BackupSection(), wrapInScaffold: true);

      expect(tile(tester).onTap, isNull);
    });

    testWidgets('is enabled when a backup sits next to the database',
        (WidgetTester tester) async {
      // Sync IO: real async IO never completes inside testWidgets' FakeAsync.
      File(p.join(tempDir.path, 'tonkatsu_box.db.bak'))
          .writeAsStringSync('bak');

      await tester.pumpApp(const BackupSection(), wrapInScaffold: true);

      expect(tile(tester).onTap, isNotNull);
    });
  });
}

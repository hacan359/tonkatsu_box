import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/storage_root.dart';
import 'package:tonkatsu_box/features/settings/widgets/storage_location_section.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_section_test');
    StorageRoot.defaultPathProvider = () async => tempDir.path;
    // Real SQLite IO never completes inside FakeAsync; stub the verdict.
    StorageRoot.validateDataDirOverride =
        (String dir) async => DataDirVerdict.ok;
    StorageRoot.resetSessionCache();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    StorageRoot.defaultPathProvider = null;
    StorageRoot.validateDataDirOverride = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageLocationSection', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await tester.pumpApp(
        const StorageLocationSection(),
        wrapInScaffold: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const StorageLocationSection(),
        wrapInScaffold: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the resolved data folder path',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const StorageLocationSection(),
        wrapInScaffold: true,
      );

      expect(find.textContaining(tempDir.path), findsOneWidget);
    });

    testWidgets('shows the custom folder when one is configured',
        (WidgetTester tester) async {
      final String customDir = p.join(tempDir.path, 'custom');
      // Sync IO: real async IO never completes inside testWidgets' FakeAsync.
      Directory(customDir).createSync(recursive: true);
      File(p.join(customDir, 'tonkatsu_box.db')).writeAsStringSync('db');
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageRoot.prefsKey: customDir,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpApp(
        const StorageLocationSection(),
        prefs: prefs,
        wrapInScaffold: true,
      );

      expect(find.textContaining(customDir), findsOneWidget);
    });
  });
}

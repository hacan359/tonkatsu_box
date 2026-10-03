import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/import_progress.dart';
import 'package:tonkatsu_box/l10n/app_localizations_en.dart';
import 'package:tonkatsu_box/shared/constants/import_stage_ui.dart';

void main() {
  group('ImportStageUi', () {
    test('every stage has a non-empty label', () {
      final SEn l = SEn();
      for (final ImportStage stage in ImportStage.values) {
        expect(stage.label(l), isNotEmpty, reason: stage.name);
      }
    });
  });
}

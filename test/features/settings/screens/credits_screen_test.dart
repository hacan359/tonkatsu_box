import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/settings/screens/credits_screen.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/constants/localization_delegates.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      localizationsDelegates: kAppLocalizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: CreditsScreen()),
    );
  }

  group('CreditsScreen', () {
    testWidgets('View Open Source Licenses button is tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Open Source Licenses'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

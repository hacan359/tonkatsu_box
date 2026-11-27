import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tonkatsu_box/core/services/update_service.dart';
import 'package:tonkatsu_box/shared/navigation/app_top_bar.dart';
import 'package:tonkatsu_box/shared/navigation/frame_chrome.dart';
import 'package:tonkatsu_box/shared/navigation/nav_tab.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AppTopBar', () {
    late FrameChromeController chrome;

    setUp(() => chrome = FrameChromeController());
    tearDown(() => chrome.dispose());

    Future<void> pumpBar(WidgetTester tester, {required double width}) {
      return tester.pumpApp(
        Center(
          child: SizedBox(
            width: width,
            child: FrameChromeScope(
              controller: chrome,
              child: AppTopBar(
                activeTab: NavTab.settings,
                onSettingsTap: () {},
              ),
            ),
          ),
        ),
        overrides: <Override>[
          updateCheckProvider.overrideWith((Ref ref) async => null),
        ],
      );
    }

    void lendLongChrome() {
      chrome.set(
        const Object(),
        FrameChrome(
          title: 'A sub-screen title long enough to hit the title cap',
          onBack: () {},
          actions: const <Widget>[
            SizedBox(width: 40, height: 40),
            SizedBox(width: 40, height: 40),
          ],
        ),
      );
    }

    testWidgets('should show the search field when there is room', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, width: 900);

      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should hide the search field when the screen opts out', (
      WidgetTester tester,
    ) async {
      chrome.set(const Object(), FrameChrome(onBack: () {}, showSearch: false));
      await pumpBar(tester, width: 900);

      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should drop the search field when title and actions leave no room',
      (WidgetTester tester) async {
        lendLongChrome();
        await pumpBar(tester, width: 470);

        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('should shrink the title when the buttons leave it less', (
      WidgetTester tester,
    ) async {
      lendLongChrome();
      await pumpBar(tester, width: 300);

      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

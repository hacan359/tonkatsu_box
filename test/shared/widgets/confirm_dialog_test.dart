import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/constants/localization_delegates.dart';
import 'package:tonkatsu_box/shared/widgets/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    Future<void> openDialog(
      WidgetTester tester, {
      String? cancelLabel,
      ValueChanged<bool>? onResult,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () async {
                  final bool result = await ConfirmDialog.show(
                    context,
                    title: 'Delete item?',
                    message: 'This cannot be undone.',
                    confirmLabel: 'Delete',
                    cancelLabel: cancelLabel,
                  );
                  onResult?.call(result);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('should render title and message', (WidgetTester tester) async {
      await openDialog(tester);
      expect(find.text('Delete item?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('should show the confirm label and default Cancel',
        (WidgetTester tester) async {
      await openDialog(tester);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should use a custom cancel label when given',
        (WidgetTester tester) async {
      await openDialog(tester, cancelLabel: 'Keep');
      expect(find.text('Keep'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('should return true when confirm is tapped',
        (WidgetTester tester) async {
      bool? result;
      await openDialog(tester, onResult: (bool r) => result = r);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('should return false when cancel is tapped',
        (WidgetTester tester) async {
      bool? result;
      await openDialog(tester, onResult: (bool r) => result = r);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('should return false when dismissed by the barrier',
        (WidgetTester tester) async {
      bool? result;
      await openDialog(tester, onResult: (bool r) => result = r);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';

void main() {
  Widget createWidget({
    String value = '',
    ValueChanged<String>? onChanged,
    String? label,
    String? placeholder,
    bool obscureText = false,
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: InlineTextField(
          value: value,
          onChanged: onChanged ?? (_) {},
          label: label,
          placeholder: placeholder,
          obscureText: obscureText,
          compact: compact,
        ),
      ),
    );
  }

  group('InlineTextField', () {
    group('display mode', () {
      testWidgets('shows value text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'Hello'));
        expect(find.text('Hello'), findsOneWidget);
      });

      testWidgets('shows placeholder when value is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: '', placeholder: 'Enter text'),
        );
        expect(find.text('Enter text'), findsOneWidget);
      });

      testWidgets('shows dots when obscureText is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'secret', obscureText: true),
        );
        // Should show bullet dots, not the actual value
        expect(find.text('secret'), findsNothing);
        expect(
          find.text('\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsOneWidget,
        );
      });

      testWidgets('shows label when provided', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'test', label: 'Username'),
        );
        expect(find.text('Username'), findsOneWidget);
      });

      testWidgets('no label renders without label text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'test'));
        // Only the value text
        expect(find.text('test'), findsOneWidget);
      });

      testWidgets('no TextField in display mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'test'));
        expect(find.byType(TextField), findsNothing);
      });
    });

    group('editing mode', () {
      testWidgets('tap enters editing mode with TextField',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'Hello'));

        // Tap to enter editing mode
        await tester.tap(find.text('Hello'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('TextField shows current value in editing mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'Initial'));

        await tester.tap(find.text('Initial'));
        await tester.pumpAndSettle();

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('Initial'));
      });

      testWidgets('Enter commits and exits editing mode',
          (WidgetTester tester) async {
        String? result;
        await tester.pumpWidget(
          createWidget(
            value: '',
            onChanged: (String v) => result = v,
          ),
        );

        // Enter editing mode by tapping the placeholder area
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Type text
        await tester.enterText(find.byType(TextField), 'New Value');

        // Press Enter
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(result, equals('New Value'));
        // Should exit editing mode — no TextField
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('trims whitespace on commit',
          (WidgetTester tester) async {
        String? result;
        await tester.pumpWidget(
          createWidget(
            value: '',
            onChanged: (String v) => result = v,
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '  trimmed  ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(result, equals('trimmed'));
      });
    });

    group('obscureText', () {
      testWidgets('shows visibility toggle when obscureText is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'secret', obscureText: true),
        );
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('no visibility toggle when obscureText is false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'visible'));
        expect(find.byIcon(Icons.visibility), findsNothing);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });

      testWidgets('tapping visibility toggle reveals text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'secret', obscureText: true),
        );

        // Initially obscured (dots shown)
        expect(find.text('secret'), findsNothing);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        // Now text is visible
        expect(find.text('secret'), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('tapping visibility again hides text',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'secret', obscureText: true),
        );

        // Reveal
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();
        expect(find.text('secret'), findsOneWidget);

        // Hide again
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();
        expect(find.text('secret'), findsNothing);
      });
    });

    group('compact mode', () {
      testWidgets('normal height is 42', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(value: 'test'));

        final AnimatedContainer container =
            tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).last,
        );
        expect(container.constraints?.maxHeight, equals(42.0));
      });

      testWidgets('compact height is 38', (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'test', compact: true),
        );

        final AnimatedContainer container =
            tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).last,
        );
        expect(container.constraints?.maxHeight, equals(38.0));
      });

      testWidgets('field renders without error in compact mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(value: 'test', compact: true),
        );
        expect(find.text('test'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('blur commit', () {
      testWidgets('losing focus commits value', (WidgetTester tester) async {
        String? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  InlineTextField(
                    value: '',
                    onChanged: (String v) => result = v,
                  ),
                  const TextField(key: Key('other')),
                ],
              ),
            ),
          ),
        );

        // Enter editing mode
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Type text
        await tester.enterText(find.byType(TextField).first, 'Blur Value');

        // Move focus to another field
        await tester.tap(find.byKey(const Key('other')));
        await tester.pumpAndSettle();

        expect(result, equals('Blur Value'));
        // Should exit editing mode
        expect(
          find.descendant(
            of: find.byType(InlineTextField),
            matching: find.byType(TextField),
          ),
          findsNothing,
        );
      });
    });

    group('commit guard', () {
      testWidgets('does not call onChanged when value unchanged',
          (WidgetTester tester) async {
        int callCount = 0;
        await tester.pumpWidget(
          createWidget(
            value: 'Same',
            onChanged: (String v) => callCount++,
          ),
        );

        // Enter editing and submit without changing
        await tester.tap(find.text('Same'));
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(callCount, equals(0));
      });

      testWidgets('does not call onChanged when only whitespace added',
          (WidgetTester tester) async {
        int callCount = 0;
        await tester.pumpWidget(
          createWidget(
            value: 'Same',
            onChanged: (String v) => callCount++,
          ),
        );

        await tester.tap(find.text('Same'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '  Same  ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(callCount, equals(0));
      });
    });

    group('obscureText with empty value', () {
      testWidgets('shows placeholder instead of dots when value is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidget(
            value: '',
            obscureText: true,
            placeholder: 'Enter key',
          ),
        );
        // Should show placeholder, not dots
        expect(find.text('Enter key'), findsOneWidget);
        expect(
          find.text(
              '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsNothing,
        );
      });
    });

    group('didUpdateWidget during editing', () {
      testWidgets('does not update controller when editing',
          (WidgetTester tester) async {
        String currentValue = 'Original';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      InlineTextField(
                        value: currentValue,
                        onChanged: (String v) =>
                            setState(() => currentValue = v),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => currentValue = 'External'),
                        child: const Text('Change'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Enter editing mode
        await tester.tap(find.text('Original'));
        await tester.pumpAndSettle();

        // Type something
        await tester.enterText(find.byType(TextField), 'My Edit');

        // External update — should NOT overwrite the editing TextField
        await tester.tap(find.text('Change'));
        await tester.pumpAndSettle();

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('My Edit'));
      });
    });

    group('external updates', () {
      testWidgets('updates text when value changes externally',
          (WidgetTester tester) async {
        String currentValue = 'Original';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      InlineTextField(
                        value: currentValue,
                        onChanged: (String v) =>
                            setState(() => currentValue = v),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => currentValue = 'Updated'),
                        child: const Text('Update'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Original'), findsOneWidget);

        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();

        expect(find.text('Updated'), findsOneWidget);
      });
    });
  });
}

import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/welcome/screens/welcome_screen.dart';
import 'package:tonkatsu_box/features/welcome/widgets/step_indicator.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_intro.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_language.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_name.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_ready.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget({bool fromSettings = false}) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: WelcomeScreen(fromSettings: fromSettings),
      ),
    );
  }

  group('WelcomeScreen', () {
    group('initial state', () {
      testWidgets('shows first step (Intro)', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(WelcomeStepIntro), findsOneWidget);
      });

      testWidgets('shows 6 StepIndicators', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(StepIndicator), findsNWidgets(6));
      });

      testWidgets('shows step labels', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Welcome'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('API Keys'), findsOneWidget);
        expect(find.text('How it works'), findsOneWidget);
        expect(find.text('Ready!'), findsOneWidget);
      });

      testWidgets('shows progress bar', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('progress bar shows 1/6 on first step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final LinearProgressIndicator indicator =
            tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(1 / 6, 0.01));
      });

      testWidgets('shows Skip link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Skip'), findsOneWidget);
      });

      testWidgets('shows Next button', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('shows Back button (disabled on first page)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Back'), findsOneWidget);

        final TextButton backButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Back'),
        );
        expect(backButton.onPressed, isNull);
      });

      testWidgets('shows 6 dot indicators', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(AnimatedContainer), findsNWidgets(6));
      });
    });

    group('PageView navigation', () {
      testWidgets('Next button navigates to step 2 (Name)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepName), findsOneWidget);
      });

      testWidgets('progress bar updates on step 2',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final LinearProgressIndicator indicator =
            tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(2 / 6, 0.01));
      });

      testWidgets('Back button is enabled on step 2',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final TextButton backButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Back'),
        );
        expect(backButton.onPressed, isNotNull);
      });

      testWidgets('Back button navigates to previous step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Back'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepIntro), findsOneWidget);
      });

      testWidgets('can navigate to step 3 (Language)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepLanguage), findsOneWidget);
      });

      testWidgets('can navigate to step 6 (Ready)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        expect(find.byType(WelcomeStepReady), findsOneWidget);
      });

      testWidgets('Next button hidden on last step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Next'), findsNothing);
      });

      testWidgets('Skip link hidden on last step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Skip'), findsNothing);
      });

      testWidgets('progress bar shows 6/6 on last step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        final LinearProgressIndicator indicator =
            tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(1.0, 0.01));
      });
    });

    group('Skip functionality', () {
      testWidgets('Skip jumps to last step', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepReady), findsOneWidget);
      });
    });

    group('dot indicators', () {
      testWidgets('tapping a dot navigates to that page',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final Finder dots = find.byType(AnimatedContainer);
        expect(dots, findsNWidgets(6));

        await tester.tap(dots.at(2));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepLanguage), findsOneWidget);
      });
    });

    group('step indicator tapping', () {
      testWidgets('tapping StepIndicator navigates to that step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final Finder nameIndicator = find.widgetWithText(
          StepIndicator,
          'Name',
        );
        expect(nameIndicator, findsOneWidget);
        await tester.tap(nameIndicator);
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepName), findsOneWidget);
      });
    });

    group('kWelcomeCompletedKey', () {
      test('is a non-empty string', () {
        expect(kWelcomeCompletedKey, isNotEmpty);
        expect(kWelcomeCompletedKey, equals('welcome_completed'));
      });
    });

    group('swipe navigation', () {
      testWidgets('swiping left goes to next step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Fling works better than drag with nested scrollables.
        await tester.fling(
          find.byType(PageView),
          const Offset(-300, 0),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(WelcomeStepName), findsOneWidget);
      });

      testWidgets('swiping right on first step does nothing',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.fling(
          find.byType(PageView),
          const Offset(300, 0),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(WelcomeStepIntro), findsOneWidget);
      });
    });

    group('compact mode', () {
      testWidgets('shows labels on narrow screen only for active step',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(500, 800),
                ),
                child: WelcomeScreen(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Welcome'), findsOneWidget);
        expect(find.text('API Keys'), findsNothing);
        expect(find.text('Ready!'), findsNothing);
      });
    });

    group('finish actions', () {
      testWidgets('Go to Settings saves welcome_completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Go to Settings'));
        // AppShell shimmer never settles, so pumpAndSettle would hang.
        await tester.pump();
        await tester.pump();

        expect(prefs.getBool(kWelcomeCompletedKey), isTrue);
      });

      testWidgets('Skip button on step 4 saves welcome_completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Skip — explore on my own'));
        // AppShell shimmer blocks pumpAndSettle.
        await tester.pump();
        await tester.pump();

        expect(prefs.getBool(kWelcomeCompletedKey), isTrue);
      });
    });

    group('fromSettings mode', () {
      testWidgets('pops on finish when fromSettings is true',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
              home: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const WelcomeScreen(fromSettings: true),
                        ),
                      );
                    },
                    child: const Text('Open Welcome'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Welcome'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeScreen), findsOneWidget);

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Skip — explore on my own'));
        await tester.pumpAndSettle();

        expect(find.text('Open Welcome'), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);
      });

      testWidgets('saves welcome_completed when fromSettings',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
              home: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const WelcomeScreen(fromSettings: true),
                        ),
                      );
                    },
                    child: const Text('Open Welcome'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Welcome'));
        await tester.pumpAndSettle();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Skip — explore on my own'));
        await tester.pumpAndSettle();

        expect(prefs.getBool(kWelcomeCompletedKey), isTrue);
      });
    });
  });
}

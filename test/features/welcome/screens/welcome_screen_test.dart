import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/welcome/screens/welcome_screen.dart';
import 'package:tonkatsu_box/features/welcome/widgets/step_indicator.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_intro.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_language.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_menu_tour.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_name.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_sources.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

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

  /// Taps the wizard's global Next button. Only safe on steps 0–3, where
  /// 'Next' is unique (the tour shows its own button).
  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  /// Steps forward to the final menu-tour page.
  Future<void> goToTour(WidgetTester tester) async {
    for (int i = 0; i < 4; i++) {
      await tapNext(tester);
    }
  }

  group('WelcomeScreen', () {
    group('initial state', () {
      testWidgets('shows first step (Intro)', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(WelcomeStepIntro), findsOneWidget);
      });

      testWidgets('shows 5 StepIndicators', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(StepIndicator), findsNWidgets(5));
      });

      testWidgets('shows step labels', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Welcome'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Sources'), findsOneWidget);
        expect(find.text('Tour'), findsOneWidget);
      });

      testWidgets('progress bar shows 1/5 on first step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        final LinearProgressIndicator indicator =
            tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(1 / 5, 0.01));
      });

      testWidgets('shows 5 dot indicators', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(AnimatedContainer), findsNWidgets(5));
      });
    });

    group('PageView navigation', () {
      testWidgets('Next navigates to step 2 (Language)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tapNext(tester);

        expect(find.byType(WelcomeStepLanguage), findsOneWidget);
      });

      testWidgets('can navigate to step 3 (Name)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tapNext(tester);
        await tapNext(tester);

        expect(find.byType(WelcomeStepName), findsOneWidget);
      });

      testWidgets('can navigate to step 4 (Sources)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tapNext(tester);
        await tapNext(tester);
        await tapNext(tester);

        expect(find.byType(WelcomeStepSources), findsOneWidget);
      });

      testWidgets('reaches the menu tour on the last step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await goToTour(tester);

        expect(find.byType(WelcomeStepMenuTour), findsOneWidget);
      });

      testWidgets('global bottom nav is hidden on the tour step',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await goToTour(tester);

        // The wizard's own Back disappears — the tour drives itself.
        expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
      });
    });

    group('Skip functionality', () {
      testWidgets('Skip jumps to the tour step', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeStepMenuTour), findsOneWidget);
      });
    });

    group('kWelcomeCompletedKey', () {
      test('is the expected key', () {
        expect(kWelcomeCompletedKey, equals('welcome_completed'));
      });
    });

    group('compact mode', () {
      testWidgets('shows labels only for the active step on narrow screens',
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
                data: MediaQueryData(size: Size(500, 800)),
                child: WelcomeScreen(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Welcome'), findsOneWidget);
        expect(find.text('Sources'), findsNothing);
        expect(find.text('Tour'), findsNothing);
      });
    });

    group('finish actions', () {
      testWidgets('skipping the tour saves welcome_completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await goToTour(tester);

        await tester.tap(find.text('Skip — explore on my own'));
        // AppShell shimmer never settles, so pumpAndSettle would hang.
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

        await goToTour(tester);
        await tester.tap(find.text('Skip — explore on my own'));
        await tester.pumpAndSettle();

        expect(find.text('Open Welcome'), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);
      });
    });
  });
}

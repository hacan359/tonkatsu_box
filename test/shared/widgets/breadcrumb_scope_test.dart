// Тесты для BreadcrumbScope InheritedWidget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  group('BreadcrumbScope', () {
    group('of()', () {
      testWidgets('возвращает один label для одного scope',
          (WidgetTester tester) async {
        List<String>? result;

        await tester.pumpWidget(
          MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: Builder(
                builder: (BuildContext context) {
                  result = BreadcrumbScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, <String>['Settings']);
      });

      testWidgets('возвращает вложенные labels в порядке от корня',
          (WidgetTester tester) async {
        List<String>? result;

        await tester.pumpWidget(
          MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: BreadcrumbScope(
                label: 'Debug',
                child: BreadcrumbScope(
                  label: 'SteamGridDB',
                  child: Builder(
                    builder: (BuildContext context) {
                      result = BreadcrumbScope.of(context);
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, <String>['Settings', 'Debug', 'SteamGridDB']);
      });

      testWidgets('возвращает пустой список без scope',
          (WidgetTester tester) async {
        List<String>? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                result = BreadcrumbScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, isEmpty);
      });

      testWidgets('scope видим через Navigator для pushed routes',
          (WidgetTester tester) async {
        List<String>? result;

        await tester.pumpWidget(
          MaterialApp(
            home: BreadcrumbScope(
              label: 'Root',
              child: Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return BreadcrumbScope(
                        label: 'Child',
                        child: Builder(
                          builder: (BuildContext ctx) {
                            result = BreadcrumbScope.of(ctx);
                            return const SizedBox();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(result, <String>['Root', 'Child']);
      });
    });

    group('updateShouldNotify()', () {
      test('возвращает true при изменении label', () {
        const BreadcrumbScope oldScope = BreadcrumbScope(
          label: 'Old',
          child: SizedBox(),
        );
        const BreadcrumbScope newScope = BreadcrumbScope(
          label: 'New',
          child: SizedBox(),
        );

        expect(newScope.updateShouldNotify(oldScope), isTrue);
      });

      test('возвращает false при одинаковом label', () {
        const BreadcrumbScope oldScope = BreadcrumbScope(
          label: 'Same',
          child: SizedBox(),
        );
        const BreadcrumbScope newScope = BreadcrumbScope(
          label: 'Same',
          child: SizedBox(),
        );

        expect(newScope.updateShouldNotify(oldScope), isFalse);
      });
    });

    group('rebuild при изменении label', () {
      testWidgets('виджет перестраивается при смене label (loading → loaded)',
          (WidgetTester tester) async {
        final ValueNotifier<String> labelNotifier =
            ValueNotifier<String>('...');
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<String>(
              valueListenable: labelNotifier,
              builder: (BuildContext context, String label, Widget? child) {
                return BreadcrumbScope(
                  label: label,
                  child: Builder(
                    builder: (BuildContext ctx) {
                      BreadcrumbScope.of(ctx);
                      buildCount++;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final int initialBuildCount = buildCount;

        // Меняем label
        labelNotifier.value = 'Item Name';
        await tester.pumpAndSettle();

        // Builder должен был перестроиться
        expect(buildCount, greaterThan(initialBuildCount));

        labelNotifier.dispose();
      });
    });
  });
}

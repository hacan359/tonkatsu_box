import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/selfhost/server_auth_token.dart';
import 'package:tonkatsu_box/features/splash/screens/server_token_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;

  setUp(() async {
    mockDb = MockDatabaseService();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ServerAuthToken.init(await SharedPreferences.getInstance());
  });

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    const ServerTokenScreen(),
    overrides: <Override>[databaseServiceProvider.overrideWithValue(mockDb)],
  );

  group('ServerTokenScreen', () {
    testWidgets('should render without exceptions', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should not call the server when the field is empty', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verifyNever(mockDb.warmUp);
      expect(ServerAuthToken.current, isNull);
    });

    testWidgets('should store the token and probe the server on submit', (
      WidgetTester tester,
    ) async {
      when(mockDb.warmUp).thenAnswer((_) async {});
      await pump(tester);

      await tester.enterText(find.byType(TextField), '  abc  ');
      await tester.tap(find.byType(FilledButton));
      // No AppRestartScope above the screen, so the spinner stays: pump by
      // hand instead of settling.
      await tester.pump();
      await tester.pump();

      expect(ServerAuthToken.current, 'abc');
      verify(mockDb.warmUp).called(1);
    });

    testWidgets('should show an error and stay when the server rejects it', (
      WidgetTester tester,
    ) async {
      when(mockDb.warmUp).thenAnswer(
        (_) => Future<void>.error(
          const RpcException(kRpcErrorKindAuth, 'Missing or wrong token'),
        ),
      );
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(ServerTokenScreen), findsOneWidget);
      final TextField field = tester.widget(find.byType(TextField));
      expect(field.decoration?.errorText, isNotNull);
      expect(field.focusNode?.hasFocus, isTrue);
      expect(field.controller?.selection.extentOffset, 'wrong'.length);
    });

    testWidgets('should surface a non-auth failure as the error text', (
      WidgetTester tester,
    ) async {
      when(mockDb.warmUp).thenAnswer(
        (_) => Future<void>.error(
          const RpcException('transport', 'server unreachable'),
        ),
      );
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.decoration?.errorText, contains('server unreachable'));
    });

    testWidgets('should fit a phone-sized screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pump(tester);

      expect(tester.takeException(), isNull);
    });
  });
}

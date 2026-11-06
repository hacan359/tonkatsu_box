import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/app_frame.dart';
import 'package:tonkatsu_box/shared/widgets/glass_panel.dart';

import '../../helpers/test_helpers.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const Text('probe');
}

void main() {
  group('AppFrame', () {
    Widget frame({required bool compact, required Key probeKey}) => AppFrame(
      compact: compact,
      topZone: const Text('top'),
      menuZone: const Text('menu'),
      child: _Probe(key: probeKey),
    );

    testWidgets('рисует зоны и контент', (WidgetTester tester) async {
      await tester.pumpApp(frame(compact: false, probeKey: GlobalKey()));

      expect(find.text('top'), findsOneWidget);
      expect(find.text('menu'), findsOneWidget);
      expect(find.text('probe'), findsOneWidget);
      expect(find.byType(GlassPanel), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('смена compact/wide сохраняет элемент контента', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_ProbeState> key = GlobalKey<_ProbeState>();
      await tester.pumpApp(frame(compact: false, probeKey: key));
      final _ProbeState? before = key.currentState;
      expect(before, isNotNull);

      await tester.pumpApp(frame(compact: true, probeKey: key));

      expect(key.currentState, same(before));
      expect(tester.takeException(), isNull);
    });

    testWidgets('контент получает нулевой MediaQuery.padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.all(20)),
          child: AppFrame(
            compact: true,
            topZone: const SizedBox(),
            menuZone: const SizedBox(),
            child: Builder(
              builder: (BuildContext context) =>
                  Text('${MediaQuery.paddingOf(context)}'),
            ),
          ),
        ),
      );

      expect(find.text('${EdgeInsets.zero}'), findsOneWidget);
    });
  });
}

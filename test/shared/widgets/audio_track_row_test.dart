import 'package:core/models/audio_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/audio_track_row.dart';

import '../../helpers/test_helpers.dart';

void main() {
  const String longTitle =
      'Episode 412 — a very long discussion title that cannot possibly fit '
      'one line of a phone-width row and gets ellipsized';

  AudioTrack track({String title = longTitle}) => AudioTrack(
        audioId: 1,
        discNumber: 1,
        position: 1,
        title: title,
      );

  group('AudioTrackRow', () {
    testWidgets('should toggle the mark when the circle is tapped',
        (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpApp(
        Material(
          child: AudioTrackRow(
            track: track(),
            listened: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      expect(taps, 1);
    });

    testWidgets('should expand the title, not toggle, when the text is tapped',
        (WidgetTester tester) async {
      int taps = 0;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        Material(
          child: AudioTrackRow(
            track: track(),
            listened: false,
            onTap: () => taps++,
          ),
        ),
      );

      Text title() => tester.widget<Text>(find.text(longTitle));
      expect(title().maxLines, 1);

      await tester.tap(find.text(longTitle));
      await tester.pump();

      expect(taps, 0);
      expect(title().maxLines, isNull);

      await tester.tap(find.text(longTitle));
      await tester.pump();
      expect(title().maxLines, 1);
    });

    testWidgets('should expand a plain row without a mark',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Material(child: AudioTrackRow(track: track())),
      );

      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

      await tester.tap(find.text(longTitle));
      await tester.pump();

      final Text title = tester.widget<Text>(find.text(longTitle));
      expect(title.maxLines, isNull);
    });
  });
}

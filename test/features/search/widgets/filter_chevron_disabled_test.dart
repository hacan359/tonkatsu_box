import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_tag_filter.dart';
import 'package:tonkatsu_box/features/search/providers/browse_provider.dart';
import 'package:tonkatsu_box/features/search/widgets/filter_control.dart';
import 'package:tonkatsu_box/shared/theme/app_colors.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FilterChevron disabledReason', () {
    testWidgets('should swallow taps and explain instead of picking',
        (WidgetTester tester) async {
      int picks = 0;
      await tester.pumpApp(
        SizedBox(
          width: 220,
          height: 40,
          child: FilterChevron(
            filter: AniListTagFilter(forAnime: true),
            value: null,
            accentColor: AppColors.brand,
            isLast: true,
            disabledReason: 'blocked by studio',
            onPick: (Object? _, CommonSelection? _) => picks++,
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(FilterChevron));
      await tester.pump();

      expect(picks, 0);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}

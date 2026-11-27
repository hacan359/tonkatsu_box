import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/frame_inset.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/frame_page.dart';
import '../content/cache_content.dart';

class CacheScreen extends StatelessWidget {
  const CacheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isWide = width >= 800;

    return FramePage(
      title: S.of(context).cacheTitle,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: FrameBleed(
            builder: (BuildContext context, EdgeInsets bars) =>
                SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(
                        horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ) +
                      bars,
                  child: const CacheContent(),
                ),
          ),
        ),
      ),
    );
  }
}

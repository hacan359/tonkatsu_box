import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/frame_page.dart';

/// A section pushed over the hub: title strip with back, then the section's
/// own screen, which keeps knowing nothing about where it is hosted.
class PersonalizationSubScreen extends StatelessWidget {
  const PersonalizationSubScreen({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FramePage(title: title, child: child);
  }
}

/// Pushes [child] as a hub section onto the nearest navigator — the hub's own.
Future<void> pushPersonalizationSection(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext _) =>
          PersonalizationSubScreen(title: title, child: child),
    ),
  );
}

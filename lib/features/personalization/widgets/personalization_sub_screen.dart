import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';

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
    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          SubScreenTitleBar(title: title),
          Expanded(child: child),
        ],
      ),
    );
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

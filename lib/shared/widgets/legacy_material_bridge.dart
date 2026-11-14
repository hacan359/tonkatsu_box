import 'package:material_ui/material_ui.dart';

/// Feeds the app theme and locale to packages still built on the in-SDK
/// Material (trina_grid, calendar_view); drop it once they move to material_ui.
class LegacyMaterialBridge extends StatelessWidget {
  const LegacyMaterialBridge({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The bridge ships deprecated on purpose, to flag it as temporary.
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(child: child);
  }
}

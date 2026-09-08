import 'package:flutter/material.dart';

import 'personalization_hub_screen.dart';

/// The hub's own navigator, so a section opens over the landing page and the
/// shell's back handling can pop it before closing the hub.
class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({this.navigatorKey, super.key});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext _) => const PersonalizationHubScreen(),
      ),
    );
  }
}

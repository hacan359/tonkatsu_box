import 'package:flutter/services.dart';

/// No local database in the browser — the DAOs are RPC stubs. The one thing to
/// switch off is the native menu, which would cover our own right-click menus.
void initPlatform() {
  BrowserContextMenu.disableContextMenu();
}

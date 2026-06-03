// Main navigation tabs of the app.

/// Tab indices for the primary navigation.
///
/// Used by [AppShell] to switch tabs and by external screens (e.g.
/// [WelcomeScreen]) to set the starting tab.
enum NavTab {
  /// Home screen (all items).
  home,

  /// Collections.
  collections,

  /// Tier lists.
  tierLists,

  /// Releases (new episodes of tracked shows).
  releases,

  /// Wishlist (search notes).
  wishlist,

  /// Search.
  search,

  /// Settings.
  settings,
}

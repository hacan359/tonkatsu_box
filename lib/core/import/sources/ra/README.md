# RetroAchievements import

Imports a RetroAchievements profile into a collection. Built on the shared
[import layer](../../README.md).

- **Input:** RA username + an add-to-wishlist toggle (`RaImportService.import`).
- **Source:** the user's RA profile (completed games + achievement progress).
  Already-linked games skip matching; the rest are searched on IGDB by name in
  throttled batches. Platform is derived from the RA console id.
- **Media:** `game`.
- **Write:** through `ImportWriter` for the collection items (RA is the
  authoritative progress source, so status downgrades are allowed). After the
  batch write, each matched game's `tracker_game_data` row is written in a
  post-write pass, keyed by IGDB id + platform, which `ImportWriter` does not
  cover. Unmatched games optionally fall back to the wishlist under a
  `RetroAchievements` tag.

> The shared RA helpers (`ra_sync_helpers.dart`, `ra_to_igdb_mapper.dart`) stay
> in `core/services` because the tracker-sync feature uses them too.

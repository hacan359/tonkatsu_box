# Steam import

Imports a Steam library into a collection. Built on the shared
[import layer](../../README.md).

- **Input:** Steam Web API key + SteamID (`SteamImportService.import`).
- **Source:** owned games + playtime + last-played from the Steam Web API; DLC
  and soundtracks are filtered out.
- **Matching:** resolved to IGDB by Steam App ID in one batch lookup (no per-row
  search). Platform is PC (IGDB id 6).
- **Media:** `game`.
- **Write:** through `ImportWriter`. New games are batch-inserted; existing ones
  get play time and last-activity refreshed, with the status bumped toward "in
  progress" without ever downgrading a local `completed` / `dropped`. Unmatched
  titles batch into the text wishlist under a `Steam` tag.

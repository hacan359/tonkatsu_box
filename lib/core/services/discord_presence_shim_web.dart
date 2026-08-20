/// Web stand-in: [kDiscordRpcAvailable] guards keep it unreachable, and
/// initialize() fails safe if one is ever missed.
class DiscordRPC {
  DiscordRPC();

  Future<void> initialize(String applicationId) async {
    throw UnsupportedError('Discord RPC is not available on the web build');
  }

  Future<void> setPresence(DiscordPresence presence) async {
    throw UnsupportedError('Discord RPC is not available on the web build');
  }

  Future<void> dispose() async {}
}

class DiscordPresence {
  const DiscordPresence({
    this.state,
    this.details,
    this.timestamps,
    this.largeAsset,
    this.smallAsset,
  });

  final String? state;
  final String? details;
  final DiscordTimestamps? timestamps;
  final DiscordAsset? largeAsset;
  final DiscordAsset? smallAsset;
}

class DiscordAsset {
  const DiscordAsset({this.key, this.text}) : url = null;

  const DiscordAsset.fromUrl(this.url, {this.text}) : key = null;

  final String? key;
  final String? url;
  final String? text;
}

class DiscordTimestamps {
  const DiscordTimestamps({this.start, this.end});

  final int? start;
  final int? end;
}

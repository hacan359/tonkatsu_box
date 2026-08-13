/// Albums and podcasts share the `audio` [MediaType]; this is the stored
/// discriminator in `audio_cache.kind`, carried through export / import.
enum AudioKind {
  /// Music album — a MusicBrainz release-group.
  album('album'),

  /// Podcast feed (Podcast Index).
  podcast('podcast');

  const AudioKind(this.value);

  /// Stable storage value written to the DB / export payload.
  final String value;

  /// Card caption shown instead of the generic "Audio" media-type label,
  /// the way anime cards show "TV" / "OVA". Proper nouns, not localized.
  String get cardLabel => this == AudioKind.podcast ? 'Podcast' : 'Music';

  /// Unknown / null falls back to [AudioKind.album], so rows predating the
  /// column stay albums.
  static AudioKind fromName(String? value) {
    if (value == null) return AudioKind.album;
    for (final AudioKind kind in AudioKind.values) {
      if (kind.value == value) return kind;
    }
    return AudioKind.album;
  }
}

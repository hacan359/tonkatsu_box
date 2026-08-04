import 'dart:convert';

/// Visual novel from the VNDB API.
class VisualNovel {
  const VisualNovel({
    required this.id,
    required this.title,
    this.altTitle,
    this.description,
    this.imageUrl,
    this.rating,
    this.voteCount,
    this.released,
    this.lengthMinutes,
    this.length,
    this.tags,
    this.developers,
    this.platforms,
    this.externalUrl,
    this.updatedAt,
  });

  factory VisualNovel.fromJson(Map<String, dynamic> json) {
    // The cover URL is nested in the `image` object.
    String? imageUrl;
    if (json['image'] != null) {
      final Map<String, dynamic> image =
          json['image'] as Map<String, dynamic>;
      imageUrl = image['url'] as String?;
    }

    // Names only, ordered by the tag's rating.
    List<String>? tags;
    if (json['tags'] != null) {
      final List<dynamic> tagsList = json['tags'] as List<dynamic>;
      final List<Map<String, dynamic>> sortedTags = tagsList
          .map((dynamic t) => t as Map<String, dynamic>)
          .toList()
        ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            ((b['rating'] as num?) ?? 0)
                .compareTo((a['rating'] as num?) ?? 0));
      tags = sortedTags
          .where((Map<String, dynamic> t) => t['name'] != null)
          .map((Map<String, dynamic> t) => t['name'] as String)
          .toList();
    }

    List<String>? developers;
    if (json['developers'] != null) {
      final List<dynamic> devList = json['developers'] as List<dynamic>;
      developers = devList
          .map((dynamic d) => d as Map<String, dynamic>)
          .where((Map<String, dynamic> d) => d['name'] != null)
          .map((Map<String, dynamic> d) => d['name'] as String)
          .toList();
    }

    List<String>? platforms;
    if (json['platforms'] != null) {
      final List<dynamic> platList = json['platforms'] as List<dynamic>;
      platforms = platList.map((dynamic p) => p as String).toList();
    }

    final String id = json['id'] as String;

    return VisualNovel(
      id: id,
      title: json['title'] as String,
      altTitle: json['alttitle'] as String?,
      description: _cleanDescription(json['description'] as String?),
      imageUrl: imageUrl,
      rating: (json['rating'] as num?)?.toDouble(),
      voteCount: json['votecount'] as int?,
      released: json['released'] as String?,
      lengthMinutes: json['length_minutes'] as int?,
      length: json['length'] as int?,
      tags: tags,
      developers: developers,
      platforms: platforms,
      externalUrl: 'https://vndb.org/$id',
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  factory VisualNovel.fromDb(Map<String, dynamic> row) {
    List<String>? tags;
    if (row['tags'] != null && (row['tags'] as String).isNotEmpty) {
      try {
        tags = (jsonDecode(row['tags'] as String) as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList();
      } on FormatException {
        tags = null;
      }
    }

    List<String>? developers;
    if (row['developers'] != null &&
        (row['developers'] as String).isNotEmpty) {
      try {
        developers =
            (jsonDecode(row['developers'] as String) as List<dynamic>)
                .map((dynamic e) => e as String)
                .toList();
      } on FormatException {
        developers = null;
      }
    }

    List<String>? platforms;
    if (row['platforms'] != null &&
        (row['platforms'] as String).isNotEmpty) {
      try {
        platforms =
            (jsonDecode(row['platforms'] as String) as List<dynamic>)
                .map((dynamic e) => e as String)
                .toList();
      } on FormatException {
        platforms = null;
      }
    }

    return VisualNovel(
      id: row['id'] as String,
      title: row['title'] as String,
      altTitle: row['alt_title'] as String?,
      description: row['description'] as String?,
      imageUrl: row['image_url'] as String?,
      rating: row['rating'] as double?,
      voteCount: row['vote_count'] as int?,
      released: row['released'] as String?,
      lengthMinutes: row['length_minutes'] as int?,
      length: row['length'] as int?,
      tags: tags,
      developers: developers,
      platforms: platforms,
      externalUrl: row['external_url'] as String?,
      updatedAt: row['updated_at'] as int?,
    );
  }

  /// VNDB id such as `v2`.
  final String id;

  final String title;

  /// Usually the original Japanese title.
  final String? altTitle;

  final String? description;

  final String? imageUrl;

  /// VNDB scale is 0–100; [rating10] converts it.
  final double? rating;

  final int? voteCount;

  /// May be partial: `2009-10-15` or just `2024`.
  final String? released;

  final int? lengthMinutes;

  /// VNDB length bucket 1–5; see [lengthLabel].
  final int? length;

  final List<String>? tags;

  final List<String>? developers;

  /// VNDB platform codes (`win`, `ps3`), not display labels.
  final List<String>? platforms;

  final String? externalUrl;

  /// Cache timestamp, Unix seconds.
  final int? updatedAt;

  /// Numeric form for `collection_items.external_id`.
  int get numericId {
    final int? parsed = int.tryParse(id.replaceFirst('v', ''));
    if (parsed == null) {
      throw FormatException('Invalid VNDB id format: $id');
    }
    return parsed;
  }

  double? get rating10 => rating != null ? rating! / 10 : null;

  String? get formattedRating {
    if (rating10 == null) return null;
    return rating10!.toStringAsFixed(1);
  }

  int? get releaseYear {
    if (released == null || released!.length < 4) return null;
    return int.tryParse(released!.substring(0, 4));
  }

  String? get genresString => tags?.join(', ');

  String? get lengthLabel => switch (length) {
        1 => '< 2h',
        2 => '2-10h',
        3 => '10-30h',
        4 => '30-50h',
        5 => '> 50h',
        _ => null,
      };

  String? get developersString => developers?.join(', ');

  String? get platformsString =>
      platforms?.map(_platformLabel).join(', ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisualNovel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VisualNovel(id: $id, title: $title)';

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'numeric_id': numericId,
      'title': title,
      'alt_title': altTitle,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'vote_count': voteCount,
      'released': released,
      'length_minutes': lengthMinutes,
      'length': length,
      'tags': tags != null ? jsonEncode(tags) : null,
      'developers': developers != null ? jsonEncode(developers) : null,
      'platforms': platforms != null ? jsonEncode(platforms) : null,
      'external_url': externalUrl,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('updated_at');
    return data;
  }

  VisualNovel copyWith({
    String? id,
    String? title,
    String? altTitle,
    String? description,
    String? imageUrl,
    double? rating,
    int? voteCount,
    String? released,
    int? lengthMinutes,
    int? length,
    List<String>? tags,
    List<String>? developers,
    List<String>? platforms,
    String? externalUrl,
    int? updatedAt,
  }) {
    return VisualNovel(
      id: id ?? this.id,
      title: title ?? this.title,
      altTitle: altTitle ?? this.altTitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      voteCount: voteCount ?? this.voteCount,
      released: released ?? this.released,
      lengthMinutes: lengthMinutes ?? this.lengthMinutes,
      length: length ?? this.length,
      tags: tags ?? this.tags,
      developers: developers ?? this.developers,
      platforms: platforms ?? this.platforms,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final RegExp _urlPattern = RegExp(r'\[url=[^\]]*\]');
  static final RegExp _boldPattern = RegExp(r'\[b\]|\[/b\]');
  static final RegExp _italicPattern = RegExp(r'\[i\]|\[/i\]');

  static String? _cleanDescription(String? description) {
    if (description == null) return null;
    // VNDB markup: [url=...]text[/url] and [spoiler]...[/spoiler].
    String clean = description;
    clean = clean.replaceAll(_urlPattern, '');
    clean = clean.replaceAll('[/url]', '');
    clean = clean.replaceAll('[spoiler]', '');
    clean = clean.replaceAll('[/spoiler]', '');
    clean = clean.replaceAll(_boldPattern, '');
    clean = clean.replaceAll(_italicPattern, '');
    clean = clean.trim();
    return clean.isEmpty ? null : clean;
  }

  static String _platformLabel(String code) => switch (code) {
        'win' => 'Windows',
        'lin' => 'Linux',
        'mac' => 'macOS',
        'and' => 'Android',
        'ios' => 'iOS',
        'swi' => 'Switch',
        'ps3' => 'PS3',
        'ps4' => 'PS4',
        'ps5' => 'PS5',
        'psv' => 'PS Vita',
        'psp' => 'PSP',
        'xb1' => 'Xbox One',
        'xbs' => 'Xbox Series',
        'web' => 'Web',
        'drc' => 'Dreamcast',
        'nes' => 'NES',
        'sfc' => 'SNES',
        'n64' => 'N64',
        'gba' => 'GBA',
        'nds' => 'NDS',
        'wii' => 'Wii',
        'p88' => 'PC-88',
        'p98' => 'PC-98',
        'x68' => 'X68000',
        'msx' => 'MSX',
        'sat' => 'Saturn',
        'ps1' => 'PS1',
        'ps2' => 'PS2',
        _ => code.toUpperCase(),
      };
}

/// A VNDB tag, used as a genre.
class VndbTag {
  const VndbTag({
    required this.id,
    required this.name,
  });

  factory VndbTag.fromJson(Map<String, dynamic> json) {
    return VndbTag(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  factory VndbTag.fromDb(Map<String, dynamic> row) {
    return VndbTag(
      id: row['id'] as String,
      name: row['name'] as String,
    );
  }

  /// VNDB tag id such as `g7`.
  final String id;

  final String name;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VndbTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VndbTag(id: $id, name: $name)';
}

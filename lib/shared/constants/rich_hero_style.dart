/// Visual style of the rich-collection hero banner, picked in settings.
enum RichHeroStyle {
  classic('classic'),
  comic('comic'),
  stickers('stickers'),
  brutalist('brutalist'),
  slats('slats');

  const RichHeroStyle(this.id);

  final String id;

  static RichHeroStyle fromId(String? id) => RichHeroStyle.values.firstWhere(
        (RichHeroStyle v) => v.id == id,
        orElse: () => RichHeroStyle.classic,
      );
}

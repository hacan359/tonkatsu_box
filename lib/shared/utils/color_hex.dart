import 'dart:ui';

/// Converts between hex strings (e.g. '#EF7B44') and [Color].
abstract final class ColorHex {
  /// Parses a hex string (with or without leading '#') into an opaque [Color].
  static Color fromHex(String hex) {
    final String cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  /// Formats a [Color] as '#RRGGBB' (alpha is dropped).
  static String toHex(Color color) {
    final int rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }
}
